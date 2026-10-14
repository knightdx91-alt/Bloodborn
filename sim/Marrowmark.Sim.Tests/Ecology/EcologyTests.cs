using System.Linq;
using Marrowmark.Sim.Ecology;
using Marrowmark.Sim.Town;
using Xunit;

namespace Marrowmark.Sim.Tests.Ecology
{
    /// <summary>
    /// content.md §2: warped populations grow if unculled and push toward
    /// roads and farms; culls are real maintenance; parts are materials;
    /// a pooling left alone births something with a name.
    /// </summary>
    public class EcologyTests
    {
        private static readonly EcologyProfile P = EcologyProfile.Default;

        private static (Wilds eco, Territory hedges) Hedges(int population = 12)
        {
            var eco = new Wilds(20260927);
            var t = eco.Pooling("hedge-pooling", "the Hedges west", population);
            return (eco, t);
        }

        [Fact]
        public void An_unculled_population_grows()
        {
            var (eco, t) = Hedges();
            eco.Advance(24f, 24f);
            Assert.True(t.Population > 12f);
        }

        [Fact]
        public void And_stops_at_what_the_land_will_hold()
        {
            var (eco, t) = Hedges();
            eco.Advance(10_000f, 10_000f);
            Assert.Equal(P.CarryingCapacity, t.Population, 1);
        }

        [Fact]
        public void A_pooling_is_never_quite_empty()
        {
            var (eco, t) = Hedges(population: 0);
            eco.Advance(240f, 240f);
            Assert.True(t.Population > 0f);
        }

        [Fact]
        public void Pressure_reads_off_the_population_and_is_capped()
        {
            var (eco, t) = Hedges(population: 0);
            Assert.Equal(0, eco.PressureOf(t));
            t.Population = P.PopulationPerPressure * 2;
            Assert.Equal(2, eco.PressureOf(t));
            t.Population = P.PopulationPerPressure * 50;
            Assert.Equal(P.MaxPressure, eco.PressureOf(t));
        }

        [Fact]
        public void At_enough_pressure_it_pushes_out_toward_the_roads()
        {
            var (eco, t) = Hedges(population: 0);
            t.Population = P.PopulationPerPressure * (P.SpillPressure - 1);
            Assert.False(eco.Spilling(t));
            t.Population = P.PopulationPerPressure * P.SpillPressure;
            Assert.True(eco.Spilling(t));
        }

        [Fact]
        public void A_cull_is_real_maintenance_and_a_supply_run()
        {
            var (eco, t) = Hedges(population: 30);
            var r = eco.Cull(t, 10, "Chris", 1f);

            Assert.Equal(10, r.Killed);
            Assert.Equal(10 * P.PartsPerKill, r.Parts);
            Assert.Equal(20f, t.Population, 3);
            Assert.Null(r.Slaying);
        }

        [Fact]
        public void You_cannot_kill_more_than_there_are()
        {
            var (eco, t) = Hedges(population: 3);
            Assert.Equal(3, eco.Cull(t, 100, "Chris", 1f).Killed);
            Assert.Equal(0f, t.Population, 3);
        }

        [Fact]
        public void The_board_reads_the_ecology()
        {
            // content.md §3: the board never lies, and now the thing it
            // reads is a population rather than a seeded number.
            var (eco, t) = Hedges(population: P.PopulationPerPressure * 3);
            var state = new TownState();

            eco.WriteInto(state);
            Assert.Contains(ContractBoard.Generate(state),
                c => c.Kind == ContractKind.Cull && c.Subject == "the Hedges west" && c.Magnitude == 3);

            eco.Cull(t, P.PopulationPerPressure * 3, "Chris", 1f);
            eco.WriteInto(state);
            Assert.DoesNotContain(ContractBoard.Generate(state), c => c.Kind == ContractKind.Cull);
        }

        [Fact]
        public void A_pooling_left_alone_births_something_specific()
        {
            var (eco, t) = Hedges();
            eco.Advance(P.HorrorAfterHours - 1f, P.HorrorAfterHours - 1f);
            Assert.Null(t.Horror);
            eco.Advance(1f, P.HorrorAfterHours);
            Assert.NotNull(t.Horror);
            Assert.StartsWith("the ", t.Horror!.Name);
            Assert.NotEmpty(t.Horror.Traits);
        }

        [Fact]
        public void A_culled_pooling_births_nothing()
        {
            var (eco, t) = Hedges(population: 60);
            for (var h = 0; h < 3; h++)
            {
                eco.Advance(P.HorrorAfterHours * 0.6f, (h + 1) * P.HorrorAfterHours * 0.6f);
                eco.Cull(t, 1, "Chris", (h + 1) * P.HorrorAfterHours * 0.6f);
            }
            Assert.Null(t.Horror);
        }

        [Fact]
        public void Only_one_horror_at_a_time()
        {
            var (eco, t) = Hedges();
            eco.Advance(P.HorrorAfterHours * 3f, P.HorrorAfterHours * 3f);
            Assert.NotNull(t.Horror);
            Assert.Empty(eco.History);
        }

        [Fact]
        public void The_horror_is_the_same_whoever_first_looks()
        {
            // The generator's rule: a pure function of seed and place.
            var a = new Wilds(7).Pooling("p", "r", 1);
            var b = new Wilds(7).Pooling("p", "r", 1);
            var ha = new Wilds(7).Birth(a, 0f);
            var hb = new Wilds(7).Birth(b, 0f);
            Assert.Equal(ha.Name, hb.Name);
            Assert.Equal(ha.Traits, hb.Traits);

            var other = new Wilds(8).Birth(a, 0f);
            Assert.True(other.Name != ha.Name || !other.Traits.SequenceEqual(ha.Traits));
        }

        [Fact]
        public void A_living_horrors_bounty_grows_by_the_day()
        {
            var (eco, t) = Hedges();
            eco.Advance(P.HorrorAfterHours, P.HorrorAfterHours);
            Assert.Equal(0, t.Horror!.Bounty);
            eco.Advance(P.HoursPerDay * 3f, P.HorrorAfterHours + P.HoursPerDay * 3f);
            Assert.Equal(P.HorrorBountyPerDay * 3, t.Horror!.Bounty);
        }

        [Fact]
        public void Slaying_it_enters_history_with_a_name_on_it()
        {
            var (eco, t) = Hedges(population: 40);
            eco.Advance(P.HorrorAfterHours + P.HoursPerDay * 2f, 0f);
            var name = t.Horror!.Name;
            var bounty = t.Horror!.Bounty;

            var r = eco.Cull(t, 5, "Ban", 500f, slayHorror: true);

            Assert.NotNull(r.Slaying);
            Assert.Equal(name, r.Slaying!.HorrorName);
            Assert.Equal("Ban", r.Slaying.By);
            Assert.Equal(bounty, r.Slaying.Bounty);
            Assert.Null(t.Horror);
            Assert.Single(eco.History);
            Assert.True(r.Parts > 5 * P.PartsPerKill);        // a rare supply run
        }

        [Fact]
        public void An_ordinary_cull_does_not_touch_the_horror()
        {
            var (eco, t) = Hedges(population: 40);
            eco.Advance(P.HorrorAfterHours, 0f);
            eco.Cull(t, 5, "Chris", 1f);
            Assert.NotNull(t.Horror);
        }
    }
}
