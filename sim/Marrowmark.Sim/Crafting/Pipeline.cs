using System;
using System.Collections.Generic;
using Marrowmark.Sim.Items;

namespace Marrowmark.Sim.Crafting
{
    /// <summary>
    /// A sequence of stages, run over a piece of material (L4, L67).
    ///
    /// A pipeline is not a recipe with one right answer. The same stages in
    /// a different order produce a different blade, and which stages you
    /// run at all is the craft. Casual players buy half-worked billets and
    /// run only the stages they enjoy — L38 explicitly wants that, and it
    /// is why intermediate goods are a market rather than an inconvenience.
    /// </summary>
    public sealed class Pipeline
    {
        private readonly List<ForgeStage> _stages = new List<ForgeStage>();

        public Pipeline Then(ForgeStage stage)
        {
            if (stage == null) throw new ArgumentNullException(nameof(stage));
            _stages.Add(stage);
            return this;
        }

        public IReadOnlyList<ForgeStage> Stages => _stages;

        /// <summary>Work the material through every stage in order.</summary>
        public MaterialProperties Run(MaterialProperties input, float skill)
        {
            var current = input;
            foreach (var stage in _stages)
                current = stage.Apply(current, skill);
            return current;
        }

        /// <summary>
        /// Work the material and sign the result. There is no unsigned
        /// path — L68 admits no exceptions.
        /// </summary>
        public CraftedItem Forge(
            MaterialProperties input,
            float skill,
            string makersMark,
            DurabilityProfile baseProfile = default)
        {
            if (baseProfile.MaxCondition <= 0f) baseProfile = DurabilityProfile.Default;

            var names = new List<string>();
            foreach (var stage in _stages) names.Add(stage.Name);

            return new CraftedItem(makersMark, Run(input, skill), names, baseProfile);
        }

        /// <summary>
        /// The ordinary road to a blade: smelt, fold, quench, temper,
        /// grind. Every stage in it is a decision a smith could make
        /// differently.
        /// </summary>
        public static Pipeline Blade => new Pipeline()
            .Then(ForgeStage.Smelt)
            .Then(ForgeStage.Fold)
            .Then(ForgeStage.Quench)
            .Then(ForgeStage.Temper)
            .Then(ForgeStage.Grind);
    }
}
