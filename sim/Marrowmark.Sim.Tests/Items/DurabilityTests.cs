using System;
using Marrowmark.Sim.Combat;
using Marrowmark.Sim.Items;
using Xunit;

namespace Marrowmark.Sim.Tests.Items
{
    /// <summary>
    /// L3, L32, L59, L60, L61. These guard the economic engine, not the
    /// numbers: gear must genuinely leave the world, nothing may break in
    /// your hands, and skill must be worth paying for.
    /// </summary>
    public class DurabilityTests
    {
        private static Durability New() => new Durability();

        [Fact]
        public void A_new_item_is_pristine()
        {
            var d = New();
            Assert.Equal(d.OriginalMax, d.Condition, 3);
            Assert.Equal(d.OriginalMax, d.Ceiling, 3);
            Assert.Equal(1f, d.Performance, 3);
            Assert.False(d.IsScrap);
        }

        // ── L60: wear only bites past a threshold ────────────────────────

        [Fact]
        public void Light_wear_costs_no_performance()
        {
            var d = New();
            d.WearFraction(0.4f); // still above the halfway threshold

            Assert.Equal(1f, d.Performance, 3);
        }

        [Fact]
        public void Neglect_costs_real_performance()
        {
            var d = New();
            d.WearFraction(0.9f);

            Assert.True(d.Performance < 1f, "a badly worn item should perform worse");
        }

        [Fact]
        public void Performance_declines_smoothly_past_the_threshold()
        {
            var half = New(); half.WearFraction(0.5f);
            var mostly = New(); mostly.WearFraction(0.75f);
            var spent = New(); spent.WearFraction(1.0f);

            Assert.True(half.Performance > mostly.Performance);
            Assert.True(mostly.Performance > spent.Performance);
        }

        [Fact]
        public void A_spent_item_still_works_until_you_use_it_again()
        {
            // L62 amends L3: things do break, but only at zero condition
            // and only on the next use. Reaching zero is not itself
            // failure — it is the last warning.
            var d = New();
            d.WearFraction(1f);

            Assert.Equal(0f, d.Condition, 3);
            Assert.False(d.IsBroken);
            Assert.True(d.Performance > 0f, "a spent but unbroken item must still function");
        }

        // ── L62: breakage, earned and never random ───────────────────────

        [Fact]
        public void Using_a_spent_item_breaks_it()
        {
            var d = New();
            d.WearFraction(1f);

            Assert.True(d.Use(1f), "using an item at zero condition should break it");
            Assert.True(d.IsBroken);
            Assert.Equal(0f, d.Performance, 3);
        }

        [Fact]
        public void A_maintained_item_never_breaks_however_long_it_is_used()
        {
            // The fairness guarantee. There is no randomness in breakage:
            // a player who repairs before the danger zone will never once
            // see an item fail, however many fights they take it into.
            var d = New();

            for (var i = 0; i < 2000; i++)
            {
                if (d.Fraction < 0.4f && !d.IsScrap) d.Repair(0.9f);
                if (d.IsScrap) break;
                Assert.False(d.Use(0.5f), $"a maintained item broke on use {i}");
            }

            Assert.False(d.IsBroken);
        }

        [Fact]
        public void Breaking_is_always_preceded_by_a_long_visible_decline()
        {
            // You cannot go from healthy to broken. Performance must have
            // fallen away first, which is the warning the player gets.
            var d = New();
            var sawDecline = false;

            while (!d.IsBroken)
            {
                if (d.Performance < 1f) sawDecline = true;
                d.Use(1f);
            }

            Assert.True(sawDecline, "an item must visibly decline before it breaks");
        }

        [Fact]
        public void A_broken_item_cannot_be_repaired()
        {
            var d = New();
            d.WearFraction(1f);
            d.Use(1f);

            var result = d.Repair(1f);

            Assert.Equal(0f, result.Restored, 3);
            Assert.True(d.IsBroken);
            Assert.True(d.IsScrap, "a snapped blade is materials, not equipment");
        }

        [Fact]
        public void Using_an_already_broken_item_changes_nothing()
        {
            var d = New();
            d.WearFraction(1f);
            d.Use(1f);

            Assert.False(d.Use(1f));
        }

        // ── L59: repairs cost the item its life ──────────────────────────

        [Fact]
        public void Repair_restores_condition_but_costs_ceiling()
        {
            var d = New();
            d.WearFraction(0.6f);

            var before = d.Ceiling;
            var result = d.Repair(smithSkill: 0.5f);

            Assert.True(result.Restored > 0f);
            Assert.True(result.CeilingLost > 0f, "every repair must cost the item some life");
            Assert.True(d.Ceiling < before);
            Assert.Equal(d.Ceiling, d.Condition, 3);
        }

