using System;
using System.Collections.Generic;
using System.Linq;

namespace Marrowmark.Sim.Economy
{
    /// <summary>What a town knows about one good: how much it has, how
    /// much it wants, what it is worth in the abstract.</summary>
    public sealed class MarketGood
    {
        public string Good = "";

        /// <summary>Physically in this town's warehouse (economy.md §5).</summary>
        public int Stock;

        /// <summary>How much the town would use. Placeholder for the
        /// ecology and the population behind it; a tuning knob today.</summary>
        public int Demand;

        /// <summary>Pennies per unit when stock meets demand exactly.</summary>
        public int BaseValue;
    }

    /// <summary>
    /// One town's market board (economy.md §3): it lists only goods
    /// physically warehoused here, and its prices are its own. There is no
    /// global auction house, so two towns can disagree about what iron is
    /// worth, and that disagreement is the caravaner's living.
    ///
    /// Price discovery is the simplest thing that moves the right way:
    /// scarce is dear, glutted is cheap, bounded both ends. A caravan
    /// selling into a short market lowers its price with every cart,
    /// which is what makes arbitrage a trade rather than a faucet.
    /// </summary>
    public sealed class Market
    {
        private readonly MarketProfile _p;
        private readonly List<MarketGood> _goods = new List<MarketGood>();

        public Market(string town, MarketProfile profile)
        {
            Town = town;
            _p = profile;
        }

        public Market(string town) : this(town, MarketProfile.Default) { }

        public string Town { get; }

        public MarketGood? Entry(string good) => _goods.FirstOrDefault(g => g.Good == good);

        /// <summary>Seed what this town has and wants. Content's door.</summary>
        public MarketGood Stock(string good, int stock, int demand, int baseValue)
        {
            var e = Entry(good);
            if (e == null)
            {
                e = new MarketGood { Good = good };
                _goods.Add(e);
            }
            e.Stock = Math.Max(0, stock);
            e.Demand = Math.Max(1, demand);
            e.BaseValue = Math.Max(1, baseValue);
            return e;
        }

        /// <summary>The board: what is actually here. Nothing at zero.</summary>
        public IEnumerable<MarketGood> Board() => _goods.Where(g => g.Stock > 0);

        /// <summary>
        /// What a unit fetches here, right now. Demand against stock,
        /// raised to the elasticity, bounded by the floor and ceiling.
        /// </summary>
        public int PriceOf(string good)
        {
            var e = Entry(good);
            if (e == null) return 0;
            var ratio = e.Demand / (float)(e.Stock + 1);
            var mult = (float)Math.Pow(ratio, _p.Elasticity);
            if (mult < _p.FloorMultiplier) mult = _p.FloorMultiplier;
            if (mult > _p.CeilingMultiplier) mult = _p.CeilingMultiplier;
            return Math.Max(1, (int)Math.Round(e.BaseValue * mult));
        }

        /// <summary>
        /// Buy from the town, one unit at a time at the moving price,
        /// into the buyer's cargo. Stops when the coin or the stock runs
        /// out. Returns units bought.
        /// </summary>
        public int Buy(string good, int quantity, Purse buyer, Cargo into, float kgPerUnit)
        {
            var e = Entry(good);
            if (e == null || quantity <= 0) return 0;
            var bought = 0;
            while (bought < quantity && e.Stock > 0)
            {
                var price = PriceOf(good);
                if (!buyer.TrySink(price)) break;   // the town's coin is not modelled; it is a faucet's other end
                e.Stock--;
                into.Add(good, 1, kgPerUnit);
                bought++;
            }
            return bought;
        }

        /// <summary>
        /// Sell to the town out of cargo, one unit at a time at the
        /// moving price. Every cart sold lowers the next. Returns coin
        /// received.
        /// </summary>
        public int Sell(string good, int quantity, Cargo from, Purse seller)
        {
            var e = Entry(good);
            if (e == null || quantity <= 0) return 0;
            var paid = 0;
            while (quantity > 0 && from.QuantityOf(good) > 0)
            {
                var price = PriceOf(good);
                from.Remove(good, 1);
                e.Stock++;
                seller.Receive(price);
                paid += price;
                quantity--;
            }
            return paid;
        }

        /// <summary>Goods arriving from the road go into the warehouse.
        /// They are now here and nowhere else.</summary>
        public void Receive(Cargo cargo)
        {
            foreach (var line in cargo.Lines.ToList())
            {
                var e = Entry(line.Good) ?? Stock(line.Good, 0, 1, 1);
                e.Stock += line.Quantity;
            }
            cargo.TransferAll(new Cargo());
        }
    }
}
