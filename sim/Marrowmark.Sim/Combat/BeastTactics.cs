using System;

namespace Marrowmark.Sim.Combat
{
    /// <summary>What a beast wants to do this tick.</summary>
    public enum BeastIntent
    {
        /// <summary>Out of the fight. Walk toward the target at a stalk.</summary>
        Stalk,

        /// <summary>Head down and running. Committed — it cannot turn.</summary>
        Charge,

        /// <summary>The charge connected or ran out; tusks, at knife range.</summary>
        Gore,

        /// <summary>Overshot or spent. Turning round for another run.</summary>
        Wheel,

        /// <summary>Committed to something already. Do not interrupt it.</summary>
        Busy,
    }

    /// <summary>One tick's decision.</summary>
    public struct BeastDecision
    {
        public BeastIntent Intent;
    }

    /// <summary>
    /// A boar's fight, which is not a swordsman's fight.
    ///
    /// The Hedges shipped with the boar running <see cref="EnemyTactics"/> —
    /// the sparring partner's brain. It circled at the edge of its reach
    /// and threw a heavy overhead, a quick to the body and a whole-body
    /// sweep, because those are the three shapes a man with a sword has.
    /// A boar has one: it runs at you.
    ///
    /// The shape of this is deliberately different rather than tuned
    /// differently. A swordsman's fight is a conversation at a fixed
    /// distance — that is what <see cref="EnemyTactics.PressureRange"/>
    /// is about. A boar's fight is a series of passes: it lines up, it
    /// commits, it cannot correct mid-run, and the answer is to not be
    /// there. combat.md §6 makes the wind-up the telegraph; here the
    /// telegraph is the whole approach, and the dodge is timed against a
    /// charge rather than against a swing.
    ///
    /// Committed means committed: once <see cref="BeastIntent.Charge"/>
    /// is returned it keeps being returned until the run is spent, so the
    /// caller cannot steer it onto a target that stepped aside. That is
    /// the entire reason a charge is beatable.
    ///
    /// Engine-free like everything else here: the caller says how far away
    /// the target is, this says what to do about it. Deterministic from a
    /// seed, because combat.md §7 makes damage server-authoritative and
    /// the server has to agree about what the beast did.
    /// </summary>
    public sealed class BeastTactics
    {
        private readonly BeastTacticsProfile _profile;
        private uint _state;
        private float _charging;     // Seconds left in the current run.
        private float _wheeling;     // Seconds left turning round.
        private float _sinceGore;

        public BeastTactics(BeastTacticsProfile profile, uint seed = 1)
        {
            _profile = profile;
            _state = seed == 0u ? 0x9E3779B9u : seed;
            _sinceGore = profile.RecoverBetweenGoresSeconds;
        }

        /// <summary>True while a charge is still running.</summary>
        public bool IsCharging => _charging > 0f;

        /// <summary>True while it is turning round for another pass.</summary>
        public bool IsWheeling => _wheeling > 0f;

        /// <summary>Seconds left in the current charge, 0 when not charging.</summary>
        public float ChargeRemaining => _charging;

        public void Tick(float deltaSeconds)
        {
            if (deltaSeconds <= 0f) return;
            _sinceGore += deltaSeconds;

            if (_charging > 0f)
            {
                _charging = Math.Max(0f, _charging - deltaSeconds);
                // A run that goes its full distance without hitting
                // anything ends in the wheel BY ITSELF. It would be
                // cheaper to leave that to the caller — Spent() is right
                // there — but then the punish window would exist only
                // while every caller remembered to ask for it, and a
                // window that depends on being asked for is not a rule.
                // Found by a test that saw one charge a minute instead of
                // twenty: the boar reached the end of its run and simply
                // started another, having never turned round.
                if (_charging <= 0f) _wheeling = _profile.WheelSeconds;
                return;
            }

            if (_wheeling > 0f) _wheeling = Math.Max(0f, _wheeling - deltaSeconds);
        }

        /// <summary>
        /// Decide. <paramref name="busy"/> is the caller saying an attack
        /// is already running.
        /// </summary>
        public BeastDecision Decide(float distanceToTarget, Stamina stamina, bool busy)
        {
            if (stamina == null) throw new ArgumentNullException(nameof(stamina));

            if (busy)
                return new BeastDecision { Intent = BeastIntent.Busy };

            // A run in progress outranks everything. It cannot be aborted
            // because the target moved — that is what makes it dodgeable.
            if (_charging > 0f)
                return new BeastDecision { Intent = BeastIntent.Charge };

            // Spent the run. Turn round before doing anything else, which
            // is the window a player uses to close, heal or leave.
            if (_wheeling > 0f)
                return new BeastDecision { Intent = BeastIntent.Wheel };

            // On top of the target: tusks, not a run. A charge needs room
            // to build, so at knife range there is nothing to build.
            if (distanceToTarget <= _profile.GoreRange)
            {
                if (_sinceGore < _profile.RecoverBetweenGoresSeconds)
                    return new BeastDecision { Intent = BeastIntent.Wheel };
                return new BeastDecision { Intent = BeastIntent.Gore };
            }

            // Far enough to build up speed, and able to pay for it.
            if (distanceToTarget <= _profile.ChargeRange
                && stamina.CanAfford(_profile.ChargeStaminaCost))
            {
                _charging = _profile.ChargeSeconds;
                return new BeastDecision { Intent = BeastIntent.Charge };
            }

            return new BeastDecision { Intent = BeastIntent.Stalk };
        }

        /// <summary>Call when a charge actually starts, to pay for it.</summary>
        public void Charged(Stamina stamina)
        {
            if (stamina == null) throw new ArgumentNullException(nameof(stamina));
            stamina.Spend(_profile.ChargeStaminaCost);
        }

        /// <summary>
        /// Call when a charge ends without connecting, or after a gore.
        /// Both put the beast into the wheel, which is the punish window.
        /// </summary>
        public void Spent()
        {
            _charging = 0f;
            _wheeling = _profile.WheelSeconds;
        }

        /// <summary>Call when the tusks are actually thrown.</summary>
        public void Gored()
        {
            _sinceGore = 0f;
        }

        /// <summary>
        /// xorshift32, the same generator <see cref="EnemyTactics"/> uses,
        /// for the same reason: deterministic and identical on every
        /// platform, which System.Random does not promise.
        /// </summary>
        private float NextRoll()
        {
            _state ^= _state << 13;
            _state ^= _state >> 17;
            _state ^= _state << 5;
            return (_state & 0xFFFFFFu) / (float)0x1000000;
        }
    }
}
