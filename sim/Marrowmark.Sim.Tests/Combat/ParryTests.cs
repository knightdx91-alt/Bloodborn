using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// combat.md §1, §2 and §6, and the L39 gate the whole project turns
    /// on. These assert the RULES — what makes parry the high-skill,
    /// high-reward answer rather than a better block.
    /// </summary>
    public class ParryTests
    {
        private static Parry New() => new Parry(ParryProfile.Default);
        private static Stamina Bar() => new Stamina(StaminaProfile.Default);

        private static void Advance(Parry p, Stamina s, float seconds, float step = 1f / 60f)
        {
            for (var t = 0f; t < seconds; t += step)
            {
                p.Tick(step);
                s.Tick(step);
            }
        }

        /// <summary>Wind a parry forward to the middle of its open window.</summary>
        private static (Parry, Stamina) Open()
        {
            var p = New();
            var s = Bar();
            p.TryStart(s);
            Advance(p, s, ParryProfile.Default.StartupSeconds + 0.01f);
            Assert.Equal(ParryPhase.Open, p.Phase);
            return (p, s);
        }

        [Fact]
        public void Starts_ready_and_turning_nothing()
        {
            var p = New();
            Assert.Equal(ParryPhase.Ready, p.Phase);
            Assert.True(p.CanAct);
            Assert.False(p.IsOpen);
            Assert.Equal(ParryOutcome.NotParrying, p.Meet(AttackProfile.Heavy, Bar()));
        }

        [Fact]
        public void Passes_through_startup_open_and_recovery_in_order()
        {
            var p = New();
            var s = Bar();
            var d = ParryProfile.Default;
            p.TryStart(s);

            Assert.Equal(ParryPhase.Startup, p.Phase);
            Advance(p, s, d.StartupSeconds + 0.01f);
            Assert.Equal(ParryPhase.Open, p.Phase);
            Advance(p, s, d.OpenSeconds);
            Assert.Equal(ParryPhase.Recovery, p.Phase);
            Advance(p, s, d.RecoverySeconds + 0.05f);
            Assert.Equal(ParryPhase.Ready, p.Phase);
        }

        [Fact]
        public void The_window_survives_the_latency_envelope()
        {
            // combat.md §7 budgets ~100ms of network tolerance and says
            // parry windows stay wide enough to survive it. A window near
            // 100ms is a lottery for anyone not on a local connection, and
            // L39 is precisely the claim that 100ms is indistinguishable
            // from zero.
            Assert.True(ParryProfile.Default.OpenSeconds >= 0.25f);
        }

        [Fact]
        public void A_parry_that_lands_refunds_most_of_its_cost()
        {
            // combat.md §2, and the reason parry is worth the risk.
            var s = Bar();
            var before = s.Current;

            var p = New();
            p.TryStart(s);
            var paid = before - s.Current;
            Advance(p, s, ParryProfile.Default.StartupSeconds + 0.01f);

            var spentBeforeMeeting = s.Current;
            Assert.Equal(ParryOutcome.Parried, p.Meet(AttackProfile.Heavy, s));

            var refunded = s.Current - spentBeforeMeeting;
            Assert.True(refunded > paid * 0.5f, "a successful parry should refund MOST of its cost");
            Assert.True(refunded < paid, "it should not be a full refund — the attempt cost something");
        }

        [Fact]
        public void A_parry_that_misses_refunds_nothing()
        {
            // "A failed one does not." The asymmetry is the whole design.
            var s = Bar();
            var p = New();
            p.TryStart(s);
            var afterPaying = s.Current;

            Assert.Equal(ParryOutcome.TooEarly, p.Meet(AttackProfile.Heavy, s));
            Assert.Equal(afterPaying, s.Current, 3);
        }

        [Fact]
        public void Failing_costs_more_than_not_trying()
        {
            // The load-bearing assertion. If a whiffed parry only cost its
            // stamina, mashing it would be correct play and the read would
            // stop mattering. It has to leave you out of position longer
            // than the dodge's recovery, which is the safe alternative.
            Assert.True(ParryProfile.Default.RecoverySeconds > DodgeProfile.Default.RecoverySeconds);
            Assert.True(ParryProfile.Default.RecoverySeconds
                > ParryProfile.Default.SuccessRecoverySeconds * 3f);
        }

        [Fact]
        public void The_committed_attack_cannot_be_parried_even_perfectly()
        {
            // combat.md §6. A perfectly timed guard against one is still a
            // mistake — the answer was to not be there.
            var (p, s) = Open();
            Assert.Equal(ParryOutcome.Unparryable, p.Meet(AttackProfile.Committed, s));
        }

        [Fact]
        public void An_unparryable_blow_does_not_consume_the_window()
        {
            // It failed to turn anything, so it should not also have eaten
            // the parry — the guard is simply the wrong answer, not spent.
            var (p, s) = Open();
            p.Meet(AttackProfile.Committed, s);
            Assert.Equal(ParryPhase.Open, p.Phase);
            Assert.Equal(ParryOutcome.Parried, p.Meet(AttackProfile.Heavy, s));
        }

        [Fact]
        public void One_parry_turns_one_blow()
        {
            // combat.md §1: parry loses to quick flurries. A guard held
            // open through several blows would beat exactly what it is
            // supposed to lose to.
            var (p, s) = Open();
            Assert.Equal(ParryOutcome.Parried, p.Meet(AttackProfile.Quick, s));
            Assert.NotEqual(ParryOutcome.Parried, p.Meet(AttackProfile.Quick, s));
        }

        [Fact]
        public void A_landed_parry_frees_you_almost_at_once()
        {
            // §6 promises a free punish, and you cannot punish anything
            // while recovering.
            var (p, s) = Open();
            p.Meet(AttackProfile.Heavy, s);
            Advance(p, s, ParryProfile.Default.SuccessRecoverySeconds + 0.02f);
            Assert.True(p.CanAct);
        }

        [Fact]
        public void The_stagger_is_long_enough_for_the_punish_to_be_free()
        {
            // §6: "stagger and a free punish." If the stagger were shorter
            // than a wind-up, the attacker would recover mid-swing and the
            // reward would be a race rather than a gift.
            var d = ParryProfile.Default;
            Assert.True(d.StaggerSeconds > AttackProfile.Default.WindupSeconds + d.SuccessRecoverySeconds);
        }

        [Fact]
        public void Is_committed_a_second_parry_cannot_interrupt_the_first()
        {
            var p = New();
            var s = Bar();
            p.TryStart(s);
            var after = s.Current;
            Assert.False(p.TryStart(s));
            Assert.Equal(after, s.Current);
        }

        [Fact]
        public void Parrying_a_quick_attack_needs_a_read_rather_than_a_reaction()
        {
            // §6 makes dodge the answer to a quick attack, and this is why:
            // the whole wind-up is shorter than the parry's own startup plus
            // any human reaction. It CAN be parried — nothing forbids it —
            // but only by someone who guessed, which is exactly the
            // intended difference between the two answers.
            var quickWindup = AttackProfile.Quick.WindupSeconds;
            var guardUpIn = ParryProfile.Default.StartupSeconds;
            const float humanReaction = 0.25f;

            Assert.True(quickWindup < guardUpIn + humanReaction,
                "if a quick attack could be reacted to, it would not need the dodge");
        }

        [Fact]
        public void Parrying_a_heavy_is_a_reaction_a_person_can_actually_make()
        {
            // The other half of the same claim, and combat.md §9's gate:
            // "reliably parry a heavy." If the wind-up were shorter than
            // reaction plus the guard coming up, the gate would be
            // unpassable by construction.
            var heavyWindup = AttackProfile.Heavy.WindupSeconds;
            var guardUpIn = ParryProfile.Default.StartupSeconds;
            const float humanReaction = 0.25f;
            const float latencyBudget = 0.1f;

            Assert.True(heavyWindup > guardUpIn + humanReaction + latencyBudget);
        }
    }
}
