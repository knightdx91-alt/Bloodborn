namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// Everything the time-to-kill estimator needs to know about one
    /// fighter. Not a runtime entity — a description used to answer "does
    /// this tuning produce fights of the right length?"
    /// </summary>
    public struct FighterSpec
    {
        public float Health;

        /// <summary>
        /// Raw weapon damage. combat.md §3: numbers come from gear, and
        /// gear comes from players (L4).
        /// </summary>
        public float WeaponDamage;

        public DamageType WeaponType;

        /// <summary>What this fighter is wearing, for incoming damage.</summary>
        public ArmorClass Armor;

        /// <summary>Stamina cost of one attack, paid on startup (§2).</summary>
        public float AttackCost;

        /// <summary>
        /// Seconds between attacks when rested — the animation's own pace.
        /// Attacks are commitments (§1), so this is not a rate the player
        /// can exceed by mashing.
        /// </summary>
        public float AttackInterval;

        /// <summary>
        /// How much longer attacks take while exhausted. combat.md §2: at
        /// zero stamina you are not stunned, you are slow — recovery frames
        /// lengthen, and that is the vulnerability. This is the number that
        /// makes the stamina economy actually cap sustained damage.
        /// </summary>
        public float ExhaustedIntervalMultiplier;

        public StaminaProfile Stamina;

        /// <summary>
        /// A baseline duellist, used to check that the tuning produces
        /// fights of the length combat.md §4 asks for. Placeholders with
        /// the right relationships, like everything else in this library.
        /// </summary>
        public static FighterSpec Default => new FighterSpec
        {
            Health = 200f,
            WeaponDamage = 24f,
            WeaponType = DamageType.Cut,
            Armor = ArmorClass.Mail,
            AttackCost = 18f,
            AttackInterval = 0.9f,
            ExhaustedIntervalMultiplier = 1.6f,
            Stamina = StaminaProfile.Default,
        };
    }
}
