using System.Collections.Generic;

namespace Marrowmark.Sim.Net
{
    /// <summary>What a whole fight came to.</summary>
    public struct DuelOutcome
    {
        public float DamageTaken;
        public int BlowsLanded;
        public int BlowsTurned;
        public bool Died;
        public int RefusedTooOld;
    }

    /// <summary>
    /// A scripted duel run through the server at a chosen latency.
    ///
    /// The point is DIFFERENTIAL: run the identical fight at 0ms and at
    /// 100ms and compare. L39's promise is that they come out the same,
    /// and a promise that can be re-run is worth more than one that is
    /// argued. combat.md §9's gate — "does a parry land right at 100ms" —
    /// is exactly this comparison, minus the half that needs a human to
    /// say whether it *felt* the same.
    ///
    /// Everything here is deterministic. No clocks, no sockets, no
    /// threads: the same inputs give the same fight every time, so a
    /// failure can be replayed rather than chased.
    /// </summary>
    public static class Duel
    {
        /// <summary>
        /// A defender who parries every blow correctly, on their own
        /// screen, at the given one-way latency.
        ///
        /// This is the honest player L39 exists to protect: they are not
        /// mistiming anything, and whether they survive should depend on
        /// their read, never on their connection.
        /// </summary>
        public static DuelOutcome PerfectDefender(
            float oneWayDelay, LatencyProfile p, int blows = 10,
            float damagePerBlow = 20f, int ticksBetweenBlows = 12)
        {
            var server = new CombatServer(p);
            server.Add("defender", oneWayDelay, 1000f);

            var claims = new Link<DefensiveClaim>(oneWayDelay);
            var outcome = new DuelOutcome();

            for (var blow = 0; blow < blows; blow++)
            {
                // The blow is at the defender NOW, on their screen, and
                // they parry it. Clients are clock-synced to the server —
                // standard, and what makes the claim's timestamp mean
                // anything — so they stamp the server time of the blow.
                var blowAt = server.Now;
                claims.Send(new DefensiveClaim
                {
                    PlayerId = "defender",
                    Kind = Defence.Parry,
                    ClientTime = blowAt,
                }, blowAt);

                // The server holds the blow open until the claim can have
                // reached it — one trip. This is §7's "reconciliation
                // happens before the death resolves, never after" as a
                // scheduling rule rather than a slogan: resolving on
                // arrival is what makes the ordering true.
                // Tick to the claim's arrival, and not by a computed
                // tick count.
                //
                // Two bugs live here, both found by running it. Spinning
                // until the link drains is an INFINITE LOOP at zero
                // latency, where the packet has already arrived and
                // nothing ticks it away. And ceil(delay / tick) lands a
                // hair SHORT of the arrival often enough to drop 2 claims
                // in 10 at 100ms, because Now accumulates float error and
                // three ticks of 1/30 is 0.09999, not 0.1.
                //
                // So: advance to the deadline itself, with a bound so a
                // mistake hangs nothing.
                var deadline = blowAt + oneWayDelay;
                var guard = 0;
                while (server.Now < deadline && guard++ < 10_000) server.Tick();

                var arrived = claims.Receive(server.Now);
                DefensiveClaim? claim = arrived.Count > 0
                    ? arrived[arrived.Count - 1]
                    : (DefensiveClaim?)null;

                var r = server.Resolve("defender", damagePerBlow, claim);
                if (r.Defended) outcome.BlowsTurned++;
                else outcome.BlowsLanded++;
                outcome.DamageTaken += r.DamageDealt;
                if (r.Killed) outcome.Died = true;

                for (var t = 0; t < ticksBetweenBlows; t++) server.Tick();
            }

            outcome.RefusedTooOld = server.Refusals[ClaimVerdict.TooOld];
            return outcome;
        }

        /// <summary>Run the same fight across a spread of latencies.</summary>
        public static Dictionary<float, DuelOutcome> Sweep(
            IEnumerable<float> oneWayDelays, LatencyProfile p)
        {
            var results = new Dictionary<float, DuelOutcome>();
            foreach (var d in oneWayDelays) results[d] = PerfectDefender(d, p);
            return results;
        }
    }
}
