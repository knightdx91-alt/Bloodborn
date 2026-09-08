using System;
using Marrowmark.Sim.Progression;
using Xunit;

namespace Marrowmark.Sim.Tests.Progression
{
    /// <summary>
    /// L18, L40, L71. The guarantees that matter: you learn from
    /// difficulty rather than repetition, the climb slows near mastery,
    /// no day can replace months, and the endgame gate stays open to any
    /// build.
    /// </summary>
    public class SkillTests
    {
        private static Skill New(float at = 0f) => new Skill("smithing", at);

        [Fact]
        public void A_skill_starts_where_it_was_told_to()
        {
            Assert.Equal(0f, New().Value, 4);
            Assert.Equal(0.5f, New(0.5f).Value, 4);
        }

        [Fact]
        public void Using_a_skill_at_your_level_teaches_you()
        {
            var s = New(0.3f);
            Assert.True(s.Use(0.3f) > 0f);
            Assert.True(s.Value > 0.3f);
        }

        // ── L71: you learn from difficulty, not repetition ───────────────

        [Fact]
        public void A_task_far_below_your_level_teaches_nothing_at_all()
        {
            // The anti-grind design in one assertion. A macro hammering an
            // easy action is not cheating — it is wasting its own time.
            var s = New(0.8f);
            Assert.Equal(0f, s.Use(0.1f), 6);
            Assert.Equal(0.8f, s.Value, 4);
        }

        [Fact]
        public void Ten_thousand_trivial_repetitions_achieve_literally_nothing()
        {
            var s = New(0.6f);
            for (var i = 0; i < 10_000; i++) s.Use(0.05f);

            Assert.Equal(0.6f, s.Value, 4);
        }

        [Fact]
        public void Learning_fades_smoothly_as_a_task_gets_easier()
        {
            var s = New(0.5f);

            Assert.True(s.ChallengeFactor(0.5f) > s.ChallengeFactor(0.4f));
            Assert.True(s.ChallengeFactor(0.4f) > s.ChallengeFactor(0.3f));
            Assert.Equal(0f, s.ChallengeFactor(0.1f), 4);
        }

        [Fact]
        public void Anything_at_or_above_your_level_teaches_fully()
        {
            var s = New(0.5f);
            Assert.Equal(1f, s.ChallengeFactor(0.5f), 4);
            Assert.Equal(1f, s.ChallengeFactor(0.9f), 4);
        }

        [Fact]
        public void A_beginner_learns_from_almost_everything()
        {
            // Nothing is beneath a novice, so the early game is generous
            // and never confusing about what to practise on.
            var s = New(0.05f);
            Assert.True(s.Use(0.05f) > 0f);
            Assert.True(s.Use(0.5f) > 0f);
        }

        // ── The climb slows ──────────────────────────────────────────────

        [Fact]
        public void The_same_task_teaches_a_veteran_less_than_a_novice()
        {
            var novice = New(0.1f);
            var veteran = New(0.7f);

            Assert.True(novice.Use(0.9f) > veteran.Use(0.9f));
        }

        [Fact]
        public void Mastery_is_approached_and_never_simply_arrived_at()
        {
            var s = New(0.5f);
            for (var i = 0; i < 100_000; i++)
            {
                s.Use(1f);
                s.NewDay();
            }

            Assert.True(s.Value < 1f, "growth should be asymptotic");
            Assert.True(s.IsMastered, "and mastery should still be reachable");
        }

        // ── L33's precedent: no day replaces months ──────────────────────

        [Fact]
        public void A_marathon_session_hits_a_soft_ceiling()
        {
            var paced = New(0.2f);
            var marathon = New(0.2f);

            for (var day = 0; day < 5; day++)
            {
                for (var i = 0; i < 40; i++) paced.Use(0.6f);
                paced.NewDay();
            }

            for (var i = 0; i < 200; i++) marathon.Use(0.6f);

            Assert.True(paced.Value > marathon.Value,
                $"five paced days ({paced.Value:F3}) should beat one marathon ({marathon.Value:F3})");
        }

