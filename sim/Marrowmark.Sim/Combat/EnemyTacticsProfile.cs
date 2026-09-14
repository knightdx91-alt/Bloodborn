namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// How one enemy picks its fights. Placeholders with the right
    /// relationships — combat.md §9 judges feel with a controller.
    ///
    /// The weights exist to teach rather than to win. §6 claims a player
    /// reads all three shapes inside the first hour, and that only happens
    /// if all three keep arriving.
    /// </summary>
    public struct EnemyTacticsProfile
    {
        /// <summary>Beyond this it walks in rather than swinging.</summary>
        public float EngageRange;

        /// <summary>
        /// Inside this it is close enough to lean on the heavy and the
        /// committed, which is what punishes a player who plants their feet.
        /// </summary>
        public float PressureRange;

        /// <summary>
        /// Gap between attacks. This is the breathing room a player uses to
        /// close, heal or leave — an enemy with none of it is not difficult,
        /// it is just noise.
        /// </summary>
        public float RecoverBetweenAttacksSeconds;

        /// <summary>
        /// Quick attacks in a row before it must throw something else.
        /// Caps §6's "chains" so the other two shapes keep being taught.
        /// </summary>
        public int MaxQuickChain;

        /// <summary>Chance of quick at knife range (0..1).</summary>
        public float QuickWeightClose;

        /// <summary>Chance of heavy at knife range, after quick.</summary>
        public float HeavyWeightClose;

        /// <summary>Chance of quick at the edge of its reach.</summary>
        public float QuickWeightFar;

        /// <summary>Chance of heavy at the edge of its reach, after quick.</summary>
        public float HeavyWeightFar;

        /// <summary>
        /// After a chain of quicks is capped, how often the follow-up is
        /// the committed swing rather than the heavy.
        /// </summary>
        public float CommittedWeightAfterChain;

        /// <summary>
        /// A first sparring partner. Leans on quick attacks, so the dodge
        /// is the first thing a player learns, and reaches for the other
        /// two often enough to teach them.
        /// </summary>
        public static EnemyTacticsProfile Default => new EnemyTacticsProfile
        {
            EngageRange = 2.2f,
            PressureRange = 1.6f,
            RecoverBetweenAttacksSeconds = 1.1f,
            MaxQuickChain = 3,
            QuickWeightClose = 0.55f,
            HeavyWeightClose = 0.30f,
            QuickWeightFar = 0.35f,
            HeavyWeightFar = 0.40f,
            CommittedWeightAfterChain = 0.35f,
        };
    }
}
