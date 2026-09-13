namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// Timing, cost and reach for one swing. Placeholders with the right
    /// relationships — combat.md §9: feel is judged with a controller.
    ///
    /// The shape is the design. combat.md §6 telegraphs an attack by its
    /// wind-up, and §1 makes committed attacks punishable, so the windup
    /// has to be long enough to read and the recovery long enough to
    /// punish. An attack whose active window is most of its length is a
    /// button, not a decision.
    /// </summary>
    public struct AttackProfile
    {
        /// <summary>
        /// The wind-up. This is the telegraph (combat.md §6) — the whole
        /// reason an opponent can answer at all — and it is committed:
        /// once it starts, the swing happens.
        /// </summary>
        public float WindupSeconds;

        /// <summary>How long the blade is actually dangerous.</summary>
        public float ActiveSeconds;

        /// <summary>
        /// Vulnerable and unable to act. What a whiffed swing costs, and
        /// what a dodge's repositioning is *for*.
        /// </summary>
        public float RecoverySeconds;

        /// <summary>
        /// Paid at the start, never on connection. combat.md §2: "attacks
        /// cost on startup, so a whiffed swing is paid for."
        /// </summary>
        public float StaminaCost;

        /// <summary>
        /// How far the blade reaches, in metres from the attacker. A rule
        /// rather than a piece of geometry: combat.md §7 makes damage
        /// server-authoritative, and the server has no animation to
        /// measure.
        /// </summary>
        public float Reach;

        /// <summary>
        /// Total width of the swing in front of the attacker, in degrees.
        /// A cut sweeps; it does not fire along a line.
        /// </summary>
        public float ArcDegrees;

        /// <summary>
        /// Recovery multiplier when the swing was not paid for. Swinging
        /// on an empty bar leaves you hanging there.
        /// </summary>
        public float ExhaustedRecoveryMultiplier;

        public float TotalSeconds =>
            WindupSeconds + ActiveSeconds + RecoverySeconds;

        /// <summary>
        /// A standard sword cut. combat.md §6's three shapes — quick,
        /// heavy, committed — arrive at Stage 1 step 5, where there is an
        /// enemy to read them from. This is the middle of that range.
        /// </summary>
        public static AttackProfile Default => new AttackProfile
        {
            WindupSeconds = 0.30f,
            ActiveSeconds = 0.12f,
            RecoverySeconds = 0.45f,
            StaminaCost = 14f,
            Reach = 2.1f,
            ArcDegrees = 110f,
            ExhaustedRecoveryMultiplier = 1.5f,
        };
    }
}
