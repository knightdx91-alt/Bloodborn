using Marrowmark.Sim.Economy;
using Marrowmark.Sim.Society;
using Xunit;

namespace Marrowmark.Sim.Tests.Society
{
    /// <summary>
    /// L5 and brainstorm.md §3: own a deed or lease, landlord gameplay is
    /// real gameplay, councils are the people who own buildings, upkeep
    /// makes property churn.
    /// </summary>
    public class PropertyTests
    {
        private static readonly PropertyProfile P = PropertyProfile.Default;

        private sealed class F
        {
            public Charters Charters = new Charters();
            public Holdings Town;
            public Purse Marta = new Purse(500);
            public Purse Odo = new Purse(500);
            public Purse Chris = new Purse(50);

            public F()
            {
                Charters.Found("house-kettle", CharterKind.House, "Marta");
                Charters.Found("the-vein", CharterKind.Circle, "Vex");
                Town = new Holdings("Thornfield", Charters, P);
                Town.Add("sheaf", BuildingUse.Tavern, deedPrice: 200, upkeepPerDay: 5);
                Town.Add("forge", BuildingUse.Smithy, deedPrice: 150, upkeepPerDay: 4);
                Town.Add("stall-1", BuildingUse.Stall, deedPrice: 30, upkeepPerDay: 1);
            }
        }

        [Fact]
        public void A_deed_costs_coin_and_the_coin_leaves_the_world()
        {
            var f = new F();
            Assert.Equal(BuyResult.Bought, f.Town.Buy("sheaf", "Marta", f.Marta));
            Assert.Equal(300, f.Marta.Coin);
            Assert.Equal("Marta", f.Town.Find("sheaf")!.Owner);
            Assert.Equal(BuyResult.CannotPay, f.Town.Buy("forge", "Chris", f.Chris));
        }

        [Fact]
        public void An_owned_building_is_not_for_sale_from_the_town()
        {
            var f = new F();
            f.Town.Buy("sheaf", "Marta", f.Marta);
            Assert.Equal(BuyResult.NotForSale, f.Town.Buy("sheaf", "Odo", f.Odo));
        }

        [Fact]
        public void A_deed_can_be_sold_on_and_the_coin_goes_owner_to_owner()
        {
            var f = new F();
            f.Town.Buy("sheaf", "Marta", f.Marta);
            Assert.Equal(BuyResult.Bought, f.Town.Sell("sheaf", "Marta", "Odo", f.Odo, 250));
            Assert.Equal("Odo", f.Town.Find("sheaf")!.Owner);
            Assert.Equal(550, f.Marta.Coin);
            Assert.Equal(250, f.Odo.Coin);
            Assert.Equal(BuyResult.NotForSale, f.Town.Sell("sheaf", "Marta", "Chris", f.Chris, 1));
        }

        [Fact]
        public void A_house_may_own_and_a_circle_may_not()
        {
            var f = new F();
            Assert.Equal(BuyResult.Bought, f.Town.Buy("forge", "house-kettle", new Purse(500)));
            Assert.Equal(BuyResult.CircleCannotOwn, f.Town.Buy("stall-1", "the-vein", new Purse(500)));
        }

        [Fact]
        public void Rent_moves_tenant_to_landlord_daily()
        {
            var f = new F();
            f.Town.Buy("sheaf", "Marta", f.Marta);                 // Marta 300
            Assert.Equal(LeaseResult.Leased, f.Town.Lease("sheaf", "Marta", "Odo", f.Odo, rentPerDay: 10));
            Assert.Equal(LeaseResult.AlreadyLet, f.Town.Lease("sheaf", "Marta", "Chris", f.Chris, 1));
            Assert.Equal(LeaseResult.NotTheOwner, f.Town.Lease("forge", "Marta", "Odo", f.Odo, 1));

            f.Town.Advance(P.HoursPerDay);

            Assert.Equal(490, f.Odo.Coin);
            Assert.Equal(300 + 10 - 5 - P.DefaultTax, f.Marta.Coin);   // rent in, upkeep and tax out
        }

        [Fact]
        public void You_cannot_let_a_building_to_yourself()
        {
            var f = new F();
            f.Town.Buy("sheaf", "Marta", f.Marta);
            Assert.Equal(LeaseResult.CannotLeaseToYourself, f.Town.Lease("sheaf", "Marta", "Marta", f.Marta, 10));
        }

        [Fact]
        public void Upkeep_and_tax_are_sinks()
        {
            var f = new F();
            f.Town.Buy("sheaf", "Marta", f.Marta);
            var worldBefore = f.Marta.Coin + f.Odo.Coin + f.Chris.Coin;
            f.Town.Advance(P.HoursPerDay);
            Assert.Equal(worldBefore - 5 - P.DefaultTax, f.Marta.Coin + f.Odo.Coin + f.Chris.Coin);
        }

