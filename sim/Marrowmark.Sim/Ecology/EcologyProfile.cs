namespace Marrowmark.Sim.Ecology
{
    /// <summary>
    /// How a warped population behaves when nobody is culling it.
    /// content.md §2: "the supply chain with teeth". Placeholders with
    /// the right relationships.
    /// </summary>
    public struct EcologyProfile
    {
        /// <summary>Growth per hour as a fraction of the population, before
        /// the cap bites. Logistic: fast when small, slowing at capacity.</summary>
        public float GrowthPerHour;

        /// <summary>The most a territory will hold.</summary>
        public int CarryingCapacity;

        /// <summary>Head of population per point of pressure. Pressure is
        /// what the town's board reads; population is what is true.</summary>
        public int PopulationPerPressure;

        /// <summary>Pressure never reads above this. The board's scale.</summary>
        public int MaxPressure;

        /// <summary>At this pressure the territory pushes out of the wedge
        /// toward roads and farms.</summary>
        public int SpillPressure;

        /// <summary>Hours a pooling goes unculled before it births
        /// something specific. A week.</summary>
        public float HorrorAfterHours;

        /// <summary>What the bounty on a living horror grows by each day.</summary>
        public int HorrorBountyPerDay;

        /// <summary>Crafting materials per ordinary kill (L4: every hunt is
        /// a supply run).</summary>
        public int PartsPerKill;

        public float HoursPerDay;

        public static EcologyProfile Default => new EcologyProfile
        {
            GrowthPerHour = 0.02f,
            CarryingCapacity = 60,
            PopulationPerPressure = 10,
            MaxPressure = 5,
            SpillPressure = 3,
            HorrorAfterHours = 168f,
            HorrorBountyPerDay = 6,
            PartsPerKill = 2,
            HoursPerDay = 24f,
        };
    }
}
