using System.Collections.Generic;
using System.Linq;
using Marrowmark.Sim.Net;
using Xunit;
using Xunit.Abstractions;

namespace Marrowmark.Sim.Tests.Net
{
    /// <summary>
    /// The differential half of combat.md §9's gate: replay the identical
    /// fight at several latencies and compare what came out.
    ///
    /// A perfect defender parries every blow on their own screen. L39's
    /// promise is that whether those parries count depends on their read
    /// and never on their connection — up to the clamp, past which §7
    /// knowingly accepts a disadvantage.
    /// </summary>
    public class DuelLatencyTests
    {
        private readonly ITestOutputHelper _out;
        public DuelLatencyTests(ITestOutputHelper output) => _out = output;

        private static LatencyProfile P => LatencyProfile.Default;

        [Fact]
        public void A_hundred_milliseconds_plays_identically_to_zero()
        {
            var lan = Duel.PerfectDefender(0f, P);
            var typical = Duel.PerfectDefender(0.100f, P);

            Assert.Equal(lan.BlowsTurned, typical.BlowsTurned);
            Assert.Equal(lan.BlowsLanded, typical.BlowsLanded);
            Assert.Equal(lan.DamageTaken, typical.DamageTaken);
            Assert.Equal(lan.Died, typical.Died);
        }

        [Fact]
        public void The_perfect_defender_takes_nothing_inside_the_clamp()
        {
            foreach (var oneWay in new[] { 0f, 0.025f, 0.050f, 0.075f, 0.100f, 0.125f })
            {
                var r = Duel.PerfectDefender(oneWay, P);
                Assert.Equal(0f, r.DamageTaken);
                Assert.Equal(10, r.BlowsTurned);
            }
        }

        [Fact]
        public void Past_the_clamp_the_same_play_starts_to_cost()
        {
            // Not a regression — the trade §7 chose, asserted so that it
            // stays a choice rather than becoming a surprise.
            var awful = Duel.PerfectDefender(0.400f, P);

            Assert.True(awful.DamageTaken > 0f);
            Assert.True(awful.RefusedTooOld > 0);
        }

        [Fact]
        public void The_sweep_is_monotonic_and_reported()
        {
            // Printed so that the numbers are in the build log rather than
            // in somebody's memory.
            var delays = new[] { 0f, 0.050f, 0.100f, 0.150f, 0.200f, 0.300f, 0.400f };
            var sweep = Duel.Sweep(delays, P);

            _out.WriteLine("one-way   turned  landed   damage   refused");
            foreach (var d in delays)
            {
                var r = sweep[d];
                _out.WriteLine($"{d * 1000,5:0}ms     {r.BlowsTurned,3}     {r.BlowsLanded,3}   " +
                               $"{r.DamageTaken,6:0}      {r.RefusedTooOld,3}");
            }

            // More latency never helps.
            var damages = delays.Select(d => sweep[d].DamageTaken).ToList();
            for (var i = 1; i < damages.Count; i++)
                Assert.True(damages[i] >= damages[i - 1],
                    $"damage fell going from {delays[i - 1] * 1000}ms to {delays[i] * 1000}ms");
        }

        [Fact]
        public void The_clamp_is_a_cliff_and_not_a_slope()
        {
            // ⚠️ The spike's real finding, pinned so it cannot move
            // quietly while somebody decides what to do about it.
            //
            // §7 describes the trade as "a fair-feeling game against
            // monsters and a disadvantaged one in PvP". What the sweep
            // shows is not a disadvantage — past a threshold EVERY
            // defence fails, because an honest claim is dated one one-way
            // trip back and the envelope stops growing to meet it.
            //
            // The boundary is MEASURED rather than derived: the server
            // overshoots the claim's arrival by up to a tick, so the flip
            // sits a little under MaxEnvelope rather than exactly on it.
            // What is asserted is the SHAPE — that it is a cliff — since
            // that is the thing worth arguing about.
            var step = 0.001f;
            var lastGood = -1f;
            var firstBad = -1f;

            for (var d = 0f; d <= P.MaxEnvelopeSeconds + 0.05f; d += step)
            {
                var turned = Duel.PerfectDefender(d, P, blows: 4).BlowsTurned;
                if (turned == 4) lastGood = d;
                else if (firstBad < 0f) firstBad = d;
            }

            Assert.True(firstBad > 0f, "never found a latency that fails");

            // Perfect right up to the edge, and nothing at all past it —
            // no band where a defender turns some blows and eats others.
            Assert.Equal(0, Duel.PerfectDefender(firstBad, P, blows: 10).BlowsTurned);
            Assert.Equal(10, Duel.PerfectDefender(lastGood, P, blows: 10).BlowsTurned);

            // And the whole transition happens inside a single tick of
            // latency. That is what makes it a cliff rather than a slope.
            Assert.True(firstBad - lastGood <= P.TickSeconds,
                $"transition spans {(firstBad - lastGood) * 1000:0}ms, " +
                $"which is more than one tick ({P.TickSeconds * 1000:0}ms)");
        }

        [Fact]
        public void Nobody_inside_the_clamp_dies_to_a_fight_they_played_perfectly()
        {
            foreach (var oneWay in new[] { 0f, 0.050f, 0.100f, 0.125f })
                Assert.False(Duel.PerfectDefender(oneWay, P, blows: 100).Died);
        }
    }
}