        [Fact]
        public void Enough_repairs_turn_any_item_into_scrap()
        {
            // The whole economic point: gear leaves the world.
            var d = New();

            for (var i = 0; i < 200 && !d.IsScrap; i++)
            {
                d.WearFraction(1f);
                d.Repair(smithSkill: 1f);
            }

            Assert.True(d.IsScrap, "no item may last forever, however well maintained");
        }

        [Fact]
        public void Remaining_life_falls_as_the_item_ages()
        {
            var d = New();
            Assert.Equal(1f, d.RemainingLife, 3);

            d.WearFraction(1f);
            d.Repair(smithSkill: 0f);

            Assert.True(d.RemainingLife < 1f);
        }

        [Fact]
        public void Scrap_cannot_be_repaired_back_into_service()
        {
            var d = New();
            while (!d.IsScrap) { d.WearFraction(1f); d.Repair(smithSkill: 0f); }

            var ceiling = d.Ceiling;
            var result = d.Repair(smithSkill: 1f);

            Assert.Equal(0f, result.CeilingLost, 3);
            Assert.Equal(ceiling, d.Ceiling, 3);
        }

        // ── L61: anyone can repair, skill sets the price ─────────────────

        [Fact]
        public void A_master_repair_costs_the_item_far_less_than_an_amateur_one()
        {
            var d = New();

            var novice = d.RepairCostAtSkill(0f);
            var master = d.RepairCostAtSkill(1f);

            Assert.True(master < novice,
                "skill must be worth paying for, or nobody hires a smith");
        }

        [Fact]
        public void A_master_maintained_blade_outlives_a_field_patched_one_severalfold()
        {
            var pampered = New();
            var abused = New();

            var pamperedRepairs = 0;
            while (!pampered.IsScrap) { pampered.WearFraction(1f); pampered.Repair(1f); pamperedRepairs++; }

            var abusedRepairs = 0;
            while (!abused.IsScrap) { abused.WearFraction(1f); abused.Repair(0f); abusedRepairs++; }

            Assert.True(pamperedRepairs > abusedRepairs * 2,
                $"master care ({pamperedRepairs} repairs) should massively outlast " +
                $"amateur patching ({abusedRepairs})");
        }

        [Fact]
        public void Repair_skill_is_clamped_to_a_sane_range()
        {
            var d = New();
            Assert.Equal(d.RepairCostAtSkill(0f), d.RepairCostAtSkill(-5f), 4);
            Assert.Equal(d.RepairCostAtSkill(1f), d.RepairCostAtSkill(5f), 4);
        }

        // ── L32: the casual player's contribution ────────────────────────

        [Fact]
        public void Dying_wears_gear_without_destroying_it()
        {
            var d = New();
            d.WearFromDeath();

            Assert.True(d.Condition < d.Ceiling, "dying should cost condition");
            Assert.Equal(1f, d.Performance, 3);
        }

        [Fact]
        public void A_casual_player_needs_repairs_but_not_constantly()
        {
            // Enough deaths to matter, few enough that upkeep is not a
            // second job. Five deaths should still leave you fighting fine.
            var d = New();
            for (var i = 0; i < 5; i++) d.WearFromDeath();

            Assert.Equal(1f, d.Performance, 3);
            Assert.True(d.Fraction < 0.7f, "five deaths should be visibly felt");
        }

        // ── Integration with combat ──────────────────────────────────────

        [Fact]
        public void A_worn_weapon_hits_softer()
        {
            var sharp = New();
            var blunted = New();
            blunted.WearFraction(0.95f);

            var request = new DamageRequest
            {
                Type = DamageType.Cut,
                Armor = ArmorClass.Light,
                Location = HitLocation.Torso,
            };

            request.WeaponDamage = 40f * sharp.Performance;
            var sharpHit = Damage.Resolve(request).Final;

            request.WeaponDamage = 40f * blunted.Performance;
            var bluntedHit = Damage.Resolve(request).Final;

            Assert.True(bluntedHit < sharpHit);
        }

        // ── Guards ───────────────────────────────────────────────────────

        [Fact]
        public void Negative_wear_is_rejected()
        {
            var d = New();
            Assert.Throws<ArgumentOutOfRangeException>(() => d.Wear(-1f));
            Assert.Throws<ArgumentOutOfRangeException>(() => d.WearFraction(-1f));
        }

        [Fact]
        public void A_zero_condition_profile_is_rejected()
        {
            var bad = DurabilityProfile.Default;
            bad.MaxCondition = 0f;
            Assert.Throws<ArgumentOutOfRangeException>(() => new Durability(bad));
        }
    }
}
