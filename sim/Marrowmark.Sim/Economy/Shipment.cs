using System;

namespace Marrowmark.Sim.Economy
{
    public enum ShipmentStatus { InTransit, Arrived, Lost }

    public enum LootResult
    {
        Taken,
        /// <summary>L32: owner-only for the grace period.</summary>
        OwnerOnly,
        /// <summary>Untouched too long. The wedge has it now.</summary>
        Gone,
        AlreadyTaken,
    }

    /// <summary>
    /// Cargo where somebody fell (L17): carried goods drop in the wedge,
    /// owner-locked for a grace period, then open loot, then gone. Not a
    /// penalty screen — a place on the ground, and a reason bandits wait.
    /// </summary>
    public sealed class Wreck
    {
        private readonly TravelProfile _p;

        internal Wreck(TravelProfile p, string owner, Cargo cargo, float fellAtSeconds, float metresFromOrigin)
        {
            _p = p;
            Owner = owner;
            Cargo = cargo;
            FellAtSeconds = fellAtSeconds;
            MetresFromOrigin = metresFromOrigin;
        }

        public string Owner { get; }
        public Cargo Cargo { get; }
        public float FellAtSeconds { get; }
        public float MetresFromOrigin { get; }
        public string LootedBy { get; private set; } = "";

        public bool InGrace(float now) => now < FellAtSeconds + _p.OwnerGraceSeconds;
        public bool Despawned(float now) => now >= FellAtSeconds + _p.DespawnSeconds;

        /// <summary>Take everything. The owner may during the grace; anyone
        /// may after; nobody may once it is gone.</summary>
        public LootResult Loot(string by, Cargo into, float now)
        {
            if (LootedBy.Length > 0) return LootResult.AlreadyTaken;
            if (Despawned(now)) return LootResult.Gone;
            if (InGrace(now) && by != Owner) return LootResult.OwnerOnly;
            Cargo.TransferAll(into);
            LootedBy = by;
            return LootResult.Taken;
        }
    }

    /// <summary>
    /// Goods on the road between two markets. economy.md §3: no mail, no
    /// teleporting goods — a shipment is in its origin's warehouse, or on
    /// the road, or in its destination's, and never two of those.
    ///
    /// The road takes time, and the time is the risk: a shipment can be
    /// lost, at which point its cargo is a <see cref="Wreck"/> on the
    /// ground where it fell.
    /// </summary>
    public sealed class Shipment
    {
        private readonly TravelProfile _p;

        public Shipment(TravelProfile profile, string owner, Market origin, Market destination,
            float distanceMetres, bool mounted)
        {
            if (distanceMetres <= 0f) throw new ArgumentOutOfRangeException(nameof(distanceMetres));
            _p = profile;
            Owner = owner;
            Origin = origin;
            Destination = destination;
            DistanceMetres = distanceMetres;
            Mounted = mounted;
            Cargo = new Cargo();
        }

        public Shipment(string owner, Market origin, Market destination, float distanceMetres, bool mounted)
            : this(TravelProfile.Default, owner, origin, destination, distanceMetres, mounted) { }

        public string Owner { get; }
        public Market Origin { get; }
        public Market Destination { get; }
        public float DistanceMetres { get; }
        public bool Mounted { get; }
        public Cargo Cargo { get; }
        public float TravelledMetres { get; private set; }
        public ShipmentStatus Status { get; private set; } = ShipmentStatus.InTransit;

        public float MetresPerSecond =>
            _p.FootMetresPerSecond * (Mounted ? _p.MountedMultiplier : 1f);

        /// <summary>How long the road takes, in seconds. Minutes on a
        /// decent horse, economy.md §3.5 asks; what the map makes of that
        /// is tech.md §1b's argument.</summary>
        public float JourneySeconds => DistanceMetres / MetresPerSecond;

        /// <summary>
        /// Load from the origin's warehouse. Goods leave the board the
        /// moment they are on the cart.
        /// </summary>
        public bool Load(string good, int quantity, float kgPerUnit)
        {
            if (Status != ShipmentStatus.InTransit || TravelledMetres > 0f) return false;
            var e = Origin.Entry(good);
            if (e == null || quantity <= 0 || e.Stock < quantity) return false;
            e.Stock -= quantity;
            Cargo.Add(good, quantity, kgPerUnit);
            return true;
        }

        /// <summary>The road, in real seconds. Arrival unloads into the
        /// destination's warehouse.</summary>
        public void Advance(float seconds)
        {
            if (Status != ShipmentStatus.InTransit || seconds <= 0f) return;
            TravelledMetres = Math.Min(DistanceMetres, TravelledMetres + MetresPerSecond * seconds);
            if (TravelledMetres >= DistanceMetres)
            {
                Status = ShipmentStatus.Arrived;
                Destination.Receive(Cargo);
            }
        }

        /// <summary>
        /// The mover died on the road. The cargo is now a wreck where they
        /// fell, and the shipment is over.
        /// </summary>
        public Wreck Lost(float nowSeconds)
        {
            if (Status != ShipmentStatus.InTransit)
                throw new InvalidOperationException("Only a shipment on the road can be lost.");
            Status = ShipmentStatus.Lost;
            var dropped = new Cargo();
            Cargo.TransferAll(dropped);
            return new Wreck(_p, Owner, dropped, nowSeconds, TravelledMetres);
        }
    }
}
