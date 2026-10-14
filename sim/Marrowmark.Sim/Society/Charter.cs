using System.Collections.Generic;
using System.Linq;

namespace Marrowmark.Sim.Society
{
    /// <summary>war-society.md §1: there is no generic guild. Four
    /// institution types with distinct mechanical identities.</summary>
    public enum CharterKind
    {
        /// <summary>Mercenary company. The war actor.</summary>
        Company,
        /// <summary>Merchant or craft house. The economic actor.</summary>
        House,
        /// <summary>Faith-licensed. Carries faith obligations.</summary>
        Order,
        /// <summary>Secret society. The only unregistered charter.</summary>
        Circle,
    }

    public enum JoinResult
    {
        Joined,
        NoSuchCharter,
        AlreadyMember,
        /// <summary>You already fly a banner — one Company OR Order.</summary>
        AlreadyHasBanner,
        /// <summary>You already have a livelihood — one House.</summary>
        AlreadyHasHouse,
    }

    /// <summary>
    /// A charter: a player institution with a mechanical identity
    /// (L24). Registered at the capitol, except that a Circle
    /// conspicuously is not, and its roster is nobody's business.
    /// </summary>
    public sealed class Charter
    {
        public string Id = "";
        public CharterKind Kind;
        public List<string> Members = new List<string>();

        /// <summary>Charters register at the capitol; Circles do not.</summary>
        public bool Registered => Kind != CharterKind.Circle;

        /// <summary>What anyone can read off the register. A Circle's
        /// roster is hidden — it exists to make secrecy (L22)
        /// organisational, not just personal.</summary>
        public IReadOnlyList<string> PublicRoster =>
            Kind == CharterKind.Circle ? new List<string>() : Members;

        /// <summary>Only Companies and Orders field banners, and so only
        /// they can declare or be declared against.</summary>
        public bool CanWar => Kind == CharterKind.Company || Kind == CharterKind.Order;

        /// <summary>A Company or an Order is somebody's banner.</summary>
        public bool IsBanner => CanWar;
    }

    /// <summary>
    /// Everybody's memberships, and the one rule about them: a character
    /// can belong to one Company OR Order (your banner), plus one House
    /// (your livelihood), plus any Circles (nobody knows).
    /// </summary>
    public sealed class Charters
    {
        private readonly List<Charter> _all = new List<Charter>();

        public IReadOnlyList<Charter> All => _all;

        public Charter? Find(string id) => _all.FirstOrDefault(c => c.Id == id);

        public Charter Found(string id, CharterKind kind, string founder)
        {
            var c = new Charter { Id = id, Kind = kind };
            _all.Add(c);
            Join(founder, id);
            return c;
        }

        /// <summary>The register: what the capitol knows. Circles are
        /// absent from it, which is the point of a Circle.</summary>
        public IEnumerable<Charter> Register() => _all.Where(c => c.Registered);

        public IEnumerable<Charter> Of(string character) =>
            _all.Where(c => c.Members.Contains(character));

        public Charter? BannerOf(string character) =>
            Of(character).FirstOrDefault(c => c.IsBanner);

        public Charter? HouseOf(string character) =>
            Of(character).FirstOrDefault(c => c.Kind == CharterKind.House);

        public JoinResult Join(string character, string charterId)
        {
            var c = Find(charterId);
            if (c == null) return JoinResult.NoSuchCharter;
            if (c.Members.Contains(character)) return JoinResult.AlreadyMember;
            if (c.IsBanner && BannerOf(character) != null) return JoinResult.AlreadyHasBanner;
            if (c.Kind == CharterKind.House && HouseOf(character) != null)
                return JoinResult.AlreadyHasHouse;
            c.Members.Add(character);
            return JoinResult.Joined;
        }

        public bool Leave(string character, string charterId)
        {
            var c = Find(charterId);
            return c != null && c.Members.Remove(character);
        }
    }
}
