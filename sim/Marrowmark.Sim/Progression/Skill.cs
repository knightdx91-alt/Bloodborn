using System;

namespace Marrowmark.Sim.Progression
{
    /// <summary>
    /// One proficiency, grown by using it. L18, L40, L71.
    ///
    /// **You learn from difficulty, not repetition.** A task well below
    /// your level teaches nothing, so the classic skill-by-use failure —
    /// macroing the same trivial action for a week — earns exactly zero
    /// without any rule forbidding it. That is the whole anti-grind
    /// design, and it is a rule about *learning* rather than a rule about
    /// *players*, which means it never punishes someone who is genuinely
    /// playing badly.
    /// </summary>
    public sealed class Skill
    {
        private readonly SkillProfile _profile;

        public Skill(string name, SkillProfile profile, float startingValue = 0f)
        {
            if (string.IsNullOrWhiteSpace(name))
                throw new ArgumentException("A skill needs a name.", nameof(name));

            Name = name;
            _profile = profile;
            Value = Clamp(startingValue);
        }

        public Skill(string name, float startingValue = 0f)
            : this(name, SkillProfile.Default, startingValue) { }

        public string Name { get; }

        /// <summary>Proficiency, 0..1. Approaches mastery, never quite arrives.</summary>
        public float Value { get; private set; }

        /// <summary>Skill gained so far today, against the soft cap.</summary>
        public float GainedToday { get; private set; }

        /// <summary>
        /// Counts as capped for L40's ascension gate.
        /// </summary>
        public bool IsMastered => Value >= _profile.MasteryThreshold;

        /// <summary>
        /// How much this task would teach, given where you are.
        ///
        /// At or above your level: full value. Below it: falling away, and
        /// past <see cref="SkillProfile.ChallengeWindow"/> it is nothing.
        /// </summary>
        public float ChallengeFactor(float taskDifficulty)
        {
            var ease = Value - Clamp(taskDifficulty);
            if (ease <= 0f) return 1f;
            if (_profile.ChallengeWindow <= 0f) return 0f;

            var factor = 1f - ease / _profile.ChallengeWindow;
            return factor < 0f ? 0f : factor;
        }

        /// <summary>
        /// Use the skill at a task of the given difficulty (0..1). Returns
        /// the skill actually gained.
        /// </summary>
        public float Use(float taskDifficulty)
        {
            var challenge = ChallengeFactor(taskDifficulty);
            if (challenge <= 0f) return 0f;

            var headroom = (float)Math.Pow(1f - Value, _profile.DiminishingExponent);
            var gain = _profile.BaseGain * challenge * headroom;

            if (GainedToday >= _profile.DailySoftCap)
                gain *= _profile.PastCapMultiplier;

            var before = Value;
            Value = Clamp(Value + gain);

            var actual = Value - before;
            GainedToday += actual;
            return actual;
        }

        /// <summary>
        /// Roll over to a new day, clearing the soft cap. Nothing is lost —
        /// there is no skill decay in Marrowmark. A trade you learned is a
        /// trade you know, and a character is the sum of what they have
        /// actually done.
        /// </summary>
        public void NewDay() => GainedToday = 0f;

        private static float Clamp(float v) => v < 0f ? 0f : (v > 1f ? 1f : v);

        public override string ToString() => $"{Name} {Value:F3}";
    }
}
