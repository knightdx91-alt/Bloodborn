namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// Timing for a parry. Placeholders with the right relationships —
    /// combat.md §9 is explicit that the parry above all is judged with a
    /// controller, and L39 makes "does a parry land right at 100ms" the
    /// gate the whole project turns on.
    ///
    /// Two numbers here are not free to move the way the others are. The
    /// open window has to survive §7's latency envelope, and the failed
    /// recovery has to be worse than eating the blow would have been —
    /// otherwise mashing parry is correct play and the read stops
    /// mattering.
    /// </summary>
    public struct ParryProfile
    {
        /// <summary>
        /// Raising the guard. Committed, and not yet turning anything.
        /// Short on purpose: the cost of a mistimed parry should be the
        /// recovery, not a sluggish start.
        /// </summary>
        public float StartupSeconds;

        /// <summary>
        /// The window blows are turned in. combat.md §7: "parry windows
        /// stay wide enough to survive the envelope" — the envelope being
        /// ~100ms of network tolerance. A window near that is not a skill
        /// test, it is a lottery for anyone not on a local connection, and
        /// it is why §3 caps skill-based window growth early.
        /// </summary>
        public float OpenSeconds;

        /// <summary>
        /// Caught out of position. This is the entire risk of parrying, and
        /// it has to be worse than simply taking the hit.
        /// </summary>
        public float RecoverySeconds;

        /// <summary>
        /// Recovery after a parry that landed. Short, because §6 promises a
        /// free punish and you cannot punish anything while recovering.
        /// </summary>
        public float SuccessRecoverySeconds;

        /// <summary>
        /// How long the attacker is opened up. §6: "highly rewarded —
        /// stagger and a free punish." This must exceed an attacker's
        /// wind-up or the punish is not free, merely fast.
        /// </summary>
        public float StaggerSeconds;

        /// <summary>
        /// How much of a blocked blow still gets through. combat.md §1:
        /// "a blocked blow still carries something through: blocking is a
        /// stamina war, never an off switch."
        /// </summary>
        public float BlockedFraction;

        /// <summary>
        /// Stamina bled per point of damage stopped. §2: "blocking bleeds
        /// stamina under pressure and breaks your guard at zero, leaving
        /// you open — the punishment for turtling."
        /// </summary>
        public float BlockStaminaPerDamage;

        /// <summary>
        /// Recovery after a guard is broken by running the bar dry. Long,
        /// because being opened up is the entire punishment for turtling.
        /// </summary>
        public float BrokenGuardRecoverySeconds;

        /// <summary>
        /// What a cancelled guard gives back. The whole cost: the input
        /// layer started it speculatively and the fighter never raised it.
        /// </summary>
        public float StaminaCostRefundedOnCancel(float efficiency) =>
            StaminaProfile.Default.ParryCost * (efficiency < 0f ? 0f : efficiency);

        public static ParryProfile Default => new ParryProfile
        {
            StartupSeconds = 0.06f,
            OpenSeconds = 0.28f,
            RecoverySeconds = 0.55f,
            SuccessRecoverySeconds = 0.12f,
            StaggerSeconds = 0.90f,
            BlockedFraction = 0.35f,
            BlockStaminaPerDamage = 0.55f,
            BrokenGuardRecoverySeconds = 1.20f,
        };
    }
}
