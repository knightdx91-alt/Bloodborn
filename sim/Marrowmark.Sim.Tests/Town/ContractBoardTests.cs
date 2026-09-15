using System.Linq;
using Marrowmark.Sim.Town;
using Xunit;

namespace Marrowmark.Sim.Tests.Town
{
    /// <summary>
    /// content.md §3: "systemic work generated from *actual world state*
    /// ... the board never lies about the world; if the contract exists,
    /// the problem exists."
    ///
    /// That sentence is the whole specification, and it is a testable one:
    /// every posting must trace back to something true, and anything that
    /// stops being true must leave the board.
    /// </summary>
    public class ContractBoardTests
    {
        private static TownState Thornfield() => new TownState
        {
            BoarPressure =
            {
                new BoarPressure { Region = "the Hedges west", Pressure = 3 },
                new BoarPressure { Region = "the Hedges east", Pressure = 2 },
                new BoarPressure { Region = "the north road", Pressure = 1 },
            },
            Caravans =
            {
                new Caravan { Id = "velmark-1", Destination = "Vellmark",
                    Status = Caravan.Mustering, Guards = 2 },
                new Caravan { Id = "greywater-1", Destination = "Greywater",
                    Status = Caravan.Mustering, Guards = 1 },
            },
            HarvestDemand = 4,
            SmithingJobs = { new SmithingJob { Id = "smith-1", Pay = 6 } },
            Coin = 12,
        };

        [Fact]
        public void No_boars_no_cull_contract()
        {
            var s = Thornfield();
            s.BoarPressure.Single(b => b.Region == "the north road").Pressure = 0;

            var posted = ContractBoard.Generate(s);

            Assert.DoesNotContain(posted,
                c => c.Kind == ContractKind.Cull && c.Subject == "the north road");
            // and the others are untouched
            Assert.Contains(posted,
                c => c.Kind == ContractKind.Cull && c.Subject == "the Hedges west");
        }

        [Fact]
        public void A_quiet_town_posts_nothing()
        {
            // The strongest version of "the board never lies": with no
            // problems at all there is no work, and the board is bare.
            var s = new TownState();

            Assert.Empty(ContractBoard.Generate(s));
        }

        [Fact]
        public void Cull_pay_scales_with_the_pressure_it_answers()
        {
            var s = Thornfield();
            var posted = ContractBoard.Generate(s);

            var west = posted.Single(c => c.Subject == "the Hedges west");
            var east = posted.Single(c => c.Subject == "the Hedges east");

            Assert.True(west.Pay > east.Pay);
            Assert.Equal(3, west.Magnitude);
        }

        [Fact]
        public void Only_mustering_caravans_want_guards()
        {
            var s = Thornfield();
            s.Caravans.Single(c => c.Id == "greywater-1").Status = "departed";

            var posted = ContractBoard.Generate(s);

            Assert.Contains(posted, c => c.Id == "escort-velmark-1");
            Assert.DoesNotContain(posted, c => c.Id == "escort-greywater-1");
        }

        [Fact]
        public void Escort_pay_scales_with_guards_wanted()
        {
            var posted = ContractBoard.Generate(Thornfield());
            var two = posted.Single(c => c.Id == "escort-velmark-1");
            var one = posted.Single(c => c.Id == "escort-greywater-1");

            Assert.True(two.Pay > one.Pay);
        }

        [Fact]
        public void No_hands_wanted_no_harvest_contract()
        {
            var s = Thornfield();
            s.HarvestDemand = 0;

            Assert.DoesNotContain(ContractBoard.Generate(s),
                c => c.Kind == ContractKind.Harvest);
        }

        [Fact]
        public void Taking_a_contract_marks_it_taken_on_the_board()
        {
            var s = Thornfield();
            var id = ContractBoard.Generate(s).First(c => c.Kind == ContractKind.Cull).Id;

            Assert.True(ContractBoard.Take(s, id));
            Assert.True(ContractBoard.Generate(s).Single(c => c.Id == id).Taken);
        }

        [Fact]
        public void The_same_contract_cannot_be_taken_twice()
        {
            var s = Thornfield();
            var id = ContractBoard.Generate(s).First().Id;

            Assert.True(ContractBoard.Take(s, id));
            Assert.False(ContractBoard.Take(s, id));
            Assert.Single(s.ContractsTaken);
        }

        [Fact]
        public void A_contract_that_is_not_posted_cannot_be_taken()
        {
            // The case that matters once a model is proposing intents
            // (L49): it may reach for anything, and the gate is here.
            var s = Thornfield();

            Assert.False(ContractBoard.Take(s, "cull-somewhere-that-is-fine"));
            Assert.False(ContractBoard.Take(s, ""));
            Assert.Empty(s.ContractsTaken);
        }

        [Fact]
        public void Work_that_disappears_cannot_still_be_taken()
        {
            var s = Thornfield();
            var id = ContractBoard.Generate(s)
                .Single(c => c.Subject == "the north road").Id;

            // Somebody else culled them.
            s.BoarPressure.Single(b => b.Region == "the north road").Pressure = 0;

            Assert.False(ContractBoard.Take(s, id));
        }

        [Fact]
        public void The_market_lists_only_what_is_actually_warehoused()
        {
            // economy.md §3. A market board showing goods the town does not
            // have is the same lie as a contract for a problem it does not
            // have.
            var s = Thornfield();
            s.Warehoused.Add(new WarehousedGood
                { Good = "grain", Quantity = 120, Price = 2, Unit = "stone" });
            s.Warehoused.Add(new WarehousedGood
                { Good = "ale", Quantity = 0, Price = 3, Unit = "cask" });

            var market = ContractBoard.Market(s);

            Assert.Contains(market, g => g.Good == "grain");
            Assert.DoesNotContain(market, g => g.Good == "ale");
        }

        [Fact]
        public void Postings_carry_no_prose()
        {
            // L88's split, asserted rather than trusted: the rules decide
            // what work exists and what it pays; a town decides how its
            // carter phrases it. If prose creeps back in here, a second
            // town cannot reuse any of this.
            var fields = typeof(Contract).GetFields()
                .Select(f => f.Name).ToArray();

            Assert.DoesNotContain("Title", fields);
            Assert.DoesNotContain("Detail", fields);
            Assert.DoesNotContain("Description", fields);
        }
    }
}
