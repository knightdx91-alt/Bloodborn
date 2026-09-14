using System;

namespace Marrowmark.Sim.Combat
{
    /// <summary>Where a parry is in its life. See ParryProfile.</summary>
    public enum ParryPhase
    {
        /// <summary>Not parrying.</summary>
        Ready,

        /// <summary>Raising the guard. Committed, turning nothing yet.</summary>
        Startup,

        /// <summary>The window. Blows arriving now are turned.</summary>
        Open,

        /// <summary>
        /// The window has passed and the guard is still up. Blows are
        /// stopped rather than turned, and the bar pays for it.
        /// </summary>
        Blocking,

        /// <summary>Caught out of position. The whole risk of parrying.</summary>
        Recovery,
    }

    /// <summary>What happened when a blow met a guard.</summary>
    public enum ParryOutcome
    {
        /// <summary>No parry was attempted. The blow lands.</summary>
        NotParrying,

        /// <summary>Turned. The attacker is staggered and the cost refunded.</summary>
        Parried,

        /// <summary>Guard still coming up. The blow lands.</summary>
        TooEarly,

        /// <summary>Window already closed. The blow lands, and you are caught.</summary>
        TooLate,

        /// <summary>
        /// combat.md §6: the committed attack cannot be parried. A perfectly
        /// timed guard against one is still a mistake — the answer was to
        /// not be there.
        /// </summary>
        Unparryable,

        /// <summary>
        /// Stopped, not turned. Most of the blow is absorbed and the bar
        /// pays for it — and if the bar runs out, the guard breaks.
        /// </summary>
        Blocked,
    }

    /// <summary>
    /// One fighter's parry (combat.md §1, §2 and §6; tech.md §6 Stage 1
    /// step 6). The hardest single-player piece, and the one L39 turns on.
    ///
    /// What makes it the high-skill answer is not the window — it is that
    /// **failing costs more than not trying**. A parry that merely wasted
    /// its stamina would be free to spam; this one leaves you out of
    /// position for longer than the blow you were trying to turn would have
    /// cost you.
    ///
    /// Directional guards (L64/L65 — an exact arc blocks, an adjacent one
    /// glances, only a thrust guard stops a thrust) are NOT here yet.
    /// `Targeting` already implements and tests that resolution; wiring it
    /// up needs guard poses to read from, which is §1's animation bill.
    ///
    /// Engine-free by the same rule as everything else: time is passed in.
    /// </summary>
    public sealed class Parry
    {
        private readonly ParryProfile _profile;
        private ParryPhase _phase = ParryPhase.Ready;
        private float _elapsed;
        private float _recoveryLength;
        private bool _spent;

        public Parry(ParryProfile profile)
        {
            if (profile.OpenSeconds <= 0f)
                throw new ArgumentOutOfRangeException(
                    nameof(profile), "A parry with no window is not a parry.");

            _profile = profile;
            _recoveryLength = profile.RecoverySeconds;
        }

        public ParryPhase Phase => _phase;

        public float Elapsed => _elapsed;

        /// <summary>True while blows are being turned.</summary>
        public bool IsOpen => _phase == ParryPhase.Open;

        /// <summary>True while the guard is up but past its window.</summary>
        public bool IsBlocking => _phase == ParryPhase.Blocking;

        /// <summary>True while the guard is up at all.</summary>
        public bool IsGuarding =>
            _phase == ParryPhase.Startup || _phase == ParryPhase.Open
            || _phase == ParryPhase.Blocking;

        /// <summary>True when free to act. False for the whole attempt.</summary>
        public bool CanAct => _phase == ParryPhase.Ready;

        /// <summary>How much of a blocked blow still gets through.</summary>
        public float BlockedFraction => _profile.BlockedFraction;

        /// <summary>
        /// Begin a parry, paying for it up front. False without touching the
        /// bar if one is already running — like every other commitment here,
        /// this is never a cancel.
        /// </summary>
        public bool TryStart(Stamina stamina, float efficiency = 1f)
        {
            if (stamina == null) throw new ArgumentNullException(nameof(stamina));
            if (_phase != ParryPhase.Ready) return false;

            stamina.SpendParry(efficiency);

            _phase = _profile.StartupSeconds > 0f ? ParryPhase.Startup : ParryPhase.Open;
            _elapsed = 0f;
            _spent = false;
            _recoveryLength = _profile.RecoverySeconds;
            return true;
        }

