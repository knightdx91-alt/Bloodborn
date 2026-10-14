using System.Linq;
using Marrowmark.Sim.Society;
using Xunit;

namespace Marrowmark.Sim.Tests.Society
{
    /// <summary>
    /// war-society.md §1 / L24: charters, not guilds. One Company OR Order
    /// (your banner), plus one House (your livelihood), plus any Circles
    /// (nobody knows). Circles conspicuously do not register.
    /// </summary>
    public class CharterTests
    {
        private static Charters World()
        {
            var c = new Charters();
            c.Found("free-blades", CharterKind.Company, "Ban");
            c.Found("hearth-order", CharterKind.Order, "Quill");
            c.Found("house-kettle", CharterKind.House, "Marta");
            c.Found("the-vein", CharterKind.Circle, "Vex");
            return c;
        }

        [Fact]
        public void One_banner_company_or_order()
        {
            var c = World();

            Assert.Equal(JoinResult.Joined, c.Join("Chris", "free-blades"));
            Assert.Equal(JoinResult.AlreadyHasBanner, c.Join("Chris", "hearth-order"));
            Assert.Equal("free-blades", c.BannerOf("Chris")!.Id);
        }

        [Fact]
        public void One_house()
        {
            var c = World();
            c.Found("house-vance", CharterKind.House, "Vance");

            Assert.Equal(JoinResult.Joined, c.Join("Chris", "house-kettle"));
            Assert.Equal(JoinResult.AlreadyHasHouse, c.Join("Chris", "house-vance"));
        }

        [Fact]
        public void A_banner_and_a_house_and_a_circle_all_at_once()
        {
            var c = World();

            Assert.Equal(JoinResult.Joined, c.Join("Chris", "free-blades"));
            Assert.Equal(JoinResult.Joined, c.Join("Chris", "house-kettle"));
            Assert.Equal(JoinResult.Joined, c.Join("Chris", "the-vein"));
            Assert.Equal(3, c.Of("Chris").Count());
        }

        [Fact]
        public void Any_number_of_circles()
        {
            var c = World();
            c.Found("the-lamp", CharterKind.Circle, "Quill");

            Assert.Equal(JoinResult.Joined, c.Join("Chris", "the-vein"));
            Assert.Equal(JoinResult.Joined, c.Join("Chris", "the-lamp"));
        }

        [Fact]
        public void Leaving_the_banner_frees_the_slot()
        {
            var c = World();
            c.Join("Chris", "free-blades");
            Assert.True(c.Leave("Chris", "free-blades"));
            Assert.Equal(JoinResult.Joined, c.Join("Chris", "hearth-order"));
        }

        [Fact]
        public void Circles_are_not_on_the_register()
        {
            var c = World();
            var register = c.Register().Select(x => x.Id).ToList();

            Assert.Contains("free-blades", register);
            Assert.Contains("house-kettle", register);
            Assert.DoesNotContain("the-vein", register);
        }

        [Fact]
        public void A_circles_roster_is_nobodys_business()
        {
            var c = World();
            c.Join("Chris", "the-vein");

            Assert.Empty(c.Find("the-vein")!.PublicRoster);
            Assert.Equal(2, c.Find("the-vein")!.Members.Count);   // the rules still know
            Assert.Contains("Ban", c.Find("free-blades")!.PublicRoster);
        }

        [Fact]
        public void Only_companies_and_orders_fight_wars()
        {
            var c = World();
            Assert.True(c.Find("free-blades")!.CanWar);
            Assert.True(c.Find("hearth-order")!.CanWar);
            Assert.False(c.Find("house-kettle")!.CanWar);
            Assert.False(c.Find("the-vein")!.CanWar);
        }
    }
}
