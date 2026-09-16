using System.Linq;
using Marrowmark.Sim.Town;
using Xunit;

namespace Marrowmark.Sim.Tests.Town
{
    /// <summary>
    /// The half of the board that did not exist: doing the work.
    ///
    /// Contracts could be taken and never discharged, so ContractsTaken
    /// only grew and the town's work economy was a one-way door. The
    /// specification these tests hold is content.md §3's — the board is
    /// generated from the world, so finishing work has to change the
    /// board by changing the world, not by editing a list of postings.
    /// </summary>
    public class ContractWorkTests
    {
        private static TownState Thornfield() => new TownState
        {
            BoarPressure =
            {
                new BoarPressure { Region = "the Hedges west", Pressure = 3 },
                new BoarPressure { Region = "the north road", Pressure = 1 },
            },
            Caravans =
            {
                new Caravan { Id = "velmark-1", Destination = "Vellmark",
                    Status = Caravan.Mustering, Guards = 2 },
            },
            Coin = 12,
        };

        private static string WestCull => "cull-the-Hedges-west";

        [Fact]
        public void A_cull_wants_work_in_proportion_to_the_problem()
        {
            var s = Thornfield();
            var west = ContractBoard.Generate(s).First(c => c.Id == WestCull);
            var road = ContractBoard.Generate(s).First(c => c.Id == "cull-the-north-road");

            Assert.True(ContractWork.Required(west, TownProfile.Default)
                > ContractWork.Required(road, TownProfile.Default));
        }

        [Fact]
        public void Killing_boars_you_were_not_paid_for_is_not_progress()
        {
            var s = Thornfield();
            // Never took the contract.
            var done = ContractWork.RecordCull(s, "the Hedges west", 5);
            Assert.Equal(0, done);
            Assert.Empty(s.ContractProgress);
        }

        [Fact]
        public void Progress_is_capped_at_what_was_asked_for()
        {
            var s = Thornfield();
            ContractBoard.Take(s, WestCull);
            var want = ContractWork.Required(s, WestCull, TownProfile.Default);

            ContractWork.RecordCull(s, "the Hedges west", want + 10);

            // A long hunt must not bank credit against the NEXT contract
            // for the same wood.
            Assert.Equal(want, ContractWork.Done(s, WestCull));
        }

        [Fact]
        public void An_unfinished_contract_pays_nothing()
        {
            var s = Thornfield();
            ContractBoard.Take(s, WestCull);
            ContractWork.RecordCull(s, "the Hedges west", 1);

            var before = s.Coin;
            var result = ContractWork.Hand(s, WestCull);

            Assert.Equal(HandInResult.NotFinished, result.Result);
            Assert.Equal(before, s.Coin);
            Assert.Contains(WestCull, s.ContractsTaken);
        }

        [Fact]
        public void Work_you_never_took_cannot_be_handed_in()
        {
            var s = Thornfield();
            Assert.Equal(HandInResult.NotTaken, ContractWork.Hand(s, WestCull).Result);
        }

        [Fact]
        public void An_escort_refuses_honestly_rather_than_paying_for_nothing()
        {
            var s = Thornfield();
            ContractBoard.Take(s, "escort-velmark-1");

            var before = s.Coin;
            var result = ContractWork.Hand(s, "escort-velmark-1");

            // There is nowhere to walk a wagon to yet. Refusing is the
            // honest answer; paying would make the board a liar.
            Assert.Equal(HandInResult.NotYetPossible, result.Result);
            Assert.Equal(before, s.Coin);
        }

        [Fact]
        public void Finishing_a_cull_pays_and_returns_the_paper()
        {
            var s = Thornfield();
            var pay = ContractBoard.Generate(s).First(c => c.Id == WestCull).Pay;
            ContractBoard.Take(s, WestCull);
            ContractWork.RecordCull(s, "the Hedges west",
                ContractWork.Required(s, WestCull, TownProfile.Default));

            var before = s.Coin;
            var result = ContractWork.Hand(s, WestCull);

            Assert.Equal(HandInResult.Paid, result.Result);
            Assert.Equal(pay, result.Paid);
            Assert.Equal(before + pay, s.Coin);
            Assert.DoesNotContain(WestCull, s.ContractsTaken);
            Assert.Empty(s.ContractProgress.Where(r => r.ContractId == WestCull));
        }