        /// <summary>
        /// Advance the guard. <paramref name="holding"/> is the player still
        /// holding it up: the window passing with the guard still raised is
        /// what turns a parry attempt into a block, rather than the attempt
        /// simply expiring.
        /// </summary>
        public void Tick(float deltaSeconds, bool holding = false)
        {
            if (_phase == ParryPhase.Ready || deltaSeconds <= 0f) return;

            // Blocking lasts as long as it is held. Nothing expires it but
            // letting go, or the bar running dry.
            if (_phase == ParryPhase.Blocking)
            {
                if (!holding) Lower();
                return;
            }

            _elapsed += deltaSeconds;

            var startupEnds = _profile.StartupSeconds;
            var openEnds = startupEnds + _profile.OpenSeconds;
            var recoveryEnds = openEnds + _recoveryLength;

            if (_elapsed >= openEnds && _phase != ParryPhase.Recovery
                && holding && !_spent)
            {
                // Held through the window without turning anything: the
                // guard stays up and becomes a block.
                _phase = ParryPhase.Blocking;
                return;
            }

            if (_elapsed >= recoveryEnds)
            {
                _phase = ParryPhase.Ready;
                _elapsed = 0f;
                _spent = false;
            }
            else if (_elapsed >= openEnds)
            {
                _phase = ParryPhase.Recovery;
            }
            else if (_elapsed >= startupEnds)
            {
                _phase = ParryPhase.Open;
            }
        }

        /// <summary>Drop the guard. Lowering it is quick; it is raising it
        /// at the wrong moment that costs.</summary>
        public void Lower()
        {
            if (!IsGuarding) return;
            _phase = ParryPhase.Recovery;
            _elapsed = _profile.StartupSeconds + _profile.OpenSeconds;
            _recoveryLength = _profile.SuccessRecoverySeconds;
        }

        /// <summary>
        /// Take it back as though it never happened, refunding the whole
        /// cost. This is not a game rule — it is for an input layer that
        /// cannot yet tell a tap from the beginning of a guard, and must
        /// start one to find out. Refused once the guard has actually done
        /// something, so it can never undo a parry.
        /// </summary>
        public bool Cancel(Stamina stamina, float efficiency = 1f)
        {
            if (stamina == null) throw new ArgumentNullException(nameof(stamina));
            if (_phase != ParryPhase.Startup || _spent) return false;

            stamina.Refund(_profile.StaminaCostRefundedOnCancel(efficiency));
            Reset();
            return true;
        }

        /// <summary>
        /// A blow has arrived. Says what became of it, and refunds on
        /// success — combat.md §2: "a successful parry refunds most of its
        /// cost. A failed one does not."
        ///
        /// One parry turns one blow. Holding a guard open through a flurry
        /// is what §1 says parry loses to.
        /// </summary>
        public ParryOutcome Meet(AttackProfile incoming, Stamina stamina,
            float damage = 0f, float efficiency = 1f)
        {
            if (stamina == null) throw new ArgumentNullException(nameof(stamina));

            if (_phase == ParryPhase.Ready) return ParryOutcome.NotParrying;

            // Checked before anything else the guard might do with it.
            // §6 calls the committed attack unblockable, not merely
            // unparryable — a guard is the wrong answer to it however it
            // is held, and blocking one would have quietly made it the
            // right answer.
            if (!incoming.CanBeParried) return ParryOutcome.Unparryable;

            switch (_phase)
            {
                case ParryPhase.Startup:
                    return ParryOutcome.TooEarly;
                case ParryPhase.Recovery:
                    return ParryOutcome.TooLate;
                case ParryPhase.Blocking:
                    return Block(incoming, stamina, damage);
            }

            if (_spent) return ParryOutcome.TooLate;


            _spent = true;
            stamina.RefundParry(efficiency);

            // Drop straight out of the window into the short recovery: the
            // reward is the punish, and it is only a reward if you are free
            // to take it.
            _phase = ParryPhase.Recovery;
            _elapsed = _profile.StartupSeconds + _profile.OpenSeconds;
            _recoveryLength = _profile.SuccessRecoverySeconds;

            return ParryOutcome.Parried;
        }

        /// <summary>
        /// Stop a blow rather than turn it. It costs the bar in proportion
        /// to what it stopped, and emptying the bar breaks the guard —
        /// §2's punishment for turtling.
        /// </summary>
        private ParryOutcome Block(AttackProfile incoming, Stamina stamina, float damage)
        {
            var cost = damage * _profile.BlockStaminaPerDamage;
            var paid = stamina.Spend(cost);
            if (!paid.Afforded)
            {
                _phase = ParryPhase.Recovery;
                _elapsed = _profile.StartupSeconds + _profile.OpenSeconds;
                _recoveryLength = _profile.BrokenGuardRecoverySeconds;
            }
            return ParryOutcome.Blocked;
        }

        /// <summary>How long a parried attacker is opened up.</summary>
        public float StaggerSeconds => _profile.StaggerSeconds;

        public void Reset()
        {
            _phase = ParryPhase.Ready;
            _elapsed = 0f;
            _spent = false;
            _recoveryLength = _profile.RecoverySeconds;
        }
    }
}
