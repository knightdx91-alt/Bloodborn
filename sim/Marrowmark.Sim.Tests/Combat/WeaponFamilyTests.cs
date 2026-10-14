using System;
using System.Linq;
using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// combat.md §5: six families, each a distinct set of verbs. §1b:
    /// families get different direction sets. L38 applied to combat:
    /// every family is viable unarmoured and unskilled.
    /// </summary>
    public class WeaponFamilyTests
    {
        private static readonly WeaponFamily[] All =
            (WeaponFamily[])Enum.GetValues(typeof(WeaponFamily));

        [Fact]
        public void There_are_six()
        {
            Assert.Equal(6, All.Length);
            foreach (var f in All) WeaponFamilyProfile.For(f);   // all resolvable
        }

        [Fact]
        public void A_dagger_has_every_direction_and_a_maul_has_no_thrust()
        {
            // §1b's own example.
            Assert.Equal(6, WeaponFamilyProfile.DaggerAndShortBlade.Directions().Count());
            Assert.False(WeaponFamilyProfile.TwoHanded.Allows(AttackDirection.Thrust));
            Assert.True(WeaponFamilyProfile.TwoHanded.Allows(AttackDirection.Overhead));
            Assert.True(WeaponFamilyProfile.TwoHanded.Directions().Count() < 6);
        }

        [Fact]
        public void The_bow_only_shoots()
        {
            var bow = WeaponFamilyProfile.BowAndCrossbow;
            Assert.True(bow.Ranged);
            Assert.Equal(new[] { AttackDirection.Thrust }, bow.Directions().ToArray());
        }

        [Fact]
        public void Every_family_throws_something()
        {
            foreach (var f in All)
                Assert.NotEmpty(WeaponFamilyProfile.For(f).Directions());
        }

        [Fact]
        public void No_two_families_share_a_shape()
        {
            // "A distinct set of verbs, not a damage number with a skin."
            var shapes = All.Select(f =>
            {
                var p = WeaponFamilyProfile.For(f);
                return (string.Join(",", p.Directions()), p.PrimaryDamage, p.Reach, p.GuardBreak);
            }).ToList();
            Assert.Equal(shapes.Count, shapes.Distinct().Count());
        }

        [Fact]
        public void A_spear_is_weak_inside_its_reach()
        {
            var spear = WeaponFamilyProfile.SpearAndPolearm;
            Assert.True(spear.MinReach > 0f);
            Assert.True(spear.DamageAt(spear.MinReach - 0.1f) < spear.DamageAt(spear.MinReach + 0.1f));
            Assert.Equal(0f, spear.DamageAt(spear.Reach + 0.1f));

            // and a sword is not — there is no inside to a sword.
            var sword = WeaponFamilyProfile.SwordAndShield;
            Assert.Equal(sword.DamageAt(0.2f), sword.DamageAt(sword.Reach - 0.1f));
        }

        [Fact]
        public void Guard_breakers_bleed_a_block_harder()
        {
            Assert.True(WeaponFamilyProfile.AxeAndMace.BlockBleedMultiplier
                        > WeaponFamilyProfile.SwordAndShield.BlockBleedMultiplier);
            Assert.True(WeaponFamilyProfile.TwoHanded.BlockBleedMultiplier
                        > WeaponFamilyProfile.DaggerAndShortBlade.BlockBleedMultiplier);
        }

        [Fact]
        public void Only_the_sword_carries_the_shield()
        {
            Assert.Single(All, f => WeaponFamilyProfile.For(f).ShieldBattery);
            Assert.True(WeaponFamilyProfile.SwordAndShield.ShieldBattery);
        }

        [Fact]
        public void The_dagger_wins_on_recovery_and_the_maul_on_commitment()
        {
            var baseline = AttackProfile.Default;
            var dagger = WeaponFamilyProfile.DaggerAndShortBlade.Shape(baseline);
            var maul = WeaponFamilyProfile.TwoHanded.Shape(baseline);

            Assert.True(dagger.RecoverySeconds < baseline.RecoverySeconds);
            Assert.True(maul.WindupSeconds > baseline.WindupSeconds);
            Assert.True(maul.DamageMultiplier > dagger.DamageMultiplier);
            Assert.True(dagger.StaminaCost < maul.StaminaCost);
        }

        [Fact]
        public void Every_family_is_viable_unarmoured_and_unskilled()
        {
            // L38's floor rule applied to combat: no weapon may hard-fail
            // a beginner. The baseline duellist is unskilled by
            // construction — nothing in FighterSpec is a skill — so the
            // only question is whether each family can finish a fight.
            var bare = FighterSpec.Default;
            bare.Armor = ArmorClass.None;

            foreach (var f in All)
            {
                var attacker = WeaponFamilyProfile.For(f).Wielding(FighterSpec.Default);
                var ttk = TimeToKill.Estimate(attacker, bare);
                Assert.True(ttk <= 15f,
                    $"{f} takes {ttk:F1}s against an unarmoured fighter; a beginner " +
                    "with it is being hard-failed");
            }
        }

        [Fact]
        public void Every_family_gets_through_plate_eventually()
        {
            // Wrong weapon, never useless (L38). A dagger against plate is
            // a bad afternoon, not an impossibility.
            var plate = FighterSpec.Default;
            plate.Armor = ArmorClass.Plate;

            foreach (var f in All)
            {
                var attacker = WeaponFamilyProfile.For(f).Wielding(FighterSpec.Default);
                Assert.True(TimeToKill.Estimate(attacker, plate) < TimeToKill.NeverKills, f.ToString());
            }
        }

        [Fact]
        public void The_triangle_still_decides_who_fears_whom()
        {
            // A mace is the answer to plate and a dagger is not (§4).
            var plate = FighterSpec.Default; plate.Armor = ArmorClass.Plate;
            var mace = WeaponFamilyProfile.AxeAndMace.Wielding(FighterSpec.Default);
            var dagger = WeaponFamilyProfile.DaggerAndShortBlade.Wielding(FighterSpec.Default);

            Assert.True(TimeToKill.Estimate(mace, plate) < TimeToKill.Estimate(dagger, plate));
        }

        [Fact]
        public void Each_family_grows_its_own_skill()
        {
            // L18: learning the spear teaches nothing about the bow.
            var names = All.Select(WeaponFamilyProfile.SkillName).ToList();
            Assert.Equal(names.Count, names.Distinct().Count());
        }
    }
}
