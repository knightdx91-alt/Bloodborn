using System;
using System.Collections.Generic;
using System.Linq;

namespace Marrowmark.Sim.Economy
{
    /// <summary>A line on the shelf.</summary>
    public sealed class StockLine
    {
        public string Good = "";
        public int Quantity;

        /// <summary>Pennies per unit. Zero means UNPRICED: on the shelf
        /// but not for sale, because nobody has said what it is worth.</summary>
        public int AskPrice;

        /// <summary>"Never sell the masterwork blade" (economy.md §2). A
        /// held line is on display and not for sale at any price.</summary>
        public bool Held;

        public bool ForSale => !Held && AskPrice > 0 && Quantity > 0;
    }

    /// <summary>"Buy iron under X" — what staff may buy on the owner's
    /// behalf while the owner is away.</summary>
    public sealed class StandingOrder
    {
        public string Good = "";

        /// <summary>Staff pay at most this per unit.</summary>
        public int MaxUnitPrice;

        /// <summary>Stop buying once the shelf holds this many.</summary>
        public int WantUpTo;
    }

    public enum SaleResult
    {
        Sold,
        /// <summary>Nobody is minding the counter.</summary>
        Closed,
        NoSuchGood,
        /// <summary>On the shelf, no price on it.</summary>
        Unpriced,
        /// <summary>The owner said never.</summary>
        Held,
        NotEnoughStock,
        BuyerCannotPay,
    }

    public enum PurchaseResult
    {
        Bought,
        Closed,
        /// <summary>No standing order covers this good, and the owner is
        /// not here to decide.</summary>
        NoOrder,
        /// <summary>Over the ceiling the owner set.</summary>
        TooDear,
        /// <summary>The shelf already holds what the order wants.</summary>
        OrderFilled,
        TillCannotPay,
    }

    public sealed class Sale
    {
        public SaleResult Result;
        public int Quantity;
        public int Paid;
    }

    public sealed class Purchase
    {
        public PurchaseResult Result;
        public int Quantity;
        public int Paid;
    }

    /// <summary>
    /// A player's shop (economy.md §2, L26): the primary way goods reach
    /// buyers, run from a rented or owned building (L5).
    ///
    /// Two things make it a shop rather than an inventory with prices:
    ///
    /// **It sells while the owner is away**, through NPC staff who follow
    /// the owner's standing orders and never improvise. Staff sell at the
    /// prices set, buy under the ceilings set, and will not price a thing
    /// themselves — stock they buy lands on the shelf unpriced and waits
    /// for the owner. That is what makes the companion app (L31)
    /// "read-and-manage only" true in the rules rather than in a policy:
    /// everything a phone can do to a shop is a thing staff could have
    /// been told, and nothing it does needs a body in the room.
    ///
    /// **It costs coin to keep open.** Wages and rent fall due daily from
    /// the till, owner present or not. Staff unpaid for long enough leave,
    /// and a shop with no staff and no owner is closed. economy.md §4
    /// wants these sinks and wants them non-negotiable; this is where
    /// they are charged.
    ///
    /// What it does not model: the building itself, the shopfront, the
    /// commission book, and whose inventory the goods came from. Goods
    /// are physical (economy.md §3), so restocking means the owner stood
    /// here with them; that is asserted, not simulated.
    /// </summary>
    public sealed class Shop
    {
        private readonly ShopProfile _p;
        private readonly List<StockLine> _stock = new List<StockLine>();
        private readonly List<StandingOrder> _orders = new List<StandingOrder>();
        private float _hoursIntoDay;

        public Shop(string owner, ShopProfile profile)
        {
            Owner = owner;
            _p = profile;
            Till = new Purse();
            Ledger = new Ledger();
        }

        public Shop(string owner) : this(owner, ShopProfile.Default) { }

        public string Owner { get; }
        public Purse Till { get; }
        public Ledger Ledger { get; }

        /// <summary>Is the owner standing in the shop. Only the owner can
        /// restock from their own hands or buy outside a standing order.</summary>
        public bool OwnerPresent;

        /// <summary>Is an NPC on the counter. Hired by the owner; they
        /// leave on their own if unpaid.</summary>
        public bool Staffed { get; private set; }

