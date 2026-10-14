using System.Collections.Generic;
using System.Linq;
using Marrowmark.Sim.Arena;
using Marrowmark.Sim.Economy;
using Marrowmark.Sim.Magic;
using Xunit;

namespace Marrowmark.Sim.Tests.Arena
{
    /// <summary>
    /// L6 and brainstorm.md §4: PvP and PvM brackets, betting where the
    /// odds move with the money, no equipment loss, echo bouts, seasons,
    /// and arena fame feeding crafter fame. L35: the shadow book is for
    /// the awakened only.
    /// </summary>
    public class RingTests
    {
        private static readonly ArenaProfile P = ArenaProfile.Default;

        private sealed class F
        {
            public Ring Ring = new Ring(P);
            public Purse Book = new Purse();
            public Dictionary<string, Purse> Purses = new Dictionary<string, Purse>
            {
                ["Marta"] = new Purse(100), ["Odo"] = new Purse(100), ["Chris"] = new Purse(100),
            };
            public Bout Bout;

            public F()
            {
                Ring.LicenceHolder = "house-kettle";
                Bout = Ring.Card(BoutKind.Duel, new[] { "Ban", "Hal" }, 10f);
            }

            public WagerResult Bet(string who, string on, int stake, bool awakened = false) =>
                Ring.Wager(Bout, who, Purses[who], on, stake, awakened);
        }

        [Fact]
        public void The_odds_move_with_the_money()
        {
            var f = new F();
            f.Bet("Marta", "Ban", 10);
            f.Bet("Odo", "Hal", 10);
            var even = f.Bout.OddsOn("Ban");

            f.Bet("Chris", "Ban", 30);
            Assert.True(f.Bout.OddsOn("Ban") < even);     // the favourite shortens
            Assert.True(f.Bout.OddsOn("Hal") > even);     // the other lengthens
        }

        [Fact]
        public void Winners_share_the_pool_in_proportion_and_the_rake_is_a_sink()
        {
            var f = new F();
            f.Bet("Marta", "Ban", 10);
            f.Bet("Chris", "Ban", 30);
            f.Bet("Odo", "Hal", 60);                        // pool 100

            var rake = f.Ring.Result(f.Bout, "Ban", f.Book, f.Purses, 10f);

            Assert.Equal((int)(100 * P.RakeFraction), rake);
            Assert.Equal(rake, f.Book.Coin);
            var toShare = 100 - rake;
            Assert.Equal(90 + toShare / 4, f.Purses["Marta"].Coin);       // 10 of 40 backed Ban
            Assert.Equal(70 + toShare - toShare / 4, f.Purses["Chris"].Coin);
            Assert.Equal(40, f.Purses["Odo"].Coin);                        // lost the stake
            Assert.Equal(300, f.Purses.Values.Sum(p => p.Coin) + f.Book.Coin);
        }

        [Fact]
        public void Coin_is_conserved_less_the_rake()
        {
            var f = new F();
            f.Bet("Marta", "Ban", 25);
            f.Bet("Chris", "Hal", 35);
            f.Bet("Odo", "Hal", 15);
            var before = f.Purses.Values.Sum(p => p.Coin) + f.Book.Coin + f.Bout.Pool;

            f.Ring.Result(f.Bout, "Hal", f.Book, f.Purses, 10f);

            Assert.Equal(before, f.Purses.Values.Sum(p => p.Coin) + f.Book.Coin);
        }

        [Fact]
        public void No_wagers_after_the_bell()
        {
            var f = new F();
            f.Bout.Begin();
            Assert.Equal(WagerResult.BoutStarted, f.Bet("Marta", "Ban", 10));
            Assert.Equal(100, f.Purses["Marta"].Coin);
        }

        [Fact]
        public void You_cannot_back_someone_who_is_not_fighting_or_stake_what_you_lack()
        {
            var f = new F();
            Assert.Equal(WagerResult.NoSuchContender, f.Bet("Marta", "Vex", 10));
            Assert.Equal(WagerResult.CannotPay, f.Bet("Marta", "Ban", 1000));
            Assert.Equal(100, f.Purses["Marta"].Coin);
        }

