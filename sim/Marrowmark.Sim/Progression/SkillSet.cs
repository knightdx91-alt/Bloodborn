using System;
using System.Collections.Generic;
using System.Linq;

namespace Marrowmark.Sim.Progression
{
    /// <summary>
    /// Everything one character has learned, and the ascension gate it
    /// opens. L18, L40.
    ///
    /// There are no classes. A character is the sum of what they have
    /// actually done, and two people who both reach the gate need not
    /// share a single skill.
    /// </summary>
    public sealed class SkillSet
    {
        /// <summary>
        /// How many skills count toward the gate (L40). Breadth past this
        /// contributes nothing, so the gate demands real depth — but which
        /// eight is entirely the player's.
        /// </summary>
        public const int CountedSkills = 8;

        private readonly Dictionary<string, Skill> _skills =
            new Dictionary<string, Skill>(StringComparer.OrdinalIgnoreCase);

        public IEnumerable<Skill> All => _skills.Values;

        /// <summary>
        /// Get a skill, creating it on first use. Skills come into
        /// existence by being used — nobody picks them from a list.
        /// </summary>
        public Skill Of(string name, SkillProfile? profile = null)
        {
            if (!_skills.TryGetValue(name, out var skill))
            {
                skill = new Skill(name, profile ?? SkillProfile.Default);
                _skills[name] = skill;
            }

            return skill;
        }

        /// <summary>Use a skill by name, creating it if this is the first time.</summary>
        public float Use(string name, float taskDifficulty) => Of(name).Use(taskDifficulty);

        /// <summary>
        /// The "level" a player sees: everything they know, added up
        /// (L18). Not the gate — just the number that grows.
        /// </summary>
        public float Total => _skills.Values.Sum(s => s.Value);

        /// <summary>
        /// The L40 figure: the highest <see cref="CountedSkills"/> skills,
        /// summed. Breadth beyond that is worth nothing here.
        /// </summary>
        public float GateScore =>
            _skills.Values
                .Select(s => s.Value)
                .OrderByDescending(v => v)
                .Take(CountedSkills)
                .Sum();

        /// <summary>The skills currently carrying the gate score.</summary>
        public IEnumerable<Skill> Counted =>
            _skills.Values.OrderByDescending(s => s.Value).Take(CountedSkills);

        /// <summary>
        /// Whether this character has reached "max level" for L12's
        /// one-way ascension.
        /// </summary>
        public bool MeetsAscensionGate(float threshold) => GateScore >= threshold;

        /// <summary>Roll every skill over to a new day.</summary>
        public void NewDay()
        {
            foreach (var skill in _skills.Values) skill.NewDay();
        }
    }
}
