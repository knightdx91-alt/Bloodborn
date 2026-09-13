using System;

namespace Marrowmark.Sim.Combat
{
    /// <summary>Where a swing is in its life. See AttackProfile.</summary>
    public enum AttackPhase
    {
        /// <summary>Not swinging.</summary>
        Ready,

        /// <summary>Winding up. Committed, and visible to the opponent.</summary>
        Windup,

        /// <summary>The blade is dangerous.</summary>
        Active,

        /// <summary>Hittable and unable to act. The punishable part.</summary>
        Recovery,
    }

    /// <summary>
    /// One fighter's swing (combat.md §1 and §6, tech.md §6 Stage 1 step 3).
    ///
    /// Owns the rules — the phases, the stamina, whether the blade is live,
    /// and the fact that a swing connects at most once. It owns no
    /// geometry: the caller asks <see cref="Reaches"/> whether a target is
    /// in front and in range, which keeps this usable on a headless server
    /// with no animation to measure, as combat.md §7 requires.
    ///
    /// Engine-free by the same rule as Stamina and Dodge: time is passed in.
    /// </summary>
    public sealed class Attack
    {
        private readonly AttackProfile _profile;
        private AttackPhase _phase = AttackPhase.Ready;
        private float _elapsed;
        private float _recoveryLength;
        private bool _hitSpent;

        public Attack(AttackProfile profile)
        {
            if (profile.WindupSeconds < 0f ||
                profile.ActiveSeconds < 0f ||
                profile.RecoverySeconds < 0f)
            {
                throw new ArgumentOutOfRangeException(
                    nameof(profile), "Attack phases cannot be negative.");
            }

            _profile = profile;
        }

        public AttackPhase Phase => _phase;

        public float Elapsed => _elapsed;

        /// <summary>True while the blade is dangerous.</summary>
        public bool IsActive => _phase == AttackPhase.Active;

        /// <summary>
        /// True when free to move, attack again, dodge or parry. False for
        /// the whole swing, recovery included.
        /// </summary>
        public bool CanAct => _phase == AttackPhase.Ready;

        /// <summary>
        /// How far through the wind-up, 0..1. This is the telegraph, and
        /// the animation layer's cue for how far the blade has been drawn
        /// back.
        /// </summary>
        public float WindupFraction
        {
            get
            {
                if (_phase == AttackPhase.Ready) return 0f;
                if (_profile.WindupSeconds <= 0f) return 1f;
                var t = _elapsed / _profile.WindupSeconds;
                return t >= 1f ? 1f : t;
            }
        }

        /// <summary>
        /// Begin a swing, paying for it up front. False without touching
        /// the bar if one is already running — the swing is committed, so
        /// this is never a cancel.
        ///
        /// A swing you cannot pay for still happens and recovers slower,
        /// per combat.md §2. It is paid for whether or not it connects:
        /// "attacks cost on startup, so a whiffed swing is paid for."
        /// </summary>
        public bool TryStart(Stamina stamina, float efficiency = 1f)
        {
            if (stamina == null) throw new ArgumentNullException(nameof(stamina));
            if (_phase != AttackPhase.Ready) return false;

            var paid = stamina.Spend(_profile.StaminaCost, efficiency);

            _phase = _profile.WindupSeconds > 0f
                ? AttackPhase.Windup
                : AttackPhase.Active;
            _elapsed = 0f;
            _hitSpent = false;
            _recoveryLength = paid.Afforded
                ? _profile.RecoverySeconds
                : _profile.RecoverySeconds * _profile.ExhaustedRecoveryMultiplier;

            return true;
        }

        /// <summary>Advance the swing. Harmless when Ready.</summary>
        public void Tick(float deltaSeconds)
        {
            if (_phase == AttackPhase.Ready || deltaSeconds <= 0f) return;

            _elapsed += deltaSeconds;

            var windupEnds = _profile.WindupSeconds;
            var activeEnds = windupEnds + _profile.ActiveSeconds;
            var recoveryEnds = activeEnds + _recoveryLength;

            if (_elapsed >= recoveryEnds)
            {
                _phase = AttackPhase.Ready;
                _elapsed = 0f;
                _hitSpent = false;
            }
            else if (_elapsed >= activeEnds)
            {
                _phase = AttackPhase.Recovery;
            }
            else if (_elapsed >= windupEnds)
            {
                _phase = AttackPhase.Active;
            }
        }

        /// <summary>
        /// Claim this swing's one hit. True at most once per swing, and
        /// only while the blade is live.
        ///
        /// One swing, one hit, is a rule rather than an optimisation: an
        /// active window spanning several frames would otherwise land a
        /// blow on every one of them, and the damage numbers in §4 are
        /// written for single blows.
        /// </summary>
        public bool TryConsumeHit()
        {
            if (!IsActive || _hitSpent) return false;
            _hitSpent = true;
            return true;
        }

        /// <summary>
        /// Whether a target at <paramref name="distance"/> metres and
        /// <paramref name="angleDegrees"/> off the attacker's facing is
        /// within this swing. Geometry stays with the caller; the numbers
        /// stay here, so client and server agree.
        /// </summary>
        public bool Reaches(float distance, float angleDegrees) =>
            distance <= _profile.Reach &&
            Math.Abs(angleDegrees) <= _profile.ArcDegrees * 0.5f;

        public void Reset()
        {
            _phase = AttackPhase.Ready;
            _elapsed = 0f;
            _hitSpent = false;
        }
    }
}
