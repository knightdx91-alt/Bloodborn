using System;

namespace Marrowmark.Sim.Combat
{
    /// <summary>Where a dodge is in its life. See DodgeProfile.</summary>
    public enum DodgePhase
    {
        /// <summary>Not dodging. The only phase from which a dodge starts.</summary>
        Ready,

        /// <summary>Committed, still hittable.</summary>
        Startup,

        /// <summary>Blows pass through you.</summary>
        Invulnerable,

        /// <summary>Hittable and unable to act. The punishable part.</summary>
        Recovery,
    }

    /// <summary>
    /// One fighter's dodge (combat.md §1, tech.md §6 Stage 1 step 2).
    ///
    /// This owns the *rules* — what phase you are in, whether blows land,
    /// whether you may act, and how far you have travelled. It owns no
    /// animation and no vector maths: the caller supplies a direction and
    /// asks how far along the dodge is. That split is what lets the same
    /// type run on a client that has a roll clip and on a headless server
    /// that has none, which combat.md §7 requires of every defensive
    /// window.
    ///
    /// Engine-free by the same rule as Stamina: time is passed in.
    /// </summary>
    public sealed class Dodge
    {
        private readonly DodgeProfile _profile;
        private DodgePhase _phase = DodgePhase.Ready;
        private float _elapsed;
        private float _distance;
        private float _recoveryLength;

        public Dodge(DodgeProfile profile)
        {
            if (profile.InvulnerableSeconds < 0f ||
                profile.StartupSeconds < 0f ||
                profile.RecoverySeconds < 0f)
            {
                throw new ArgumentOutOfRangeException(
                    nameof(profile), "Dodge phases cannot be negative.");
            }

            _profile = profile;
        }

        public DodgePhase Phase => _phase;

        /// <summary>Seconds since this dodge began. Zero when Ready.</summary>
        public float Elapsed => _elapsed;

        /// <summary>
        /// True while blows pass through. The only thing the damage layer
        /// needs to ask.
        /// </summary>
        public bool IsInvulnerable => _phase == DodgePhase.Invulnerable;

        /// <summary>
        /// True when the fighter is free to attack, block, parry or dodge
        /// again. False for the whole dodge, recovery included.
        /// </summary>
        public bool CanAct => _phase == DodgePhase.Ready;

        /// <summary>
        /// Ground this dodge will cover in total, decided at the moment it
        /// starts. Zero when Ready.
        /// </summary>
        public float Distance => _distance;

        /// <summary>
        /// How far through the travel the dodge is, 0..1. All of the
        /// movement happens during startup and the invulnerable window;
        /// recovery is spent standing still, which is what makes it
        /// punishable rather than merely slow.
        /// </summary>
        public float TravelFraction
        {
            get
            {
                if (_phase == DodgePhase.Ready) return 0f;
                var moving = _profile.StartupSeconds + _profile.InvulnerableSeconds;
                if (moving <= 0f) return 1f;
                var t = _elapsed / moving;
                return t >= 1f ? 1f : t;
            }
        }

        /// <summary>
        /// Metres travelled so far. Eased so the dodge leaves quickly and
        /// settles, rather than sliding at a constant rate.
        /// </summary>
        public float TravelledDistance => _distance * Ease(TravelFraction);

        /// <summary>
        /// Attempt a dodge, paying for it out of <paramref name="stamina"/>.
        /// Returns false without touching the bar if a dodge is already
        /// running — combat.md §1 makes the dodge committed, so this is
        /// never a cancel.
        ///
        /// An unaffordable dodge still happens, per combat.md §2: at zero
        /// you are slow, not stunned. It goes less far and recovers slower.
        /// </summary>
        public bool TryStart(Stamina stamina, float efficiency = 1f)
        {
            if (stamina == null) throw new ArgumentNullException(nameof(stamina));
            if (_phase != DodgePhase.Ready) return false;

            var paid = stamina.SpendDodge(efficiency);

            _phase = _profile.StartupSeconds > 0f
                ? DodgePhase.Startup
                : DodgePhase.Invulnerable;
            _elapsed = 0f;
            _distance = paid.Afforded
                ? _profile.Distance
                : _profile.Distance * _profile.ExhaustedDistanceFraction;
            _recoveryLength = paid.Afforded
                ? _profile.RecoverySeconds
                : _profile.RecoverySeconds * _profile.ExhaustedRecoveryMultiplier;

            return true;
        }

        /// <summary>Advance the dodge. Harmless when Ready.</summary>
        public void Tick(float deltaSeconds)
        {
            if (_phase == DodgePhase.Ready || deltaSeconds <= 0f) return;

            _elapsed += deltaSeconds;

            var startupEnds = _profile.StartupSeconds;
            var invulnerableEnds = startupEnds + _profile.InvulnerableSeconds;
            var recoveryEnds = invulnerableEnds + _recoveryLength;

            if (_elapsed >= recoveryEnds)
            {
                _phase = DodgePhase.Ready;
                _elapsed = 0f;
                _distance = 0f;
            }
            else if (_elapsed >= invulnerableEnds)
            {
                _phase = DodgePhase.Recovery;
            }
            else if (_elapsed >= startupEnds)
            {
                _phase = DodgePhase.Invulnerable;
            }
        }

        /// <summary>Drop out of the dodge immediately. For respawns and tests.</summary>
        public void Reset()
        {
            _phase = DodgePhase.Ready;
            _elapsed = 0f;
            _distance = 0f;
        }

        /// <summary>
        /// Fast out, gentle settle. Cubic ease-out, which reads as a shove
        /// rather than a glide.
        /// </summary>
        private static float Ease(float t)
        {
            var inv = 1f - t;
            return 1f - inv * inv * inv;
        }
    }
}
