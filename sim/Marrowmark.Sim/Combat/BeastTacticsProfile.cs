namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// How a beast picks its fight. Placeholders with the right
    /// relationships — combat.md §9 judges feel with a controller.
    /// </summary>
    public struct BeastTacticsProfile
    {
        /// <summary>
        /// Inside this it will commit to a run. Beyond it there is too
        /// much ground to cover and it stalks instead.
        /// </summary>
        public float ChargeRange;

        /// <summary>
        /// Inside this a charge has no room to build, so it uses tusks.
        /// </summary>
        public float GoreRange;

        /// <summary>
        /// How long a run lasts. The beast cannot turn for this whole
        /// time, which is the entire reason a charge can be beaten by
        /// stepping aside rather than by out-damaging it.
        /// </summary>
        public float ChargeSeconds;

        /// <summary>
        /// Turning round after a spent run. The punish window: long
        /// enough to be worth taking, short enough to be worth taking
        /// *quickly*.
        /// </summary>
        public float WheelSeconds;

        /// <summary>Gap between gores at knife range.</summary>
        public float RecoverBetweenGoresSeconds;

        /// <summary>
        /// What a run costs. An exhausted boar stops charging and is
        /// reduced to its tusks, which is a readable state change
        /// rather than a number going down.
        /// </summary>
        public float ChargeStaminaCost;

        /// <summary>A blood-warped boar of the Hedges.</summary>
        public static BeastTacticsProfile Boar => new BeastTacticsProfile
        {
            ChargeRange = 9.0f,
            GoreRange = 1.8f,
            ChargeSeconds = 1.15f,
            WheelSeconds = 1.35f,
            RecoverBetweenGoresSeconds = 1.4f,
            ChargeStaminaCost = 18.0f,
        };
    }
}