        [Fact]
        public void A_licensed_book_needs_the_licence()
        {
            // Bookmaking licences are a purchasable right.
            var f = new F();
            f.Ring.LicenceHolder = "";
            Assert.Equal(WagerResult.NoLicence, f.Bet("Marta", "Ban", 10));
        }

        [Fact]
        public void The_shadow_book_takes_wagers_from_the_awakened_only()
        {
            // L35.
            var f = new F();
            var veiled = f.Ring.Veiled(BoutKind.SuccessionTrial, new[] { "A", "B" }, 72f);
            Assert.Equal(WagerResult.NotAwakened, f.Ring.Wager(veiled, "Marta", f.Purses["Marta"], "A", 10, awakened: false));
            Assert.Equal(WagerResult.Placed, f.Ring.Wager(veiled, "Marta", f.Purses["Marta"], "A", 10, awakened: true));
            Assert.True(veiled.Rake > f.Bout.Rake);          // and it charges more
        }

        [Fact]
        public void The_trial_is_never_on_the_public_card()
        {
            var f = new F();
            Assert.Throws<System.ArgumentException>(() => f.Ring.Card(BoutKind.SuccessionTrial, new[] { "A", "B" }, 1f));
        }

        [Fact]
        public void Nothing_is_dropped_on_the_sand()
        {
            Assert.False(new F().Bout.StakesEquipment);
        }

        [Fact]
        public void A_result_writes_the_table_and_the_table_clears_each_season()
        {
            var f = new F();
            f.Ring.Result(f.Bout, "Ban", f.Book, f.Purses, 10f);
            var second = f.Ring.Card(BoutKind.Duel, new[] { "Ban", "Hal" }, 20f);
            f.Ring.Result(second, "Ban", f.Book, f.Purses, 20f);

            var top = f.Ring.Table().First();
            Assert.Equal("Ban", top.Fighter);
            Assert.Equal(2, top.Wins);
            Assert.Equal(2, f.Ring.Table().Single(s => s.Fighter == "Hal").Losses);

            var next = f.Ring.Card(BoutKind.Duel, new[] { "Ban", "Hal" }, P.SeasonHours + 1f);
            f.Ring.Result(next, "Hal", f.Book, f.Purses, P.SeasonHours + 1f);
            Assert.Equal(1, f.Ring.Table().Single(s => s.Fighter == "Hal").Wins);
            Assert.Equal(0, f.Ring.Table().Single(s => s.Fighter == "Hal").Losses);   // cleared
        }

        [Fact]
        public void Arena_fame_feeds_the_mark_on_the_winning_blade()
        {
            var f = new F();
            f.Ring.Result(f.Bout, "Ban", f.Book, f.Purses, 10f, winnersWeaponMark: "Odo");
            Assert.Equal(1, f.Ring.FameOf("Odo"));
            Assert.Equal(0, f.Ring.FameOf("Pell"));

            var next = f.Ring.Card(BoutKind.Duel, new[] { "Ban", "Hal" }, P.SeasonHours + 1f);
            f.Ring.Result(next, "Ban", f.Book, f.Purses, P.SeasonHours + 1f, "Odo");
            Assert.Equal(2, f.Ring.FameOf("Odo"));        // permanent; the table is not
        }

        [Fact]
        public void A_bout_settles_once()
        {
            var f = new F();
            f.Bet("Marta", "Ban", 10);
            f.Ring.Result(f.Bout, "Ban", f.Book, f.Purses, 10f);
            var after = f.Purses["Marta"].Coin;
            f.Ring.Result(f.Bout, "Hal", f.Book, f.Purses, 11f);
            Assert.Equal("Ban", f.Bout.Winner);
            Assert.Equal(after, f.Purses["Marta"].Coin);
        }

        [Fact]
        public void An_echo_does_not_cast_in_public_before_the_unveiling()
        {
            // content.md §5 / feasibility-review.md §4.3: or the arena
            // itself breaks the myth.
            Assert.False(Ring.EchoMayCast(Epoch.Myth, shadow: false));
            Assert.False(Ring.EchoMayCast(Epoch.Whispers, shadow: false));
            Assert.True(Ring.EchoMayCast(Epoch.Unveiling, shadow: false));
            Assert.True(Ring.EchoMayCast(Epoch.Myth, shadow: true));
        }
    }
}
