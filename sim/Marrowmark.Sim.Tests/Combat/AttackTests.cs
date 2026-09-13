using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// The RULES from design/combat.md §1, §2 and §6. The timings will move
    /// the first time someone holds a controller; what must not move is
    /// that the wind-up is long enough to read, that a whiffed swing is
    /// paid for, and that one swing lands at most one blow.
    /// </summary>
    public class AttackTests
    {
        private static Attack New() => new Attack(AttackProfile.Default);
        private static Stamina Bar() => new Stamina(StaminaProfile.Default);

        private static void Advance(Attack a, Stamina s, float seconds, float step = 1f / 60f)
        {
            for (var t = 0f; t < seconds; t += step)
            {
                a.Tick(step);
                s.Tick(step);
            }
        }

        [Fact]
        public void Starts_ready_and_harmless()
        {
            var a = New();
            Assert.Equal(AttackPhase.Ready, a.Phase);
            Assert.True(a.CanAct);
            Assert.False(a.IsActive);
            Assert.False(a.TryConsumeHit());
        }

        [Fact]
        public void Passes_through_windup_active_and_recovery_in_order()
        {
            var a = New();
            var s = Bar();
            var p = AttackProfile.Default;
            a.TryStart(s);

            Assert.Equal(AttackPhase.Windup, a.Phase);

            Advance(a, s, p.WindupSeconds + 0.01f);
            Assert.Equal(AttackPhase.Active, a.Phase);

            Advance(a, s, p.ActiveSeconds);
            Assert.Equal(AttackPhase.Recovery, a.Phase);

            Advance(a, s, p.RecoverySeconds + 0.05f);
            Assert.Equal(AttackPhase.Ready, a.Phase);
        }

        [Fact]
        public void A_whiffed_swing_is_paid_for()
        {
            // combat.md §2: attacks cost on startup. Nothing here ever
            // touches a target, and the bar still moves.
            var a = New();
            var s = Bar();
            var before = s.Current;

            a.TryStart(s);

            Assert.Equal(AttackProfile.Default.StaminaCost, before - s.Current, 3);
        }

        [Fact]
        public void Connecting_costs_nothing_extra()
        {
            var a = New();
            var s = Bar();
            var p = AttackProfile.Default;
            a.TryStart(s);
            var after_startup = s.Current;

            Advance(a, s, p.WindupSeconds + 0.01f);
            Assert.True(a.TryConsumeHit());

            // The bar only moves by regeneration from here, never by
            // landing the blow.
            Assert.True(s.Current >= after_startup);
        }

        [Fact]
        public void Is_committed_a_second_swing_cannot_interrupt_the_first()
        {
            var a = New();
            var s = Bar();
            a.TryStart(s);
            var after_first = s.Current;

            Assert.False(a.TryStart(s));
            Assert.Equal(after_first, s.Current);
        }

        [Fact]
        public void The_blade_is_harmless_during_the_windup()
        {
            // The wind-up is the telegraph (combat.md §6). If it hurt,
            // there would be nothing to read and no reason to answer.
            var a = New();
            var s = Bar();
            a.TryStart(s);

            Assert.Equal(AttackPhase.Windup, a.Phase);
            Assert.False(a.IsActive);
            Assert.False(a.TryConsumeHit());
        }

        [Fact]
        public void The_blade_is_harmless_during_recovery()
        {
            var a = New();
            var s = Bar();
            var p = AttackProfile.Default;
            a.TryStart(s);
            Advance(a, s, p.WindupSeconds + p.ActiveSeconds + 0.01f);

            Assert.Equal(AttackPhase.Recovery, a.Phase);
            Assert.False(a.IsActive);
            Assert.False(a.TryConsumeHit());
            Assert.False(a.CanAct);
        }

        [Fact]
        public void One_swing_lands_at_most_one_blow()
        {
            var a = New();
            var s = Bar();
            var p = AttackProfile.Default;
            a.TryStart(s);
            Advance(a, s, p.WindupSeconds + 0.01f);

            Assert.True(a.TryConsumeHit());

            // The active window spans several frames. Every one of them
            // would otherwise be a hit, and §4's numbers are written for
            // single blows.
            var extra = 0;
            for (var i = 0; i < 10; i++)
            {
                a.Tick(1f / 60f);
                if (a.TryConsumeHit()) extra++;
            }

            Assert.Equal(0, extra);
        }

        [Fact]
        public void A_new_swing_gets_a_new_hit()
        {
            var a = New();
            var s = Bar();
            var p = AttackProfile.Default;

            a.TryStart(s);
            Advance(a, s, p.WindupSeconds + 0.01f);
            Assert.True(a.TryConsumeHit());

            Advance(a, s, p.TotalSeconds);
            Assert.Equal(AttackPhase.Ready, a.Phase);

            a.TryStart(s);
            Advance(a, s, p.WindupSeconds + 0.01f);
            Assert.True(a.TryConsumeHit());
        }

        [Fact]
        public void The_windup_is_long_enough_to_read()
        {
            // combat.md §6 makes the wind-up the whole telegraph, and §7
            // budgets ~100ms for the network. A wind-up near that is not a
            // telegraph, it is a coin toss on a laggy connection.
            var p = AttackProfile.Default;
            Assert.True(p.WindupSeconds >= 0.2f);
            Assert.True(p.WindupSeconds > p.ActiveSeconds);
        }

        [Fact]
        public void Recovery_is_the_longest_phase()
        {
            // Why the dodge repositions rather than merely evading: a
            // whiffed swing has to leave something to punish.
            var p = AttackProfile.Default;
            Assert.True(p.RecoverySeconds > p.WindupSeconds);
            Assert.True(p.RecoverySeconds > p.ActiveSeconds);
        }

        [Fact]
        public void A_swing_you_cannot_pay_for_recovers_slower()
        {
            var p = AttackProfile.Default;
            var s = Bar();
            s.Spend(s.Max);

            var a = New();
            a.TryStart(s);
            Advance(a, s, p.TotalSeconds + 0.02f);

            Assert.NotEqual(AttackPhase.Ready, a.Phase);
        }

        [Fact]
        public void Reach_covers_the_front_and_not_the_back()
        {
            var a = New();
            var p = AttackProfile.Default;

            Assert.True(a.Reaches(p.Reach - 0.1f, 0f));
            Assert.True(a.Reaches(1.0f, p.ArcDegrees * 0.5f - 1f));
            Assert.True(a.Reaches(1.0f, -(p.ArcDegrees * 0.5f - 1f)));

            Assert.False(a.Reaches(p.Reach + 0.1f, 0f));      // too far
            Assert.False(a.Reaches(1.0f, 180f));              // behind you
            Assert.False(a.Reaches(1.0f, p.ArcDegrees));      // outside the sweep
        }

        [Fact]
        public void A_dodge_out_of_reach_beats_the_swing()
        {
            // The two systems have to agree, and this is where: the dodge
            // covers more ground than the sword reaches, so stepping away
            // is a real answer and not just a prettier way to be hit.
            Assert.True(DodgeProfile.Default.Distance > AttackProfile.Default.Reach * 0.5f);
        }
    }
}
