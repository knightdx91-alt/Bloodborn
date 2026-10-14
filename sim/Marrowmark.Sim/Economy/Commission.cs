using System;
using System.Collections.Generic;
using System.Linq;
using Marrowmark.Sim.Crafting;

namespace Marrowmark.Sim.Economy
{
    /// <summary>The numbers behind the order book.</summary>
    public struct CommissionProfile
    {
        /// <summary>What a crafter keeps if the buyer cancels work already
        /// agreed. Not nothing — they turned other work away — and not
        /// everything — they have the materials still.</summary>
        public float CancelFeeFraction;

        public static CommissionProfile Default => new CommissionProfile
        {
            CancelFeeFraction = 0.25f,
        };
    }

    public enum CommissionStatus { Open, Accepted, Delivered, Cancelled, Reclaimed }

    public enum PostResult { Posted, CannotPayBudget, NoBudget, DeadlinePassed }
    public enum BidResult { Bid, NoSuchCommission, NotOpen, OverBudget, TooLate, OwnCommission }
    public enum AcceptResult { Accepted, NoSuchCommission, NotTheBuyer, NotOpen, NoSuchBid }
    public enum DeliverResult
    {
        Paid,
        NoSuchCommission,
        NotAccepted,
        NotTheCrafter,
        /// <summary>L68: the mark on it is not yours. A commission is to a
        /// person, and the thing handed over says who made it.</summary>
        NotYourWork,
        /// <summary>The deadline was the contract.</summary>
        PastDeadline,
    }
    public enum CancelResult { Refunded, RefundedLessFee, NoSuchCommission, NotTheBuyer, Finished }
    public enum ReclaimResult { Reclaimed, NoSuchCommission, NotTheBuyer, NotYetDue, Finished }

    public sealed class Bid
    {
        public string Crafter = "";
        public int Price;
        public float ByHour;
    }

    /// <summary>
    /// One order: a buyer wants a thing made, by a date, for at most a
    /// budget. The budget is escrowed when the order is posted, because
    /// an order book full of coin nobody has is a quest board.
    /// </summary>
    public sealed class Commission
    {
        public string Id = "";
        public string Buyer = "";

        /// <summary>What is wanted. Prose to the rules; the engine and the
        /// crafter read it.</summary>
        public string Want = "";

        public float DeadlineHour;
        public CommissionStatus Status = CommissionStatus.Open;
        public Purse Escrow = new Purse();
        public List<Bid> Bids = new List<Bid>();
        public Bid? Accepted;

        /// <summary>What was handed over, once it was.</summary>
        public CraftedItem? Delivered;
    }

    /// <summary>
    /// A town's order book (economy.md §2): "buyers post commission
    /// orders ... crafters bid. The order book is where crafting careers
    /// start."
    ///
    /// Disputes are the open question in economy.md, and the answer here
    /// is to leave no room for one: every outcome keys off something the
    /// server can prove (feasibility-review.md §2.6). The coin was
    /// escrowed or the order was never posted. The thing delivered
    /// carries a mark or it is not that crafter's work. The deadline
    /// passed or it did not. There is nothing to argue about, so there is
    /// nothing to adjudicate.
    /// </summary>
    public sealed class CommissionBook
    {
        private readonly CommissionProfile _p;
        private readonly List<Commission> _orders = new List<Commission>();
        private int _next = 1;

        public CommissionBook(string town, CommissionProfile profile)
        {
            Town = town;
            _p = profile;
        }

        public CommissionBook(string town) : this(town, CommissionProfile.Default) { }

        public string Town { get; }
        public IReadOnlyList<Commission> Orders => _orders;
        public IEnumerable<Commission> Open => _orders.Where(o => o.Status == CommissionStatus.Open);
        public Commission? Find(string id) => _orders.FirstOrDefault(o => o.Id == id);

        /// <summary>Post an order. The budget leaves the buyer's purse now.
        /// Binding, so the conversation layer confirms first (L49).</summary>
        public PostResult Post(string buyer, Purse buyerPurse, string want, float deadlineHour,
            int budget, float nowHour, out Commission? order)
        {
            order = null;
            if (budget <= 0) return PostResult.NoBudget;
            if (deadlineHour <= nowHour) return PostResult.DeadlinePassed;
            var o = new Commission
            {
                Id = Town + "-" + _next, Buyer = buyer, Want = want, DeadlineHour = deadlineHour,
            };
            if (!buyerPurse.TryPay(o.Escrow, budget)) return PostResult.CannotPayBudget;
            _next++;
            _orders.Add(o);
            order = o;
            return PostResult.Posted;
        }

