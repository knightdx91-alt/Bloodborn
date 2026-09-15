namespace Marrowmark.Sim.Net
{
    public enum Defence { Parry, Dodge }

    /// <summary>
    /// "I parried at t." What a client is allowed to assert.
    ///
    /// Note what is NOT here: no hit, no damage, no kill. §7 gives the
    /// client authority over its own defence and nothing else, and the
    /// absence is the security property — a fully compromised client can
    /// claim to have survived something, which shows up in the statistics
    /// §7 says to watch, and can never claim to have killed anyone.
    /// </summary>
    public struct DefensiveClaim
    {
        public string PlayerId;
        public Defence Kind;

        /// <summary>When the client believes it happened, on its own
        /// clock. The server does not trust this — it checks it against
        /// the envelope.</summary>
        public float ClientTime;
    }

    /// <summary>Why a claim was honoured or refused. Refusals are
    /// counted rather than silently dropped, because §7's anti-cheat
    /// posture is to "detect statistically ... never by tightening the
    /// envelope", and you cannot detect what you did not count.</summary>
    public enum ClaimVerdict
    {
        /// <summary>Inside the envelope. The defender wins.</summary>
        Honoured,

        /// <summary>Dated further back than the envelope allows. This is
        /// the one that would be a cheat if it were common, and a bad
        /// connection if it were rare — hence counting rather than
        /// tightening.</summary>
        TooOld,

        /// <summary>Dated in the server's future. A clock ahead of the
        /// server's, or a client trying to pre-declare a defence it has
        /// not made yet.</summary>
        FromTheFuture,

        /// <summary>The player is already dead. §7: no rollback of death,
        /// ever — "a player who has seen themselves die stays dead".</summary>
        AlreadyDead,
    }

    /// <summary>
    /// The tolerance envelope of L39 / §7.
    ///
    /// A claim is honoured if it is dated no further back than the
    /// link's own one-way delay plus the tolerance — and the whole thing
    /// is clamped, because an envelope that grows without limit rewards
    /// latency and makes adding some the cheapest exploit in the game.
    /// </summary>
    public static class ToleranceEnvelope
    {
        /// <summary>How far back a claim may be dated, for this link.</summary>
        public static float Width(float oneWayDelay, LatencyProfile p)
        {
            var width = oneWayDelay + p.ToleranceSeconds;
            return width > p.MaxEnvelopeSeconds ? p.MaxEnvelopeSeconds : width;
        }

        public static ClaimVerdict Judge(
            float serverTime, float claimTime, float oneWayDelay, LatencyProfile p)
        {
            // A claim from the future is never honoured. It costs nothing
            // to refuse and it closes pre-declaration outright.
            if (claimTime > serverTime) return ClaimVerdict.FromTheFuture;

            var age = serverTime - claimTime;
            return age <= Width(oneWayDelay, p)
                ? ClaimVerdict.Honoured
                : ClaimVerdict.TooOld;
        }
    }
}
