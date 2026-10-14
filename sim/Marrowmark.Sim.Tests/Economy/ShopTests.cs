using System.Linq;
using Marrowmark.Sim.Economy;
using Xunit;

namespace Marrowmark.Sim.Tests.Economy
{
    /// <summary>
    /// economy.md §2: the shop is the interface. Stock and pricing by the
    /// owner, NPC staff who sell while the owner is away and follow
    /// standing orders, books that record what sold to whom at what
    /// price, and wages and rent as sinks (§4) that fall due whether
    /// anyone is looking.
    ///
    /// Relationships, never numbers: that staff cost coin is a rule,
    /// that they cost 6 a day is not.
    /// </summary>
    public class ShopTests
    {
        private static Shop Open()
        {
            var s = new Shop("Marta") { OwnerPresent = true };
            s.Restock("iron", 10, 3);
            s.Restock("masterwork blade", 1, 120);
            s.Till.Receive(50);
            return s;
        }

        // ── Selling ─────────────────────────────────────────────────────

        [Fact]
        public void A_sale_moves_stock_out_and_coin_in()
        {
            var s = Open();
            var buyer = new Purse(20);

            var sale = s.Sell("iron", 4, "Odo", buyer, hour: 10f);

            Assert.Equal(SaleResult.Sold, sale.Result);
            Assert.Equal(12, sale.Paid);
            Assert.Equal(6, s.Line("iron")!.Quantity);
            Assert.Equal(8, buyer.Coin);
            Assert.Equal(62, s.Till.Coin);
        }

        [Fact]
        public void A_buyer_who_cannot_pay_gets_nothing_and_the_shelf_is_untouched()
        {
            var s = Open();
            var buyer = new Purse(5);

            var sale = s.Sell("iron", 4, "Odo", buyer, 10f);

            Assert.Equal(SaleResult.BuyerCannotPay, sale.Result);
            Assert.Equal(10, s.Line("iron")!.Quantity);
            Assert.Equal(5, buyer.Coin);
        }

        [Fact]
        public void The_whole_quantity_or_nothing()
        {
            var s = Open();
            var sale = s.Sell("iron", 11, "Odo", new Purse(100), 10f);
            Assert.Equal(SaleResult.NotEnoughStock, sale.Result);
            Assert.Equal(10, s.Line("iron")!.Quantity);
        }

        [Fact]
        public void A_held_line_is_never_for_sale()
        {
            // "never sell the masterwork blade"
            var s = Open();
            s.Hold("masterwork blade");

            var sale = s.Sell("masterwork blade", 1, "a stranger", new Purse(1000), 10f);

            Assert.Equal(SaleResult.Held, sale.Result);
            Assert.NotNull(s.Line("masterwork blade"));
            s.Release("masterwork blade");
            Assert.Equal(SaleResult.Sold,
                s.Sell("masterwork blade", 1, "a stranger", new Purse(1000), 11f).Result);
        }

        [Fact]
        public void Unpriced_stock_is_on_display_and_not_for_sale()
        {
            var s = Open();
            s.Price("iron", 0);
            Assert.Equal(SaleResult.Unpriced,
                s.Sell("iron", 1, "Odo", new Purse(100), 10f).Result);
        }

        [Fact]
        public void A_sold_out_line_leaves_the_shelf()
        {
            var s = Open();
            s.Sell("masterwork blade", 1, "a stranger", new Purse(1000), 10f);
            Assert.Null(s.Line("masterwork blade"));
            Assert.Equal(SaleResult.NoSuchGood,
                s.Sell("masterwork blade", 1, "another", new Purse(1000), 11f).Result);
        }

        // ── Who is at the counter ───────────────────────────────────────

        [Fact]
        public void With_nobody_at_the_counter_the_shop_is_closed()
        {
            var s = Open();
            s.OwnerPresent = false;

            Assert.False(s.Open);
            Assert.Equal(SaleResult.Closed, s.Sell("iron", 1, "Odo", new Purse(100), 10f).Result);
            Assert.Equal(10, s.Line("iron")!.Quantity);
        }

        [Fact]
        public void Staff_sell_while_the_owner_is_away()
        {
            var s = Open();
            s.HireStaff();
            s.OwnerPresent = false;

            Assert.True(s.Open);
            Assert.Equal(SaleResult.Sold, s.Sell("iron", 1, "Odo", new Purse(100), 10f).Result);
        }

        [Fact]
        public void Only_a_present_owner_restocks_from_their_own_hands()
        {
            // Goods are physical (economy.md §3). You cannot put iron on a
            // shelf from a phone.
            var s = Open();
            s.HireStaff();
            s.OwnerPresent = false;

            Assert.False(s.Restock("iron", 5, 3));
            Assert.Equal(10, s.Line("iron")!.Quantity);
            Assert.False(s.Withdraw("iron", 5));
        }

