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

            if (armorMultipliers.GetLength(0) != 3 || armorMultipliers.GetLength(1) != 4)
                throw new ArgumentException(
                    "Armour multipliers must be 3 damage types by 4 armour classes.",
                    nameof(armorMultipliers));
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
        /// The spread across armoured classes is deliberately moderate —
        /// the worst matchup still lands roughly two thirds of its damage.
        /// Bringing the wrong weapon should be a real disadvantage you can
        /// feel and still fight through, never a wall (L38's floor rule,
        /// applied to combat).
        ///
        /// Unarmoured sits outside that band on purpose: every damage type
        /// is devastating against bare flesh, cutting worst of all. That is
        /// what makes L57's tradeoff bite — a hauler who dropped their
        /// armour to carry goods is genuinely in danger, not merely
        /// inconvenienced.
        ///
        /// Every unarmoured entry is well clear of the best armoured one
        /// (1.25), and deliberately so. An earlier draft had blunt at 1.30
        /// against bare flesh versus 1.25 against plate, which made plate
        /// almost pointless against maces — the exact armour it should
        /// answer. Keep the gap wide: if any armour is not clearly better
        /// than none against every damage type, nobody will wear it.
        /// </summary>
        public static DamageTable Default => new DamageTable(
            new[,]
            {
                //           None   Light  Mail   Plate
                /* Cut    */ { 1.75f, 1.25f, 0.80f, 0.65f },
                /* Pierce */ { 1.60f, 1.00f, 1.25f, 1.00f },
                /* Blunt  */ { 1.50f, 1.00f, 1.00f, 1.25f },
            },
            new[]
            {
                /* Torso */ 1.00f,
                /* Limb  */ 0.75f,
                /* Head  */ 1.50f,
            });
    }
}
