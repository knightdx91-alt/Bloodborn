using System.Collections.Generic;
using Marrowmark.Sim.Crafting;
using Marrowmark.Sim.Economy;
using Marrowmark.Sim.Items;
using Xunit;

namespace Marrowmark.Sim.Tests.Economy
{
    /// <summary>
    /// economy.md §2: buyers post commissions, crafters bid, the order
    /// book is where careers start. The escrow question is answered by
    /// leaving nothing to dispute: every outcome keys off something the
    /// server can prove.
    /// </summary>
    public class CommissionTests
    {
        private static readonly CommissionProfile P = CommissionProfile.Default;

        private static CraftedItem Made(string by) =>
            new CraftedItem(by, new MaterialProperties(0.4f, 0.45f, 0.5f, 0.35f), new List<string>(), DurabilityProfile.Default);

        private sealed class F
        {
            public CommissionBook Book = new CommissionBook("Thornfield");
            public Purse Buyer = new Purse(100);
            public Purse Smith = new Purse(0);
            public Commission Order;

            public F()
            {
                Book.Post("Marta", Buyer, "a winter coat, wolf-lined", deadlineHour: 100f, budget: 60, nowHour: 0f, out var o);
                Order = o!;
            }
        }

        [Fact]
        public void Posting_escrows_the_budget_or_does_not_post()
        {
            var f = new F();
            Assert.Equal(40, f.Buyer.Coin);
            Assert.Equal(60, f.Order.Escrow.Coin);

            var broke = new Purse(10);
            Assert.Equal(PostResult.CannotPayBudget,
                f.Book.Post("Chris", broke, "a sword", 100f, 50, 0f, out var none));
            Assert.Null(none);
            Assert.Equal(10, broke.Coin);
            Assert.Single(f.Book.Orders);
        }

        [Fact]
        public void A_deadline_in_the_past_is_not_an_order()
        {
            var f = new F();
            Assert.Equal(PostResult.DeadlinePassed, f.Book.Post("Chris", new Purse(50), "x", 5f, 10, 6f, out _));
        }

        [Fact]
        public void A_bid_is_under_the_budget_and_before_the_deadline()
        {
            var f = new F();
            Assert.Equal(BidResult.OverBudget, f.Book.Bid(f.Order.Id, "Odo", 61, 50f));
            Assert.Equal(BidResult.TooLate, f.Book.Bid(f.Order.Id, "Odo", 40, 101f));
            Assert.Equal(BidResult.Bid, f.Book.Bid(f.Order.Id, "Odo", 40, 50f));
            Assert.Equal(BidResult.OwnCommission, f.Book.Bid(f.Order.Id, "Marta", 40, 50f));
        }

        [Fact]
        public void A_crafters_second_bid_replaces_the_first()
        {
            var f = new F();
            f.Book.Bid(f.Order.Id, "Odo", 50, 50f);
            f.Book.Bid(f.Order.Id, "Odo", 40, 50f);
            Assert.Single(f.Order.Bids);
            Assert.Equal(40, f.Order.Bids[0].Price);
        }

        [Fact]
        public void Only_the_buyer_accepts_and_the_surplus_goes_home()
        {
            var f = new F();
            f.Book.Bid(f.Order.Id, "Odo", 40, 50f);

            Assert.Equal(AcceptResult.NotTheBuyer, f.Book.Accept(f.Order.Id, "Chris", "Odo", new Purse()));
            Assert.Equal(AcceptResult.NoSuchBid, f.Book.Accept(f.Order.Id, "Marta", "Pell", f.Buyer));
            Assert.Equal(AcceptResult.Accepted, f.Book.Accept(f.Order.Id, "Marta", "Odo", f.Buyer));

            Assert.Equal(CommissionStatus.Accepted, f.Order.Status);
            Assert.Equal(40, f.Order.Escrow.Coin);
            Assert.Equal(60, f.Buyer.Coin);          // 40 left + 20 back
            Assert.Equal(BidResult.NotOpen, f.Book.Bid(f.Order.Id, "Pell", 30, 50f));
        }

        [Fact]
        public void Delivery_pays_the_crafter_and_hands_the_buyer_the_thing()
        {
            var f = new F();
            f.Book.Bid(f.Order.Id, "Odo", 40, 50f);
            f.Book.Accept(f.Order.Id, "Marta", "Odo", f.Buyer);
            var coat = Made("Odo");

            Assert.Equal(DeliverResult.Paid, f.Book.Deliver(f.Order.Id, "Odo", coat, f.Smith, nowHour: 50f));

            Assert.Equal(40, f.Smith.Coin);
            Assert.Equal(0, f.Order.Escrow.Coin);
            Assert.Same(coat, f.Order.Delivered);
            Assert.Equal(CommissionStatus.Delivered, f.Order.Status);
        }