        /// <summary>A crafter offers to do it for a price by a date. Over
        /// the budget or past the deadline is not a bid.</summary>
        public BidResult Bid(string id, string crafter, int price, float byHour)
        {
            var o = Find(id);
            if (o == null) return BidResult.NoSuchCommission;
            if (o.Status != CommissionStatus.Open) return BidResult.NotOpen;
            if (crafter == o.Buyer) return BidResult.OwnCommission;
            if (price <= 0 || price > o.Escrow.Coin) return BidResult.OverBudget;
            if (byHour > o.DeadlineHour) return BidResult.TooLate;
            o.Bids.RemoveAll(b => b.Crafter == crafter);
            o.Bids.Add(new Bid { Crafter = crafter, Price = price, ByHour = byHour });
            return BidResult.Bid;
        }

        /// <summary>The buyer picks a bid. Escrow above the price goes home
        /// now: the crafter is owed the price and nothing more.</summary>
        public AcceptResult Accept(string id, string buyer, string crafter, Purse buyerPurse)
        {
            var o = Find(id);
            if (o == null) return AcceptResult.NoSuchCommission;
            if (o.Buyer != buyer) return AcceptResult.NotTheBuyer;
            if (o.Status != CommissionStatus.Open) return AcceptResult.NotOpen;
            var bid = o.Bids.FirstOrDefault(b => b.Crafter == crafter);
            if (bid == null) return AcceptResult.NoSuchBid;
            o.Accepted = bid;
            o.Status = CommissionStatus.Accepted;
            o.Escrow.TryPay(buyerPurse, o.Escrow.Coin - bid.Price);
            return AcceptResult.Accepted;
        }

        /// <summary>
        /// The crafter hands over the thing. It must carry their mark
        /// (L68) and arrive before the deadline; then the escrow is theirs
        /// and the item is the buyer's.
        /// </summary>
        public DeliverResult Deliver(string id, string crafter, CraftedItem item, Purse crafterPurse, float nowHour)
        {
            var o = Find(id);
            if (o == null) return DeliverResult.NoSuchCommission;
            if (o.Status != CommissionStatus.Accepted || o.Accepted == null) return DeliverResult.NotAccepted;
            if (o.Accepted.Crafter != crafter) return DeliverResult.NotTheCrafter;
            if (item.MakersMark != crafter) return DeliverResult.NotYourWork;
            if (nowHour > o.DeadlineHour) return DeliverResult.PastDeadline;
            o.Escrow.TryPay(crafterPurse, o.Escrow.Coin);
            o.Delivered = item;
            o.Status = CommissionStatus.Delivered;
            return DeliverResult.Paid;
        }

        /// <summary>The buyer withdraws. Before anyone agreed, everything
        /// comes back; after, the crafter keeps a fee.</summary>
        public CancelResult Cancel(string id, string buyer, Purse buyerPurse, Purse crafterPurse)
        {
            var o = Find(id);
            if (o == null) return CancelResult.NoSuchCommission;
            if (o.Buyer != buyer) return CancelResult.NotTheBuyer;
            if (o.Status == CommissionStatus.Open)
            {
                o.Escrow.TryPay(buyerPurse, o.Escrow.Coin);
                o.Status = CommissionStatus.Cancelled;
                return CancelResult.Refunded;
            }
            if (o.Status == CommissionStatus.Accepted && o.Accepted != null)
            {
                var fee = (int)Math.Round(o.Accepted.Price * _p.CancelFeeFraction);
                o.Escrow.TryPay(crafterPurse, fee);
                o.Escrow.TryPay(buyerPurse, o.Escrow.Coin);
                o.Status = CommissionStatus.Cancelled;
                return CancelResult.RefundedLessFee;
            }
            return CancelResult.Finished;
        }

        /// <summary>The crafter backs out. The order reopens for bids and
        /// their own bid is gone; nothing is owed either way.</summary>
        public bool Withdraw(string id, string crafter)
        {
            var o = Find(id);
            if (o == null || o.Status != CommissionStatus.Accepted || o.Accepted?.Crafter != crafter)
                return false;
            o.Bids.RemoveAll(b => b.Crafter == crafter);
            o.Accepted = null;
            o.Status = CommissionStatus.Open;
            return true;
        }

        /// <summary>Deadline passed and nothing came. The buyer takes the
        /// escrow back; the crafter who promised keeps nothing.</summary>
        public ReclaimResult Reclaim(string id, string buyer, Purse buyerPurse, float nowHour)
        {
            var o = Find(id);
            if (o == null) return ReclaimResult.NoSuchCommission;
            if (o.Buyer != buyer) return ReclaimResult.NotTheBuyer;
            if (o.Status != CommissionStatus.Open && o.Status != CommissionStatus.Accepted)
                return ReclaimResult.Finished;
            if (nowHour <= o.DeadlineHour) return ReclaimResult.NotYetDue;
            o.Escrow.TryPay(buyerPurse, o.Escrow.Coin);
            o.Status = CommissionStatus.Reclaimed;
            return ReclaimResult.Reclaimed;
        }
    }
}
