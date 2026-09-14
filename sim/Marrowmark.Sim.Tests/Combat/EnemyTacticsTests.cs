using System.Collections.Generic;
using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// combat.md §6 claims a player learns all three shapes in the first
    /// hour by reading them. That is a claim about the ENEMY as much as the
    /// animation: an opponent that never throws a heavy teaches nobody to
    /// parry. These tests are mostly about teaching, not about winning.
    /// </summary>
    public class EnemyTacticsTests
    {
        private static EnemyTactics New(uint seed = 7) =>
            new EnemyTactics(EnemyTacticsProfile.Default, seed);

        private static Stamina Bar() => new Stamina(StaminaProfile.Default);

        /// <summary>Run a fight at a fixed distance and collect what was thrown.</summary>
        private static List<AttackShape> Spar(
            EnemyTactics t, float distance, int seconds = 120, float refill = 1f)
        {
            var thrown = new List<AttackShape>();
            var s = Bar();
            const float step = 1f / 30f;

            for (var i = 0; i < seconds * 30; i++)
            {
                t.Tick(step);
                s.Tick(step * refill);

                var d = t.Decide(distance, s, busy: false);
                if (d.Intent != TacticalIntent.Attack) continue;

                s.Spend(AttackProfile.For(d.Shape).StaminaCost);
                t.Threw(d.Shape);
                thrown.Add(d.Shape);
            }
            return thrown;
        }

        [Fact]
        public void Walks_in_when_out_of_range()
        {
            var t = New();
            var d = t.Decide(6f, Bar(), busy: false);
            Assert.Equal(TacticalIntent.Close, d.Intent);
        }

        [Fact]
        public void Will_not_interrupt_its_own_swing()
        {
            // The enemy is as committed to its attacks as the player is to
            // theirs (combat.md §1). An enemy that could cancel would make
            // every telegraph a lie.
            var t = New();
            var d = t.Decide(1.5f, Bar(), busy: true);
            Assert.Equal(TacticalIntent.Busy, d.Intent);
        }

        [Fact]
        public void Leaves_a_gap_between_attacks()
        {
            // The breathing room a player uses to close, drink or leave. An
            // enemy with none of it is not difficult, it is just noise.
            var t = New();
            var s = Bar();

            var first = t.Decide(1.5f, s, busy: false);
            Assert.Equal(TacticalIntent.Attack, first.Intent);
            t.Threw(first.Shape);

            Assert.Equal(TacticalIntent.Circle, t.Decide(1.5f, s, busy: false).Intent);

            t.Tick(EnemyTacticsProfile.Default.RecoverBetweenAttacksSeconds + 0.01f);
            Assert.Equal(TacticalIntent.Attack, t.Decide(1.5f, s, busy: false).Intent);
        }

        [Fact]
        public void Teaches_all_three_shapes_at_both_ranges()
        {
            // The whole point. If any shape never arrives, the player never
            // learns to answer it, and §6's claim about the first hour is
            // false.
            foreach (var distance in new[] { 1.2f, 2.0f })
            {
                var thrown = Spar(New(), distance);
                Assert.True(thrown.Count > 20, $"only {thrown.Count} attacks at {distance}m");

                foreach (var shape in new[] { AttackShape.Quick, AttackShape.Heavy, AttackShape.Committed })
                {
                    Assert.True(
                        thrown.Contains(shape),
                        $"the enemy never threw {shape} at {distance}m in two minutes, " +
                        "so a player could not learn to answer it");
                }
            }
        }

        [Fact]
        public void Leans_on_quick_attacks_up_close_and_long_ones_at_range()
        {
            // The read that teaches a player to commit: hovering at the
            // edge of its reach should feel worse than closing.
            var close = Spar(New(), 1.2f);
            var far = Spar(New(), 2.0f);

            var quickClose = close.FindAll(s => s == AttackShape.Quick).Count / (float)close.Count;
            var quickFar = far.FindAll(s => s == AttackShape.Quick).Count / (float)far.Count;

            Assert.True(quickClose > quickFar,
                $"quick share was {quickClose:P0} close and {quickFar:P0} far");
        }

        [Fact]
        public void Quick_attacks_chain_but_not_forever()
        {
            // §6 says quick attacks chain. They must — and an enemy that
            // only ever jabs teaches neither the parry nor the disengage.
            var thrown = Spar(New(), 1.2f);

            var longest = 0;
            var run = 0;
            var sawAChain = false;
            foreach (var shape in thrown)
            {
                run = shape == AttackShape.Quick ? run + 1 : 0;
                if (run >= 2) sawAChain = true;
                if (run > longest) longest = run;
            }

            Assert.True(sawAChain, "quick attacks never chained at all");
            Assert.True(longest <= EnemyTacticsProfile.Default.MaxQuickChain,
                $"chained {longest} quick attacks in a row");
        }

        [Fact]
        public void Will_not_reach_for_an_expensive_swing_while_broke()
        {
            // It still swings — combat.md §2 says at zero you are slow, not
            // stunned — but it picks the one it might afford.
            var t = New();
            var s = Bar();
            s.Spend(s.Max);

            var d = t.Decide(1.5f, s, busy: false);
            Assert.Equal(TacticalIntent.Attack, d.Intent);
            Assert.Equal(AttackShape.Quick, d.Shape);
        }

        [Fact]
        public void The_same_seed_produces_the_same_fight()
        {
            // combat.md §7 makes damage server-authoritative, so client and
            // server have to be able to agree about what the enemy did.
            Assert.Equal(Spar(New(42), 1.5f), Spar(New(42), 1.5f));
        }

        [Fact]
        public void Different_seeds_produce_different_fights()
        {
            Assert.NotEqual(Spar(New(1), 1.5f), Spar(New(999), 1.5f));
        }

        [Fact]
        public void A_zero_seed_still_produces_a_fight()
        {
            // The generator has a fixed point at zero, and "seed = 0" is
            // exactly what a caller who forgot to seed would pass.
            var thrown = Spar(new EnemyTactics(EnemyTacticsProfile.Default, 0), 1.5f);
            Assert.Contains(AttackShape.Heavy, thrown);
            Assert.Contains(AttackShape.Quick, thrown);
        }
    }
}