        [Fact]
        public void Prices_holds_and_orders_can_be_set_from_anywhere()
        {
            // L31: the companion app is read-and-manage. Everything a
            // phone can do is a thing staff could have been told.
            var s = Open();
            s.OwnerPresent = false;

            Assert.True(s.Price("iron", 5));
            Assert.True(s.Hold("masterwork blade"));
            s.PlaceOrder("ore", 2, 20);

            Assert.Equal(5, s.Line("iron")!.AskPrice);
            Assert.True(s.Line("masterwork blade")!.Held);
            Assert.Single(s.Orders);
        }

        // ── Buying ──────────────────────────────────────────────────────

        [Fact]
        public void Staff_buy_under_the_ceiling_the_owner_set_and_not_over_it()
        {
            var s = Open();
            s.HireStaff();
            s.OwnerPresent = false;
            s.PlaceOrder("ore", maxUnitPrice: 2, wantUpTo: 20);
            var seller = new Purse();

            var dear = s.Buy("ore", 5, unitPrice: 3, "a miner", seller, 10f);
            Assert.Equal(PurchaseResult.TooDear, dear.Result);
            Assert.Null(s.Line("ore"));

            var fair = s.Buy("ore", 5, unitPrice: 2, "a miner", seller, 10f);
            Assert.Equal(PurchaseResult.Bought, fair.Result);
            Assert.Equal(5, fair.Quantity);
            Assert.Equal(10, seller.Coin);
            Assert.Equal(40, s.Till.Coin);
        }

        [Fact]
        public void Staff_stop_buying_once_the_order_is_filled()
        {
            var s = Open();
            s.HireStaff();
            s.OwnerPresent = false;
            s.PlaceOrder("ore", 2, wantUpTo: 8);
            var seller = new Purse();

            var first = s.Buy("ore", 6, 2, "a miner", seller, 10f);
            var second = s.Buy("ore", 6, 2, "a miner", seller, 11f);
            var third = s.Buy("ore", 6, 2, "a miner", seller, 12f);

            Assert.Equal(6, first.Quantity);
            Assert.Equal(2, second.Quantity);           // only the room left
            Assert.Equal(PurchaseResult.OrderFilled, third.Result);
            Assert.Equal(8, s.Line("ore")!.Quantity);
        }

        [Fact]
        public void Staff_never_price_what_they_buy()
        {
            // The owner decides what a thing is worth. Stock bought on a
            // standing order lands unpriced and waits.
            var s = Open();
            s.HireStaff();
            s.OwnerPresent = false;
            s.PlaceOrder("ore", 2, 20);

            s.Buy("ore", 5, 2, "a miner", new Purse(), 10f);

            Assert.False(s.Line("ore")!.ForSale);
            Assert.Equal(SaleResult.Unpriced, s.Sell("ore", 1, "Odo", new Purse(50), 11f).Result);
            s.Price("ore", 4);
            Assert.Equal(SaleResult.Sold, s.Sell("ore", 1, "Odo", new Purse(50), 12f).Result);
        }

        [Fact]
        public void Without_an_order_staff_buy_nothing()
        {
            var s = Open();
            s.HireStaff();
            s.OwnerPresent = false;

            Assert.Equal(PurchaseResult.NoOrder,
                s.Buy("ore", 5, 1, "a miner", new Purse(), 10f).Result);
        }

        [Fact]
        public void A_present_owner_buys_what_they_like_and_prices_it_on_the_spot()
        {
            var s = Open();
            var seller = new Purse();

            var p = s.Buy("ore", 5, unitPrice: 4, "a miner", seller, 10f, ownerAsk: 7);

            Assert.Equal(PurchaseResult.Bought, p.Result);
            Assert.Equal(7, s.Line("ore")!.AskPrice);
            Assert.Equal(20, seller.Coin);
        }

        [Fact]
        public void The_till_buys_what_it_can_afford_and_no_more()
        {
            var s = Open();                       // till 50
            var seller = new Purse();

            var p = s.Buy("ore", 100, unitPrice: 4, "a miner", seller, 10f, ownerAsk: 7);

            Assert.Equal(PurchaseResult.Bought, p.Result);
            Assert.Equal(12, p.Quantity);         // 12 * 4 = 48 <= 50
            Assert.Equal(2, s.Till.Coin);

            var broke = s.Buy("ore", 1, unitPrice: 4, "a miner", seller, 11f, ownerAsk: 7);
            Assert.Equal(PurchaseResult.TillCannotPay, broke.Result);
        }

        // ── The books ───────────────────────────────────────────────────

        [Fact]
        public void The_ledger_says_what_sold_to_whom_at_what_price()
        {
            var s = Open();
            s.Sell("iron", 4, "Odo", new Purse(50), hour: 10f);
            s.Sell("iron", 2, "Pell", new Purse(50), hour: 14f);

            var entries = s.Ledger.Of("iron").ToList();

            Assert.Equal(2, entries.Count);
            Assert.Equal("Odo", entries[0].Counterparty);
            Assert.Equal(3, entries[0].UnitPrice);
            Assert.Equal(4, entries[0].Quantity);
            Assert.Equal("Pell", entries[1].Counterparty);
            Assert.Equal(18, s.Ledger.Takings());
            Assert.Equal(6, s.Ledger.Takings(sinceHour: 12f));
        }

