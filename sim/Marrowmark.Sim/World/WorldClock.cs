using System;

namespace Marrowmark.Sim.World
{
    public enum DayPhase { Night, Dawn, Day, Dusk }

    /// <summary>
    /// The one clock everybody on a server shares (L89).
    ///
    /// It lives here rather than in the renderer because it is world
    /// state, not presentation: two players standing together must see
    /// the same light, "meet me at dusk" has to mean something, and a
    /// server deciding when night falls is the only way either is true.
    /// L88 puts that in sim/; the prototype mirrors it.
    ///
    /// What the client does with the numbers — how dark night actually
    /// gets, what colour the light runs — is the client's business, and
    /// L89 leaves it open on purpose.
    /// </summary>
    public sealed class WorldClock
    {
        private readonly DayProfile _p;
        private float _seconds;

        public WorldClock(DayProfile profile, float startAtFraction = 0.30f)
        {
            _p = profile;
            _seconds = Wrap01(startAtFraction) * profile.RealSecondsPerDay;
        }

        /// <summary>Where we are in the day: 0 is midnight, 0.25 sunrise,
        /// 0.5 noon, 0.75 sunset.</summary>
        public float Fraction => _seconds / _p.RealSecondsPerDay;

        /// <summary>The hour on a 24-hour clock, for anyone who has to say
        /// one out loud. Nothing in the world displays it (L80).</summary>
        public float Hour => Fraction * 24f;

        public void Tick(float deltaSeconds)
        {
            if (deltaSeconds <= 0f) return;
            _seconds = (_seconds + deltaSeconds) % _p.RealSecondsPerDay;
            if (_seconds < 0f) _seconds += _p.RealSecondsPerDay;
        }

        /// <summary>Put the clock somewhere. A server sets this from its
        /// own time; a test sets it to look at dusk without waiting.</summary>
        public void SetFraction(float fraction) =>
            _seconds = Wrap01(fraction) * _p.RealSecondsPerDay;

        /// <summary>
        /// How high the sun is, in degrees. Negative is below the horizon.
        ///
        /// A cosine rather than anything cleverer: it puts noon at the top,
        /// midnight at the bottom, and spends most of its time near neither
        /// — which is what makes dawn and dusk long enough to be worth
        /// naming.
        /// </summary>
        public float SunElevationDegrees
        {
            get
            {
                var t = (float)Math.Cos(Fraction * 2.0 * Math.PI);
                // t: +1 at midnight, -1 at noon.
                return t <= 0f
                    ? -t * _p.NoonElevationDegrees
                    : -t * _p.MidnightDepressionDegrees;
            }
        }

        /// <summary>
        /// Where the sun is on the horizon, in degrees, measured clockwise
        /// from north.
        ///
        /// **This is the compass** (L89). East at sunrise, south at noon,
        /// west at sunset — always, everywhere, because a compass that
        /// varied by region would be a puzzle rather than an instrument.
        /// </summary>
        public float SunAzimuthDegrees => 90f + (Fraction - 0.25f) * 360f;

        /// <summary>Rising, rather than setting. What separates dawn from
        /// dusk, since elevation alone cannot.</summary>
        public bool SunIsRising => Fraction > 0f && Fraction < 0.5f;

        public DayPhase Phase
        {
            get
            {
                var e = SunElevationDegrees;
                if (e >= _p.DayAboveDegrees) return DayPhase.Day;
                if (e <= _p.NightBelowDegrees) return DayPhase.Night;
                return SunIsRising ? DayPhase.Dawn : DayPhase.Dusk;
            }
        }

        /// <summary>
        /// 0 in full night, 1 in full day, sliding across twilight. What a
        /// renderer actually wants: one number to blend every palette,
        /// energy and fog value against, so nothing has to re-derive the
        /// time of day for itself and drift from everything else.
        /// </summary>
        public float Daylight
        {
            get
            {
                var e = SunElevationDegrees;
                var span = _p.DayAboveDegrees - _p.NightBelowDegrees;
                if (span <= 0f) return e >= _p.DayAboveDegrees ? 1f : 0f;
                var t = (e - _p.NightBelowDegrees) / span;
                return t < 0f ? 0f : t > 1f ? 1f : t;
            }
        }

        private static float Wrap01(float v)
        {
            v %= 1f;
            return v < 0f ? v + 1f : v;
        }
    }
}
