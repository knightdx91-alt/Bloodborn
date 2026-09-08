using System;
using Marrowmark.Sim.Combat;
using Marrowmark.Sim.Crafting;
using Xunit;

namespace Marrowmark.Sim.Tests.Crafting
{
    /// <summary>
    /// L4, L66–L68. The flagship system. These guard the promises the
    /// design makes about it: no stage may hard-fail a beginner (L38),
    /// skill must raise the ceiling rather than gate the floor, every
    /// property must cost something, and every item must be signed.
    /// </summary>
    public class CraftingTests
    {
        private static MaterialProperties Ore =>
            new MaterialProperties(hardness: 0.40f, toughness: 0.45f, density: 0.50f, purity: 0.35f);

        // ── L38: the floor is never gated ────────────────────────────────

        [Fact]
        public void A_beginner_following_the_steps_still_improves_the_work()
        {
            var raw = Ore;
            var forged = Pipeline.Blade.Run(raw, skill: 0f);

            Assert.True(forged.CutPower > raw.CutPower,
                "an unskilled smith who follows the pipeline must still end up with a better blade");
        }

        [Fact]
        public void No_stage_collects_nothing_however_unskilled_the_hand()
        {
            foreach (var stage in new[]
                     {
                         ForgeStage.Smelt, ForgeStage.Fold, ForgeStage.Quench,
                         ForgeStage.Temper, ForgeStage.Grind,
                     })
            {
                Assert.True(ForgeStage.Realisation(0f, 0f) > 0f,
                    $"{stage.Name} must give a beginner something — L38 forbids a gated floor");
            }
        }

        [Fact]
        public void A_beginners_blade_is_serviceable_not_broken()
        {
            var forged = Pipeline.Blade.Run(Ore, skill: 0f);

            Assert.True(forged.CutPower > 0.2f);
            Assert.True(forged.DurabilityFactor > 0.5f);
        }

        // ── L67: skill raises the ceiling ────────────────────────────────

        [Fact]
        public void The_same_ore_yields_a_far_better_blade_in_better_hands()
        {
            var novice = Pipeline.Blade.Run(Ore, skill: 0f);
            var journeyman = Pipeline.Blade.Run(Ore, skill: 0.5f);
            var master = Pipeline.Blade.Run(Ore, skill: 1f);

            Assert.True(journeyman.CutPower > novice.CutPower);
            Assert.True(master.CutPower > journeyman.CutPower);
        }

        [Fact]
        public void The_gap_between_hands_is_large_enough_to_build_a_reputation_on()
        {
            var novice = Pipeline.Blade.Run(Ore, skill: 0f);
            var master = Pipeline.Blade.Run(Ore, skill: 1f);

            Assert.True(master.CutPower > novice.CutPower * 1.3f,
                $"master {master.CutPower:F2} vs novice {novice.CutPower:F2} — too close for " +
                "maker's marks to matter");
        }

        [Fact]
        public void Purity_rewards_a_good_hand_more_than_a_poor_one()
        {
            // Why master smiths bid for clean ore and beginners should not.
            var dirty = new MaterialProperties(0.4f, 0.45f, 0.5f, 0.1f);
            var clean = new MaterialProperties(0.4f, 0.45f, 0.5f, 1.0f);

            var noviceGain = Pipeline.Blade.Run(clean, 0f).CutPower
                             - Pipeline.Blade.Run(dirty, 0f).CutPower;
            var masterGain = Pipeline.Blade.Run(clean, 1f).CutPower
                             - Pipeline.Blade.Run(dirty, 1f).CutPower;

            Assert.True(masterGain > noviceGain,
                "clean stock should reward skill, not substitute for it");
        }

        // ── L66: every property costs something ──────────────────────────

        [Fact]
        public void Quenching_buys_hardness_and_charges_toughness()
        {
            var before = Ore;
            var after = ForgeStage.Quench.Apply(before, skill: 1f);

            Assert.True(after.Hardness > before.Hardness);
            Assert.True(after.Toughness < before.Toughness,
                "a hard quench must cost toughness, or there is no decision in it");
        }

        [Fact]
        public void Tempering_trades_back_the_other_way()
        {
            var quenched = ForgeStage.Quench.Apply(Ore, 1f);
            var tempered = ForgeStage.Temper.Apply(quenched, 1f);

            Assert.True(tempered.Toughness > quenched.Toughness);
            Assert.True(tempered.Hardness < quenched.Hardness);
        }

        [Fact]
        public void There_is_no_stage_that_is_pure_gain()
        {
            foreach (var stage in new[]
                     {
                         ForgeStage.Smelt, ForgeStage.Fold, ForgeStage.Quench,
                         ForgeStage.Temper, ForgeStage.Grind,
                     })
            {
                var cost = stage.Cost;
                var total = cost.Hardness + cost.Toughness + cost.Density + cost.Purity;

                Assert.True(total > 0f,
                    $"{stage.Name} charges nothing — a free stage is a button, not a decision");
            }
        }

