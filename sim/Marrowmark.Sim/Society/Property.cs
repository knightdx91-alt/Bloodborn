using System;
using System.Collections.Generic;
using System.Linq;
using Marrowmark.Sim.Economy;

namespace Marrowmark.Sim.Society
{
    /// <summary>The numbers behind owning a building and sitting on a
    /// council. brainstorm.md §3, economy.md §4.</summary>
    public struct PropertyProfile
    {
        /// <summary>Days of unpaid upkeep before the deed reverts to the
        /// town. "Upkeep costs so property churns and new players can
        /// eventually buy in" — this is the churn.</summary>
        public int UpkeepForfeitDays;

        /// <summary>The least a council may set the daily tax per building
        /// to. Zero: a council may choose to charge nothing.</summary>
        public int TaxMin;

        /// <summary>The most. A council of three cannot tax a town into
        /// the ground.</summary>
        public int TaxMax;

        /// <summary>What a town charges before any council has voted.</summary>
        public int DefaultTax;

        public float HoursPerDay;

        public static PropertyProfile Default => new PropertyProfile
        {
            UpkeepForfeitDays = 7,
            TaxMin = 0,
            TaxMax = 5,
            DefaultTax = 1,
            HoursPerDay = 24f,
        };
    }

    /// <summary>brainstorm.md §3's list. What a building is for decides
    /// what can run in it; that is the engine's business.</summary>
    public enum BuildingUse
    {
        Shop, Smithy, Tavern, Inn, Stable, Chapel, BettingParlour,
        TrainingHall, Warehouse, Stall, House,
    }

    public enum BuyResult { Bought, NoSuchBuilding, NotForSale, CannotPay, CircleCannotOwn, NoSuchCharter }
    public enum LeaseResult { Leased, NoSuchBuilding, NotTheOwner, AlreadyLet, CannotLeaseToYourself }

    /// <summary>
    /// A building in a town: a deed, a use, an owner of record, perhaps
    /// a tenant. L5.
    /// </summary>
    public sealed class Building
    {
        public string Id = "";
        public BuildingUse Use;

        /// <summary>A character, or a registered charter. Empty: the
        /// town's, and for sale.</summary>
        public string Owner = "";

        /// <summary>What the town asks when it is the town's.</summary>
        public int DeedPrice;

        /// <summary>Daily, from the owner, to nobody. A sink.</summary>
        public int UpkeepPerDay;

        public string Tenant = "";
        public int RentPerDay;

        public int UpkeepDaysUnpaid;

        public bool Owned => Owner.Length > 0;
        public bool Let => Tenant.Length > 0;
    }

    /// <summary>
    /// A town's buildings and the council of the people who own them.
    ///
    /// Property is how a town gets its politics without a guild system
    /// (brainstorm.md §3): the council is not a charter, it is
    /// everybody with a deed, one seat each, and what it decides is the
    /// tax. Charters can own (a House's joint property); a Circle
    /// cannot be the owner of record, because the register is public and
    /// a Circle's property is a front held by somebody else.
    ///
    /// Three sinks live here, all daily, all charged whether anyone is
    /// looking: upkeep to nobody, tax to nobody, and rent — which is not
    /// a sink but a transfer from tenant to landlord, and the reason
    /// landlord gameplay is real gameplay.
    /// </summary>
    public sealed class Holdings
    {
        private readonly PropertyProfile _p;
        private readonly Charters _charters;
        private readonly List<Building> _buildings = new List<Building>();
        private readonly Dictionary<string, Purse> _purses = new Dictionary<string, Purse>();
        private float _hoursIntoDay;
        private int _proposedTax = -1;
        private readonly HashSet<string> _votesFor = new HashSet<string>();
        private readonly HashSet<string> _votesAgainst = new HashSet<string>();

        public Holdings(string name, Charters charters, PropertyProfile profile)
        {
            Name = name;
            _charters = charters;
            _p = profile;
            Tax = profile.DefaultTax;
        }

        public Holdings(string name, Charters charters) : this(name, charters, PropertyProfile.Default) { }

        public string Name { get; }
        public IReadOnlyList<Building> Buildings => _buildings;

        /// <summary>Daily, per building, from each owner. What the council
        /// decides.</summary>
        public int Tax { get; private set; }

        public int ProposedTax => _proposedTax;

        public Building? Find(string id) => _buildings.FirstOrDefault(b => b.Id == id);

        /// <summary>Content's door: a building the town has.</summary>
        public Building Add(string id, BuildingUse use, int deedPrice, int upkeepPerDay)
        {
            var b = new Building { Id = id, Use = use, DeedPrice = deedPrice, UpkeepPerDay = upkeepPerDay };
            _buildings.Add(b);
            return b;
        }

        /// <summary>Whose coin pays whose bills. Registered once, read at
        /// every day's end.</summary>
        public void Bank(string who, Purse purse) => _purses[who] = purse;

        public Purse? PurseOf(string who) => _purses.TryGetValue(who, out var p) ? p : null;

        // ── Deeds ───────────────────────────────────────────────────────

