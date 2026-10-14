namespace Marrowmark.Sim.Economy
{
    /// <summary>
    /// How a town's prices answer its stock. economy.md §3: "iron is
    /// cheap in Hammarsted and dear in Greywater, and that spread is a
    /// profession." These numbers decide how steep the spread is and how
    /// fast a caravan flattens it.
    /// </summary>
    public struct MarketProfile
    {
        /// <summary>How sharply price answers scarcity. 1 is proportional;
        /// below 1 is gentler. Placeholder.</summary>
        public float Elasticity;

        /// <summary>A glut never drives a price below this fraction of the
        /// good's base value. Nothing is worthless; it just stops being
        /// worth the cart.</summary>
        public float FloorMultiplier;

        /// <summary>A famine never drives it above this multiple. A price
        /// with no ceiling is a price nobody pays.</summary>
        public float CeilingMultiplier;

        public static MarketProfile Default => new MarketProfile
        {
            Elasticity = 0.5f,
            FloorMultiplier = 0.4f,
            CeilingMultiplier = 3.0f,
        };
    }

    /// <summary>
    /// What it costs to move things, and what happens to them when the
    /// mover dies. economy.md §3.5 and L17/L32.
    /// </summary>
    public struct TravelProfile
    {
        /// <summary>On foot. Matches the prototype's sustainable walk
        /// (`tech.md` §1b: 3.0 m/s), held here so the map's size and the
        /// road's time agree.</summary>
        public float FootMetresPerSecond;

        /// <summary>"Mounts are the fast travel." tech.md §1b's working
        /// figure.</summary>
        public float MountedMultiplier;

        /// <summary>L32: a wedge cargo drop is owner-only for about ten
        /// minutes. Real seconds.</summary>
        public float OwnerGraceSeconds;

        /// <summary>L32: untouched, it is gone in about an hour.</summary>
        public float DespawnSeconds;

        public static TravelProfile Default => new TravelProfile
        {
            FootMetresPerSecond = 3.0f,
            MountedMultiplier = 2.5f,
            OwnerGraceSeconds = 600f,
            DespawnSeconds = 3600f,
        };
    }
}
