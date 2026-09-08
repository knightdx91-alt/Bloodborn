namespace Marrowmark.Sim.Items
{
    /// <summary>
    /// Tuning for how an item wears, repairs, and eventually dies.
    /// L3, L32, L59, L60, L61.
    /// </summary>
    public struct DurabilityProfile
    {
        /// <summary>Condition of a freshly made item, and its original ceiling.</summary>
        public float MaxCondition;

        /// <summary>
        /// Fraction of the current ceiling above which the item performs
        /// perfectly (L60). Casual wear costs nothing; only neglect is
        /// punished, which is L38's floor philosophy applied to upkeep.
        /// </summary>
        public float PerformanceThreshold;

        /// <summary>
        /// Performance multiplier at zero condition. Never zero — L3
        /// forbids mid-fight breakage, so a neglected item gets bad, not
        /// useless. Nothing in Marrowmark ever stops working in your hands.
        /// </summary>
        public float MinPerformance;

        /// <summary>
        /// Once the ceiling falls below this fraction of the original, the
        /// item is scrap (L59). This is the sink that makes crafters matter
        /// forever (`brainstorm.md` §2.6).
        /// </summary>
        public float ScrapCeilingFraction;

        /// <summary>
        /// Ceiling lost per repair, as a fraction of the ORIGINAL maximum,
        /// by an unskilled hand. L61: anyone can repair; skill decides what
        /// it costs the item.
        /// </summary>
        public float NoviceRepairLoss;

        /// <summary>Ceiling lost per repair by a master. Much smaller.</summary>
        public float MasterRepairLoss;

        /// <summary>Condition lost on every death, as a fraction of the ceiling (L32).</summary>
        public float DeathWearFraction;

        public static DurabilityProfile Default => new DurabilityProfile
        {
            MaxCondition = 100f,
            PerformanceThreshold = 0.5f,
            MinPerformance = 0.5f,
            ScrapCeilingFraction = 0.25f,
            NoviceRepairLoss = 0.04f,
            MasterRepairLoss = 0.01f,
            DeathWearFraction = 0.10f,
        };
    }
}