        /// <summary>Buy a deed from the town. Coin to the town is a sink.</summary>
        public BuyResult Buy(string buildingId, string buyer, Purse buyerPurse)
        {
            var b = Find(buildingId);
            if (b == null) return BuyResult.NoSuchBuilding;
            if (b.Owned) return BuyResult.NotForSale;
            var owns = CanOwn(buyer);
            if (owns != BuyResult.Bought) return owns;
            if (!buyerPurse.TrySink(b.DeedPrice)) return BuyResult.CannotPay;
            b.Owner = buyer;
            b.UpkeepDaysUnpaid = 0;
            Bank(buyer, buyerPurse);
            return BuyResult.Bought;
        }

        /// <summary>Sell a deed to somebody. Coin goes owner to owner.</summary>
        public BuyResult Sell(string buildingId, string seller, string buyer, Purse buyerPurse, int price)
        {
            var b = Find(buildingId);
            if (b == null) return BuyResult.NoSuchBuilding;
            if (b.Owner != seller) return BuyResult.NotForSale;
            var owns = CanOwn(buyer);
            if (owns != BuyResult.Bought) return owns;
            var sellerPurse = PurseOf(seller) ?? new Purse();
            if (!buyerPurse.TryPay(sellerPurse, price)) return BuyResult.CannotPay;
            b.Owner = buyer;
            b.UpkeepDaysUnpaid = 0;
            Bank(buyer, buyerPurse);
            return BuyResult.Bought;
        }

        private BuyResult CanOwn(string who)
        {
            var charter = _charters.Find(who);
            if (charter == null) return BuyResult.Bought;          // a person
            if (charter.Kind == CharterKind.Circle) return BuyResult.CircleCannotOwn;
            return BuyResult.Bought;
        }

        // ── Leases ──────────────────────────────────────────────────────

        public LeaseResult Lease(string buildingId, string owner, string tenant, Purse tenantPurse, int rentPerDay)
        {
            var b = Find(buildingId);
            if (b == null) return LeaseResult.NoSuchBuilding;
            if (b.Owner != owner) return LeaseResult.NotTheOwner;
            if (b.Let) return LeaseResult.AlreadyLet;
            if (tenant == owner) return LeaseResult.CannotLeaseToYourself;
            b.Tenant = tenant;
            b.RentPerDay = Math.Max(0, rentPerDay);
            Bank(tenant, tenantPurse);
            return LeaseResult.Leased;
        }

        public bool EndLease(string buildingId, string by)
        {
            var b = Find(buildingId);
            if (b == null || !b.Let || (by != b.Owner && by != b.Tenant)) return false;
            b.Tenant = "";
            b.RentPerDay = 0;
            return true;
        }

        // ── The council ─────────────────────────────────────────────────

        /// <summary>Everybody with a deed, one seat each. A charter that
        /// owns three buildings has one seat, like a person who does.</summary>
        public IReadOnlyList<string> Seats() =>
            _buildings.Where(b => b.Owned).Select(b => b.Owner).Distinct().ToList();

        public bool HasSeat(string who) => Seats().Contains(who);

        /// <summary>Put a tax rate to the council. Only a seat may; only
        /// within the bounds.</summary>
        public bool Propose(string who, int taxPerBuildingPerDay)
        {
            if (!HasSeat(who)) return false;
            if (taxPerBuildingPerDay < _p.TaxMin || taxPerBuildingPerDay > _p.TaxMax) return false;
            _proposedTax = taxPerBuildingPerDay;
            _votesFor.Clear();
            _votesAgainst.Clear();
            return true;
        }

        /// <summary>One seat, one vote. A majority of ALL seats carries
        /// it, not a majority of those who turned up — silence is a no.</summary>
        public bool Vote(string who, bool inFavour)
        {
            if (_proposedTax < 0 || !HasSeat(who)) return false;
            _votesFor.Remove(who);
            _votesAgainst.Remove(who);
            (inFavour ? _votesFor : _votesAgainst).Add(who);

            if (_votesFor.Count * 2 > Seats().Count)
            {
                Tax = _proposedTax;
                _proposedTax = -1;
                _votesFor.Clear();
                _votesAgainst.Clear();
            }
            return true;
        }

        // ── Time ────────────────────────────────────────────────────────

        /// <summary>Let the hours pass. Each day's end: rent tenant to
        /// owner, then upkeep and tax from the owner to nobody. Upkeep
        /// unpaid long enough forfeits the deed to the town.</summary>
        public void Advance(float hours)
        {
            if (hours <= 0f) return;
            _hoursIntoDay += hours;
            while (_hoursIntoDay >= _p.HoursPerDay)
            {
                _hoursIntoDay -= _p.HoursPerDay;
                EndOfDay();
            }
        }

        private void EndOfDay()
        {
            foreach (var b in _buildings.Where(b => b.Owned).ToList())
            {
                var owner = PurseOf(b.Owner) ?? new Purse();

                if (b.Let && b.RentPerDay > 0)
                {
                    var tenant = PurseOf(b.Tenant) ?? new Purse();
                    tenant.TryPay(owner, b.RentPerDay);
                }

                if (owner.TrySink(b.UpkeepPerDay + Tax))
                {
                    b.UpkeepDaysUnpaid = 0;
                }
                else
                {
                    b.UpkeepDaysUnpaid++;
                    if (b.UpkeepDaysUnpaid >= _p.UpkeepForfeitDays)
                    {
                        // The town takes it back. The tenant's lease goes
                        // with the landlord who could not keep the roof on.
                        b.Owner = "";
                        b.Tenant = "";
                        b.RentPerDay = 0;
                        b.UpkeepDaysUnpaid = 0;
                    }
                }
            }
        }
    }
}
