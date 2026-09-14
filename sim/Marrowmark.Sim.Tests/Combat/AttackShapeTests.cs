using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// combat.md §6's vocabulary. These assert the GRAMMAR, not the
    /// numbers: a player is supposed to learn all three shapes in the first
    /// hour by reading them, and that only works if the relationships
    /// between them hold no matter how the timings are tuned later.
    /// </summary>
    public class AttackShapeTests
    {
        private static readonly AttackProfile Quick = AttackProfile.Quick;
        private static readonly AttackProfile Heavy = AttackProfile.Heavy;
        private static readonly AttackProfile Committed = AttackProfile.Committed;

        [Fact]
        public void Commitment_escalates_across_the_three_shapes()
        {
            // The whole grammar in one assertion: the longer the windup,
            // the more it hurts and the longer you hang afterwards. Every
            // read a player makes depends on this ordering holding.
            Assert.True(Quick.WindupSeconds < Heavy.WindupSeconds);
            Assert.True(Heavy.WindupSeconds < Committed.WindupSeconds);

            Assert.True(Quick.DamageMultiplier < Heavy.DamageMultiplier);
            Assert.True(Heavy.DamageMultiplier < Committed.DamageMultiplier);

            Assert.True(Quick.RecoverySeconds < Heavy.RecoverySeconds);
            Assert.True(Heavy.RecoverySeconds < Committed.RecoverySeconds);
        }

        [Fact]
        public void The_committed_attack_cannot_be_parried()
        {
            // §6: "Cannot be parried." This is what makes disengage a
            // distinct answer rather than a worse parry.
            Assert.False(Committed.CanBeParried);
            Assert.True(Quick.CanBeParried);
            Assert.True(Heavy.CanBeParried);
        }

        [Fact]
        public void Every_windup_survives_the_latency_budget()
        {
            // combat.md §7 budgets ~100ms of network tolerance. A windup
            // near that is not a telegraph, it is a coin toss for anyone
            // not on a local connection — and §6 says readability is a
            // hard requirement, not a stretch goal.
            foreach (var p in new[] { Quick, Heavy, Committed })
                Assert.True(p.WindupSeconds >= 0.2f);
        }

        [Fact]
        public void Each_shape_is_told_apart_by_its_windup_not_its_damage()
        {
            // §6: readability comes from animation and sound only — no
            // glowing weapons, no prompt. What a player actually sees is
            // the wind-up, so the gaps between them have to be wide enough
            // to read under pressure. Damage is learned by being hit, which
            // is too late to be a tell.
            Assert.True(Heavy.WindupSeconds - Quick.WindupSeconds >= 0.25f);
            Assert.True(Committed.WindupSeconds - Heavy.WindupSeconds >= 0.25f);
        }

        [Fact]
        public void The_quick_attack_is_the_one_you_can_afford_to_throw()
        {
            // §6 says quick attacks chain. They cannot chain if each one
            // costs what a heavy costs.
            Assert.True(Quick.StaminaCost < Heavy.StaminaCost);
            Assert.True(Heavy.StaminaCost < Committed.StaminaCost);
        }

        [Fact]
        public void The_committed_attack_is_hard_to_simply_step_out_of()
        {
            // §6: "badly punished if dodged late." A whole-body swing has
            // to cover ground the other two do not, or disengage would be
            // strictly easier than the dodge it is supposed to replace.
            Assert.True(Committed.Reach > Heavy.Reach);
            Assert.True(Committed.ArcDegrees > Heavy.ArcDegrees);
            Assert.True(Heavy.ArcDegrees > Quick.ArcDegrees);
        }

        [Fact]
        public void A_dodge_can_clear_the_widest_swing()
        {
            // The systems have to agree. If the committed attack's reach
            // exceeded what a dodge covers, disengage would not be an
            // answer at all and §6's third line would be a lie.
            Assert.True(DodgeProfile.Default.Distance > Committed.Reach - 0.5f);
        }

        [Fact]
        public void For_returns_the_matching_shape()
        {
            Assert.Equal(AttackShape.Quick, AttackProfile.For(AttackShape.Quick).Shape);
            Assert.Equal(AttackShape.Heavy, AttackProfile.For(AttackShape.Heavy).Shape);
            Assert.Equal(AttackShape.Committed, AttackProfile.For(AttackShape.Committed).Shape);
        }

        [Fact]
        public void An_attack_runs_the_same_machinery_whatever_its_shape()
        {
            // Monsters use the same three shapes with different bodies
            // (§6), so nothing about the shape may special-case the phase
            // machine.
            foreach (var shape in new[] { AttackShape.Quick, AttackShape.Heavy, AttackShape.Committed })
            {
                var p = AttackProfile.For(shape);
                var a = new Attack(p);
                var s = new Stamina(StaminaProfile.Default);

                Assert.True(a.TryStart(s));
                Assert.Equal(AttackPhase.Windup, a.Phase);
                Assert.False(a.TryConsumeHit());

                for (var t = 0f; t < p.WindupSeconds + 0.01f; t += 1f / 60f) a.Tick(1f / 60f);
                Assert.Equal(AttackPhase.Active, a.Phase);
                Assert.True(a.TryConsumeHit());
                Assert.False(a.TryConsumeHit());
            }
        }
    }
}