        [Fact]
        public void Density_cuts_both_ways()
        {
            var light = new MaterialProperties(0.6f, 0.5f, 0.2f, 0.5f);
            var heavy = new MaterialProperties(0.6f, 0.5f, 0.9f, 0.5f);

            Assert.True(heavy.BluntPower > light.BluntPower, "mass should hit harder");
            Assert.True(heavy.PiercePower < light.PiercePower, "mass should make a worse point");
            Assert.True(heavy.Weight > light.Weight, "mass should cost encumbrance (L55/L57)");
        }

        [Fact]
        public void Toughness_buys_a_longer_life()
        {
            var brittle = new MaterialProperties(0.9f, 0.1f, 0.5f, 0.5f);
            var stubborn = new MaterialProperties(0.9f, 0.9f, 0.5f, 0.5f);

            Assert.True(stubborn.DurabilityFactor > brittle.DurabilityFactor);
        }

        // ── Order matters: a pipeline is a craft, not a checklist ────────

        [Fact]
        public void The_same_stages_in_a_different_order_make_a_different_blade()
        {
            var quenchThenTemper = new Pipeline()
                .Then(ForgeStage.Quench).Then(ForgeStage.Temper).Run(Ore, 0.7f);
            var temperThenQuench = new Pipeline()
                .Then(ForgeStage.Temper).Then(ForgeStage.Quench).Run(Ore, 0.7f);

            Assert.NotEqual(quenchThenTemper.Hardness, temperThenQuench.Hardness, 3);
        }

        [Fact]
        public void Buying_a_good_billet_beats_doing_every_stage_badly_yourself()
        {
            // L38: casuals buy intermediates and run only the stages they
            // enjoy. That has to actually pay, or the intermediate-goods
            // market the economy wants never forms.
            var boughtBillet = new Pipeline()
                .Then(ForgeStage.Smelt).Then(ForgeStage.Fold)
                .Run(Ore, skill: 0.95f); // a specialist made this

            var finishedByAmateur = new Pipeline()
                .Then(ForgeStage.Quench).Then(ForgeStage.Temper).Then(ForgeStage.Grind)
                .Run(boughtBillet, skill: 0.1f);

            var allAmateur = Pipeline.Blade.Run(Ore, skill: 0.1f);

            Assert.True(finishedByAmateur.RoughValue > allAmateur.RoughValue,
                $"bought billet finished badly ({finishedByAmateur}) should beat " +
                $"doing everything badly ({allAmateur})");
        }

        // ── L68: everything is signed ────────────────────────────────────

        [Fact]
        public void Every_finished_item_carries_its_makers_name()
        {
            var item = Pipeline.Blade.Forge(Ore, skill: 0.5f, makersMark: "Corran of Ashfell");

            Assert.Equal("Corran of Ashfell", item.MakersMark);
            Assert.Equal(5, item.Pipeline.Count);
        }

        [Fact]
        public void There_is_no_way_to_forge_anonymously()
        {
            Assert.Throws<ArgumentException>(() =>
                Pipeline.Blade.Forge(Ore, 0.5f, makersMark: ""));
            Assert.Throws<ArgumentException>(() =>
                Pipeline.Blade.Forge(Ore, 0.5f, makersMark: null));
        }

        // ── Reaching the rest of the game ───────────────────────────────

        [Fact]
        public void A_tougher_blade_gets_a_bigger_durability_ceiling()
        {
            var brittleOre = new MaterialProperties(0.5f, 0.1f, 0.5f, 0.5f);
            var toughOre = new MaterialProperties(0.5f, 0.9f, 0.5f, 0.5f);

            var brittle = Pipeline.Blade.Forge(brittleOre, 0.5f, "A");
            var tough = Pipeline.Blade.Forge(toughOre, 0.5f, "B");

            Assert.True(tough.Durability.OriginalMax > brittle.Durability.OriginalMax);
        }

        [Fact]
        public void A_worn_blade_hits_softer_than_a_fresh_one()
        {
            var item = Pipeline.Blade.Forge(Ore, 0.8f, "Corran");
            var fresh = item.EffectivePowerFor(DamageType.Cut);

            item.Durability.WearFraction(0.95f);

            Assert.True(item.EffectivePowerFor(DamageType.Cut) < fresh);
        }

        [Fact]
        public void Properties_stay_inside_their_range_however_much_you_work_them()
        {
            var p = new MaterialProperties(1f, 1f, 1f, 1f);
            for (var i = 0; i < 50; i++) p = ForgeStage.Quench.Apply(p, 1f);

            Assert.InRange(p.Hardness, 0f, 1f);
            Assert.InRange(p.Toughness, 0f, 1f);
        }

        [Fact]
        public void Guards_reject_nonsense()
        {
            Assert.Throws<ArgumentNullException>(() => new Pipeline().Then(null));
            Assert.Throws<ArgumentNullException>(() =>
                new ForgeStage(null, default, default));
        }
    }
}
