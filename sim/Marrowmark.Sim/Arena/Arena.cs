using System;
using System.Collections.Generic;
using System.Linq;
using Marrowmark.Sim.Economy;
using Marrowmark.Sim.Magic;

namespace Marrowmark.Sim.Arena
{
    /// <summary>The numbers behind the Ring and its books.</summary>
    public struct ArenaProfile
    {
        /// <summary>What a licensed book keeps of every pool. economy.md
        /// §4: "betting rake at the Ring" is a sink.</summary>
        public float RakeFraction;

        /// <summary>What a shadow book keeps. Dearer, because nobody can
        /// complain to anyone.</summary>
        public float ShadowRakeFraction;

        /// <summary>How long a season of rankings runs before the table
        /// clears. Working: a quarter.</summary>
        public float SeasonHours;

        public static ArenaProfile Default => new ArenaProfile
        {
            RakeFraction = 0.05f,
            ShadowRakeFraction = 0.10f,
            SeasonHours = 2160f,
        };
    }

    public enum BoutKind
    {
        /// <summary>Player against player.</summary>
        Duel,
        /// <summary>Player against a captured beast.</summary>
        Beast,
        /// <summary>A headline: the ghost of a dead demigod, summoned
        /// from the Monument (L14).</summary>
        Echo,
        /// <summary>L35: the hidden circuit's biggest night.</summary>
        SuccessionTrial,
    }

    public enum WagerResult
    {
        Placed,
        NoSuchBout,
        /// <summary>The bell has gone.</summary>
        BoutStarted,
        NoSuchContender,
        CannotPay,
        /// <summary>L35: the shadow book takes wagers from the awakened
        /// only. Nobody else knows there is a book.</summary>
        NotAwakened,
        /// <summary>A licensed book needs the licence; without it, the
        /// book is a shadow book and says so.</summary>
        NoLicence,
    }

    public sealed class Wager
    {
        public string Bettor = "";
        public string On = "";
        public int Stake;
        public Purse Purse = new Purse();
    }

    /// <summary>
    /// One bout and the book on it. The book is pari-mutuel — "odds move
    /// with the money like a real book": every wager goes into one pool,
    /// the house takes its rake, and the winners share what is left in
    /// proportion to what they staked. There is nothing to fix and no
    /// odds to post wrongly, because the odds ARE the money.
    ///
    /// No equipment loss (L6): the arena is sport, wars are stakes. The
    /// only thing at risk here is coin, and only the coin you wagered.
    /// </summary>
    public sealed class Bout
    {
        private readonly ArenaProfile _p;
        private readonly List<Wager> _wagers = new List<Wager>();

        internal Bout(ArenaProfile p, string id, BoutKind kind, IEnumerable<string> contenders,
            float scheduledHour, bool shadow)
        {
            _p = p;
            Id = id;
            Kind = kind;
            Contenders = contenders.ToList();
            ScheduledHour = scheduledHour;
            Shadow = shadow;
        }

        public string Id { get; }
        public BoutKind Kind { get; }
        public IReadOnlyList<string> Contenders { get; }
        public float ScheduledHour { get; }

        /// <summary>The Veiled Ring's book, off the books.</summary>
        public bool Shadow { get; }

        public bool Started { get; private set; }
        public string Winner { get; private set; } = "";
        public IReadOnlyList<Wager> Wagers => _wagers;

        /// <summary>L6: sport. Nothing is dropped on the sand.</summary>
        public bool StakesEquipment => false;

        public int Pool => _wagers.Sum(w => w.Stake);
        public int PoolOn(string contender) => _wagers.Where(w => w.On == contender).Sum(w => w.Stake);

        /// <summary>What a unit staked now would return if this contender
        /// won and no more money came in. Moves with every wager.</summary>
        public float OddsOn(string contender)
        {
            var on = PoolOn(contender);
            if (on <= 0) return 0f;
            return Pool * (1f - Rake) / on;
        }

        public float Rake => Shadow ? _p.ShadowRakeFraction : _p.RakeFraction;

        public WagerResult Place(string bettor, Purse purse, string on, int stake, bool bettorAwakened)
        {
            if (Started) return WagerResult.BoutStarted;
            if (!Contenders.Contains(on)) return WagerResult.NoSuchContender;
            if (Shadow && !bettorAwakened) return WagerResult.NotAwakened;
            var escrow = new Purse();
            if (stake <= 0 || !purse.TryPay(escrow, stake)) return WagerResult.CannotPay;
            _wagers.Add(new Wager { Bettor = bettor, On = on, Stake = stake, Purse = escrow });
            return WagerResult.Placed;
        }

        public void Begin() => Started = true;

