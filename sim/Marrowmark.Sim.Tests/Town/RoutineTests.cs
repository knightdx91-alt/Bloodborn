using System.Collections.Generic;
using Marrowmark.Sim.Town;
using Xunit;

namespace Marrowmark.Sim.Tests.Town
{
    /// <summary>
    /// A town is alive when it has a life that does not depend on you.
    /// These hold the awkward half of that: midnight.
    /// </summary>
    public class RoutineTests
    {
        private static Routine Smith() => new Routine
        {
            NpcId = "odo",
            Fallback = "home",
            Postings =
            {
                new Posting { Place = "forge", From = 6f, To = 19f },
                new Posting { Place = "inn", From = 19f, To = 22f },
            },
        };

        private static Routine Innkeeper() => new Routine
        {
            NpcId = "mara",
            Fallback = "home",
            Postings =
            {
                // Awake when everyone else is not: 16:00 through 02:00.
                new Posting { Place = "inn", From = 16f, To = 2f },
            },
        };

        [Fact]
        public void The_smith_is_at_his_forge_by_day()
        {
            Assert.Equal("forge", TownRoutine.PlaceFor(Smith(), 9f));
            Assert.Equal("forge", TownRoutine.PlaceFor(Smith(), 18.9f));
        }

        [Fact]
        public void And_in_the_inn_in_the_evening()
        {
            Assert.Equal("inn", TownRoutine.PlaceFor(Smith(), 20f));
        }

        [Fact]
        public void And_home_when_nothing_covers_the_hour()
        {
            Assert.Equal("home", TownRoutine.PlaceFor(Smith(), 3f));
            Assert.Equal("home", TownRoutine.PlaceFor(Smith(), 23f));
        }

        [Fact]
        public void A_posting_that_wraps_midnight_covers_both_sides_of_it()
        {
            // The case that breaks naive from<=hour<to comparisons, and
            // the case every innkeeper needs.
            Assert.Equal("inn", TownRoutine.PlaceFor(Innkeeper(), 23f));
            Assert.Equal("inn", TownRoutine.PlaceFor(Innkeeper(), 0.5f));
            Assert.Equal("inn", TownRoutine.PlaceFor(Innkeeper(), 1.9f));
            Assert.Equal("home", TownRoutine.PlaceFor(Innkeeper(), 3f));
            Assert.Equal("home", TownRoutine.PlaceFor(Innkeeper(), 15f));
        }

        [Fact]
        public void An_hour_past_the_end_of_the_dial_wraps_rather_than_falling_through()
        {
            // A clock handing over 24.5 instead of 0.5 must not silently
            // send everybody home.
            Assert.Equal("inn", TownRoutine.PlaceFor(Innkeeper(), 24.5f));
            Assert.Equal("forge", TownRoutine.PlaceFor(Smith(), 30f));
        }

        [Fact]
        public void The_first_posting_that_covers_the_hour_wins()
        {
            var greedy = new Routine
            {
                NpcId = "x",
                Postings =
                {
                    new Posting { Place = "first", From = 8f, To = 12f },
                    new Posting { Place = "second", From = 9f, To = 11f },
                },
            };
            Assert.Equal("first", TownRoutine.PlaceFor(greedy, 10f));
        }

        [Fact]
        public void Only_the_people_whose_place_changed_are_moving()
        {
            var town = new List<Routine> { Smith(), Innkeeper() };

            // 18:00 → 20:00: the smith leaves the forge for the inn.
            // Mara is already in the inn and must NOT be re-walked there.
            var moving = TownRoutine.Moving(town, 18f, 20f);
            Assert.Contains("odo", moving);
            Assert.DoesNotContain("mara", moving);
        }

        [Fact]
        public void Nobody_is_moving_when_the_hour_barely_changes()
        {
            var town = new List<Routine> { Smith(), Innkeeper() };
            Assert.Empty(TownRoutine.Moving(town, 9f, 9.01f));
        }

        [Fact]
        public void A_person_with_no_routine_is_simply_at_home()
        {
            Assert.Equal("home", TownRoutine.PlaceFor((Routine)null, 12f));
            Assert.Equal("home", TownRoutine.PlaceFor(new List<Routine>(), "nobody", 12f));
        }

        [Fact]
        public void The_town_wakes_and_sleeps()
        {
            Assert.False(TownRoutine.Waking(3f));
            Assert.True(TownRoutine.Waking(9f));
            Assert.True(TownRoutine.Waking(21.9f));
            Assert.False(TownRoutine.Waking(23f));
        }
    }
}
