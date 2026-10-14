using System;
using System.Collections.Generic;

namespace Marrowmark.Sim.Combat
{
    /// <summary>combat.md §5: six families, each a distinct set of verbs,
    /// not a damage number with a skin.</summary>
    public enum WeaponFamily
    {
        SwordAndShield,
        TwoHanded,
        SpearAndPolearm,
        DaggerAndShortBlade,
        AxeAndMace,
        BowAndCrossbow,
    }

    /// <summary>
    /// What makes one family different from another, as numbers and
    /// switches. Every multiplier is against <see cref="AttackProfile"/>'s
    /// baseline sword cut, so a family is described by how it departs from
    /// the middle rather than by a second set of absolutes.
    ///
    /// The direction set is the part combat.md §1b made load-bearing: a
    /// dagger has all five arcs and a thrust, a two-handed maul has an
    /// overhead and two side arcs and no thrust worth the name. That is
    /// historically true, makes families feel distinct, and cuts the
    /// animation matrix by a third — which is the one content cost the
    /// design cannot afford to ignore.
    /// </summary>
    public struct WeaponFamilyProfile
    {
        public bool Overhead;
        public bool UpperCuts;
        public bool LowerCuts;
        public bool Thrust;

        /// <summary>Cut, pierce or blunt — where the family sits on §4's
        /// triangle. A crafter can move a weapon within its family (a
        /// mace head on an axe haft) but not out of it.</summary>
        public DamageType PrimaryDamage;

        public float WindupMultiplier;
        public float RecoveryMultiplier;
        public float StaminaCostMultiplier;
        public float DamageMultiplier;

        /// <summary>Metres. The spear's whole argument.</summary>
        public float Reach;

        /// <summary>Inside this the weapon is awkward. Zero for most.</summary>
        public float MinReach;

        /// <summary>Damage multiplier inside <see cref="MinReach"/>.
        /// "Weak once inside its range."</summary>
        public float InsideReachMultiplier;

        /// <summary>How much extra stamina a blocked blow from this family
        /// bleeds from the guard, as a fraction. Axes and mauls are
        /// guard-breakers; a dagger is not.</summary>
        public float GuardBreak;

        /// <summary>The shield is a stamina battery that trades mobility
        /// for safety. Only one family carries one.</summary>
        public bool ShieldBattery;

        /// <summary>The draw is a commitment and the aim sways; the blow
        /// lands at range. No auto-aim on any platform.</summary>
        public bool Ranged;

        public bool Allows(AttackDirection d)
        {
            switch (d)
            {
                case AttackDirection.Overhead: return Overhead;
                case AttackDirection.UpperLeft:
                case AttackDirection.UpperRight: return UpperCuts;
                case AttackDirection.LowerLeft:
                case AttackDirection.LowerRight: return LowerCuts;
                case AttackDirection.Thrust: return Thrust;
                default: throw new ArgumentOutOfRangeException(nameof(d));
            }
        }

        public IEnumerable<AttackDirection> Directions()
        {
            foreach (AttackDirection d in Enum.GetValues(typeof(AttackDirection)))
                if (Allows(d)) yield return d;
        }

        /// <summary>The family's version of a baseline swing.</summary>
        public AttackProfile Shape(AttackProfile baseline)
        {
            baseline.WindupSeconds *= WindupMultiplier;
            baseline.RecoverySeconds *= RecoveryMultiplier;
            baseline.StaminaCost *= StaminaCostMultiplier;
            baseline.DamageMultiplier *= DamageMultiplier;
            baseline.Reach = Reach;
            return baseline;
        }

        /// <summary>What a blow at this distance is worth, as a multiplier
        /// on the weapon's damage. Past reach: nothing. Inside the minimum:
        /// awkward. Otherwise the family's own.</summary>
        public float DamageAt(float distance)
        {
            if (distance > Reach) return 0f;
            if (distance < MinReach) return DamageMultiplier * InsideReachMultiplier;
            return DamageMultiplier;
        }

        /// <summary>Stamina a guard bleeds per blocked blow, relative to
        /// an ordinary cut.</summary>
        public float BlockBleedMultiplier => 1f + GuardBreak;

        /// <summary>A fighter wielding this family, for the time-to-kill
        /// guard. Pace is the mean of windup and recovery, because that is
        /// what decides how often the blade comes round.</summary>
        public FighterSpec Wielding(FighterSpec baseline)
        {
            baseline.WeaponDamage *= DamageMultiplier;
            baseline.WeaponType = PrimaryDamage;
            baseline.AttackCost *= StaminaCostMultiplier;
            baseline.AttackInterval *= (WindupMultiplier + RecoveryMultiplier) * 0.5f;
            return baseline;
        }

