using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// The RULES from design/combat.md §1 and §2, not the numbers. The
    /// timings will change the first time someone holds a controller;
    /// what must not change is that the safe window is shorter than the
    /// committed one, that recovery is punishable, and that a dodge you
    /// cannot pay for still happens.
    /// </summary>
    public class DodgeTests
    {
        private static Dodge New() => new Dodge(DodgeProfile.Default);
        private static Stamina Bar() => new Stamina(StaminaProfile.Default);

        /// <summary>Run a dodge forward in small steps, as a frame loop would.</summary>
        private static void Advance(Dodge d, Stamina s, float seconds, float step = 1f / 60f)
        {
            for (var t = 0f; t < seconds; t += step)
            {
                d.Tick(step);
                s.Tick(step);
            }
        }

        [Fact]
        public void Starts_ready_able_to_act_and_hittable()
        {
            var d = New();
            Assert.Equal(DodgePhase.Ready, d.Phase);
            Assert.True(d.CanAct);
            Assert.False(d.IsInvulnerable);
        }

        [Fact]
        public void Dodging_costs_stamina()
        {
            var d = New();
            var s = Bar();
            var before = s.Current;

            Assert.True(d.TryStart(s));
            Assert.True(s.Current < before);
        }

        [Fact]
        public void Is_committed_a_second_dodge_cannot_interrupt_the_first()
        {
            var d = New();
            var s = Bar();
            d.TryStart(s);
            var after_first = s.Current;

            Assert.False(d.TryStart(s));
            // combat.md §1: the dodge is committed. A refused dodge must
            // not quietly charge for itself.
            Assert.Equal(after_first, s.Current);
        }

        [Fact]
        public void Passes_through_startup_invulnerability_and_recovery_in_order()
        {
            var d = New();
            var s = Bar();
            var p = DodgeProfile.Default;
            d.TryStart(s);

            Assert.Equal(DodgePhase.Startup, d.Phase);

            Advance(d, s, p.StartupSeconds + 0.01f);
            Assert.Equal(DodgePhase.Invulnerable, d.Phase);

            Advance(d, s, p.InvulnerableSeconds);
            Assert.Equal(DodgePhase.Recovery, d.Phase);

            Advance(d, s, p.RecoverySeconds + 0.05f);
            Assert.Equal(DodgePhase.Ready, d.Phase);
        }

        [Fact]
        public void Startup_is_committed_but_not_yet_safe()
        {
            var d = New();
            var s = Bar();
            d.TryStart(s);

            Assert.Equal(DodgePhase.Startup, d.Phase);
            Assert.False(d.IsInvulnerable);   // dodging early is a mistake
            Assert.False(d.CanAct);           // and it cannot be taken back
        }

        [Fact]
        public void Recovery_is_punishable_hittable_and_unable_to_act()
        {
            var d = New();
            var s = Bar();
            var p = DodgeProfile.Default;
            d.TryStart(s);
            Advance(d, s, p.StartupSeconds + p.InvulnerableSeconds + 0.01f);

            Assert.Equal(DodgePhase.Recovery, d.Phase);
            Assert.False(d.IsInvulnerable);
            Assert.False(d.CanAct);
        }

        [Fact]
        public void Most_of_a_dodge_is_spent_hittable()
        {
            // The heart of the design: if the safe window covered the whole
            // dodge there would be no timing decision, and spamming it
            // would be free. Guards against tuning that quietly erases the
            // risk rather than changing it.
            var p = DodgeProfile.Default;
            Assert.True(p.InvulnerableSeconds < p.TotalSeconds / 2f);
        }

        [Fact]
        public void Panic_rolling_drains_you()
        {
            // combat.md §2: consecutive dodges cost escalating amounts.
            var s = Bar();
            var first = s.NextDodgeCost();

            var d = New();
            d.TryStart(s);
            var second = s.NextDodgeCost();

            Assert.True(second > first);
        }

        [Fact]
        public void A_dodge_you_cannot_pay_for_still_happens_but_goes_nowhere()
        {
            // combat.md §2: at zero you are not stunned, you are slow.
            var s = Bar();
            var p = DodgeProfile.Default;
            s.Spend(s.Max);   // empty the bar

            var d = New();
            Assert.True(d.TryStart(s));
            Assert.True(d.Distance < p.Distance);
            Assert.True(d.Distance > 0f);
        }

        [Fact]
        public void A_dodge_you_cannot_pay_for_recovers_slower()
        {
            var p = DodgeProfile.Default;
            var full = p.StartupSeconds + p.InvulnerableSeconds + p.RecoverySeconds;

            var s = Bar();
            s.Spend(s.Max);
            var d = New();
            d.TryStart(s);
            Advance(d, s, full + 0.02f);

            // A paid dodge would be over by now.
            Assert.NotEqual(DodgePhase.Ready, d.Phase);
        }

        [Fact]
        public void Travel_finishes_before_recovery_does()
        {
            // L56: the dodge repositions. It must arrive somewhere while
            // still invulnerable — landing mid-recovery would mean sliding
            // helplessly into the blow you were avoiding.
            var d = New();
            var s = Bar();
            var p = DodgeProfile.Default;
            d.TryStart(s);
            Advance(d, s, p.StartupSeconds + p.InvulnerableSeconds + 0.01f);

            Assert.Equal(DodgePhase.Recovery, d.Phase);
            Assert.Equal(1f, d.TravelFraction, 3);
        }

        [Fact]
        public void Travel_leaves_fast_and_settles()
        {
            var d = New();
            var s = Bar();
            d.TryStart(s);
            var p = DodgeProfile.Default;
            var moving = p.StartupSeconds + p.InvulnerableSeconds;

            Advance(d, s, moving * 0.5f);
            // Past halfway in distance by halfway in time — a shove, not a
            // glide. Without this the dodge reads as a slow strafe.
            Assert.True(d.TravelledDistance > d.Distance * 0.5f);
            Assert.True(d.TravelledDistance < d.Distance);
        }

        [Fact]
        public void Returns_to_ready_with_nothing_left_over()
        {
            var d = New();
            var s = Bar();
            var p = DodgeProfile.Default;
            d.TryStart(s);
            Advance(d, s, p.TotalSeconds + 0.1f);

            Assert.Equal(DodgePhase.Ready, d.Phase);
            Assert.True(d.CanAct);
            Assert.Equal(0f, d.Elapsed);
            Assert.Equal(0f, d.Distance);
            Assert.Equal(0f, d.TravelFraction);
        }

        [Fact]
        public void Spacing_dodges_resets_the_escalation()
        {
            // The counterplay to panic-roll escalation, from combat.md §2.
            var s = Bar();
            var d = New();
            var first = s.NextDodgeCost();

            d.TryStart(s);
            Advance(d, s, StaminaProfile.Default.DodgeChainWindowSeconds + 0.2f);

            Assert.Equal(first, s.NextDodgeCost(), 3);
        }
    }
}
