using System.Linq;
using Marrowmark.Sim.Economy;
using Xunit;

namespace Marrowmark.Sim.Tests.Economy
{
    /// <summary>
    /// economy.md §3: markets are local, goods must travel, and the price
    /// spread between towns is a profession.
    /// </summary>
    public class MarketTests
    {
        private static Market Hammarsted()
        {
            var m = new Market("Hammarsted");
            m.Stock("iron", stock: 200, demand: 50, baseValue: 10);   // iron country
            m.Stock("ale", stock: 5, demand: 40, baseValue: 4);
            return m;
        }

        private static Market Greywater()
        {
            var m = new Market("Greywater");
            m.Stock("iron", stock: 5, demand: 50, baseValue: 10);     // none to be had
            m.Stock("ale", stock: 100, demand: 40, baseValue: 4);
            return m;
        }

        [Fact]
        public void The_board_lists_only_what_is_warehoused_here()
        {
            var m = Hammarsted();
            m.Stock("silk", stock: 0, demand: 10, baseValue: 30);

            Assert.DoesNotContain(m.Board(), g => g.Good == "silk");
            Assert.Equal(0, new Market("nowhere").PriceOf("iron"));
        }

        [Fact]
        public void Scarce_is_dear_and_glutted_is_cheap()
        {
            Assert.True(Greywater().PriceOf("iron") > Hammarsted().PriceOf("iron"));
            Assert.True(Hammarsted().PriceOf("ale") > Greywater().PriceOf("ale"));
        }

        [Fact]
        public void Prices_are_bounded_both_ends()
        {
            var p = MarketProfile.Default;
            var glut = new Market("glut"); glut.Stock("iron", 1_000_000, 1, 10);
            var famine = new Market("famine"); famine.Stock("iron", 0, 1_000_000, 10);

            Assert.Equal((int)System.Math.Round(10 * p.FloorMultiplier), glut.PriceOf("iron"));
            Assert.Equal((int)System.Math.Round(10 * p.CeilingMultiplier), famine.PriceOf("iron"));
        }

        [Fact]
        public void Selling_into_a_market_lowers_its_price_and_buying_raises_it()
        {
            var m = Greywater();
            var before = m.PriceOf("iron");
            var cargo = new Cargo(); cargo.Add("iron", 20, 1f);

            m.Sell("iron", 20, cargo, new Purse());
            Assert.True(m.PriceOf("iron") < before);

            var after = m.PriceOf("iron");
            m.Buy("iron", 20, new Purse(10_000), new Cargo(), 1f);
            Assert.True(m.PriceOf("iron") > after);
        }

        [Fact]
        public void A_buyer_stops_when_the_coin_runs_out_and_keeps_what_they_paid_for()
        {
            var m = Hammarsted();
            var purse = new Purse(m.PriceOf("iron") * 3 + 1);
            var cargo = new Cargo();

            var bought = m.Buy("iron", 10, purse, cargo, 1f);

            Assert.True(bought >= 3 && bought < 10);
            Assert.Equal(bought, cargo.QuantityOf("iron"));
            Assert.True(purse.Coin < m.PriceOf("iron"));
        }

        [Fact]
        public void You_cannot_sell_what_you_are_not_carrying()
        {
            var m = Greywater();
            var paid = m.Sell("iron", 5, new Cargo(), new Purse());
            Assert.Equal(0, paid);
        }

        [Fact]
        public void The_spread_is_a_profession_and_working_it_narrows_it()
        {
            // Buy where it is cheap, carry it, sell where it is dear. The
            // trip pays, and the two towns agree a little more afterwards.
            var h = Hammarsted();
            var g = Greywater();
            var purse = new Purse(500);
            var cargo = new Cargo();
            var spreadBefore = g.PriceOf("iron") - h.PriceOf("iron");

            var bought = h.Buy("iron", 20, purse, cargo, 1f);
            var spent = 500 - purse.Coin;
            var earned = g.Sell("iron", bought, cargo, purse);

            Assert.True(earned > spent, $"spent {spent}, earned {earned}");
            Assert.True(g.PriceOf("iron") - h.PriceOf("iron") < spreadBefore);
        }
    }
}
