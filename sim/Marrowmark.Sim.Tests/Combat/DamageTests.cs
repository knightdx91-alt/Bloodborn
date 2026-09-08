using System;
using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// Asserts the SHAPE of the damage triangle from design/combat.md §4,
    /// never its numbers. The multipliers will be retuned repeatedly; that
    /// cut beats light armour and fails against plate must not change
    /// without the design changing first.
    /// </summary>
    public class DamageTests
    {
        private static float Multiplier(DamageType type, ArmorClass armor) =>
            DamageTable.Default.Against(type, armor);

        // ── The grid, row by row (combat.md §4) ──────────────────────────

        [Fact]
        public void Cut_is_strong_against_light_and_worst_against_plate()
        {
            Assert.True(Multiplier(DamageType.Cut, ArmorClass.Light) > 1f);
            Assert.True(Multiplier(DamageType.Cut, ArmorClass.Mail)
                        < Multiplier(DamageType.Cut, ArmorClass.Light));
            Assert.True(Multiplier(DamageType.Cut, ArmorClass.Plate)
                        < Multiplier(DamageType.Cut, ArmorClass.Mail));
        }

        [Fact]
        public void Pierce_is_the_answer_to_mail()
        {
            var vsMail = Multiplier(DamageType.Pierce, ArmorClass.Mail);
            Assert.True(vsMail > Multiplier(DamageType.Pierce, ArmorClass.Light));
            Assert.True(vsMail > Multiplier(DamageType.Pierce, ArmorClass.Plate));
        }

        [Fact]
        public void Blunt_is_the_answer_to_plate()
        {
            var vsPlate = Multiplier(DamageType.Blunt, ArmorClass.Plate);
            Assert.True(vsPlate > Multiplier(DamageType.Blunt, ArmorClass.Light));
            Assert.True(vsPlate > Multiplier(DamageType.Blunt, ArmorClass.Mail));
        }

        [Fact]
        public void Every_armour_class_has_exactly_one_best_answer()
        {
            foreach (ArmorClass armor in Enum.GetValues(typeof(ArmorClass)))
            {
                // Unarmoured is not a rock-paper-scissors position; it is
                // simply bad. Everything hurts, cutting worst.
                if (armor == ArmorClass.None) continue;
                var best = -1f;
                var winners = 0;

                foreach (DamageType type in Enum.GetValues(typeof(DamageType)))
                {
                    var m = Multiplier(type, armor);
                    if (m > best) { best = m; winners = 1; }
                    else if (Math.Abs(m - best) < 0.0001f) { winners++; }
                }

                Assert.True(winners == 1,
                    $"{armor} should have one clearly best damage type, found {winners}");
            }
        }

        // ── L38's floor rule, applied to combat ─────────────────────────

        [Fact]
        public void The_worst_matchup_is_a_disadvantage_not_a_wall()
        {
            var worst = float.MaxValue;

            foreach (DamageType type in Enum.GetValues(typeof(DamageType)))
            foreach (ArmorClass armor in Enum.GetValues(typeof(ArmorClass)))
                worst = Math.Min(worst, Multiplier(type, armor));


            Assert.True(worst >= 0.5f,
                $"worst matchup at {worst:P0} makes the wrong weapon useless; " +
                "L38's floor rule says a beginner with the wrong tool must still be able to fight");
        }

        [Fact]
        public void The_triangle_is_sharp_enough_to_be_worth_reading()
        {
            var best = 0f;
            var worst = float.MaxValue;

            // Armoured classes only — unarmoured sits outside the band by
            // design and would flatter the spread.
            foreach (DamageType type in Enum.GetValues(typeof(DamageType)))
            foreach (ArmorClass armor in Enum.GetValues(typeof(ArmorClass)))
            {
                if (armor == ArmorClass.None) continue;
                var m = Multiplier(type, armor);
                best = Math.Max(best, m);
                worst = Math.Min(worst, m);
            }

            Assert.True(best / worst >= 1.5f,
                $"spread of {best / worst:F2}x is too flat for armour choice to be a real decision");
        }

        // ── Hit location ────────────────────────────────────────────────

        [Fact]
        public void Head_hurts_most_and_limbs_least()
        {
            var t = DamageTable.Default;
            Assert.True(t.At(HitLocation.Head) > t.At(HitLocation.Torso));
            Assert.True(t.At(HitLocation.Limb) < t.At(HitLocation.Torso));
        }

        // ── Resolution ──────────────────────────────────────────────────

        [Fact]
        public void Resolve_multiplies_weapon_damage_by_both_factors()
        {
            var result = Damage.Resolve(new DamageRequest
            {
                WeaponDamage = 40f,
                Type = DamageType.Blunt,
                Armor = ArmorClass.Plate,
                Location = HitLocation.Head,
            });

            var expected = 40f
                           * Multiplier(DamageType.Blunt, ArmorClass.Plate)
                           * DamageTable.Default.At(HitLocation.Head);

            Assert.Equal(expected, result.Final, 3);
        }

        [Fact]
        public void Resolve_reports_its_parts_for_tuning()
        {
            var result = Damage.Resolve(new DamageRequest
            {
                WeaponDamage = 10f,
                Type = DamageType.Cut,
                Armor = ArmorClass.Plate,
                Location = HitLocation.Limb,
            });

            Assert.Equal(Multiplier(DamageType.Cut, ArmorClass.Plate), result.ArmorMultiplier, 3);
            Assert.Equal(DamageTable.Default.At(HitLocation.Limb), result.LocationMultiplier, 3);
        }

        [Fact]
        public void Right_weapon_beats_wrong_weapon_against_the_same_armour()
        {
            var request = new DamageRequest
            {
                WeaponDamage = 50f,
                Armor = ArmorClass.Plate,
                Location = HitLocation.Torso,
            };

            request.Type = DamageType.Blunt;
            var right = Damage.Resolve(request).Final;

            request.Type = DamageType.Cut;
            var wrong = Damage.Resolve(request).Final;

            Assert.True(right > wrong);
        }

        [Fact]
        public void A_better_weapon_beats_a_better_matchup()
        {
            // combat.md §3/§4: raw damage comes from the weapon, so a master
            // crafter's blade in the wrong matchup should still outperform a
            // poor weapon in the right one. This is what makes crafters
            // famous and keeps gear the source of numbers.
            var masterwork = Damage.Resolve(new DamageRequest
            {
                WeaponDamage = 100f,
                Type = DamageType.Cut,
                Armor = ArmorClass.Plate, // worst matchup
                Location = HitLocation.Torso,
            }).Final;

            var crude = Damage.Resolve(new DamageRequest
            {
                WeaponDamage = 50f,
                Type = DamageType.Blunt,
                Armor = ArmorClass.Plate, // best matchup
                Location = HitLocation.Torso,
            }).Final;

            Assert.True(masterwork > crude,
                "a far better weapon in the wrong matchup should still beat a poor one in the right matchup");
        }

        // ── Guards ──────────────────────────────────────────────────────

        [Fact]
        public void Negative_weapon_damage_is_rejected()
        {
            Assert.Throws<ArgumentOutOfRangeException>(() =>
                Damage.Resolve(new DamageRequest { WeaponDamage = -1f }));
        }

        [Fact]
        public void Null_table_is_rejected()
        {
            Assert.Throws<ArgumentNullException>(() =>
                Damage.Resolve(new DamageRequest { WeaponDamage = 1f }, null));
        }

        [Fact]
        public void Malformed_tables_are_rejected()
        {
            Assert.Throws<ArgumentException>(() =>
                new DamageTable(new float[2, 4], new float[3]));
            Assert.Throws<ArgumentException>(() =>
                new DamageTable(new float[3, 3], new float[3]));
            Assert.Throws<ArgumentException>(() =>
                new DamageTable(new float[3, 4], new float[2]));
        }
    }
}