        [Fact]
        public void Finishing_a_cull_thins_the_boars()
        {
            var s = Thornfield();
            ContractBoard.Take(s, WestCull);
            ContractWork.RecordCull(s, "the Hedges west",
                ContractWork.Required(s, WestCull, TownProfile.Default));

            var result = ContractWork.Hand(s, WestCull);

            Assert.Equal(2, result.PressureAfter);
            Assert.Equal(2, s.BoarPressure.First(b => b.Region == "the Hedges west").Pressure);
        }

        [Fact]
        public void The_next_posting_for_that_wood_is_smaller_and_pays_less()
        {
            var s = Thornfield();
            var beforePay = ContractBoard.Generate(s).First(c => c.Id == WestCull).Pay;
            ContractBoard.Take(s, WestCull);
            ContractWork.RecordCull(s, "the Hedges west",
                ContractWork.Required(s, WestCull, TownProfile.Default));
            ContractWork.Hand(s, WestCull);

            var after = ContractBoard.Generate(s).First(c => c.Id == WestCull);

            // Still posted, because boars still press — but it is a
            // smaller problem now, and the board says so without anybody
            // being told. This is the loop.
            Assert.False(after.Taken);
            Assert.True(after.Pay < beforePay);
            Assert.True(ContractWork.Required(after, TownProfile.Default)
                < ContractWork.Required(new Contract { Kind = ContractKind.Cull, Magnitude = 3 },
                    TownProfile.Default));
        }

        [Fact]
        public void Culling_a_wood_quiet_takes_it_off_the_board_entirely()
        {
            var s = Thornfield();
            // The north road is pressure 1: one contract clears it.
            const string road = "cull-the-north-road";
            ContractBoard.Take(s, road);
            ContractWork.RecordCull(s, "the north road",
                ContractWork.Required(s, road, TownProfile.Default));

            var result = ContractWork.Hand(s, road);

            Assert.Equal(HandInResult.Paid, result.Result);
            Assert.Equal(0, result.PressureAfter);
            // No pressure, no contract. content.md §3, enforced.
            Assert.DoesNotContain(ContractBoard.Generate(s), c => c.Id == road);
        }

        [Fact]
        public void A_quiet_wood_can_be_worked_again_when_the_boars_return()
        {
            var s = Thornfield();
            const string road = "cull-the-north-road";
            ContractBoard.Take(s, road);
            ContractWork.RecordCull(s, "the north road", 99);
            ContractWork.Hand(s, road);
            Assert.DoesNotContain(ContractBoard.Generate(s), c => c.Id == road);

            // Boars come back; the contract comes back with them, fresh.
            s.BoarPressure.First(b => b.Region == "the north road").Pressure = 2;

            var again = ContractBoard.Generate(s).First(c => c.Id == road);
            Assert.False(again.Taken);
            Assert.Equal(0, ContractWork.Done(s, road));
        }

        [Fact]
        public void Two_contracts_are_progressed_independently()
        {
            var s = Thornfield();
            ContractBoard.Take(s, WestCull);
            ContractBoard.Take(s, "cull-the-north-road");

            ContractWork.RecordCull(s, "the north road", 1);

            Assert.Equal(0, ContractWork.Done(s, WestCull));
            Assert.Equal(1, ContractWork.Done(s, "cull-the-north-road"));
        }

        // --- Giving the paper back -----------------------------------
        //
        // Taking work used to be a one-way door: a contract taken by
        // mistake stayed on your name for good. These are about the door
        // opening both ways WITHOUT abandoning becoming free.

