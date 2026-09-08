namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// Tuning for one fighter's stamina. Every number here is a first
    /// guess to be replaced by playtesting — see design/combat.md §9:
    /// feel is judged with a controller, never derived on paper.
    /// </summary>
    public struct StaminaProfile
    {
        /// <summary>Full bar.</summary>
        public float Max;

        /// <summary>Points regained per second once regeneration starts.</summary>
        public float RegenPerSecond;

        /// <summary>
        /// Pause after any spend before regeneration resumes. This is what
        /// makes sustained aggression cost something: attacking constantly
        /// never lets the bar move.
        /// </summary>
        public float RegenDelaySeconds;

        /// <summary>
        /// Regeneration multiplier while exhausted. Below 1 means running
        /// yourself to zero is punished twice — once by having nothing, and
        /// again by getting it back slowly.
        /// </summary>
        public float ExhaustedRegenMultiplier;

        /// <summary>
        /// Fraction of Max that must be recovered before exhaustion clears.
        /// Without this, a fighter flickers in and out of exhaustion at zero.
        /// </summary>
        public float ExhaustionRecoveryFraction;

        /// <summary>Base cost of one dodge, before chain escalation.</summary>
        public float DodgeCost;

        /// <summary>
        /// Extra fraction added per consecutive dodge. combat.md §2:
        /// "consecutive dodges cost escalating amounts, so panic-rolling
        /// drains you." At 0.5, the second dodge in a chain costs 150%.
        /// </summary>
        public float DodgeChainEscalation;

        /// <summary>
        /// Gap without dodging that resets the chain. Spacing your dodges
        /// is the counterplay to escalation.
        /// </summary>
        public float DodgeChainWindowSeconds;

        /// <summary>Base cost of a parry attempt.</summary>
        public float ParryCost;

        /// <summary>
        /// Fraction of the parry cost returned on success. combat.md §2:
        /// "A successful parry refunds most of its cost. A failed one does
        /// not. Parry is the high-skill, high-reward answer by construction."
        /// </summary>
        public float ParryRefundFraction;

        /// <summary>Sprint drain per second.</summary>
        public float SprintDrainPerSecond;

        /// <summary>
        /// Climb drain per second. combat.md §2: climbing and swimming
        /// drain harder than sprinting, because running out halfway up is
        /// meant to be a consequence.
        /// </summary>
        public float ClimbDrainPerSecond;

        /// <summary>Swim drain per second.</summary>
        public float SwimDrainPerSecond;

        /// <summary>Cost of one jump.</summary>
        public float JumpCost;

        /// <summary>
        /// Fraction of the bar lost at full carrying capacity. L55: what you
        /// carry shrinks what you have to spend, so hauling is felt before
        /// any bandit appears. At 0.4, a fully loaded traveller fights with
        /// 60% of their bar.
        /// </summary>
        public float MaxEncumbrancePenalty;

        /// <summary>
        /// A sane starting point. These are placeholders with the right
        /// relationships between them, not tuned values.
        /// </summary>
        public static StaminaProfile Default => new StaminaProfile
        {
            Max = 100f,
            RegenPerSecond = 25f,
            RegenDelaySeconds = 0.6f,
            ExhaustedRegenMultiplier = 0.5f,
            ExhaustionRecoveryFraction = 0.3f,
            DodgeCost = 20f,
            DodgeChainEscalation = 0.5f,
            DodgeChainWindowSeconds = 1.2f,
            ParryCost = 15f,
            ParryRefundFraction = 0.8f,
            // Deliberately low. combat.md §1: disengage is a first-class
            // answer and L19 promises a skilled newcomer can always escape,
            // so fleeing must stay affordable.
            SprintDrainPerSecond = 8f,
            ClimbDrainPerSecond = 14f,
            SwimDrainPerSecond = 12f,
            JumpCost = 6f,
            MaxEncumbrancePenalty = 0.4f,
        };
    }
}
