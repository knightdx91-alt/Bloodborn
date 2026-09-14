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
    /// <summary>
    /// The three shapes an attack can take (combat.md §6). Players learn to
    /// read these in the first hour without a tutorial, from animation and
    /// sound alone — no glowing weapons, no red flash, no prompt.
    ///
    /// The grammar is the point. Monsters use the same three shapes with
    /// different bodies, and the warped things in deep places break it
    /// deliberately: a named horror whose heavy has no weight shift is
    /// terrifying precisely because the grammar is otherwise reliable.
    /// </summary>
    public enum AttackShape
    {
        /// <summary>Short windup, low damage, chains. Answer: dodge.</summary>
        Quick,

        /// <summary>
        /// Long windup with a visible weight shift. Answer: parry, which is
        /// highly rewarded — stagger and a free punish.
        /// </summary>
        Heavy,

        /// <summary>
        /// The longest windup, whole-body. Answer: disengage. Cannot be
        /// parried, and badly punished if dodged late.
        /// </summary>
        Committed,
    }

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

        /// <summary>Which of §6's three shapes this is.</summary>
        public AttackShape Shape;

        /// <summary>
        /// Scales the attacker's weapon damage. Not a replacement for it —
        /// combat.md §3 keeps raw damage with the weapon, and L4 keeps
        /// weapons with players. This is what commitment buys: a quick jab
        /// and a whole-body swing from the same sword land differently.
        /// </summary>
        public float DamageMultiplier;

        /// <summary>
        /// combat.md §6: the committed attack cannot be parried. That is a
        /// rule, not a tuning value — it is what makes disengage a distinct
        /// answer rather than a worse parry.
        /// </summary>
        public bool CanBeParried => Shape != AttackShape.Committed;

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
            Shape = AttackShape.Heavy,
            DamageMultiplier = 1f,
        };

        /// <summary>
        /// §6's quick attack. Short windup, low damage, chains — the one
        /// the dodge answers. Its windup is deliberately close to the
        /// latency budget in §7, which is what makes it the hardest of the
        /// three to read and the reason it does not hit hard.
        /// </summary>
        public static AttackProfile Quick => new AttackProfile
        {
            WindupSeconds = 0.22f,
            ActiveSeconds = 0.10f,
            RecoverySeconds = 0.30f,
            StaminaCost = 9f,
            Reach = 1.9f,
            ArcDegrees = 90f,
            ExhaustedRecoveryMultiplier = 1.5f,
            Shape = AttackShape.Quick,
            DamageMultiplier = 0.6f,
        };

        /// <summary>
        /// §6's heavy. A long windup with a visible weight shift, and the
        /// one parrying is *for*. It hits hard enough that eating one is a
        /// real mistake, which is what makes the reward for reading it feel
        /// earned.
        /// </summary>
        public static AttackProfile Heavy => new AttackProfile
        {
            WindupSeconds = 0.62f,
            ActiveSeconds = 0.14f,
            RecoverySeconds = 0.70f,
            StaminaCost = 22f,
            Reach = 2.3f,
            ArcDegrees = 130f,
            ExhaustedRecoveryMultiplier = 1.5f,
            Shape = AttackShape.Heavy,
            DamageMultiplier = 1.5f,
        };

        /// <summary>
        /// §6's committed attack. The longest windup, whole-body, and
        /// unparryable — the answer is to not be there. Its recovery is
        /// enormous, because a disengage that earns nothing is not an
        /// answer, it is just running away.
        /// </summary>
        public static AttackProfile Committed => new AttackProfile
        {
            WindupSeconds = 1.00f,
            ActiveSeconds = 0.18f,
            RecoverySeconds = 1.10f,
            StaminaCost = 30f,
            Reach = 2.8f,
            ArcDegrees = 200f,
            ExhaustedRecoveryMultiplier = 1.5f,
            Shape = AttackShape.Committed,
            DamageMultiplier = 2.2f,
        };

        /// <summary>All three of §6's shapes, in escalating commitment.</summary>
        public static AttackProfile For(AttackShape shape) => shape switch
        {
            AttackShape.Quick => Quick,
            AttackShape.Heavy => Heavy,
            _ => Committed,
        };
    }
}