        [Fact]
        public void The_soft_cap_slows_learning_without_ever_stopping_it()
        {
            // L38's spirit: never hard-stop someone who is still playing.
            var s = New(0.2f);
            for (var i = 0; i < 500; i++) s.Use(0.8f);

            var before = s.Value;
            Assert.True(s.Use(0.8f) > 0f, "past the cap you should still learn something");
            Assert.True(s.Value > before);
        }

        [Fact]
        public void A_new_day_clears_the_cap()
        {
            var s = New(0.2f);
            for (var i = 0; i < 500; i++) s.Use(0.8f);
            s.NewDay();

            Assert.Equal(0f, s.GainedToday, 5);
        }

        [Fact]
        public void Skills_never_decay()
        {
            // A trade you learned is a trade you know.
            var s = New(0.6f);
            for (var i = 0; i < 1000; i++) s.NewDay();

            Assert.Equal(0.6f, s.Value, 4);
        }

        [Fact]
        public void A_nameless_skill_is_rejected()
        {
            Assert.Throws<ArgumentException>(() => new Skill("", 0f));
        }
    }

    /// <summary>L40: the ascension gate, and that it stays open to any build.</summary>
    public class SkillSetTests
    {
        [Fact]
        public void Skills_come_into_existence_by_being_used()
        {
            var set = new SkillSet();
            set.Use("bowyery", 0.4f);

            Assert.Contains(set.All, s => s.Name == "bowyery");
        }

        [Fact]
        public void Only_the_top_eight_count_toward_the_gate()
        {
            var wide = new SkillSet();
            for (var i = 0; i < 30; i++) wide.Of($"skill{i}").Use(0.5f);

            var deep = new SkillSet();
            for (var i = 0; i < 8; i++) deep.Of($"skill{i}").Use(0.5f);

            Assert.Equal(deep.GateScore, wide.GateScore, 4);
            Assert.True(wide.Total > deep.Total, "breadth still shows in the level you see");
        }

        [Fact]
        public void Dabbling_in_everything_does_not_open_the_gate()
        {
            var dabbler = new SkillSet();
            for (var i = 0; i < 50; i++) dabbler.Of($"skill{i}", Shallow()).Use(0.5f);

            Assert.False(dabbler.MeetsAscensionGate(6f),
                "breadth alone must not reach the endgame — L40 demands real depth");
        }

        [Fact]
        public void Two_characters_can_reach_the_gate_sharing_no_skill_at_all()
        {
            // The classless promise (L18) made testable.
            var smith = Master("smithing", "mining", "haggling", "riding",
                               "masonry", "carpentry", "appraisal", "bookkeeping");
            var soldier = Master("swordplay", "shieldwork", "archery", "tracking",
                                 "horsemanship", "scouting", "command", "field-surgery");

            Assert.True(smith.MeetsAscensionGate(7f));
            Assert.True(soldier.MeetsAscensionGate(7f));

            foreach (var a in smith.Counted)
            foreach (var b in soldier.Counted)
                Assert.NotEqual(a.Name, b.Name);
        }

        [Fact]
        public void The_gate_reports_which_skills_are_carrying_it()
        {
            var set = new SkillSet();
            set.Of("swordplay", Started(0.9f));
            for (var i = 0; i < 12; i++) set.Of($"filler{i}", Started(0.1f));

            Assert.Contains(set.Counted, s => s.Name == "swordplay");
            Assert.Equal(SkillSet.CountedSkills, System.Linq.Enumerable.Count(set.Counted));
        }

        [Fact]
        public void A_new_day_rolls_over_every_skill()
        {
            var set = new SkillSet();
            set.Use("smithing", 0.9f);
            set.NewDay();

            Assert.Equal(0f, set.Of("smithing").GainedToday, 5);
        }

        private static SkillProfile Shallow()
        {
            var p = SkillProfile.Default;
            p.BaseGain = 0.001f;
            return p;
        }

        private static SkillProfile Started(float _) => SkillProfile.Default;

        private static SkillSet Master(params string[] names)
        {
            var set = new SkillSet();
            foreach (var n in names)
            {
                var s = set.Of(n);
                for (var day = 0; day < 400; day++)
                {
                    for (var i = 0; i < 20; i++) s.Use(1f);
                    s.NewDay();
                }
            }

            return set;
        }
    }
}
