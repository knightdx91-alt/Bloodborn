using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// combat.md §2: "Blocking bleeds stamina under pressure and breaks
    /// your guard at zero, leaving you open — the punishment for
    /// turtling." And §1: "a blocked blow still carries something through:
    /// blocking is a stamina war, never an off switch."
    ///
    /// The guard is one thing with two halves. Raise it at the right
    /// moment and you parry; hold it and you block. These assert that the
    /// second half is a worse deal than the first, which is what keeps
    /// parry the high-skill answer rather than a flourish.
    /// </summary>
    public class BlockTests
    {
        private static Parry New() => new Parry(ParryProfile.Default);
        private static Stamina Bar() => new Stamina(StaminaProfile.Default);

        /// <summary>Raise a guard and hold it until it becomes a block.</summary>
        private static (Parry, Stamina) Blocking()
        {
            var p = New();
            var s = Bar();
            p.TryStart(s);
            var d = ParryProfile.Default;
            for (var t = 0f; t < d.StartupSeconds + d.OpenSeconds + 0.05f; t += 1f / 60f)
            {
                p.Tick(1f / 60f, holding: true);
                s.Tick(1f / 60f);
            }
            Assert.Equal(ParryPhase.Blocking, p.Phase);
            return (p, s);
        }

        [Fact]
        public void Holding_the_guard_through_the_window_turns_it_into_a_block()
        {
            var (p, _) = Blocking();
            Assert.True(p.IsBlocking);
            Assert.True(p.IsGuarding);
            Assert.False(p.IsOpen);
        }

        [Fact]
        public void Letting_go_before_the_window_ends_does_not_block()
        {
            // Holding is what makes it a block. A guard raised and dropped
            // is a parry attempt that missed, and should be punished as one.
            var p = New();
            var s = Bar();
            var d = ParryProfile.Default;
            p.TryStart(s);
            for (var t = 0f; t < d.StartupSeconds + d.OpenSeconds + 0.05f; t += 1f / 60f)
                p.Tick(1f / 60f, holding: false);

            Assert.Equal(ParryPhase.Recovery, p.Phase);
        }

        [Fact]
        public void A_blocked_blow_still_carries_something_through()
        {
            // §1: never an off switch.
            var (p, s) = Blocking();
            Assert.Equal(ParryOutcome.Blocked, p.Meet(AttackProfile.Heavy, s, damage: 40f));
            Assert.True(p.BlockedFraction > 0f, "a block that stopped everything would be an off switch");
            Assert.True(p.BlockedFraction < 1f, "a block has to be worth something");
        }

        [Fact]
        public void Blocking_costs_the_bar_in_proportion_to_the_blow()
        {
            var (p, s) = Blocking();
            var before = s.Current;
            p.Meet(AttackProfile.Heavy, s, damage: 40f);
            var light = before - s.Current;

            var (p2, s2) = Blocking();
            var before2 = s2.Current;
            p2.Meet(AttackProfile.Heavy, s2, damage: 80f);
            var heavy = before2 - s2.Current;

            Assert.True(heavy > light, "a harder blow should cost more to stop");
        }

        [Fact]
        public void The_guard_breaks_when_the_bar_runs_dry()
        {
            // §2's punishment for turtling, and the reason a shield is not
            // an answer to everything.
            var (p, s) = Blocking();
            s.Spend(s.Current - 2f);   // almost nothing left

            // A heavy, not the committed attack: that one is unblockable
            // and would never reach the guard at all.
            Assert.Equal(ParryOutcome.Blocked, p.Meet(AttackProfile.Heavy, s, damage: 90f));
            Assert.Equal(ParryPhase.Recovery, p.Phase);
            Assert.False(p.IsGuarding);
            Assert.False(p.CanAct);
        }

        [Fact]
        public void A_broken_guard_leaves_you_open_for_longer_than_a_missed_parry()
        {
            var d = ParryProfile.Default;
            Assert.True(d.BrokenGuardRecoverySeconds > d.RecoverySeconds);
        }

        [Fact]
        public void The_committed_attack_is_not_blockable_either()
        {
            // §6 calls it unblockable, not merely unparryable. A guard is
            // the wrong answer to it however it is held.
            var (p, s) = Blocking();
            Assert.Equal(ParryOutcome.Unparryable, p.Meet(AttackProfile.Committed, s));
        }

        [Fact]
        public void Turtling_costs_more_than_reading_the_blow()
        {
            // The load-bearing comparison. A parry refunds most of its
            // cost; a block pays for every blow it stops. If blocking were
            // the cheaper habit, nobody would ever take the risk.
            const float blow = 40f;

            var (blocker, blockerBar) = Blocking();
            var blockedFrom = blockerBar.Current;
            blocker.Meet(AttackProfile.Heavy, blockerBar, damage: blow);
            var blockCost = blockedFrom - blockerBar.Current;

            var parrier = New();
            var parrierBar = Bar();
            parrier.TryStart(parrierBar);
            var parriedFrom = parrierBar.Current;
            for (var t = 0f; t < ParryProfile.Default.StartupSeconds + 0.01f; t += 1f / 60f)
                parrier.Tick(1f / 60f, holding: true);
            parrier.Meet(AttackProfile.Heavy, parrierBar, damage: blow);
            var parryCost = parriedFrom - parrierBar.Current;

            Assert.True(blockCost > parryCost,
                $"blocking cost {blockCost} and parrying cost {parryCost} — " +
                "turtling must be the worse habit");
        }

        [Fact]
        public void A_guard_can_be_taken_back_before_it_has_done_anything()
        {
            // For an input layer that cannot tell a tap from the start of a
            // guard without starting one. It must never be able to undo a
            // parry that landed.
            var p = New();
            var s = Bar();
            var full = s.Current;
            p.TryStart(s);
            Assert.True(s.Current < full);

            Assert.True(p.Cancel(s));
            Assert.Equal(full, s.Current, 3);
            Assert.True(p.CanAct);
        }

        [Fact]
        public void A_guard_that_turned_a_blow_cannot_be_taken_back()
        {
            var p = New();
            var s = Bar();
            p.TryStart(s);
            for (var t = 0f; t < ParryProfile.Default.StartupSeconds + 0.01f; t += 1f / 60f)
                p.Tick(1f / 60f, holding: true);
            Assert.Equal(ParryOutcome.Parried, p.Meet(AttackProfile.Heavy, s));

            Assert.False(p.Cancel(s));
        }
    }
}
