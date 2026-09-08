using System;

namespace Marrowmark.Sim.Crafting
{
    /// <summary>
    /// One hands-on operation in a pipeline — a smelt, a fold, a quench,
    /// a tempering (L4, L67).
    ///
    /// Every stage is a **trade**: it offers something and charges
    /// something. Skill decides how much of the offer you collect; the
    /// charge is the same for everyone. So a master and a beginner
    /// quenching the same billet both lose the same toughness, and the
    /// master walks away with far more hardness for it.
    ///
    /// That asymmetry is L38 made mechanical: the beginner's result is
    /// worse, never broken, and no stage can hard-fail a patient hand.
    /// </summary>
    public sealed class ForgeStage
    {
        /// <summary>
        /// Floor on how much of a stage's benefit an unskilled hand
        /// collects. Never zero — a beginner who follows the steps must
        /// still improve the work, or the floor has been gated (L38).
        /// </summary>
        public const float NoviceRealisation = 0.35f;

        public ForgeStage(string name, MaterialProperties benefit, MaterialProperties cost)
        {
            Name = name ?? throw new ArgumentNullException(nameof(name));
            Benefit = benefit;
            Cost = cost;
        }

        public string Name { get; }

        /// <summary>What the stage offers, at full realisation.</summary>
        public MaterialProperties Benefit { get; }

        /// <summary>What it charges, regardless of skill.</summary>
        public MaterialProperties Cost { get; }

        /// <summary>
        /// How much of the benefit a smith of this skill collects from
        /// material of this purity.
        ///
        /// Purity is a *multiplier on skill's reach*, not a bonus in its
        /// own right: clean stock rewards a good hand and does little for
        /// a poor one, which is why master smiths bid for good ore.
        /// </summary>
        public static float Realisation(float skill, float purity)
        {
            skill = Clamp(skill);
            purity = Clamp(purity);

            var reach = NoviceRealisation + (1f - NoviceRealisation) * skill;
            return reach * (0.75f + 0.25f * purity);
        }

        /// <summary>
        /// Work the material. Returns the transformed properties.
        ///
        /// Gains meet **diminishing returns** — a stage moves a property
        /// towards its ceiling, so quenching soft steel buys a great deal
        /// of hardness and quenching already-hard steel buys almost none.
        /// Costs scale with what is there to lose.
        ///
        /// That is what makes **order part of the craft**. Quench then
        /// temper is not the same blade as temper then quench, because each
        /// stage acts on what the last one left. A pipeline is a sequence of
        /// decisions, not a checklist — and a smith who understands why
        /// tempering an unquenched billet is a wasted heat knows something
        /// worth knowing.
        /// </summary>
        public MaterialProperties Apply(MaterialProperties input, float skill)
        {
            var r = Realisation(skill, input.Purity);

            return new MaterialProperties(
                Work(input.Hardness, Benefit.Hardness, Cost.Hardness, r),
                Work(input.Toughness, Benefit.Toughness, Cost.Toughness, r),
                Work(input.Density, Benefit.Density, Cost.Density, r),
                Work(input.Purity, Benefit.Purity, Cost.Purity, r));
        }

        private static float Work(float current, float benefit, float cost, float realisation) =>
            current
            + benefit * realisation * (1f - current) // headroom shrinks as you approach the ceiling
            - cost * current;                        // you can only lose what you have

        private static float Clamp(float v) => v < 0f ? 0f : (v > 1f ? 1f : v);

        // ── The canonical stages ────────────────────────────────────────
        // Real smithing, and every one of them is a genuine decision.

        /// <summary>Burn off the slag. Buys purity, costs a little mass.</summary>
        public static ForgeStage Smelt => new ForgeStage(
            "smelt",
            benefit: new MaterialProperties(0f, 0f, 0f, 0.45f),
            cost: new MaterialProperties(0f, 0f, 0.05f, 0f));

        /// <summary>
        /// Fold and weld. Buys toughness and evens the metal out; costs a
        /// little hardness as the carbon spreads.
        /// </summary>
        public static ForgeStage Fold => new ForgeStage(
            "fold",
            benefit: new MaterialProperties(0f, 0.30f, 0f, 0.10f),
            cost: new MaterialProperties(0.05f, 0f, 0f, 0f));

        /// <summary>
        /// Quench hard. The big hardness gain, and the one that snaps
        /// blades — it costs real toughness whoever does it.
        /// </summary>
        public static ForgeStage Quench => new ForgeStage(
            "quench",
            benefit: new MaterialProperties(0.40f, 0f, 0f, 0f),
            cost: new MaterialProperties(0f, 0.18f, 0f, 0f));

        /// <summary>
        /// Draw the temper back. Buys toughness at a little hardness — the
        /// answer to an over-hard quench, and the mark of a smith who knows
        /// when to stop.
        /// </summary>
        public static ForgeStage Temper => new ForgeStage(
            "temper",
            benefit: new MaterialProperties(0f, 0.22f, 0f, 0f),
            cost: new MaterialProperties(0.06f, 0f, 0f, 0f));

        /// <summary>
        /// Grind and polish. A modest edge, and it takes metal off, so the
        /// blade grows lighter.
        /// </summary>
        public static ForgeStage Grind => new ForgeStage(
            "grind",
            benefit: new MaterialProperties(0.12f, 0f, 0f, 0f),
            cost: new MaterialProperties(0f, 0f, 0.04f, 0f));
    }
}
