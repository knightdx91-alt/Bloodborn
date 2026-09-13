namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// Timing and distance for a dodge. Every number is a placeholder with
    /// the right relationships between them — combat.md §9 is explicit that
    /// feel is judged with a controller, never derived on paper.
    ///
    /// The phases are the whole design. combat.md §1 makes the dodge the
    /// answer to a quick attack and §2 makes its recovery punishable, so
    /// the window where you are safe has to be shorter than the window
    /// where you are committed. If those two were the same length there
    /// would be no decision to make.
    /// </summary>
    public struct DodgeProfile
    {
        /// <summary>
        /// Committed but not yet safe. The dodge cannot be cancelled from
        /// here, which is what makes dodging early a real mistake.
        /// </summary>
        public float StartupSeconds;

        /// <summary>How long the invulnerable window lasts.</summary>
        public float InvulnerableSeconds;

        /// <summary>
        /// Vulnerable, still unable to act. combat.md §1: "recovery is
        /// punishable." This is the whole cost of a mistimed dodge.
        /// </summary>
        public float RecoverySeconds;

        /// <summary>
        /// Ground covered, in metres. L56: "a dodge repositions, it does
        /// not merely evade" — this is large enough to change where the
        /// fight is happening, not just to slip a blow.
        /// </summary>
        public float Distance;

        /// <summary>
        /// Fraction of <see cref="Distance"/> still covered when the dodge
        /// was started with an empty bar. At zero stamina you are not
        /// stunned, you are slow (combat.md §2) — so the dodge happens, it
        /// just does not get you anywhere useful.
        /// </summary>
        public float ExhaustedDistanceFraction;

        /// <summary>
        /// Recovery multiplier when the dodge was not paid for. The second
        /// half of the same punishment: a broke dodge leaves you lying
        /// there longer.
        /// </summary>
        public float ExhaustedRecoveryMultiplier;

        /// <summary>Startup + invulnerable + recovery.</summary>
        public float TotalSeconds =>
            StartupSeconds + InvulnerableSeconds + RecoverySeconds;

        /// <summary>
        /// A sane starting point. Recovery is the longest phase on purpose
        /// — combat.md §1 makes it the punishable one — so rather more than
        /// half of a dodge is spent being hittable.
        ///
        /// These also happen to land where the roll clip does: the
        /// prototype's roll drops the hips at about 50ms in, is lowest
        /// three tenths later, and is back on its feet by 700ms.
        /// </summary>
        public static DodgeProfile Default => new DodgeProfile
        {
            StartupSeconds = 0.05f,
            InvulnerableSeconds = 0.30f,
            RecoverySeconds = 0.35f,
            Distance = 2.6f,
            ExhaustedDistanceFraction = 0.45f,
            ExhaustedRecoveryMultiplier = 1.6f,
        };
    }
}
