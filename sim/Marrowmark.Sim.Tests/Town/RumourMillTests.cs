using Marrowmark.Sim.Town;
using Xunit;

namespace Marrowmark.Sim.Tests.Town
{
    /// <summary>
    /// content.md §3 makes rumour the way content is discovered — "content
    /// discovery *is* the fireside story (L22)" — and buying a drink the
    /// way you search. That only works if what comes back is ranked
    /// usefully and decays honestly.
    ///
    /// These also part-answer an open question content.md still lists: the
    /// rumour data model, epoch plus history plus noise mixing.
    /// </summary>
    public class RumourMillTests
    {
        private static TownState Talkative() => new TownState
        {
            Coin = 12,
            Rumours =
            {
                new Rumour { Text = "boars took two sheep", Source = "a drover",
                    AgeHours = 30f, Distortion = 0.1f },
                new Rumour { Text = "the wagon is short two guards",
                    Source = "Carter Pell", AgeHours = 12f, Distortion = 0.05f },
                new Rumour { Text = "the mill burnt in my gran's time",
                    Source = "a market-goer", AgeHours = 200f, Distortion = 0.6f },
            },
        };

        [Fact]
        public void The_freshest_thing_comes_up_first()
        {
            var r = RumourMill.Search(Talkative());

            Assert.True(r.Found);
            Assert.Equal("Carter Pell", r.Rumour!.Source);
        }

        [Fact]
        public void A_fresh_lie_still_loses_to_a_slightly_older_truth()
        {
            // The property that makes the mill worth consulting instead of
            // merely noisy. Without the distortion penalty, ranking is just
            // recency and the bent story always wins by being newest.
            var s = new TownState
            {
                Rumours =
                {
                    new Rumour { Text = "bent", Source = "a drunk",
                        AgeHours = 9f, Distortion = 0.85f },
                    new Rumour { Text = "true", Source = "the reeve",
                        AgeHours = 11f, Distortion = 0.0f },
                },
            };

            Assert.Equal("the reeve", RumourMill.Search(s).Rumour!.Source);
        }

        [Fact]
        public void A_bent_rumour_comes_back_hedged()
        {
            var s = new TownState
            {
                Rumours = { new Rumour { Text = "the wheel still turns",
                    Source = "a market-goer", AgeHours = 1f, Distortion = 0.7f } },
            };

            Assert.True(RumourMill.Search(s).Hedged);
        }

        [Fact]
        public void A_reliable_rumour_is_vouched_for()
        {
            var s = new TownState
            {
                Rumours = { new Rumour { Text = "the wagon musters at dawn",
                    Source = "Carter Pell", AgeHours = 1f, Distortion = 0.02f } },
            };

            Assert.False(RumourMill.Search(s).Hedged);
        }

        [Fact]
        public void A_silent_town_turns_up_nothing_rather_than_inventing()
        {
            var r = RumourMill.Search(new TownState());

            Assert.False(r.Found);
            Assert.Null(r.Rumour);
        }

        [Fact]
        public void Time_bends_a_story()
        {
            var s = Talkative();
            var drover = s.Rumours[0];
            var wasAge = drover.AgeHours;
            var wasBent = drover.Distortion;

            RumourMill.AgeAll(s, 48f);

            Assert.True(drover.AgeHours > wasAge);
            Assert.True(drover.Distortion > wasBent);
        }

        [Fact]
        public void A_story_never_bends_all_the_way()
        {
            // Capped below 1 deliberately: a rumour that is pure noise is
            // not a rumour, it is a lie, and the teller would know.
            var s = Talkative();

            RumourMill.AgeAll(s, 100_000f);

            foreach (var r in s.Rumours)
                Assert.True(r.Distortion < 1.0f);
        }

        [Fact]
        public void No_time_passing_bends_nothing()
        {
            var s = Talkative();
            var before = s.Rumours[0].Distortion;

            RumourMill.AgeAll(s, 0f);
            RumourMill.AgeAll(s, -5f);

            Assert.Equal(before, s.Rumours[0].Distortion);
        }

        [Fact]
        public void Buying_the_drink_costs_the_coin()
        {
            var s = Talkative();
            var before = s.Coin;

            var r = RumourMill.BuyDrink(s);

            Assert.True(r.Paid);
            Assert.True(r.Found);
            Assert.True(s.Coin < before);
        }

        [Fact]
        public void An_empty_purse_buys_no_talk_and_spends_nothing()
        {
            var s = Talkative();
            s.Coin = 0;

            var r = RumourMill.BuyDrink(s);

            Assert.False(r.Paid);
            Assert.Equal(0, s.Coin);
        }

        [Fact]
        public void The_free_search_costs_nothing()
        {
            // Asking around is free; buying the drink is what gets you the
            // good stuff. Only the second one is binding (L49).
            var s = Talkative();
            var before = s.Coin;

            RumourMill.Search(s);

            Assert.Equal(before, s.Coin);
        }
    }
}
