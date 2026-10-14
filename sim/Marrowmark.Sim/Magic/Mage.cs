using System.Collections.Generic;
using System.Linq;

namespace Marrowmark.Sim.Magic
{
    /// <summary>One character's standing in one spell.</summary>
    public sealed class SpellStanding
    {
        public string Spell = "";
        public float Xp;

        /// <summary>Who taught it. Empty for a discoverer. One master per
        /// spell — this is the lineage (brainstorm.md §5.3).</summary>
        public string Master = "";

        /// <summary>Current disciples, if this character teaches it.</summary>
        public List<string> Disciples = new List<string>();

        /// <summary>Disciples who reached Master under this character.</summary>
        public int Graduates;

        /// <summary>Slots locked by dismissals: when each frees.</summary>
        public List<float> LockedUntil = new List<float>();

        /// <summary>Trickle received today, against the cap.</summary>
        public float TrickleToday;
    }

    /// <summary>
    /// A character as the hidden system sees them: awakened or not, what
    /// they know, whose lineage they are in, what seat they hold.
    /// </summary>
    public sealed class Mage
    {
        public Mage(string name) { Name = name; }

        public string Name { get; }

        /// <summary>brainstorm.md §5.1: the magic interface does not exist
        /// for a character until this is true.</summary>
        public bool Awakened;

        /// <summary>Last time the account was seen. L10's lapse reads it.</summary>
        public float LastSeenHour;

        /// <summary>The spell this character is Incarnate of, or empty. One
        /// per character, ever (L10).</summary>
        public string IncarnateOf = "";

        /// <summary>Seats declined. Each adds a teaching slot in that spell.</summary>
        public HashSet<string> Declined = new HashSet<string>();

        /// <summary>L10's regency: usable once.</summary>
        public bool RegencyUsed;
        public float RegencyUntilHour = -1f;

        public List<SpellStanding> Spells = new List<SpellStanding>();

        public SpellStanding? Standing(string spell) => Spells.FirstOrDefault(s => s.Spell == spell);

        public SpellStanding StandingOrNew(string spell)
        {
            var s = Standing(spell);
            if (s == null) { s = new SpellStanding { Spell = spell }; Spells.Add(s); }
            return s;
        }

        public bool Knows(string spell) => Standing(spell) != null;
    }
}
