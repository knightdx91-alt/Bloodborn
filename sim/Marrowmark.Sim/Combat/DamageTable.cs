using System;

namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// The damage triangle from design/combat.md §4, as data rather than
    /// hardcoded rules.
    ///
    /// combat.md leaves open "whether the triangle is multiplicative or
    /// additive, and how sharply — sharp enough to matter, soft enough that
    /// the wrong weapon is never useless (L38's floor rule)." This type
    /// takes no position on that question: it holds multipliers that can be
    /// retuned freely, and the tests assert only the shape the design
    /// requires, never the values.
    /// </summary>
    public sealed class DamageTable
    {
        private readonly float[,] _armor;   // [DamageType, ArmorClass]
        private readonly float[] _location; // [HitLocation]

        public DamageTable(float[,] armorMultipliers, float[] locationMultipliers)
        {
            if (armorMultipliers == null) throw new ArgumentNullException(nameof(armorMultipliers));
            if (locationMultipliers == null) throw new ArgumentNullException(nameof(locationMultipliers));

            if (armorMultipliers.GetLength(0) != 3 || armorMultipliers.GetLength(1) != 3)
                throw new ArgumentException("Armour multipliers must be 3x3.", nameof(armorMultipliers));
            if (locationMultipliers.Length != 3)
                throw new ArgumentException("Location multipliers must have 3 entries.", nameof(locationMultipliers));

            _armor = armorMultipliers;
            _location = locationMultipliers;
        }

        /// <summary>How this damage type fares against this armour.</summary>
        public float Against(DamageType type, ArmorClass armor) =>
            _armor[(int)type, (int)armor];

        /// <summary>Multiplier for where the blow landed.</summary>
        public float At(HitLocation location) => _location[(int)location];

        /// <summary>
        /// The launch table. These implement combat.md §4's grid:
        ///
        ///            Light   Mail    Plate
        ///   Cut      strong  weak    very weak
        ///   Pierce   fair    strong  fair
        ///   Blunt    fair    fair    strong
        ///
        /// The spread is deliberately moderate — the worst matchup still
        /// lands roughly two thirds of its damage. Bringing the wrong weapon
        /// should be a real disadvantage you can feel and still fight
        /// through, never a wall (L38's floor rule, applied to combat).
        /// </summary>
        public static DamageTable Default => new DamageTable(
            new[,]
            {
                //           Light  Mail   Plate
                /* Cut    */ { 1.25f, 0.80f, 0.65f },
                /* Pierce */ { 1.00f, 1.25f, 1.00f },
                /* Blunt  */ { 1.00f, 1.00f, 1.25f },
            },
            new[]
            {
                /* Torso */ 1.00f,
                /* Limb  */ 0.75f,
                /* Head  */ 1.50f,
            });
    }
}
