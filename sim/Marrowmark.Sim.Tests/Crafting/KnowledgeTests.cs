using System;
using System.Linq;
using Marrowmark.Sim.Crafting;
using Xunit;

namespace Marrowmark.Sim.Tests.Crafting
{
    /// <summary>
    /// L4, L72, L73. There is no recipe list: a recipe is a known
    /// pipeline, and knowledge arrives by experiment, by discovery, or by
    /// being taught.
    /// </summary>
    public class KnowledgeTests
    {
        private static Knowledge Apprentice() =>
            new Knowledge(
                knownStages: new[] { "smelt", "fold" },
                discoverable: new[] { "quench", "temper", "grind" });

        [Fact]
        public void A_smith_starts_knowing_only_what_they_were_shown()
        {
            var k = Apprentice();
            Assert.True(k.Knows("smelt"));
            Assert.False(k.Knows("quench"));
        }

        [Fact]
        public void You_cannot_run_a_stage_you_have_never_seen_done()
        {
            var k = Apprentice();
            Assert.False(k.CanRun(new[] { "smelt", "quench" }));
            Assert.Throws<InvalidOperationException>(() =>
                k.Attempt(new[] { "smelt", "quench" }));
        }

        // ── Experimentation: novelty teaches, repetition does not ────────

        [Fact]
        public void A_novel_sequence_yields_insight()
        {
            var k = Apprentice();
            var result = k.Attempt(new[] { "smelt", "fold" });

            Assert.True(result.WasNovel);
            Assert.True(result.Insight > 0f);
        }

        [Fact]
        public void Repeating_a_sequence_teaches_nothing_new()
        {
            // L71's principle applied to knowledge: a smith who runs one
            // known-good recipe forever learns nothing, and no rule had to
            // forbid it.
            var k = Apprentice();
            k.Attempt(new[] { "smelt", "fold" });

            var again = k.Attempt(new[] { "smelt", "fold" });

            Assert.False(again.WasNovel);
            Assert.Equal(0f, again.Insight, 5);
        }

        [Fact]
        public void Order_counts_as_a_different_experiment()
        {
            var k = Apprentice();
            k.Attempt(new[] { "smelt", "fold" });

            // L67 makes order part of the craft, so trying the reverse is
            // a genuinely different thing to have tried.
            Assert.True(k.Attempt(new[] { "fold", "smelt" }).WasNovel);
        }

        [Fact]
        public void Enough_experimentation_reveals_a_stage_you_did_not_know()
        {
            var k = Apprentice();
            string found = null;

            found ??= k.Attempt(new[] { "smelt" }).Discovered;
            found ??= k.Attempt(new[] { "fold" }).Discovered;
            found ??= k.Attempt(new[] { "smelt", "fold" }).Discovered;
            found ??= k.Attempt(new[] { "fold", "smelt" }).Discovered;

            Assert.NotNull(found);
            Assert.True(k.Knows(found));
        }

        [Fact]
        public void Discovery_is_earned_by_exploring_not_by_luck()
        {
            // Two smiths who try the same number of novel sequences end up
            // knowing the same amount. Nothing here is a dice roll.
            var a = Apprentice();
            var b = Apprentice();

            foreach (var seq in new[]
                     {
                         new[] { "smelt" }, new[] { "fold" },
                         new[] { "smelt", "fold" }, new[] { "fold", "smelt" },
                     })
            {
                a.Attempt(seq);
                b.Attempt(seq);
            }

            Assert.Equal(a.KnownStages.Count(), b.KnownStages.Count());
        }

        [Fact]
        public void A_smith_who_runs_out_of_novelty_needs_the_world()
        {
            // You cannot bootstrap the whole craft alone at one bench.
            // Eventually you need a teacher, a ruin, or someone's notes.
            var k = new Knowledge(new[] { "smelt" }, discoverable: new string[0]);
            k.Attempt(new[] { "smelt" });

            Assert.Null(k.Attempt(new[] { "smelt" }).Discovered);
            Assert.Single(k.KnownStages);
        }

        // ── Near-miss hints (brainstorm §2.3) ────────────────────────────

        [Fact]
        public void A_poor_result_earns_a_nudge_about_what_went_wrong()
        {
            var k = Apprentice();
            var result = k.Attempt(
                new[] { "smelt" },
                result: new MaterialProperties(0.2f, 0.6f, 0.5f, 0.6f),
                potential: new MaterialProperties(0.8f, 0.6f, 0.5f, 0.6f));

            Assert.NotNull(result.Hint);
            Assert.Contains("edge", result.Hint);
        }

        [Fact]
        public void The_hint_points_at_the_worst_shortfall_only()
        {
            var k = Apprentice();
            var result = k.Attempt(
                new[] { "smelt" },
                result: new MaterialProperties(0.5f, 0.5f, 0.5f, 0.1f),
                potential: new MaterialProperties(0.55f, 0.55f, 0.55f, 0.9f));

            Assert.Contains("dirt", result.Hint);
        }

        [Fact]
        public void Good_work_earns_no_hint_at_all()
        {
            var k = Apprentice();
            var fine = new MaterialProperties(0.7f, 0.6f, 0.5f, 0.8f);

            Assert.Null(k.Attempt(new[] { "smelt" }, fine, fine).Hint);
        }

        // ── L73: knowledge is an economy ─────────────────────────────────

        [Fact]
        public void A_schematic_teaches_everything_written_in_it()
        {
            var k = Apprentice();
            var plans = new Schematic("Ashfell pattern", "Corran",
                new[] { "smelt", "fold", "quench", "temper" });

            Assert.Equal(2, k.Read(plans));
            Assert.True(k.Knows("quench"));
            Assert.True(k.Knows("temper"));
        }

        [Fact]
        public void Reading_a_schematic_twice_teaches_nothing_the_second_time()
        {
            var k = Apprentice();
            var plans = new Schematic("p", "Corran", new[] { "quench" });

            Assert.Equal(1, k.Read(plans));
            Assert.Equal(0, k.Read(plans));
        }

        [Fact]
        public void A_schematic_records_who_wrote_it()
        {
            var plans = new Schematic("Ashfell pattern", "Corran", new[] { "smelt", "fold" });

            Assert.Equal("Corran", plans.Author);
            Assert.Equal("smelt>fold", plans.Signature);
        }

        [Fact]
        public void Blank_and_unsigned_schematics_are_rejected()
        {
            Assert.Throws<ArgumentException>(() => new Schematic("p", "Corran", new string[0]));
            Assert.Throws<ArgumentException>(() => new Schematic("p", "", new[] { "smelt" }));
            Assert.Throws<ArgumentException>(() => new Schematic("", "Corran", new[] { "smelt" }));
        }

        [Fact]
        public void Being_taught_directly_works_too()
        {
            var k = Apprentice();
            Assert.True(k.Learn("quench"));
            Assert.False(k.Learn("quench"));
            Assert.True(k.Knows("quench"));
        }

        [Fact]
        public void Guards_reject_nonsense()
        {
            var k = Apprentice();
            Assert.Throws<ArgumentNullException>(() => k.Read(null));
            Assert.Throws<ArgumentNullException>(() => k.Attempt(null));
            Assert.Throws<ArgumentException>(() => k.Attempt(new string[0]));
            Assert.Throws<ArgumentException>(() => k.Learn(""));
        }
    }
}
