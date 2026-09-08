namespace Marrowmark.Sim.Progression
{
    /// <summary>
    /// How one proficiency grows. L18, L40, L71.
    /// </summary>
    public struct SkillProfile
    {
        /// <summary>Skill gained from one ideally-pitched use, at zero skill.</summary>
        public float BaseGain;

        /// <summary>
        /// How far *below* your skill a task can be and still teach you
        /// anything. This single number is the anti-grind design (L71):
        /// past it, repetition earns nothing at all, so a macro hammering
        /// the same easy action is not cheating — it is simply wasting
        /// its own time.
        /// </summary>
        public float ChallengeWindow;

        /// <summary>
        /// How sharply gains fall off as skill approaches mastery. Higher
        /// means a longer, slower climb at the top.
        /// </summary>
        public float DiminishingExponent;

        /// <summary>
        /// Daily gain past which learning slows sharply. Follows L33's
        /// precedent for spell trickle: a soft ceiling on how much one day
        /// can teach, so a marathon session cannot replace months.
        /// </summary>
        public float DailySoftCap;

        /// <summary>
        /// Multiplier applied past the soft cap. Deliberately not zero —
        /// L38's spirit says never hard-stop a player who is still
        /// genuinely playing.
        /// </summary>
        public float PastCapMultiplier;

        /// <summary>
        /// Skill at which a proficiency counts as capped for L40's
        /// ascension gate. Growth is asymptotic, so an exact 1.0 is never
        /// reached and never needs to be.
        /// </summary>
        public float MasteryThreshold;

        public static SkillProfile Default => new SkillProfile
        {
            BaseGain = 0.004f,
            ChallengeWindow = 0.30f,
            DiminishingExponent = 1.5f,
            DailySoftCap = 0.05f,
            PastCapMultiplier = 0.15f,
            MasteryThreshold = 0.95f,
        };
    }
}
