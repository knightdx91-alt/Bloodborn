using System;
using System.Linq;
using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// L56 and combat.md §3: techniques are primarily how you move, and
    /// are Marrowmark's Sword Skill. L95: three per family, taught by a
    /// person and never gated; what you cannot yet back with skill you
    /// pay for in stamina and wind-up.
    /// </summary>
    public class TechniqueTests
    {
        private static readonly TechniqueProfile P = TechniqueProfile.Default;

        private static Repertoire Master()
        {
            var r = new Repertoire();
            foreach (var t in TechniqueBook.All) r.Grant(t.Id);
            return r;
        }

        // ── The book ────────────────────────────────────────────────────

        [Fact]
        public void Three_per_family_eighteen_in_all()
        {
            Assert.Equal(P.PerFamily * 6, TechniqueBook.All.Count);
            foreach (WeaponFamily f in Enum.GetValues(typeof(WeaponFamily)))
            {
                var of = TechniqueBook.Of(f).ToList();
                Assert.Equal(P.PerFamily, of.Count);
                Assert.Equal(new[] { 1, 2, 3 }, of.Select(t => t.Tier).ToArray());
            }
            Assert.Equal(TechniqueBook.All.Count, TechniqueBook.All.Select(t => t.Id).Distinct().Count());
        }

        [Fact]
        public void Every_technique_moves_the_body()
        {
            // Mobility is the point. A technique that does not move you is
            // not one.
            foreach (var t in TechniqueBook.All)
                Assert.True(t.Distance > 0f, t.Id);
        }

        [Fact]
        public void Nothing_exceeds_what_a_trained_body_could_do()
        {
            // L56's ceiling. No double jumps, no air dashes.
            foreach (var t in TechniqueBook.All)
                Assert.True(t.Distance <= P.MaxDistance, $"{t.Id} travels {t.Distance} m");
        }

        [Fact]
        public void Every_technique_is_a_commitment()
        {
            // Still stamina-priced, still readable (§6's grammar survives).
            foreach (var t in TechniqueBook.All)
            {
                Assert.True(t.StaminaCost > 0f, t.Id);
                Assert.True(t.WindupSeconds > 0f, t.Id);
            }
        }

        [Fact]
        public void A_technique_lands_a_blow_its_family_can_throw()
        {
            foreach (var t in TechniqueBook.All)
                Assert.True(WeaponFamilyProfile.For(t.Family).Allows(t.Strike),
                    $"{t.Id} strikes {t.Strike}, which {t.Family} cannot");
        }

        [Fact]
        public void The_bow_moves_like_everyone_else()
        {
            // Decided 2026-10-14: archers are mobile, not turrets.
            var bow = TechniqueBook.Of(WeaponFamily.BowAndCrossbow).ToList();
            Assert.Equal(P.PerFamily, bow.Count);
            Assert.True(bow.Select(t => t.Bearing).Distinct().Count() > 1);
        }

        [Fact]
        public void Each_family_moves_in_more_than_one_direction()
        {
            foreach (WeaponFamily f in Enum.GetValues(typeof(WeaponFamily)))
                Assert.True(TechniqueBook.Of(f).Select(t => t.Bearing).Distinct().Count() >= 2, f.ToString());
        }

        // ── Teaching ────────────────────────────────────────────────────

        [Fact]
        public void Nobody_knows_anything_until_shown()
        {
            var r = new Repertoire();
            Assert.Empty(r.Known);
            Assert.Equal(AttemptResult.NotKnown,
                r.Try("lunge", new Stamina(StaminaProfile.Default), 1f).Result);
        }

        [Fact]
        public void A_person_who_knows_it_can_show_you()
        {
            var student = new Repertoire();
            Assert.Equal(TeachResult.Taught, student.LearnFrom(Master(), "lunge"));
            Assert.True(student.Knows("lunge"));
            Assert.Equal(TeachResult.AlreadyKnown, student.LearnFrom(Master(), "lunge"));
        }

        [Fact]
        public void You_cannot_be_shown_what_the_teacher_does_not_know()
        {
            var teacher = new Repertoire();
            teacher.Grant("lunge");
            var student = new Repertoire();

            Assert.Equal(TeachResult.TeacherDoesNotKnow, student.LearnFrom(teacher, "vaulting-point"));
            Assert.False(student.Knows("vaulting-point"));
        }

        [Fact]
        public void You_cannot_teach_yourself()
        {
            var r = Master();
            Assert.Equal(TeachResult.SameFighter, r.LearnFrom(r, "lunge"));
        }

        [Fact]
        public void Knowledge_spreads_person_to_person()
        {
            // Like spells (L9): the student becomes a teacher.
            var a = Master();
            var b = new Repertoire();
            var c = new Repertoire();

            b.LearnFrom(a, "slip-behind");
            Assert.Equal(TeachResult.Taught, c.LearnFrom(b, "slip-behind"));
        }

        [Fact]
        public void Learning_is_not_gated_by_skill()
        {
            // L95 as decided: a day-one student can be shown a master's
            // move. What stops them being a master is below.
            var student = new Repertoire();
            Assert.Equal(TeachResult.Taught, student.LearnFrom(Master(), "leaping-overhead"));
            Assert.Equal(AttemptResult.Started,
                student.Try("leaping-overhead", new Stamina(StaminaProfile.Default), familySkill: 0f).Result);
        }

        // ── Doing ───────────────────────────────────────────────────────

        [Fact]
        public void Unskilled_hands_pay_more_and_telegraph_longer()
        {
            // This is what keeps L19 true without a gate: the move happens,
            // and everyone can see it coming.
            var t = TechniqueBook.Find("leaping-overhead")!;

            Assert.True(t.CostFor(0f, P) > t.CostFor(1f, P));
            Assert.True(t.WindupFor(0f, P) > t.WindupFor(1f, P));
            Assert.Equal(t.StaminaCost, t.CostFor(1f, P), 4);
            Assert.Equal(t.WindupSeconds, t.WindupFor(1f, P), 4);
            Assert.True(t.CostFor(0.5f, P) > t.CostFor(1f, P));
            Assert.True(t.CostFor(0.5f, P) < t.CostFor(0f, P));
        }

        [Fact]
        public void A_technique_is_paid_from_the_bar()
        {
            var r = new Repertoire();
            r.LearnFrom(Master(), "lunge");
            var stamina = new Stamina(StaminaProfile.Default);
            var before = stamina.Current;

            var a = r.Try("lunge", stamina, 1f);

            Assert.Equal(AttemptResult.Started, a.Result);
            Assert.True(a.Afforded);
            Assert.Equal(before - a.Cost, stamina.Current, 3);
            Assert.Equal(Bearing.Forward, a.Bearing);
            Assert.True(a.Distance > 0f);
        }

        [Fact]
        public void An_empty_bar_refuses_it_as_it_refuses_the_dodge()
        {
            var r = new Repertoire();
            r.LearnFrom(Master(), "lunge");
            var stamina = new Stamina(StaminaProfile.Default);
            while (!stamina.IsExhausted) stamina.Spend(stamina.Max);

            var a = r.Try("lunge", stamina, 1f);

            Assert.Equal(AttemptResult.Exhausted, a.Result);
        }

        [Fact]
        public void A_masters_move_in_a_students_hands_costs_more_than_a_students_move_in_a_masters()
        {
            // The order L19 wants: the veteran is frightening because they
            // can be somewhere sooner and cheaper, not because they hit harder.
            var tier1 = TechniqueBook.Of(WeaponFamily.TwoHanded).First();
            var tier3 = TechniqueBook.Of(WeaponFamily.TwoHanded).Last();

            Assert.True(tier3.CostFor(0f, P) > tier1.CostFor(1f, P));
            Assert.True(tier3.WindupFor(0f, P) > tier1.WindupFor(1f, P));
        }
    }
}