        [Fact]
        public void A_taken_contract_can_be_given_back()
        {
            var s = Thornfield();
            var c = ContractBoard.Generate(s).First(x => x.Id == WestCull);
            s.ContractsTaken.Add(c.Id);

            var a = ContractWork.Abandon(s, c.Id);

            Assert.Equal(AbandonResult.Released, a.Result);
            Assert.DoesNotContain(c.Id, s.ContractsTaken);
        }

        [Fact]
        public void One_you_never_took_cannot_be_given_back()
        {
            var s = Thornfield();
            var a = ContractWork.Abandon(s, WestCull);
            Assert.Equal(AbandonResult.NotTaken, a.Result);
            Assert.Equal(0, s.ContractsAbandoned);
        }

        /// <summary>
        /// The point of the whole design. If progress survived, abandoning
        /// would be a free pause on a job you were losing — take it back
        /// later with the hard part already done.
        /// </summary>
        [Fact]
        public void The_work_goes_back_with_the_paper()
        {
            var s = Thornfield();
            var c = ContractBoard.Generate(s).First(x => x.Id == WestCull);
            s.ContractsTaken.Add(c.Id);
            ContractWork.RecordCull(s, c.Subject, 3);
            Assert.Equal(3, ContractWork.Done(s, c.Id));

            var a = ContractWork.Abandon(s, c.Id);
            Assert.Equal(3, a.Forfeited);

            // Take it again: it starts from nothing.
            s.ContractsTaken.Add(c.Id);
            Assert.Equal(0, ContractWork.Done(s, c.Id));
        }

        [Fact]
        public void Abandoning_costs_no_coin()
        {
            var s = Thornfield();
            var c = ContractBoard.Generate(s).First(x => x.Id == WestCull);
            s.ContractsTaken.Add(c.Id);
            var before = s.Coin;
            ContractWork.Abandon(s, c.Id);
            Assert.Equal(before, s.Coin);
        }

        /// <summary>The cost is that the town watched.</summary>
        [Fact]
        public void But_the_town_counts_it()
        {
            var s = Thornfield();
            var c = ContractBoard.Generate(s).First(x => x.Id == WestCull);
            s.ContractsTaken.Add(c.Id);
            ContractWork.Abandon(s, c.Id);
            Assert.Equal(1, s.ContractsAbandoned);
        }

        /// <summary>
        /// A posting withdrawn while you held it must still be droppable.
        /// Refusing to let go of work nobody is offering is the same dead
        /// end in a smaller room.
        /// </summary>
        [Fact]
        public void A_paper_for_a_withdrawn_posting_can_still_be_dropped()
        {
            var s = Thornfield();
            s.ContractsTaken.Add("cull-nowhere-at-all");
            var a = ContractWork.Abandon(s, "cull-nowhere-at-all");
            Assert.Equal(AbandonResult.Released, a.Result);
        }

        [Fact]
        public void Abandoning_does_not_thin_the_boars()
        {
            var s = Thornfield();
            var c = ContractBoard.Generate(s).First(x => x.Id == WestCull);
            s.ContractsTaken.Add(c.Id);
            var before = s.BoarPressure.First(b => b.Region == c.Subject).Pressure;
            ContractWork.Abandon(s, c.Id);
            Assert.Equal(before,
                s.BoarPressure.First(b => b.Region == c.Subject).Pressure);
            Assert.Equal(0, s.CullsCompleted);
        }

        /// <summary>And it is a paper, not a pause: handing in afterwards fails.</summary>
        [Fact]
        public void You_cannot_hand_in_what_you_gave_back()
        {
            var s = Thornfield();
            var c = ContractBoard.Generate(s).First(x => x.Id == WestCull);
            s.ContractsTaken.Add(c.Id);
            ContractWork.RecordCull(s, c.Subject, 99);
            ContractWork.Abandon(s, c.Id);

            Assert.Equal(HandInResult.NotTaken, ContractWork.Hand(s, c.Id).Result);
        }
    }
}
