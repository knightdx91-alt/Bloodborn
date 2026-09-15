using System.Collections.Generic;
using Marrowmark.Sim.Combat;

namespace Marrowmark.Sim.Net
{
    /// <summary>What the server decided happened to one blow.</summary>
    public struct Resolution
    {
        public string Defender;
        public bool Defended;
        public float DamageDealt;
        public bool Killed;
        public ClaimVerdict Verdict;
    }

    /// <summary>
    /// The authoritative half. Holds every fighter's health and decides
    /// damage, death and whether a defence counted.
    ///
    /// This runs the same <see cref="Health"/> and combat rules the
    /// prototype does — that was the whole reason sim/ was written
    /// engine-free (tech.md: "everything in sim/ was written to run on
    /// that server unchanged"), and this spike is the first thing to
    /// actually collect on it.
    ///
    /// Deliberately NOT a Godot node, NOT a socket, and NOT threaded. It
    /// is a function of (state, claims, time) so that a whole fight can
    /// be replayed at three latencies and compared.
    /// </summary>
    public sealed class CombatServer
    {
        private readonly LatencyProfile _p;
        private readonly Dictionary<string, Health> _health =
            new Dictionary<string, Health>();
        private readonly Dictionary<string, float> _delay =
            new Dictionary<string, float>();

        /// <summary>Claims that arrived but were not honoured, by reason.
        /// §7 detects statistically; this is the raw material.</summary>
        public readonly Dictionary<ClaimVerdict, int> Refusals =
            new Dictionary<ClaimVerdict, int>();

        public float Now { get; private set; }

        public CombatServer(LatencyProfile p)
        {
            _p = p;
            foreach (ClaimVerdict v in System.Enum.GetValues(typeof(ClaimVerdict)))
                Refusals[v] = 0;
        }

        public void Add(string playerId, float oneWayDelay, float maxHealth = 100f)
        {
            _health[playerId] = new Health(maxHealth);
            _delay[playerId] = oneWayDelay;
        }

        public Health HealthOf(string playerId) => _health[playerId];
        public bool IsDead(string playerId) => _health[playerId].IsDead;

        public void Tick() => Now += _p.TickSeconds;

        /// <summary>
        /// Resolve one incoming blow against a defender who may have
        /// claimed a defence.
        ///
        /// The claim is judged first and the damage second, which is the
        /// order §7 requires: "reconciliation happens before the death
        /// resolves, never after." Judging afterwards would mean undoing
        /// a death, and a player who has seen themselves die stays dead.
        /// </summary>
        public Resolution Resolve(string defenderId, float damage, DefensiveClaim? claim)
        {
            var health = _health[defenderId];

            // Nothing touches the dead. A late claim cannot revive, and a
            // late blow cannot kill twice.
            if (health.IsDead)
            {
                Count(ClaimVerdict.AlreadyDead);
                return new Resolution
                {
                    Defender = defenderId,
                    Defended = false,
                    DamageDealt = 0f,
                    Killed = false,
                    Verdict = ClaimVerdict.AlreadyDead,
                };
            }

            var verdict = ClaimVerdict.TooOld;
            var defended = false;

            if (claim.HasValue)
            {
                verdict = ToleranceEnvelope.Judge(
                    Now, claim.Value.ClientTime, _delay[defenderId], _p);
                defended = verdict == ClaimVerdict.Honoured;
                if (!defended) Count(verdict);
            }

            if (defended)
                return new Resolution
                {
                    Defender = defenderId,
                    Defended = true,
                    DamageDealt = 0f,
                    Killed = false,
                    Verdict = verdict,
                };

            health.Take(damage);
            return new Resolution
            {
                Defender = defenderId,
                Defended = false,
                DamageDealt = damage,
                Killed = health.IsDead,
                Verdict = verdict,
            };
        }

        private void Count(ClaimVerdict v) => Refusals[v] = Refusals[v] + 1;
    }
}