        /// <summary>Consecutive days the staff went unpaid.</summary>
        public int UnpaidWageDays { get; private set; }

        /// <summary>Rent owed and not paid, in pennies. What the landlord
        /// does about it is L5's business.</summary>
        public int RentArrears { get; private set; }

        /// <summary>Somebody is at the counter.</summary>
        public bool Open => OwnerPresent || Staffed;

        public IReadOnlyList<StockLine> Stock => _stock;
        public IReadOnlyList<StandingOrder> Orders => _orders;

        public StockLine? Line(string good) => _stock.FirstOrDefault(l => l.Good == good);

        // ── Things the owner does, from anywhere (L31) ──────────────────

        /// <summary>Put a price on a line. Zero takes it off sale.</summary>
        public bool Price(string good, int askPrice)
        {
            var line = Line(good);
            if (line == null || askPrice < 0) return false;
            line.AskPrice = askPrice;
            return true;
        }

        /// <summary>"Never sell this."</summary>
        public bool Hold(string good)
        {
            var line = Line(good);
            if (line == null) return false;
            line.Held = true;
            return true;
        }

        public bool Release(string good)
        {
            var line = Line(good);
            if (line == null) return false;
            line.Held = false;
            return true;
        }

        /// <summary>Tell the staff what to buy and what to pay. One order
        /// per good; a new one replaces the old.</summary>
        public void PlaceOrder(string good, int maxUnitPrice, int wantUpTo)
        {
            _orders.RemoveAll(o => o.Good == good);
            if (maxUnitPrice <= 0 || wantUpTo <= 0) return;
            _orders.Add(new StandingOrder
                { Good = good, MaxUnitPrice = maxUnitPrice, WantUpTo = wantUpTo });
        }

        public void CancelOrder(string good) => _orders.RemoveAll(o => o.Good == good);

        /// <summary>Hire the counter hand. Wages start from the next day.</summary>
        public void HireStaff()
        {
            Staffed = true;
            UnpaidWageDays = 0;
        }

        public void DismissStaff() => Staffed = false;

        // ── Things that need a body in the room ─────────────────────────

        /// <summary>Owner puts goods from their own hands on the shelf. No
        /// coin moves: whatever these cost happened elsewhere.</summary>
        public bool Restock(string good, int quantity, int askPrice)
        {
            if (!OwnerPresent || quantity <= 0 || askPrice < 0) return false;
            AddStock(good, quantity, askPrice);
            return true;
        }

        /// <summary>Owner takes goods off the shelf and away.</summary>
        public bool Withdraw(string good, int quantity)
        {
            var line = Line(good);
            if (!OwnerPresent || line == null || quantity <= 0 || line.Quantity < quantity)
                return false;
            line.Quantity -= quantity;
            if (line.Quantity == 0) _stock.Remove(line);
            return true;
        }

        // ── Trade ───────────────────────────────────────────────────────

        /// <summary>A customer buys. Staff or owner, the rule is the same:
        /// the shelf price, the whole quantity or nothing.</summary>
        public Sale Sell(string good, int quantity, string buyer, Purse buyerPurse, float hour)
        {
            var sale = new Sale();
            var line = Line(good);

            if (!Open) { sale.Result = SaleResult.Closed; return sale; }
            if (line == null || quantity <= 0) { sale.Result = SaleResult.NoSuchGood; return sale; }
            if (line.Held) { sale.Result = SaleResult.Held; return sale; }
            if (line.AskPrice <= 0) { sale.Result = SaleResult.Unpriced; return sale; }
            if (line.Quantity < quantity) { sale.Result = SaleResult.NotEnoughStock; return sale; }

            var price = line.AskPrice * quantity;
            if (!buyerPurse.TryPay(Till, price))
            {
                sale.Result = SaleResult.BuyerCannotPay;
                return sale;
            }

            line.Quantity -= quantity;
            if (line.Quantity == 0) _stock.Remove(line);

            Ledger.Record(new LedgerEntry
            {
                Hour = hour, Kind = EntryKind.Sale, Good = good, Quantity = quantity,
                UnitPrice = line.AskPrice, Counterparty = buyer, Coin = price,
            });

            sale.Result = SaleResult.Sold;
            sale.Quantity = quantity;
            sale.Paid = price;
            return sale;
        }

