namespace Marrowmark.Sim.Town
{
    /// <summary>
    /// The numbers behind a town's boards, drinks and shrine.
    ///
    /// Separated from the rules for the same reason combat's profiles are:
    /// these change daily once someone is playing, and they are mirrored
    /// into GDScript because Godot's web export cannot run C#. The mirror
    /// is guarded by a test, so the two cannot drift.
    /// </summary>
    public struct TownProfile
    {
        /// <summary>Base pay for a cull, before pressure is counted.</summary>
        public int CullBasePay;

        /// <summary>Added per point of boar pressure. Pay scales with the
        /// problem because the contract IS the problem — content.md §3:
        /// "the board never lies about the world".</summary>
        public int CullPayPerPressure;

        public int EscortBasePay;

        /// <summary>Added per guard the caravan wants. A wagon that needs
        /// more hands is a wagon in more trouble.</summary>
        public int EscortPayPerGuard;

        public int HarvestPay;

        /// <summary>What Mara charges for the ale that buys you the talk.
        /// content.md §3 makes the drink the search interface, so this is
        /// the price of a query and wants to stay small.</summary>
        public int DrinkPrice;

        /// <summary>The shrine's toll, in pennies (lore.md §3). You come
        /// back poorer; onboarding.md §3 teaches the death ladder from its
        /// bottom rung, and a toll you can always pay teaches nothing.</summary>
        public int ShrineToll;

        /// <summary>How much distortion an hour adds. Small on purpose:
        /// rumour should bend over days, not over an errand.</summary>
        public float DistortionPerHour;

        /// <summary>Distortion never reaches 1. A rumour that is pure
        /// noise is not a rumour, it is a lie, and the teller would know.</summary>
        public float MaxDistortion;

        /// <summary>Past this, the teller hedges rather than vouches.</summary>
        public float HedgeAbove;

        /// <summary>Weight on freshness when ranking. Higher means an old
        /// rumour is buried faster.</summary>
        public float FreshnessWeight;

        /// <summary>Penalty on a bent rumour when ranking. Freshest-first,
        /// but a fresh lie should still lose to a slightly older truth.</summary>
        public float DistortionPenalty;

        public static TownProfile Default => new TownProfile
        {
            CullBasePay = 4,
            CullPayPerPressure = 3,
            EscortBasePay = 10,
            EscortPayPerGuard = 4,
            HarvestPay = 5,
            DrinkPrice = 2,
            ShrineToll = 4,
            DistortionPerHour = 0.002f,
            MaxDistortion = 0.9f,
            HedgeAbove = 0.5f,
            FreshnessWeight = 100f,
            DistortionPenalty = 10f,
        };
    }
}
