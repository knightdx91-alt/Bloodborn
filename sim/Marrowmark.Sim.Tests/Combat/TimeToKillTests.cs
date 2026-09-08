using System;
using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// design/combat.md §4: "Time to kill between comparable players:
    /// roughly 5–15 seconds. Long enough that reads and stamina management
    /// decide it; short enough that being ganked is not a ten-minute
    /// ordeal."
    ///
    /// These turn that sentence into something that fails loudly. Any
    /// change to weapon damage, health, the damage triangle, attack pacing
    /// or the stamina economy that pushes fights out of range breaks these
    /// tests — which is the point, because the drift usually happens
    /// somewhere other than where it shows.
    /// </summary>
    public class TimeToKillTests
    {
        private const float MinSeconds = 5f;
        private const float MaxSeconds = 15f;

        // These cover ONE fighter profile — a duellist. L56/L57 introduce
        // archetypes, and a plate-and-shield mirror match is a stamina war
        // that will legitimately run longer. Whether the window above
        // applies per archetype or describes the median fight is deferred
        // to the prototype (combat.md §9: feel is judged with a
        // controller). Do not widen these bounds to accommodate a tank
        // profile without settling that question first.

        [Fact]
        public void Mirror_match_lands_in_the_target_window()
        {
            var ttk = TimeToKill.Mirror(FighterSpec.Default);

            Assert.InRange(ttk, MinSeconds, MaxSeconds);
        }

        [Fact]
        public void Every_matchup_lands_in_the_target_window()
        {
            var spec = FighterSpec.Default;

            foreach (DamageType type in Enum.GetValues(typeof(DamageType)))
            foreach (ArmorClass armor in Enum.GetValues(typeof(ArmorClass)))
            {
                var attacker = spec; attacker.WeaponType = type;
                var defender = spec; defender.Armor = armor;

                var ttk = TimeToKill.Estimate(attacker, defender);

                Assert.True(ttk >= MinSeconds && ttk <= MaxSeconds,
                    $"{type} vs {armor} kills in {ttk:F2}s, outside combat.md §4's " +
                    $"{MinSeconds}–{MaxSeconds}s window");
            }
        }

        [Fact]
        public void Stamina_genuinely_caps_sustained_damage()
        {
            // The whole reason TTK is simulated rather than calculated. If
            // this fails, the stamina economy has stopped mattering in a
            // fight and combat.md §2 is decorative.
            var normal = FighterSpec.Default;
            normal.WeaponType = DamageType.Cut;

            var defender = FighterSpec.Default;
            defender.Armor = ArmorClass.Plate; // long enough fight to exhaust

            var tireless = normal;
            tireless.Stamina.Max = 100000f;

            var normalTtk = TimeToKill.Estimate(normal, defender);
            var tirelessTtk = TimeToKill.Estimate(tireless, defender);

            Assert.True(tirelessTtk < normalTtk,
                $"a fighter who never tires ({tirelessTtk:F2}s) should kill faster " +
                $"than one who does ({normalTtk:F2}s)");
        }

        [Fact]
        public void A_better_weapon_kills_faster()
        {
            var poor = FighterSpec.Default;
            var fine = FighterSpec.Default;
            fine.WeaponDamage *= 1.5f;

            Assert.True(
                TimeToKill.Estimate(fine, FighterSpec.Default) <
                TimeToKill.Estimate(poor, FighterSpec.Default));
        }

        [Fact]
        public void The_right_damage_type_kills_faster()
        {
            var defender = FighterSpec.Default;
            defender.Armor = ArmorClass.Plate;

            var blunt = FighterSpec.Default; blunt.WeaponType = DamageType.Blunt;
            var cut = FighterSpec.Default; cut.WeaponType = DamageType.Cut;

            Assert.True(
                TimeToKill.Estimate(blunt, defender) < TimeToKill.Estimate(cut, defender));
        }

        [Fact]
        public void Heavier_armour_survives_longer_against_the_wrong_weapon()
        {
            var attacker = FighterSpec.Default;
            attacker.WeaponType = DamageType.Cut;

            var light = FighterSpec.Default; light.Armor = ArmorClass.Light;
            var plate = FighterSpec.Default; plate.Armor = ArmorClass.Plate;

            Assert.True(
                TimeToKill.Estimate(attacker, plate) > TimeToKill.Estimate(attacker, light));
        }

        [Fact]
        public void Even_the_worst_matchup_still_kills()
        {
            // L38's floor rule again: the wrong weapon is a disadvantage,
            // never a wall. A matchup that cannot kill at all is a wall.
            var attacker = FighterSpec.Default;
            attacker.WeaponType = DamageType.Cut;

            var defender = FighterSpec.Default;
            defender.Armor = ArmorClass.Plate;

            Assert.NotEqual(TimeToKill.NeverKills, TimeToKill.Estimate(attacker, defender));
        }

        [Fact]
        public void Result_is_stable_across_simulation_step_sizes()
        {
            var coarse = TimeToKill.Estimate(FighterSpec.Default, FighterSpec.Default, stepSeconds: 1f / 30f);
            var fine = TimeToKill.Estimate(FighterSpec.Default, FighterSpec.Default, stepSeconds: 1f / 240f);

            Assert.Equal(coarse, fine, 1);
        }

        [Fact]
        public void A_harmless_weapon_never_kills()
        {
            var harmless = FighterSpec.Default;
            harmless.WeaponDamage = 0f;

            Assert.Equal(TimeToKill.NeverKills,
                TimeToKill.Estimate(harmless, FighterSpec.Default));
        }

        [Fact]
        public void Invalid_simulation_parameters_are_rejected()
        {
            Assert.Throws<ArgumentOutOfRangeException>(() =>
                TimeToKill.Estimate(FighterSpec.Default, FighterSpec.Default, stepSeconds: 0f));
            Assert.Throws<ArgumentOutOfRangeException>(() =>
                TimeToKill.Estimate(FighterSpec.Default, FighterSpec.Default, capSeconds: 0f));
        }
    }
}
