using Marrowmark.Sim.Town;
using Xunit;

namespace Marrowmark.Sim.Tests.Town
{
    /// <summary>
    /// lore.md §3's shrine stone, which is also the respawn point.
    /// onboarding.md §3 teaches the death ladder from its bottom rung, and
    /// a toll you never feel teaches nothing.
    /// </summary>
    public class ShrineTests
    {
        [Fact]
        public void The_stone_keeps_what_it_is_owed()
        {
            var s = new TownState { Coin = 12 };

            var paid = Shrine.Respawn(s);

            Assert.Equal(TownProfile.Default.ShrineToll, paid);
            Assert.Equal(12 - paid, s.Coin);
            Assert.Equal(1, s.Respawns);
        }

        [Fact]
        public void Poverty_never_blocks_coming_back()
        {
            // L17's ordinary death is a cost, never a wall. A player who
            // cannot pay still gets up; the unpaid part is remembered in
            // the count instead of becoming a debt or a refusal.
            var s = new TownState { Coin = 1 };

            var paid = Shrine.Respawn(s);

            Assert.Equal(1, paid);
            Assert.Equal(0, s.Coin);
            Assert.Equal(1, s.Respawns);
        }

        [Fact]
        public void A_pauper_still_rises()
        {
            var s = new TownState { Coin = 0 };

            Assert.Equal(0, Shrine.Respawn(s));
            Assert.Equal(0, s.Coin);
            Assert.Equal(1, s.Respawns);
        }

        [Fact]
        public void Coin_never_goes_negative()
        {
            var s = new TownState { Coin = 3 };

            for (var i = 0; i < 10; i++) Shrine.Respawn(s);

            Assert.Equal(0, s.Coin);
            Assert.Equal(10, s.Respawns);
        }

        [Fact]
        public void The_count_remembers_every_death()
        {
            var s = new TownState { Coin = 1000 };

            for (var i = 0; i < 5; i++) Shrine.Respawn(s);

            Assert.Equal(5, s.Respawns);
            Assert.Equal(TownProfile.Default.ShrineToll, s.LastTollPaid);
        }
    }
}
