using System;
using System.Collections.Generic;
using System.Linq;

namespace Marrowmark.Sim.Crafting
{
    /// <summary>What an attempt taught, if anything.</summary>
    public struct DiscoveryResult
    {
        /// <summary>True if this attempt was one the smith had never made before.</summary>
        public bool WasNovel;

        /// <summary>Insight gained. Enough of it reveals a new stage.</summary>
        public float Insight;

        /// <summary>The stage revealed by this attempt, or null.</summary>
        public string Discovered;

        /// <summary>An in-world nudge about what went wrong, or null.</summary>
        public string Hint;
    }

    /// <summary>
    /// What one smith knows and how they come to know more. L4, L72.
    ///
    /// **There is no recipe list.** A recipe here is a *known pipeline* —
    /// which stages, in which order — and knowledge arrives three ways
    /// (`brainstorm.md` §2.3): experimentation, discovery in the world,
    /// and being taught.
    ///
    /// Experimentation is **deterministic, not lucky**. Insight comes from
    /// trying sequences you have never tried, so a smith who genuinely
    /// experiments makes progress and one who repeats a known-good recipe
    /// forever does not. That is L71's anti-grind principle applied to
    /// knowledge rather than skill: novelty teaches, repetition does not.
    /// </summary>
    public sealed class Knowledge
    {
        /// <summary>Insight needed to work out that a new stage exists.</summary>
        public const float InsightPerDiscovery = 1f;

        private readonly HashSet<string> _known = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        private readonly HashSet<string> _tried = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        private readonly Queue<string> _discoverable = new Queue<string>();
        private float _insight;

        /// <summary>
        /// A smith who knows the basics and has a world of stages left to
        /// find. The discoverable queue is what this character *could*
        /// work out for themselves, in order.
        /// </summary>
        public Knowledge(IEnumerable<string> knownStages, IEnumerable<string> discoverable = null)
        {
            foreach (var s in knownStages ?? Enumerable.Empty<string>()) _known.Add(s);
            foreach (var s in discoverable ?? Enumerable.Empty<string>()) _discoverable.Enqueue(s);
        }

        public IEnumerable<string> KnownStages => _known;

        /// <summary>How many distinct sequences this smith has tried.</summary>
        public int AttemptsRecorded => _tried.Count;

        public float Insight => _insight;

        public bool Knows(string stage) => _known.Contains(stage);

        /// <summary>
        /// Learn a stage from outside your own bench — a teacher, a ruin,
        /// a schematic bought off a market board. Returns false if it was
        /// already known.
        /// </summary>
        public bool Learn(string stage)
        {
            if (string.IsNullOrWhiteSpace(stage))
                throw new ArgumentException("A stage needs a name.", nameof(stage));

            return _known.Add(stage);
        }

        /// <summary>
        /// Read a schematic. Teaches every stage in it that you did not
        /// already know, and returns how many were new.
        /// </summary>
        public int Read(Schematic schematic)
        {
            if (schematic == null) throw new ArgumentNullException(nameof(schematic));
            return schematic.Stages.Count(Learn);
        }

        /// <summary>
        /// Can this smith actually run this sequence? Every stage in it
        /// must be known — you cannot follow instructions for something
        /// you have never seen done.
        /// </summary>
        public bool CanRun(IEnumerable<string> sequence) => sequence.All(Knows);

        /// <summary>
        /// Record an attempt at the bench, and report what it taught.
        ///
        /// <paramref name="result"/> and <paramref name="potential"/> drive
        /// the near-miss hint: the material as it came out, versus what a
        /// perfect hand could have drawn from it.
        /// </summary>
        public DiscoveryResult Attempt(
            IReadOnlyList<string> sequence,
            MaterialProperties result = default,
            MaterialProperties potential = default)
        {
            if (sequence == null) throw new ArgumentNullException(nameof(sequence));
            if (sequence.Count == 0)
                throw new ArgumentException("An empty sequence is not an attempt.", nameof(sequence));
            if (!CanRun(sequence))
                throw new InvalidOperationException(
                    "A smith cannot run a stage they have never seen done.");

            var signature = string.Join(">", sequence);
            var novel = _tried.Add(signature);

            var outcome = new DiscoveryResult
            {
                WasNovel = novel,
                Insight = 0f,
                Hint = Hint(result, potential),
            };

            if (!novel) return outcome;

            // Novelty is what teaches. Longer sequences teach a little more,
            // because there is more in them to notice.
            var gained = 0.25f + 0.05f * (sequence.Count - 1);
            _insight += gained;
            outcome.Insight = gained;

            if (_insight >= InsightPerDiscovery && _discoverable.Count > 0)
            {
                _insight -= InsightPerDiscovery;
                var found = _discoverable.Dequeue();
                _known.Add(found);
                outcome.Discovered = found;
            }

            return outcome;
        }

        /// <summary>
        /// The near-miss nudge from `brainstorm.md` §2.3 — *"the alloy
        /// cracked, too much of something"*. Names the property that came
        /// out furthest below what the material could have given, and never
        /// names the fix. A hint points; it does not answer.
        /// </summary>
        private static string Hint(MaterialProperties result, MaterialProperties potential)
        {
            var gaps = new (string Text, float Gap)[]
            {
                ("the edge is soft — something here is drawing the temper", potential.Hardness - result.Hardness),
                ("it rings wrong; this steel will crack before it bends", potential.Toughness - result.Toughness),
                ("it feels light in the hand, thinner than it should be", potential.Density - result.Density),
                ("there is dirt still in it", potential.Purity - result.Purity),
            };

            var worst = gaps.OrderByDescending(g => g.Gap).First();
            return worst.Gap > 0.05f ? worst.Text : null;
        }
    }
}