        /// <summary>
        /// The bell. Winners share the pool less the rake, in proportion;
        /// the rake goes to the book; losers' stakes are what the winners
        /// share. Returns the rake taken. Every winning bettor's purse is
        /// found through their wager.
        /// </summary>
        public int Settle(string winner, Purse book, IDictionary<string, Purse> purses)
        {
            if (!Contenders.Contains(winner) || Winner.Length > 0) return 0;
            Started = true;
            Winner = winner;

            var pool = Pool;
            var rake = (int)Math.Floor(pool * Rake);
            var toShare = pool - rake;
            var winning = PoolOn(winner);

            // Gather the escrowed stakes into one pot.
            var pot = new Purse();
            foreach (var w in _wagers) w.Purse.TryPay(pot, w.Purse.Coin);

            pot.TryPay(book, rake);

            if (winning > 0)
            {
                var paid = 0;
                var winners = _wagers.Where(w => w.On == winner).ToList();
                for (var i = 0; i < winners.Count; i++)
                {
                    var w = winners[i];
                    var share = i == winners.Count - 1
                        ? toShare - paid                                   // the last takes the rounding
                        : (int)Math.Floor((long)toShare * w.Stake / (double)winning);
                    if (purses.TryGetValue(w.Bettor, out var purse)) pot.TryPay(purse, share);
                    else pot.TrySink(share);
                    paid += share;
                }
            }
            else
            {
                // Nobody backed the winner: the pool is the book's, less
                // nothing — the rake was never the point of that night.
                pot.TryPay(book, pot.Coin);
            }
            return rake;
        }
    }

    /// <summary>A line in the season's table.</summary>
    public sealed class Standing
    {
        public string Fighter = "";
        public int Wins;
        public int Losses;
    }

    /// <summary>
    /// The Great Ring (L6, lore.md §6) and the Veiled Ring beneath it.
    /// Fight nights, beast bouts, echo bouts, the Succession Trial; a
    /// licensed book above and a shadow book below; seasons and rankings;
    /// and arena fame feeding crafter fame through the marks on winning
    /// gear.
    /// </summary>
    public sealed class Ring
    {
        private readonly ArenaProfile _p;
        private readonly List<Bout> _bouts = new List<Bout>();
        private readonly Dictionary<string, Standing> _table = new Dictionary<string, Standing>();
        private readonly Dictionary<string, int> _makerFame = new Dictionary<string, int>();
        private float _seasonStartHour;
        private int _next = 1;

        public Ring(ArenaProfile profile) { _p = profile; }
        public Ring() : this(ArenaProfile.Default) { }

        public IReadOnlyList<Bout> Bouts => _bouts;

        /// <summary>Bookmaking licences are a purchasable right
        /// (brainstorm.md §4). Whoever holds one runs the licensed book.</summary>
        public string LicenceHolder = "";

        /// <summary>A bout on the public card. Needs a licensed book to
        /// take wagers; a Succession Trial is never on the public card.</summary>
        public Bout Card(BoutKind kind, IEnumerable<string> contenders, float scheduledHour)
        {
            if (kind == BoutKind.SuccessionTrial)
                throw new ArgumentException("The Trial is the Veiled Ring's (L22).", nameof(kind));
            var b = new Bout(_p, "bout-" + _next++, kind, contenders, scheduledHour, shadow: false);
            _bouts.Add(b);
            return b;
        }

        /// <summary>A bout after dark, off the books.</summary>
        public Bout Veiled(BoutKind kind, IEnumerable<string> contenders, float scheduledHour)
        {
            var b = new Bout(_p, "veiled-" + _next++, kind, contenders, scheduledHour, shadow: true);
            _bouts.Add(b);
            return b;
        }

        /// <summary>Place a wager through the right book. A licensed bout
        /// with no licence holder has no book.</summary>
        public WagerResult Wager(Bout bout, string bettor, Purse purse, string on, int stake, bool awakened)
        {
            if (!_bouts.Contains(bout)) return WagerResult.NoSuchBout;
            if (!bout.Shadow && LicenceHolder.Length == 0) return WagerResult.NoLicence;
            return bout.Place(bettor, purse, on, stake, awakened);
        }

        /// <summary>
        /// The result. Settles the book, writes the table, and credits the
        /// maker of the winner's weapon — arena fame feeding crafter fame
        /// (brainstorm.md §4, L68).
        /// </summary>
        public int Result(Bout bout, string winner, Purse book, IDictionary<string, Purse> purses,
            float nowHour, string winnersWeaponMark = "")
        {
            RollSeason(nowHour);
            var rake = bout.Settle(winner, book, purses);
            if (bout.Winner.Length == 0) return 0;

            foreach (var c in bout.Contenders)
            {
                if (!_table.TryGetValue(c, out var s)) _table[c] = s = new Standing { Fighter = c };
                if (c == winner) s.Wins++; else s.Losses++;
            }
            if (winnersWeaponMark.Length > 0)
                _makerFame[winnersWeaponMark] = FameOf(winnersWeaponMark) + 1;
            return rake;
        }

        public IEnumerable<Standing> Table() =>
            _table.Values.OrderByDescending(s => s.Wins).ThenBy(s => s.Losses);

        public int FameOf(string makersMark) => _makerFame.TryGetValue(makersMark, out var f) ? f : 0;

        /// <summary>L14 and content.md §5: an echo is a dead demigod's
        /// ghost, and it must not cast in public before the Unveiling or
        /// the arena itself breaks the myth.</summary>
        public static bool EchoMayCast(Epoch epoch, bool shadow) => shadow || epoch >= Epoch.Unveiling;

        private void RollSeason(float nowHour)
        {
            if (nowHour - _seasonStartHour >= _p.SeasonHours)
            {
                _seasonStartHour = nowHour;
                _table.Clear();          // fame on the marks is permanent; the table is not
            }
        }
    }
}