        [Fact]
        public void The_thing_delivered_must_carry_the_crafters_own_mark()
        {
            // L68: everything is signed, and a commission is to a person.
            var f = new F();
            f.Book.Bid(f.Order.Id, "Odo", 40, 50f);
            f.Book.Accept(f.Order.Id, "Marta", "Odo", f.Buyer);

            Assert.Equal(DeliverResult.NotYourWork, f.Book.Deliver(f.Order.Id, "Odo", Made("Pell"), f.Smith, 50f));
            Assert.Equal(DeliverResult.NotTheCrafter, f.Book.Deliver(f.Order.Id, "Pell", Made("Pell"), f.Smith, 50f));
            Assert.Equal(0, f.Smith.Coin);
            Assert.Equal(CommissionStatus.Accepted, f.Order.Status);
        }

        [Fact]
        public void The_deadline_is_the_contract()
        {
            var f = new F();
            f.Book.Bid(f.Order.Id, "Odo", 40, 50f);
            f.Book.Accept(f.Order.Id, "Marta", "Odo", f.Buyer);

            Assert.Equal(DeliverResult.PastDeadline, f.Book.Deliver(f.Order.Id, "Odo", Made("Odo"), f.Smith, 101f));
            Assert.Equal(ReclaimResult.NotYetDue, f.Book.Reclaim(f.Order.Id, "Marta", f.Buyer, 100f));
            Assert.Equal(ReclaimResult.Reclaimed, f.Book.Reclaim(f.Order.Id, "Marta", f.Buyer, 101f));
            Assert.Equal(100, f.Buyer.Coin);
            Assert.Equal(0, f.Smith.Coin);
        }

        [Fact]
        public void Cancelling_before_anyone_agreed_refunds_everything()
        {
            var f = new F();
            Assert.Equal(CancelResult.Refunded, f.Book.Cancel(f.Order.Id, "Marta", f.Buyer, f.Smith));
            Assert.Equal(100, f.Buyer.Coin);
            Assert.Equal(CancelResult.Finished, f.Book.Cancel(f.Order.Id, "Marta", f.Buyer, f.Smith));
        }

        [Fact]
        public void Cancelling_agreed_work_leaves_the_crafter_a_fee()
        {
            var f = new F();
            f.Book.Bid(f.Order.Id, "Odo", 40, 50f);
            f.Book.Accept(f.Order.Id, "Marta", "Odo", f.Buyer);

            Assert.Equal(CancelResult.RefundedLessFee, f.Book.Cancel(f.Order.Id, "Marta", f.Buyer, f.Smith));

            var fee = (int)System.Math.Round(40 * P.CancelFeeFraction);
            Assert.Equal(fee, f.Smith.Coin);
            Assert.Equal(100 - fee, f.Buyer.Coin);
            Assert.Equal(0, f.Order.Escrow.Coin);
        }

        [Fact]
        public void A_crafter_who_backs_out_reopens_the_order_and_is_owed_nothing()
        {
            var f = new F();
            f.Book.Bid(f.Order.Id, "Odo", 40, 50f);
            f.Book.Accept(f.Order.Id, "Marta", "Odo", f.Buyer);

            Assert.True(f.Book.Withdraw(f.Order.Id, "Odo"));
            Assert.Equal(CommissionStatus.Open, f.Order.Status);
            Assert.Empty(f.Order.Bids);
            Assert.Equal(0, f.Smith.Coin);
            Assert.Equal(BidResult.Bid, f.Book.Bid(f.Order.Id, "Pell", 40, 50f));
        }

        [Fact]
        public void Only_the_buyer_cancels_or_reclaims()
        {
            var f = new F();
            Assert.Equal(CancelResult.NotTheBuyer, f.Book.Cancel(f.Order.Id, "Odo", new Purse(), f.Smith));
            Assert.Equal(ReclaimResult.NotTheBuyer, f.Book.Reclaim(f.Order.Id, "Odo", new Purse(), 200f));
        }

        [Fact]
        public void Coin_is_conserved_through_every_path()
        {
            // Escrow is a place, not a sink. Whatever happens, what went
            // in comes out to somebody.
            var f = new F();
            f.Book.Bid(f.Order.Id, "Odo", 40, 50f);
            f.Book.Accept(f.Order.Id, "Marta", "Odo", f.Buyer);
            f.Book.Deliver(f.Order.Id, "Odo", Made("Odo"), f.Smith, 50f);
            Assert.Equal(100, f.Buyer.Coin + f.Smith.Coin + f.Order.Escrow.Coin);
        }
    }
}
