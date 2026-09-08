using System;
using System.Collections.Generic;
using System.Linq;

namespace Marrowmark.Sim.Crafting
{
    /// <summary>
    /// A written pipeline: which stages, in which order (L73).
    ///
    /// **Knowledge is an economy.** A schematic is an item — it can be
    /// sold, stolen, copied, hoarded, or buried with its author. This is
    /// the deliberate parallel to spell teaching (L9): in Marrowmark
    /// *knowing* is a thing you can own and lose, in crafting exactly as
    /// in magic.
    /// </summary>
    public sealed class Schematic
    {
        public Schematic(string name, string author, IEnumerable<string> stages)
        {
            if (string.IsNullOrWhiteSpace(name))
                throw new ArgumentException("A schematic needs a name.", nameof(name));
            if (string.IsNullOrWhiteSpace(author))
                throw new ArgumentException(
                    "A schematic records who wrote it (L68's logic applied to knowledge).",
                    nameof(author));

            Name = name;
            Author = author;
            Stages = (stages ?? Enumerable.Empty<string>()).ToList();

            if (Stages.Count == 0)
                throw new ArgumentException("A schematic with no stages is a blank page.", nameof(stages));
        }

        public string Name { get; }

        /// <summary>Who wrote it down. Outlives them, like a maker's mark.</summary>
        public string Author { get; }

        public IReadOnlyList<string> Stages { get; }

        /// <summary>The sequence as a comparable signature.</summary>
        public string Signature => string.Join(">", Stages);

        public override string ToString() => $"{Name} ({Author}): {Signature}";
    }
}
