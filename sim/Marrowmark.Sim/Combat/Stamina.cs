using System;

namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// One fighter's stamina bar — the whole combat economy in one number.
    /// See design/combat.md §2.
    ///
    /// Deliberately free of any engine dependency: time is passed in rather
    /// than read from a global clock, so this is deterministic, unit
    /// testable, and reusable on the server exactly as written. Nothing in
    /// Marrowmark.Sim may reference UnityEngine.
    /// </summary>
    public sealed class Stamina
    {
        private readonly StaminaProfile _profile;
        private float _current;
        private float _regenDelayRemaining;
        private float _sinceLastDodge;
        private bool _exhausted;
        private int _consecutiveDodges;
        private float _encumbrance;

        public Stamina(StaminaProfile profile)
        {
            if (profile.Max <= 0f)
                throw new ArgumentOutOfRangeException(
                    nameof(profile), "StaminaProfile.Max must be greater than zero.");

            _profile = profile;
            _current = profile.Max;
            _sinceLastDodge = float.MaxValue;
        }

        /// <summary>Stamina remaining.</summary>
        public float Current => _current;

        /// <summary>Unburdened bar, from the profile.</summary>
        public float Max => _profile.Max;

        /// <summary>
        /// The bar actually available right now, after what you are
        /// carrying. L55: encumbrance shrinks the bar rather than slowing
        /// recovery — a loaded traveller is limited, not broken.
        /// </summary>
        public float EffectiveMax =>
            _profile.Max * (1f - _profile.MaxEncumbrancePenalty * _encumbrance);

        /// <summary>Current stamina as 0..1 of the bar you actually have.</summary>
        public float Fraction => _current / EffectiveMax;

        /// <summary>
        /// Carried load as 0 (unburdened) to 1 (at capacity). Set this when
        /// cargo changes; dropping your load before a fight is meant to be a
        /// real tactical choice.
        /// </summary>
        public float Encumbrance
        {
            get => _encumbrance;
            set
            {
                _encumbrance = value < 0f ? 0f : (value > 1f ? 1f : value);
                if (_current > EffectiveMax) _current = EffectiveMax;
            }
        }

        /// <summary>
        /// True while recovering from a full drain. combat.md §2: this does
        /// not stun — it lengthens recovery frames, which is the
        /// vulnerability. Applying that penalty is the animation layer's
        /// job; this type only reports the state.
        /// </summary>
        public bool IsExhausted => _exhausted;

        /// <summary>Dodges in the current chain. Feeds escalating cost.</summary>
        public int ConsecutiveDodges => _consecutiveDodges;

        /// <summary>Cost of the next dodge, including chain escalation.</summary>
        public float NextDodgeCost(float efficiency = 1f) =>
            _profile.DodgeCost
            * (1f + _profile.DodgeChainEscalation * _consecutiveDodges)
            * Clamp01Plus(efficiency);

        /// <summary>Can this cost be paid in full right now?</summary>
        public bool CanAfford(float cost) => cost <= _current;

        /// <summary>
        /// Advance time. Handles regeneration, the post-spend delay, and
        /// expiry of the dodge chain.
        /// </summary>
        public void Tick(float deltaSeconds)
        {
            if (deltaSeconds <= 0f) return;

            if (_sinceLastDodge < float.MaxValue)
            {
                _sinceLastDodge += deltaSeconds;
                if (_sinceLastDodge >= _profile.DodgeChainWindowSeconds)
                    _consecutiveDodges = 0;
            }

            if (_regenDelayRemaining > 0f)
            {
                _regenDelayRemaining -= deltaSeconds;
                if (_regenDelayRemaining > 0f) return;

                // Spend the remainder of this frame regenerating rather than
                // dropping it, so behaviour does not depend on frame rate.
                deltaSeconds = -_regenDelayRemaining;
                _regenDelayRemaining = 0f;
            }

            var rate = _profile.RegenPerSecond;
            if (_exhausted) rate *= _profile.ExhaustedRegenMultiplier;

            _current = Math.Min(EffectiveMax, _current + rate * deltaSeconds);

            if (_exhausted &&
                _current >= EffectiveMax * _profile.ExhaustionRecoveryFraction)
            {
                _exhausted = false;
            }
        }

        /// <summary>
        /// Spend stamina. The action always happens — see SpendResult.Afforded.
        /// </summary>
        /// <param name="efficiency">
        /// Skill multiplier below 1 makes the same action cheaper.
        /// combat.md §3: skill buys efficiency and options, never raw damage.
        /// </param>
        public SpendResult Spend(float cost, float efficiency = 1f)
        {
            if (cost < 0f)
                throw new ArgumentOutOfRangeException(nameof(cost), "Cost cannot be negative.");

            var actual = cost * Clamp01Plus(efficiency);
            var afforded = actual <= _current;
            var spent = Math.Min(actual, _current);

            _current -= spent;
            _regenDelayRemaining = _profile.RegenDelaySeconds;

            var causedExhaustion = false;
            if (!afforded && !_exhausted)
            {
                _exhausted = true;
                causedExhaustion = true;
            }

            return new SpendResult
            {
                Afforded = afforded,
                Spent = spent,
                CausedExhaustion = causedExhaustion,
            };
        }

        /// <summary>
        /// Spend a dodge, applying and then advancing the chain escalation.
        /// </summary>
        public SpendResult SpendDodge(float efficiency = 1f)
        {
            var result = Spend(NextDodgeCost(efficiency));
            _consecutiveDodges++;
            _sinceLastDodge = 0f;
            return result;
        }

        /// <summary>
        /// Spend a parry attempt. Call <see cref="RefundParry"/> if it lands.
        /// </summary>
        public SpendResult SpendParry(float efficiency = 1f) =>
            Spend(_profile.ParryCost, efficiency);

        /// <summary>
        /// Return most of a parry's cost after a successful parry.
        /// Does not clear the regeneration delay — the refund is a reward,
        /// not a reset.
        /// </summary>
        public void RefundParry(float efficiency = 1f)
        {
            var refund = _profile.ParryCost
                         * Clamp01Plus(efficiency)
                         * _profile.ParryRefundFraction;
            _current = Math.Min(EffectiveMax, _current + refund);
        }

        /// <summary>
        /// Drain for one tick of sustained effort. Returns false once the
        /// bar is empty, at which point the caller should drop the player
        /// out of the activity — to a walk, off the wall, under the water.
        /// </summary>
        public bool Exert(float ratePerSecond, float deltaSeconds, float efficiency = 1f)
        {
            if (deltaSeconds <= 0f) return _current > 0f;
            if (ratePerSecond < 0f)
                throw new ArgumentOutOfRangeException(
                    nameof(ratePerSecond), "Drain rate cannot be negative.");

            var drain = ratePerSecond * deltaSeconds * Clamp01Plus(efficiency);

            _current = Math.Max(0f, _current - drain);
            _regenDelayRemaining = _profile.RegenDelaySeconds;
            return _current > 0f;
        }

        /// <summary>One tick of sprinting (L55).</summary>
        public bool Sprint(float deltaSeconds, float efficiency = 1f) =>
            Exert(_profile.SprintDrainPerSecond, deltaSeconds, efficiency);

        /// <summary>
        /// One tick of climbing. Drains harder than sprinting — running out
        /// halfway up is a consequence, not an inconvenience.
        /// </summary>
        public bool Climb(float deltaSeconds, float efficiency = 1f) =>
            Exert(_profile.ClimbDrainPerSecond, deltaSeconds, efficiency);

        /// <summary>One tick of swimming.</summary>
        public bool Swim(float deltaSeconds, float efficiency = 1f) =>
            Exert(_profile.SwimDrainPerSecond, deltaSeconds, efficiency);

        /// <summary>A single jump.</summary>
        public SpendResult Jump(float efficiency = 1f) =>
            Spend(_profile.JumpCost, efficiency);

        /// <summary>Refill to full and clear all state. For respawns and tests.</summary>
        public void Reset()
        {
            _current = EffectiveMax;
            _regenDelayRemaining = 0f;
            _sinceLastDodge = float.MaxValue;
            _exhausted = false;
            _consecutiveDodges = 0;
        }

        private static float Clamp01Plus(float efficiency) =>
            efficiency < 0f ? 0f : efficiency;
    }
}