        // ── The six, as placeholders with the right relationships ───────

        public static WeaponFamilyProfile SwordAndShield => new WeaponFamilyProfile
        {
            Overhead = true, UpperCuts = true, LowerCuts = true, Thrust = true,
            PrimaryDamage = DamageType.Cut,
            WindupMultiplier = 1.0f, RecoveryMultiplier = 1.0f,
            StaminaCostMultiplier = 1.0f, DamageMultiplier = 1.0f,
            Reach = 2.1f, MinReach = 0f, InsideReachMultiplier = 1f,
            GuardBreak = 0.1f, ShieldBattery = true, Ranged = false,
        };

        public static WeaponFamilyProfile TwoHanded => new WeaponFamilyProfile
        {
            Overhead = true, UpperCuts = true, LowerCuts = false, Thrust = false,
            PrimaryDamage = DamageType.Cut,
            WindupMultiplier = 1.4f, RecoveryMultiplier = 1.3f,
            StaminaCostMultiplier = 1.3f, DamageMultiplier = 1.6f,
            Reach = 2.5f, MinReach = 0f, InsideReachMultiplier = 1f,
            GuardBreak = 0.6f, ShieldBattery = false, Ranged = false,
        };

        public static WeaponFamilyProfile SpearAndPolearm => new WeaponFamilyProfile
        {
            Overhead = true, UpperCuts = false, LowerCuts = true, Thrust = true,
            PrimaryDamage = DamageType.Pierce,
            WindupMultiplier = 1.1f, RecoveryMultiplier = 1.1f,
            StaminaCostMultiplier = 1.1f, DamageMultiplier = 1.1f,
            Reach = 3.2f, MinReach = 1.2f, InsideReachMultiplier = 0.5f,
            GuardBreak = 0.2f, ShieldBattery = false, Ranged = false,
        };

        public static WeaponFamilyProfile DaggerAndShortBlade => new WeaponFamilyProfile
        {
            Overhead = true, UpperCuts = true, LowerCuts = true, Thrust = true,
            PrimaryDamage = DamageType.Pierce,
            WindupMultiplier = 0.7f, RecoveryMultiplier = 0.6f,
            StaminaCostMultiplier = 0.7f, DamageMultiplier = 0.6f,
            Reach = 1.3f, MinReach = 0f, InsideReachMultiplier = 1f,
            GuardBreak = 0f, ShieldBattery = false, Ranged = false,
        };

        public static WeaponFamilyProfile AxeAndMace => new WeaponFamilyProfile
        {
            Overhead = true, UpperCuts = true, LowerCuts = true, Thrust = false,
            PrimaryDamage = DamageType.Blunt,
            WindupMultiplier = 1.2f, RecoveryMultiplier = 1.4f,
            StaminaCostMultiplier = 1.2f, DamageMultiplier = 1.3f,
            Reach = 2.0f, MinReach = 0f, InsideReachMultiplier = 1f,
            GuardBreak = 0.7f, ShieldBattery = false, Ranged = false,
        };

        /// <summary>The shot is a thrust: it seeks the gap, lands on the
        /// torso, and only a thrust guard turns it — which is what a
        /// shield is for.</summary>
        public static WeaponFamilyProfile BowAndCrossbow => new WeaponFamilyProfile
        {
            Overhead = false, UpperCuts = false, LowerCuts = false, Thrust = true,
            PrimaryDamage = DamageType.Pierce,
            WindupMultiplier = 1.5f, RecoveryMultiplier = 0.8f,
            StaminaCostMultiplier = 1.2f, DamageMultiplier = 1.2f,
            Reach = 40f, MinReach = 3f, InsideReachMultiplier = 0.4f,
            GuardBreak = 0f, ShieldBattery = false, Ranged = true,
        };

        public static WeaponFamilyProfile For(WeaponFamily family)
        {
            switch (family)
            {
                case WeaponFamily.SwordAndShield: return SwordAndShield;
                case WeaponFamily.TwoHanded: return TwoHanded;
                case WeaponFamily.SpearAndPolearm: return SpearAndPolearm;
                case WeaponFamily.DaggerAndShortBlade: return DaggerAndShortBlade;
                case WeaponFamily.AxeAndMace: return AxeAndMace;
                case WeaponFamily.BowAndCrossbow: return BowAndCrossbow;
                default: throw new ArgumentOutOfRangeException(nameof(family));
            }
        }

        /// <summary>The name of the skill that grows by using this family
        /// (L18). One per family: learning the spear teaches nothing about
        /// the bow.</summary>
        public static string SkillName(WeaponFamily family) => family.ToString();
    }
}
