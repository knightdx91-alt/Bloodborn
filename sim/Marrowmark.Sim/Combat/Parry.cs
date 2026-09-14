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

        /// <summary>True when free to act. False for the whole attempt.</summary>
        public bool CanAct => _phase == ParryPhase.Ready;

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

        public void Tick(float deltaSeconds)
        {
            if (_phase == ParryPhase.Ready || deltaSeconds <= 0f) return;

            _elapsed += deltaSeconds;

            var startupEnds = _profile.StartupSeconds;
            var openEnds = startupEnds + _profile.OpenSeconds;
            var recoveryEnds = openEnds + _recoveryLength;

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

        /// <summary>
        /// A blow has arrived. Says what became of it, and refunds on
        /// success — combat.md §2: "a successful parry refunds most of its
        /// cost. A failed one does not."
        ///
        /// One parry turns one blow. Holding a guard open through a flurry
        /// is what §1 says parry loses to.
        /// </summary>
        public ParryOutcome Meet(AttackProfile incoming, Stamina stamina, float efficiency = 1f)
        {
            if (stamina == null) throw new ArgumentNullException(nameof(stamina));

            switch (_phase)
            {
                case ParryPhase.Ready:
                    return ParryOutcome.NotParrying;
                case ParryPhase.Startup:
                    return ParryOutcome.TooEarly;
                case ParryPhase.Recovery:
                    return ParryOutcome.TooLate;
            }

            if (_spent) return ParryOutcome.TooLate;
            if (!incoming.CanBeParried) return ParryOutcome.Unparryable;

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
