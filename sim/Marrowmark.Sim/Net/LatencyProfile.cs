namespace Marrowmark.Sim.Net
{
    /// <summary>
    /// The latency contract, L39 / combat.md §7, as numbers.
    ///
    /// §7's stance in one line: **favour the defender.** The client
    /// declares "I parried at t" and the server accepts it inside an
    /// envelope; damage, position and death stay server-authoritative.
    /// The asymmetry is deliberate and is the security argument — the
    /// worst an exploiting client can do is *survive* things, which is
    /// visible, statistically detectable and bannable, rather than *kill*
    /// things, which is not recoverable.
    /// </summary>
    public struct LatencyProfile
    {
        /// <summary>
        /// How far back a defensive claim may be dated and still be
        /// honoured, over and above the link's own one-way delay.
        ///
        /// This is the ~100ms L39 turns on. It is not a guess at network
        /// conditions — it is the slack that makes a claim which was true
        /// on the defender's screen true on the server too.
        /// </summary>
        public float ToleranceSeconds;

        /// <summary>
        /// The hard clamp on the whole envelope. §7: "beyond the clamp
        /// the envelope stops widening, so a player on a 400ms connection
        /// gets a fair-feeling game against monsters and a disadvantaged
        /// one in PvP. That is the correct trade."
        ///
        /// Without this the envelope rewards latency, and the cheapest
        /// exploit in any such game is to add some.
        /// </summary>
        public float MaxEnvelopeSeconds;

        /// <summary>
        /// Server simulation step. Everything in sim/ is tick-driven so
        /// that a server and a client advance identically.
        /// </summary>
        public float TickSeconds;

        public static LatencyProfile Default => new LatencyProfile
        {
            ToleranceSeconds = 0.100f,
            MaxEnvelopeSeconds = 0.250f,
            TickSeconds = 1f / 30f,
        };
    }
}
