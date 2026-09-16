using Marrowmark.Sim.World;
using Xunit;

namespace Marrowmark.Sim.Tests.World
{
    /// <summary>
    /// L89. The parts worth asserting are the ones the design leans on:
    /// the sun is a COMPASS, so its bearing must be dependable; twilight
    /// is a span rather than an instant, so dawn and dusk exist long
    /// enough to name; and the clock wraps without a seam, because a
    /// world that jolts at midnight is worse than one that never moves.
    /// </summary>
    public class WorldClockTests
    {
        private static WorldClock At(float fraction)
        {
            var c = new WorldClock(DayProfile.Default);
            c.SetFraction(fraction);
            return c;
        }

        // ── the compass ───────────────────────────────────────────────

        [Fact]
        public void The_sun_rises_in_the_east()
        {
            // L89's load-bearing claim: this is the compass L80 forbids on
            // screen. If it is not dependable it is a puzzle, not a tool.
            Assert.Equal(90f, At(0.25f).SunAzimuthDegrees, 1);
        }

        [Fact]
        public void It_is_south_at_noon_and_west_at_sunset()
        {
            Assert.Equal(180f, At(0.50f).SunAzimuthDegrees, 1);
            Assert.Equal(270f, At(0.75f).SunAzimuthDegrees, 1);
        }

        [Fact]
        public void The_bearing_advances_evenly_and_never_jumps()
        {
            var c = new WorldClock(DayProfile.Default);
            c.SetFraction(0f);
            var previous = c.SunAzimuthDegrees;
            for (var i = 0; i < 400; i++)
            {
                c.Tick(DayProfile.Default.RealSecondsPerDay / 400f);
                var now = c.SunAzimuthDegrees;
                var step = now - previous;
                // One wrap is expected; anything else is a jolt.
                if (step < -180f) step += 360f;
                Assert.InRange(step, 0f, 2f);
                previous = now;
            }
        }

        // ── the shape of a day ────────────────────────────────────────

        [Fact]
        public void The_sun_is_highest_at_noon_and_lowest_at_midnight()
        {
            Assert.Equal(DayProfile.Default.NoonElevationDegrees,
                At(0.5f).SunElevationDegrees, 1);
            Assert.Equal(-DayProfile.Default.MidnightDepressionDegrees,
                At(0f).SunElevationDegrees, 1);
        }

        [Fact]
        public void Noon_is_day_and_midnight_is_night()
        {
            Assert.Equal(DayPhase.Day, At(0.5f).Phase);
            Assert.Equal(DayPhase.Night, At(0f).Phase);
        }

        [Fact]
        public void Dawn_and_dusk_are_different_things()
        {
            // Elevation alone cannot tell them apart — the sun is at the
            // same height twice a day. Which way it is going is the whole
            // difference, and "meet me at dusk" depends on it.
            Assert.True(At(0.25f).SunIsRising);
            Assert.False(At(0.75f).SunIsRising);
        }

        [Fact]
        public void Twilight_is_a_span_not_an_instant()
        {
            // Sample a whole day and count how much of it is neither full
            // day nor full night. A cycle that snaps between them has no
            // dusk to meet at.
            var c = new WorldClock(DayProfile.Default);
            var twilight = 0;
            const int samples = 2000;
            for (var i = 0; i < samples; i++)
            {
                c.SetFraction(i / (float)samples);
                if (c.Phase == DayPhase.Dawn || c.Phase == DayPhase.Dusk) twilight++;
            }

            Assert.True(twilight > samples * 0.02f,
                $"only {twilight * 100f / samples:0.0}% of the day is twilight");
        }

        [Fact]
        public void Night_is_a_real_fraction_of_the_day_and_less_than_half()
        {
            // L89's stated principle, asserted so a tuning change cannot
            // quietly delete night or drown the day in it.
            var c = new WorldClock(DayProfile.Default);
            var night = 0;
            const int samples = 2000;
            for (var i = 0; i < samples; i++)
            {
                c.SetFraction(i / (float)samples);
                if (c.Phase == DayPhase.Night) night++;
            }

            var share = night / (float)samples;
            Assert.InRange(share, 0.15f, 0.5f);
        }

        // ── the one number a renderer needs ───────────────────────────

        [Fact]
        public void Daylight_runs_zero_to_one_across_the_day()
        {
            Assert.Equal(1f, At(0.5f).Daylight, 3);
            Assert.Equal(0f, At(0f).Daylight, 3);
            Assert.InRange(At(0.25f).Daylight, 0.05f, 0.95f);
        }

        [Fact]
        public void Daylight_never_leaves_its_range_anywhere_in_the_day()
        {
            var c = new WorldClock(DayProfile.Default);
            for (var i = 0; i < 1000; i++)
            {
                c.SetFraction(i / 1000f);
                Assert.InRange(c.Daylight, 0f, 1f);
            }
        }

        // ── the clock itself ──────────────────────────────────────────

        [Fact]
        public void A_full_day_of_ticks_comes_back_to_where_it_started()
        {
            var c = new WorldClock(DayProfile.Default);
            c.SetFraction(0.3f);
            for (var i = 0; i < 600; i++)
                c.Tick(DayProfile.Default.RealSecondsPerDay / 600f);

            Assert.Equal(0.3f, c.Fraction, 2);
        }

        [Fact]
        public void The_fraction_never_leaves_its_range()
        {
            var c = new WorldClock(DayProfile.Default);
            for (var i = 0; i < 500; i++)
            {
                c.Tick(997f);   // deliberately not a factor of the day
                Assert.InRange(c.Fraction, 0f, 1f);
            }
        }

        [Fact]
        public void Time_does_not_run_backwards()
        {
            var c = new WorldClock(DayProfile.Default);
            c.SetFraction(0.4f);
            var before = c.Fraction;
            c.Tick(0f);
            c.Tick(-500f);
            Assert.Equal(before, c.Fraction, 5);
        }

        [Fact]
        public void Two_clocks_started_together_stay_together()
        {
            // L89: one clock, shared. Two players standing beside each
            // other must see the same light.
            var a = new WorldClock(DayProfile.Default);
            var b = new WorldClock(DayProfile.Default);
            for (var i = 0; i < 300; i++)
            {
                a.Tick(1f / 60f);
                b.Tick(1f / 60f);
            }

            Assert.Equal(a.Fraction, b.Fraction, 5);
            Assert.Equal(a.SunElevationDegrees, b.SunElevationDegrees, 4);
        }
    }
}
