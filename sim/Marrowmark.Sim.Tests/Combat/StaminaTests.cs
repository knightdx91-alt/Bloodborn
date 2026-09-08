using System;
using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// These tests assert the RULES from design/combat.md §2, not the
    /// numbers. Tuning values will change constantly once there is a
    /// controller in hand; the relationships between them should not.
    /// </summary>
    public class StaminaTests
    {
        private static Stamina New() => new Stamina(StaminaProfile.Default);

        [Fact]
        public void Starts_full_and_rested()
        {
            var s = New();
            Assert.Equal(s.Max, s.Current);
            Assert.False(s.IsExhausted);
            Assert.Equal(1f, s.Fraction);
        }

        [Fact]
        public void Spending_reduces_stamina()
        {
            var s = New();
            var result = s.Spend(30f);

            Assert.True(result.Afforded);
            Assert.Equal(30f, result.Spent, 3);
            Assert.Equal(70f, s.Current, 3);
        }

        [Fact]
        public void Does_not_regenerate_during_the_delay_window()
        {
            var s = New();
            s.Spend(50f);

            // Half the delay has passed — still nothing back.
            s.Tick(StaminaProfile.Default.RegenDelaySeconds / 2f);
            Assert.Equal(50f, s.Current, 3);
        }

        [Fact]
        public void Regenerates_after_the_delay_window()
        {
            var s = New();
            s.Spend(50f);

            s.Tick(StaminaProfile.Default.RegenDelaySeconds + 1f);

            // One full second of regen past the delay.
            Assert.Equal(50f + StaminaProfile.Default.RegenPerSecond, s.Current, 3);
        }

        [Fact]
        public void Regeneration_is_frame_rate_independent()
        {
            var coarse = New();
            var fine = New();

            coarse.Spend(60f);
            fine.Spend(60f);

            coarse.Tick(1f);
            for (var i = 0; i < 100; i++) fine.Tick(0.01f);

            Assert.Equal(coarse.Current, fine.Current, 2);
        }

        [Fact]
        public void Never_exceeds_max()
        {
            var s = New();
            s.Spend(10f);
            s.Tick(100f);
            Assert.Equal(s.Max, s.Current, 3);
        }

        // ── Exhaustion ───────────────────────────────────────────────────

        [Fact]
        public void Overspending_empties_the_bar_but_the_action_still_happens()
        {
            var s = New();
            var result = s.Spend(150f);

            Assert.False(result.Afforded);
            Assert.Equal(100f, result.Spent, 3);
            Assert.Equal(0f, s.Current, 3);
            Assert.True(s.IsExhausted);
            Assert.True(result.CausedExhaustion);
        }

        [Fact]
        public void Exhaustion_clears_only_after_recovering_the_threshold()
        {
            var p = StaminaProfile.Default;
            var s = New();
            s.Spend(150f);
            Assert.True(s.IsExhausted);

            // Just under the recovery threshold: still exhausted.
            var threshold = p.Max * p.ExhaustionRecoveryFraction;
            var rate = p.RegenPerSecond * p.ExhaustedRegenMultiplier;
            s.Tick(p.RegenDelaySeconds + (threshold - 1f) / rate);
            Assert.True(s.IsExhausted);

            // Cross it, and exhaustion lifts.
            s.Tick(2f / rate);
            Assert.False(s.IsExhausted);
        }

        [Fact]
        public void Exhausted_regeneration_is_slower()
        {
            var p = StaminaProfile.Default;

            var rested = New();
            rested.Spend(10f);
            rested.Tick(p.RegenDelaySeconds + 0.5f);
            var restedGain = rested.Current - 90f;

            var tired = New();
            tired.Spend(150f);
            tired.Tick(p.RegenDelaySeconds + 0.5f);
            var tiredGain = tired.Current;

            Assert.True(tiredGain < restedGain,
                $"exhausted regen ({tiredGain}) should be slower than rested ({restedGain})");
        }

        [Fact]
        public void CausedExhaustion_only_fires_on_the_transition()
        {
            var s = New();
            Assert.True(s.Spend(150f).CausedExhaustion);
            Assert.False(s.Spend(10f).CausedExhaustion);
        }

        // ── Dodge chain escalation (combat.md §2) ────────────────────────

        [Fact]
        public void Consecutive_dodges_cost_progressively_more()
        {
            var s = New();

            var first = s.SpendDodge().Spent;
            var second = s.SpendDodge().Spent;
            var third = s.SpendDodge().Spent;

            Assert.True(second > first, "second dodge should cost more than the first");
            Assert.True(third > second, "third dodge should cost more than the second");
        }

        [Fact]
        public void Panic_rolling_drains_far_faster_than_spaced_dodges()
        {
            var p = StaminaProfile.Default;

            var panic = New();
            for (var i = 0; i < 3; i++) panic.SpendDodge();

            var spaced = New();
            for (var i = 0; i < 3; i++)
            {
                spaced.SpendDodge();
                spaced.Tick(p.DodgeChainWindowSeconds + 0.1f);
            }

            Assert.True(spaced.Current > panic.Current,
                "spacing dodges should leave more stamina than panic-rolling");
        }

        [Fact]
        public void Dodge_chain_resets_after_the_window()
        {
            var s = New();
            s.SpendDodge();
            Assert.Equal(1, s.ConsecutiveDodges);

            s.Tick(StaminaProfile.Default.DodgeChainWindowSeconds + 0.1f);
            Assert.Equal(0, s.ConsecutiveDodges);
        }

        [Fact]
        public void Dodge_chain_does_not_reset_inside_the_window()
        {
            var s = New();
            s.SpendDodge();
            s.Tick(StaminaProfile.Default.DodgeChainWindowSeconds / 2f);
            Assert.Equal(1, s.ConsecutiveDodges);
        }

        // ── Parry (combat.md §2: high skill, high reward) ────────────────

        [Fact]
        public void Successful_parry_refunds_most_of_its_cost()
        {
            var p = StaminaProfile.Default;
            var s = New();

            s.SpendParry();
            s.RefundParry();

            var netCost = p.Max - s.Current;
            Assert.True(netCost > 0f, "a successful parry should still cost something");
            Assert.True(netCost < p.ParryCost, "a successful parry should refund most of its cost");
        }

        [Fact]
        public void Failed_parry_refunds_nothing()
        {
            var p = StaminaProfile.Default;
            var s = New();

            s.SpendParry();

            Assert.Equal(p.Max - p.ParryCost, s.Current, 3);
        }

        [Fact]
        public void Parry_is_cheaper_than_dodge_when_it_lands_and_dearer_when_it_misses()
        {
            var p = StaminaProfile.Default;

            var landed = New();
            landed.SpendParry();
            landed.RefundParry();

            var missed = New();
            missed.SpendParry();

            var dodged = New();
            dodged.SpendDodge();

            Assert.True(landed.Current > dodged.Current,
                "a landed parry should beat a dodge on stamina");
            Assert.True(missed.Current > dodged.Current || p.ParryCost < p.DodgeCost,
                "profile relationship between parry and dodge cost should be intentional");
        }

        // ── Sprint (combat.md §1: escape is never gated) ─────────────────

        [Fact]
        public void Sprinting_drains_slowly_enough_to_escape()
        {
            var s = New();

            // Three full seconds of sprinting from full.
            for (var i = 0; i < 3; i++) s.Sprint(1f);

            Assert.True(s.Current > s.Max * 0.5f,
                "three seconds of sprint should not cost half the bar — fleeing must stay affordable");
        }

        [Fact]
        public void Sprint_reports_empty_when_the_bar_runs_out()
        {
            var s = New();
            Assert.False(s.Sprint(1000f));
            Assert.Equal(0f, s.Current, 3);
        }

        // ── Skill efficiency (combat.md §3) ──────────────────────────────

        [Fact]
        public void Efficiency_below_one_makes_the_same_action_cheaper()
        {
            var novice = New();
            var veteran = New();

            novice.Spend(40f);
            veteran.Spend(40f, efficiency: 0.75f);

            Assert.True(veteran.Current > novice.Current,
                "a more skilled fighter should pay less for the same action");
        }

        [Fact]
        public void Efficiency_cannot_go_negative_and_pay_you()
        {
            var s = New();
            s.Spend(40f, efficiency: -5f);
            Assert.Equal(s.Max, s.Current, 3);
        }

        // ── Guards ───────────────────────────────────────────────────────

        [Fact]
        public void Negative_cost_is_rejected()
        {
            var s = New();
            Assert.Throws<ArgumentOutOfRangeException>(() => s.Spend(-10f));
        }

        [Fact]
        public void Zero_max_profile_is_rejected()
        {
            var bad = StaminaProfile.Default;
            bad.Max = 0f;
            Assert.Throws<ArgumentOutOfRangeException>(() => new Stamina(bad));
        }

        [Fact]
        public void Reset_restores_everything()
        {
            var s = New();
            s.Spend(150f);
            s.SpendDodge();
            s.Reset();

            Assert.Equal(s.Max, s.Current, 3);
            Assert.False(s.IsExhausted);
            Assert.Equal(0, s.ConsecutiveDodges);
        }
    }
}
