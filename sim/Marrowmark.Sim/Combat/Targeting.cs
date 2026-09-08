using System;
using Marrowmark.Sim.Items;

namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// Where blows land and how guards answer them. L64.
    ///
    /// This is what makes L63's per-slot armour mean something. Which piece
    /// of a harness fails is no longer arbitrary — it is a record of how
    /// its owner was fought. A duellist who keeps going overhead ruins your
    /// helm, and you finish the fight bare-headed in front of everyone.
    /// </summary>
    public static class Targeting
    {
        /// <summary>
        /// Which piece of armour a blow along this arc meets.
        ///
        /// Note what is missing: nothing routes to the arms. Arms are what
        /// you raise to defend, so vambraces wear from *blocking*
        /// (<see cref="GuardWearSlot"/>), not from being aimed at. A
        /// sword-arm that gives out because you parried all day is the most
        /// grounded failure this system can produce.
        /// </summary>
        public static ArmorSlot SlotFor(AttackDirection direction)
        {
            switch (direction)
            {
                case AttackDirection.Overhead:
                    return ArmorSlot.Head;
                case AttackDirection.UpperLeft:
                case AttackDirection.UpperRight:
                case AttackDirection.Thrust:
                    return ArmorSlot.Torso;
                case AttackDirection.LowerLeft:
                case AttackDirection.LowerRight:
                    return ArmorSlot.Legs;
                default:
                    throw new ArgumentOutOfRangeException(nameof(direction));
            }
        }

        /// <summary>The slot that wears when you defend: your arms.</summary>
        public static ArmorSlot GuardWearSlot => ArmorSlot.Arms;

        /// <summary>
        /// Whether two cutting arcs sit next to each other on the wheel.
        /// Adjacency is what makes a near-miss read a glancing turn rather
        /// than a clean hit — being nearly right should be worth something.
        /// </summary>
        public static bool AreAdjacent(AttackDirection a, AttackDirection b)
        {
            if (a == AttackDirection.Thrust || b == AttackDirection.Thrust) return false;
            if (a == b) return false;

            // Wheel order: UpperLeft - Overhead - UpperRight - LowerRight - LowerLeft
            int Index(AttackDirection d)
            {
                switch (d)
                {
                    case AttackDirection.UpperLeft: return 0;
                    case AttackDirection.Overhead: return 1;
                    case AttackDirection.UpperRight: return 2;
                    case AttackDirection.LowerRight: return 3;
                    case AttackDirection.LowerLeft: return 4;
                    default: throw new ArgumentOutOfRangeException(nameof(d));
                }
            }

            var diff = Math.Abs(Index(a) - Index(b));
            return diff == 1 || diff == 4; // 4 wraps the wheel
        }

        /// <summary>
        /// How a guard held in one direction answers a blow from another.
        ///
        /// The thrust is deliberately unforgiving: only a thrust guard
        /// stops it, and no cut guard glances it aside. That is what makes
        /// the point dangerous against someone reading edges, and it is
        /// why a spear is frightening.
        /// </summary>
        public static GuardOutcome Resolve(AttackDirection attack, AttackDirection guard)
        {
            if (attack == guard) return GuardOutcome.Blocked;
            if (attack == AttackDirection.Thrust) return GuardOutcome.Clean;
            if (AreAdjacent(attack, guard)) return GuardOutcome.Glancing;
            return GuardOutcome.Clean;
        }

        /// <summary>
        /// Damage multiplier for a guard outcome. A blocked blow still
        /// carries something through — plate turns a sword, it does not
        /// erase it — which keeps blocking a stamina war (L56) rather than
        /// an off switch.
        /// </summary>
        public static float DamageMultiplier(GuardOutcome outcome)
        {
            switch (outcome)
            {
                case GuardOutcome.Blocked: return 0.15f;
                case GuardOutcome.Glancing: return 0.60f;
                case GuardOutcome.Clean: return 1.00f;
                default: throw new ArgumentOutOfRangeException(nameof(outcome));
            }
        }
    }
}
