using System.Collections.Generic;
using System.Linq;

namespace Marrowmark.Sim.Economy
{
    public enum EntryKind
    {
        /// <summary>Stock left, coin came in.</summary>
        Sale,
        /// <summary>Coin left, stock came in.</summary>
        Purchase,
        /// <summary>Coin left to an NPC. A sink.</summary>
        Wage,
        /// <summary>Coin left to a landlord. A sink.</summary>
        Rent,
    }

    /// <summary>One line in the books. economy.md §2: "what sold, to whom,
    /// at what price."</summary>
    public sealed class LedgerEntry
    {
        public float Hour;
        public EntryKind Kind;
        public string Good = "";
        public int Quantity;
        public int UnitPrice;

        /// <summary>Who was on the other side. Empty for a sink.</summary>
        public string Counterparty = "";

        /// <summary>Net effect on the till. Positive for a sale.</summary>
        public int Coin;
    }

    /// <summary>
    /// Every shop keeps books (economy.md §2). Good data is part of the
    /// shopkeeper game — and, §6 notes, a smuggler's liability, which is
    /// why entries are never deleted and never edited: the ledger is a
    /// record of what happened, not what the owner wishes had.
    ///
    /// The queries here are the shopkeeper's evening glance (L31): what
    /// came in, what went out, what is selling.
    /// </summary>
    public sealed class Ledger
    {
        private readonly List<LedgerEntry> _entries = new List<LedgerEntry>();

        public IReadOnlyList<LedgerEntry> Entries => _entries;

        internal void Record(LedgerEntry e) => _entries.Add(e);

        /// <summary>Coin taken in sales since an hour.</summary>
        public int Takings(float sinceHour = float.NegativeInfinity) =>
            _entries.Where(e => e.Kind == EntryKind.Sale && e.Hour >= sinceHour)
                    .Sum(e => e.Coin);

        /// <summary>Coin that left — purchases, wages and rent — since an hour.</summary>
        public int Outgoings(float sinceHour = float.NegativeInfinity) =>
            _entries.Where(e => e.Kind != EntryKind.Sale && e.Hour >= sinceHour)
                    .Sum(e => -e.Coin);

        /// <summary>Everything that touched one good.</summary>
        public IEnumerable<LedgerEntry> Of(string good) =>
            _entries.Where(e => e.Good == good);

        /// <summary>The good that moved the most units out of the door, or
        /// empty if nothing has sold.</summary>
        public string BestSeller(float sinceHour = float.NegativeInfinity)
        {
            var best = _entries
                .Where(e => e.Kind == EntryKind.Sale && e.Hour >= sinceHour)
                .GroupBy(e => e.Good)
                .Select(g => new { Good = g.Key, Units = g.Sum(e => e.Quantity) })
                .OrderByDescending(x => x.Units)
                .FirstOrDefault();
            return best == null ? "" : best.Good;
        }
    }
}