        /// <summary>
        /// Somebody offers to sell the shop goods.
        ///
        /// With the owner present, the owner decides and this always buys
        /// what the till can afford, at the offered price, and prices the
        /// line at the ask given. With staff only, the standing order
        /// decides: under the ceiling, up to the quantity wanted, and the
        /// goods land UNPRICED, because staff do not set prices.
        /// </summary>
        public Purchase Buy(string good, int quantity, int unitPrice, string seller,
            Purse sellerPurse, float hour, int ownerAsk = 0)
        {
            var p = new Purchase();
            if (!Open) { p.Result = PurchaseResult.Closed; return p; }
            if (quantity <= 0 || unitPrice <= 0) { p.Result = PurchaseResult.NoOrder; return p; }

            int take;
            int ask;
            if (OwnerPresent)
            {
                take = quantity;
                ask = ownerAsk;
            }
            else
            {
                var order = _orders.FirstOrDefault(o => o.Good == good);
                if (order == null) { p.Result = PurchaseResult.NoOrder; return p; }
                if (unitPrice > order.MaxUnitPrice) { p.Result = PurchaseResult.TooDear; return p; }

                var holding = Line(good)?.Quantity ?? 0;
                var room = order.WantUpTo - holding;
                if (room <= 0) { p.Result = PurchaseResult.OrderFilled; return p; }
                take = Math.Min(quantity, room);
                ask = 0;
            }

            // Buy as much of it as the till can stand, never more.
            var affordable = Till.Coin / unitPrice;
            take = Math.Min(take, affordable);
            if (take <= 0) { p.Result = PurchaseResult.TillCannotPay; return p; }

            var cost = take * unitPrice;
            Till.TryPay(sellerPurse, cost);
            AddStock(good, take, ask);

            Ledger.Record(new LedgerEntry
            {
                Hour = hour, Kind = EntryKind.Purchase, Good = good, Quantity = take,
                UnitPrice = unitPrice, Counterparty = seller, Coin = -cost,
            });

            p.Result = PurchaseResult.Bought;
            p.Quantity = take;
            p.Paid = cost;
            return p;
        }

        // ── Time ────────────────────────────────────────────────────────

        /// <summary>
        /// Let the hours pass. Each day boundary charges wages and rent
        /// from the till, owner present or not. Wages that cannot be paid
        /// are counted against the staff's patience; rent that cannot be
        /// paid goes into arrears.
        /// </summary>
        public void Advance(float hours, float nowHour)
        {
            if (hours <= 0f) return;
            _hoursIntoDay += hours;
            while (_hoursIntoDay >= _p.HoursPerDay)
            {
                _hoursIntoDay -= _p.HoursPerDay;
                var at = nowHour - _hoursIntoDay;
                EndOfDay(at);
            }
        }

        private void EndOfDay(float hour)
        {
            if (Staffed)
            {
                if (Till.TrySink(_p.StaffWagePerDay))
                {
                    UnpaidWageDays = 0;
                    Ledger.Record(new LedgerEntry
                    {
                        Hour = hour, Kind = EntryKind.Wage, Quantity = 1,
                        UnitPrice = _p.StaffWagePerDay, Coin = -_p.StaffWagePerDay,
                    });
                }
                else
                {
                    UnpaidWageDays++;
                    if (UnpaidWageDays >= _p.StaffQuitAfterUnpaidDays)
                        Staffed = false;
                }
            }

            var owed = _p.RentPerDay + RentArrears;
            if (Till.TrySink(owed))
            {
                Ledger.Record(new LedgerEntry
                {
                    Hour = hour, Kind = EntryKind.Rent, Quantity = 1,
                    UnitPrice = owed, Coin = -owed,
                });
                RentArrears = 0;
            }
            else
            {
                RentArrears = owed;
            }
        }

        private void AddStock(string good, int quantity, int askPrice)
        {
            var line = Line(good);
            if (line == null)
            {
                _stock.Add(new StockLine { Good = good, Quantity = quantity, AskPrice = askPrice });
                return;
            }
            line.Quantity += quantity;
            // A price the owner gave now wins over whatever was there; an
            // unpriced delivery never erases a price that exists.
            if (askPrice > 0) line.AskPrice = askPrice;
        }
    }
}
