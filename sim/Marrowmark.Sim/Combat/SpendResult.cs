namespace Marrowmark.Sim.Combat
{
    /// <summary>What happened when stamina was spent.</summary>
    public struct SpendResult
    {
        /// <summary>
        /// True if the full cost was available. False means the action still
        /// happened — combat.md §2: at zero you are not stunned, you are
        /// slow — but it emptied the bar and triggered exhaustion.
        /// </summary>
        public bool Afforded;

        /// <summary>Stamina actually removed (never more than was left).</summary>
        public float Spent;

        /// <summary>True only on the tick where exhaustion began.</summary>
        public bool CausedExhaustion;
    }
}
