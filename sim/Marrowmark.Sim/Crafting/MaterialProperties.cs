using System;

namespace Marrowmark.Sim.Crafting
{
    /// <summary>
    /// What actually varies between two lumps of iron (L4, L66). Four
    /// continuous axes, each 0..1, each with a real cost attached — there
    /// is no configuration that is simply best.
    /// </summary>
    public struct MaterialProperties
    {
        /// <summary>
        /// Takes and holds an edge. Drives cutting and piercing power — and
        /// fights toughness, because hard steel is brittle steel.
        /// </summary>
        public float Hardness;

        /// <summary>
        /// Resists shattering and deformation. Sets how much life the
        /// finished item has (L59's ceiling) and keeps a hard blade from
        /// snapping the first time it catches a blow.
        /// </summary>
        public float Toughness;

        /// <summary>
        /// Mass. Adds blunt force — and weight, which eats stamina headroom
        /// under L55/L57. A dense maul hits plate like nothing else and
        /// costs you the bar you needed to swing it twice.
        /// </summary>
        public float Density;

        /// <summary>
        /// Freedom from slag and inclusion. Purity does not make an item
        /// better by itself — it makes the material *answer the hand*, so
        /// a skilled smith realises more of what a clean billet offers than
        /// a dirty one.
        /// </summary>
        public float Purity;

        public MaterialProperties(float hardness, float toughness, float density, float purity)
        {
            Hardness = Clamp(hardness);
            Toughness = Clamp(toughness);
            Density = Clamp(density);
            Purity = Clamp(purity);
        }

        // ── Derived stats: how properties reach the rest of the game ────

        /// <summary>Cutting power — the edge (`combat.md` §4).</summary>
        public float CutPower => Hardness;

        /// <summary>
        /// Piercing power. Rewards a hard, *fine* point, so a dense billet
        /// makes a worse needle than a light one.
        /// </summary>
        public float PiercePower => Hardness * (1f - 0.3f * Density);

        /// <summary>Blunt power — mass behind the blow.</summary>
        public float BluntPower => Density;

        /// <summary>
        /// Multiplier on the item's durability ceiling (L59). Tough
        /// material simply lasts longer before it is scrap.
        /// </summary>
        public float DurabilityFactor => 0.5f + Toughness;

        /// <summary>
        /// Relative weight, feeding the encumbrance budget (L55/L57).
        /// </summary>
        public float Weight => Density;

        /// <summary>
        /// A single figure of merit, for sorting a market board or judging
        /// a trade at a glance. Deliberately crude — it averages away every
        /// tradeoff that makes the system interesting, and no crafting
        /// decision should ever be made from it.
        /// </summary>
        public float RoughValue => (Hardness + Toughness + Density + Purity) / 4f;

        public static MaterialProperties Lerp(MaterialProperties a, MaterialProperties b, float t)
        {
            t = Clamp(t);
            return new MaterialProperties(
                a.Hardness + (b.Hardness - a.Hardness) * t,
                a.Toughness + (b.Toughness - a.Toughness) * t,
                a.Density + (b.Density - a.Density) * t,
                a.Purity + (b.Purity - a.Purity) * t);
        }

        public override string ToString() =>
            $"H{Hardness:F2} T{Toughness:F2} D{Density:F2} P{Purity:F2}";

        private static float Clamp(float v) => v < 0f ? 0f : (v > 1f ? 1f : v);
    }
}