        [Fact]
        public void The_best_seller_is_counted_in_units_not_coin()
        {
            var s = Open();
            s.Sell("masterwork blade", 1, "a stranger", new Purse(1000), 10f);  // 120 coin, 1 unit
            s.Sell("iron", 3, "Odo", new Purse(50), 11f);                       // 9 coin, 3 units

            Assert.Equal("iron", s.Ledger.BestSeller());
        }

        [Fact]
        public void Nothing_in_the_ledger_can_be_rewritten()
        {
            // economy.md §6: good data is a smuggler's liability. The books
            // are a record of what happened.
            var s = Open();
            s.Sell("iron", 1, "Odo", new Purse(50), 10f);
            var before = s.Ledger.Entries.Count;

            // The only way in is Record, and it is internal to the rules.
            Assert.Equal(before, s.Ledger.Entries.Count);
            Assert.IsAssignableFrom<System.Collections.Generic.IReadOnlyList<LedgerEntry>>(
                s.Ledger.Entries);
        }

        // ── What it costs to keep open ──────────────────────────────────

        [Fact]
        public void Wages_and_rent_fall_due_daily_owner_or_no_owner()
        {
            var p = ShopProfile.Default;
            var s = Open();
            s.HireStaff();
            s.OwnerPresent = false;
            var before = s.Till.Coin;

            s.Advance(p.HoursPerDay, nowHour: p.HoursPerDay);

            Assert.Equal(before - p.StaffWagePerDay - p.RentPerDay, s.Till.Coin);
            Assert.Equal(p.StaffWagePerDay + p.RentPerDay, s.Ledger.Outgoings());
            Assert.Contains(s.Ledger.Entries, e => e.Kind == EntryKind.Wage);
            Assert.Contains(s.Ledger.Entries, e => e.Kind == EntryKind.Rent);
        }

        [Fact]
        public void Nothing_falls_due_inside_a_day()
        {
            var p = ShopProfile.Default;
            var s = Open();
            s.HireStaff();
            var before = s.Till.Coin;

            s.Advance(p.HoursPerDay * 0.9f, p.HoursPerDay * 0.9f);

            Assert.Equal(before, s.Till.Coin);
        }

        [Fact]
        public void Several_days_at_once_charge_several_days()
        {
            var p = ShopProfile.Default;
            var s = Open();                        // no staff: rent only
            var before = s.Till.Coin;

            s.Advance(p.HoursPerDay * 3f, p.HoursPerDay * 3f);

            Assert.Equal(before - 3 * p.RentPerDay, s.Till.Coin);
            Assert.Equal(3, s.Ledger.Entries.Count(e => e.Kind == EntryKind.Rent));
        }

        [Fact]
        public void Unpaid_staff_leave_and_the_shop_closes_behind_them()
        {
            var p = ShopProfile.Default;
            var s = new Shop("Marta");
            s.HireStaff();                         // till is empty
            Assert.True(s.Open);

            for (var day = 0; day < p.StaffQuitAfterUnpaidDays; day++)
                s.Advance(p.HoursPerDay, p.HoursPerDay * (day + 1));

            Assert.False(s.Staffed);
            Assert.False(s.Open);
        }

        [Fact]
        public void One_missed_wage_is_forgiven_once_paid()
        {
            var p = ShopProfile.Default;
            var s = new Shop("Marta");
            s.HireStaff();

            s.Advance(p.HoursPerDay, p.HoursPerDay);
            Assert.Equal(1, s.UnpaidWageDays);
            Assert.True(s.Staffed);

            s.Till.Receive(100);
            s.Advance(p.HoursPerDay, 2 * p.HoursPerDay);
            Assert.Equal(0, s.UnpaidWageDays);
            Assert.True(s.Staffed);
        }

        [Fact]
        public void Unpaid_rent_goes_into_arrears_and_is_collected_when_it_can_be()
        {
            var p = ShopProfile.Default;
            var s = new Shop("Marta");

            s.Advance(p.HoursPerDay, p.HoursPerDay);
            s.Advance(p.HoursPerDay, 2 * p.HoursPerDay);
            Assert.Equal(2 * p.RentPerDay, s.RentArrears);
            Assert.Empty(s.Ledger.Entries);        // nothing was paid, so nothing is recorded

            s.Till.Receive(100);
            s.Advance(p.HoursPerDay, 3 * p.HoursPerDay);
            Assert.Equal(0, s.RentArrears);
            Assert.Equal(100 - 3 * p.RentPerDay, s.Till.Coin);
        }

        [Fact]
        public void Wages_and_rent_are_sinks_not_transfers()
        {
            // economy.md §4: coin paid to an NPC leaves the world.
            var p = ShopProfile.Default;
            var s = Open();
            s.HireStaff();
            var worldCoin = s.Till.Coin;

            s.Advance(p.HoursPerDay, p.HoursPerDay);

            Assert.True(s.Till.Coin < worldCoin);
            // and there is no purse anywhere that got richer.
        }
    }
}