        [Fact]
        public void Unpaid_upkeep_forfeits_the_deed_and_the_town_sells_it_again()
        {
            // "Upkeep costs so property churns and new players can
            // eventually buy in."
            var f = new F();
            var broke = new Purse(30);
            f.Town.Buy("stall-1", "Chris", broke);                 // 0 left
            f.Town.Lease("stall-1", "Chris", "Odo", new Purse(0), 1); // a tenant who also cannot pay

            for (var d = 0; d < P.UpkeepForfeitDays - 1; d++) f.Town.Advance(P.HoursPerDay);
            Assert.Equal("Chris", f.Town.Find("stall-1")!.Owner);

            f.Town.Advance(P.HoursPerDay);
            var b = f.Town.Find("stall-1")!;
            Assert.False(b.Owned);
            Assert.False(b.Let);
            Assert.Equal(BuyResult.Bought, f.Town.Buy("stall-1", "Odo", f.Odo));
        }

        [Fact]
        public void One_paid_day_clears_the_count()
        {
            var f = new F();
            var tight = new Purse(30);
            f.Town.Buy("stall-1", "Chris", tight);
            f.Town.Advance(P.HoursPerDay);
            Assert.Equal(1, f.Town.Find("stall-1")!.UpkeepDaysUnpaid);
            tight.Receive(100);
            f.Town.Advance(P.HoursPerDay);
            Assert.Equal(0, f.Town.Find("stall-1")!.UpkeepDaysUnpaid);
        }

        [Fact]
        public void The_council_is_the_people_with_deeds_one_seat_each()
        {
            var f = new F();
            Assert.Empty(f.Town.Seats());
            f.Town.Buy("sheaf", "Marta", f.Marta);
            f.Town.Buy("forge", "Marta", f.Marta);
            f.Town.Buy("stall-1", "Odo", f.Odo);

            Assert.Equal(2, f.Town.Seats().Count);
            Assert.True(f.Town.HasSeat("Marta"));
            Assert.False(f.Town.HasSeat("Chris"));
        }

        [Fact]
        public void A_tax_passes_by_a_majority_of_all_seats()
        {
            var f = new F();
            f.Town.Buy("sheaf", "Marta", f.Marta);
            f.Town.Buy("forge", "Odo", f.Odo);
            f.Town.Buy("stall-1", "Chris", f.Chris);

            Assert.False(f.Town.Propose("nobody", 3));
            Assert.True(f.Town.Propose("Marta", 3));
            Assert.True(f.Town.Vote("Marta", true));
            Assert.Equal(P.DefaultTax, f.Town.Tax);          // one of three is not a majority
            Assert.True(f.Town.Vote("Odo", false));
            Assert.Equal(P.DefaultTax, f.Town.Tax);
            Assert.True(f.Town.Vote("Chris", true));
            Assert.Equal(3, f.Town.Tax);                      // two of three
            Assert.Equal(-1, f.Town.ProposedTax);
        }

        [Fact]
        public void Silence_is_a_no()
        {
            var f = new F();
            f.Town.Buy("sheaf", "Marta", f.Marta);
            f.Town.Buy("forge", "Odo", f.Odo);
            f.Town.Propose("Marta", 2);
            f.Town.Vote("Marta", true);
            Assert.Equal(P.DefaultTax, f.Town.Tax);           // one of two
        }

        [Fact]
        public void The_tax_is_bounded()
        {
            var f = new F();
            f.Town.Buy("sheaf", "Marta", f.Marta);
            Assert.False(f.Town.Propose("Marta", P.TaxMax + 1));
            Assert.False(f.Town.Propose("Marta", P.TaxMin - 1));
            Assert.True(f.Town.Propose("Marta", P.TaxMax));
        }

        [Fact]
        public void A_passed_tax_is_charged_from_the_next_day()
        {
            var f = new F();
            f.Town.Buy("sheaf", "Marta", f.Marta);              // 300
            f.Town.Propose("Marta", 4);
            f.Town.Vote("Marta", true);
            f.Town.Advance(P.HoursPerDay);
            Assert.Equal(300 - 5 - 4, f.Marta.Coin);
        }

        [Fact]
        public void Only_a_seat_votes()
        {
            var f = new F();
            f.Town.Buy("sheaf", "Marta", f.Marta);
            f.Town.Propose("Marta", 2);
            Assert.False(f.Town.Vote("Chris", true));
        }
    }
}
