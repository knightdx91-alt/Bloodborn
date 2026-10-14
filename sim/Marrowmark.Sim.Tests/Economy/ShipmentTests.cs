using Marrowmark.Sim.Economy;
using Xunit;

namespace Marrowmark.Sim.Tests.Economy
{
    /// <summary>
    /// economy.md §3 and §3.5: goods physically travel, the road takes
    /// time, mounts are the fast travel. L17/L32: cargo drops where you
    /// fell, owner-only for a grace, then open, then gone.
    /// </summary>
    public class ShipmentTests
    {
        private static readonly TravelProfile P = TravelProfile.Default;

        private static (Market from, Market to) Towns()
        {
            var h = new Market("Hammarsted"); h.Stock("iron", 100, 50, 10);
            var g = new Market("Greywater"); g.Stock("iron", 0, 50, 10);
            return (h, g);
        }

        [Fact]
        public void Goods_are_in_one_place_at_a_time()
        {
            var (h, g) = Towns();
            var s = new Shipment("Marta", h, g, distanceMetres: 3000f, mounted: false);

            Assert.True(s.Load("iron", 30, 1f));
            Assert.Equal(70, h.Entry("iron")!.Stock);          // left the origin
            Assert.Equal(0, g.Entry("iron")!.Stock);           // not yet at the destination
            Assert.Equal(30, s.Cargo.QuantityOf("iron"));      // on the road

            s.Advance(s.JourneySeconds * 0.5f);
            Assert.Equal(ShipmentStatus.InTransit, s.Status);
            Assert.Equal(0, g.Entry("iron")!.Stock);

            s.Advance(s.JourneySeconds * 0.5f + 1f);
            Assert.Equal(ShipmentStatus.Arrived, s.Status);
            Assert.Equal(30, g.Entry("iron")!.Stock);
            Assert.True(s.Cargo.IsEmpty);
        }

        [Fact]
        public void You_cannot_load_what_the_town_does_not_have()
        {
            var (h, g) = Towns();
            var s = new Shipment("Marta", h, g, 3000f, false);
            Assert.False(s.Load("iron", 101, 1f));
            Assert.False(s.Load("silk", 1, 1f));
            Assert.Equal(100, h.Entry("iron")!.Stock);
        }

        [Fact]
        public void Nothing_loads_once_the_cart_has_left()
        {
            var (h, g) = Towns();
            var s = new Shipment("Marta", h, g, 3000f, false);
            s.Load("iron", 10, 1f);
            s.Advance(10f);
            Assert.False(s.Load("iron", 10, 1f));
        }

        [Fact]
        public void A_horse_is_the_fast_travel()
        {
            var (h, g) = Towns();
            var foot = new Shipment("Marta", h, g, 23_400f, mounted: false);
            var horse = new Shipment("Marta", h, g, 23_400f, mounted: true);

            Assert.Equal(foot.JourneySeconds / P.MountedMultiplier, horse.JourneySeconds, 2);
            Assert.True(horse.JourneySeconds < foot.JourneySeconds);
        }

        [Fact]
        public void Losing_the_cart_leaves_the_cargo_on_the_ground_where_it_fell()
        {
            var (h, g) = Towns();
            var s = new Shipment("Marta", h, g, 3000f, false);
            s.Load("iron", 30, 1f);
            s.Advance(200f);
            var where = s.TravelledMetres;

            var wreck = s.Lost(nowSeconds: 200f);

            Assert.Equal(ShipmentStatus.Lost, s.Status);
            Assert.True(s.Cargo.IsEmpty);
            Assert.Equal(30, wreck.Cargo.QuantityOf("iron"));
            Assert.Equal(where, wreck.MetresFromOrigin);
            Assert.Equal(0, g.Entry("iron")!.Stock);           // never arrived
            s.Advance(10_000f);
            Assert.Equal(0, g.Entry("iron")!.Stock);           // and never will
        }

        [Fact]
        public void The_owner_has_a_grace_and_then_it_is_anyones()
        {
            var (h, g) = Towns();
            var s = new Shipment("Marta", h, g, 3000f, false);
            s.Load("iron", 30, 1f);
            var wreck = s.Lost(nowSeconds: 1000f);
            var bandit = new Cargo();

            Assert.Equal(LootResult.OwnerOnly, wreck.Loot("Grim", bandit, 1000f + P.OwnerGraceSeconds - 1f));
            Assert.True(bandit.IsEmpty);
            Assert.Equal(LootResult.Taken, wreck.Loot("Grim", bandit, 1000f + P.OwnerGraceSeconds));
            Assert.Equal(30, bandit.QuantityOf("iron"));
            Assert.Equal(LootResult.AlreadyTaken, wreck.Loot("Marta", new Cargo(), 1000f + P.OwnerGraceSeconds + 1f));
        }

        [Fact]
        public void The_owner_may_recover_it_at_once()
        {
            var (h, g) = Towns();
            var s = new Shipment("Marta", h, g, 3000f, false);
            s.Load("iron", 30, 1f);
            var wreck = s.Lost(1000f);
            var mine = new Cargo();

            Assert.Equal(LootResult.Taken, wreck.Loot("Marta", mine, 1001f));
            Assert.Equal(30, mine.QuantityOf("iron"));
        }

        [Fact]
        public void Untouched_long_enough_it_is_gone()
        {
            var (h, g) = Towns();
            var s = new Shipment("Marta", h, g, 3000f, false);
            s.Load("iron", 30, 1f);
            var wreck = s.Lost(1000f);

            Assert.Equal(LootResult.Gone, wreck.Loot("Marta", new Cargo(), 1000f + P.DespawnSeconds));
        }

        [Fact]
        public void A_wreck_is_a_sink()
        {
            // Goods that despawn leave the world: L17's death ladder feeds
            // crafting demand because things really do go.
            var (h, g) = Towns();
            var s = new Shipment("Marta", h, g, 3000f, false);
            s.Load("iron", 30, 1f);
            s.Lost(1000f);

            Assert.Equal(70, h.Entry("iron")!.Stock);
            Assert.Equal(0, g.Entry("iron")!.Stock);
        }
    }
}
