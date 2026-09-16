namespace Marrowmark.Sim.World
{
    /// <summary>
    /// The shape of a day (L89). Numbers, so they can be moved without
    /// touching the rules that read them.
    /// </summary>
    public struct DayProfile
    {
        /// <summary>Real seconds in one in-game day.
        ///
        /// L89's principle rather than a measured value: a normal session
        /// should contain both day and night. Short enough to see both,
        /// long enough that the sky is not strobing while you fight.</summary>
        public float RealSecondsPerDay;

        /// <summary>Sun elevation, in degrees, at noon. Below 90 because a
        /// sun directly overhead flattens everything it lights and kills
        /// the long shadows art-audio.md §5 leans on.</summary>
        public float NoonElevationDegrees;

        /// <summary>How far below the horizon the sun goes at midnight.
        /// Depth, not darkness — how dark it actually gets is the client's
        /// business and L89 flags it as open.</summary>
        public float MidnightDepressionDegrees;

        /// <summary>Elevation above which it is unambiguously day.</summary>
        public float DayAboveDegrees;

        /// <summary>Elevation below which it is unambiguously night. The
        /// band between the two is dawn on the way up and dusk on the way
        /// down — twilight is a span, not an instant.</summary>
        public float NightBelowDegrees;

        public static DayProfile Default => new DayProfile
        {
            RealSecondsPerDay = 5400f,   // 90 minutes
            NoonElevationDegrees = 62f,
            MidnightDepressionDegrees = 18f,
            DayAboveDegrees = 6f,
            NightBelowDegrees = -4f,
        };
    }
}
