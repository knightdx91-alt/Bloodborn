using System;
using Marrowmark.Sim.Combat;
using Marrowmark.Sim.Items;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// L64: five cutting arcs plus the thrust, chosen by free aim. These
    /// assert that where you aim decides what breaks — the thing that makes
    /// L63's per-slot armour worth having.
    /// </summary>
    public class TargetingTests
    {
        [Fact]
        public void Overhead_blows_land_on_the_head()
        {
            Assert.Equal(ArmorSlot.Head, Targeting.SlotFor(AttackDirection.Overhead));
        }

        [Fact]
        public void Low_arcs_land_on_the_legs()
        {
            Assert.Equal(ArmorSlot.Legs, Targeting.SlotFor(AttackDirection.LowerLeft));
            Assert.Equal(ArmorSlot.Legs, Targeting.SlotFor(AttackDirection.LowerRight));
        }

        [Fact]
        public void Thrusts_and_high_cuts_land_on_the_torso()
        {
            Assert.Equal(ArmorSlot.Torso, Targeting.SlotFor(AttackDirection.Thrust));
            Assert.Equal(ArmorSlot.Torso, Targeting.SlotFor(AttackDirection.UpperLeft));
            Assert.Equal(ArmorSlot.Torso, Targeting.SlotFor(AttackDirection.UpperRight));
        }

        [Fact]
        public void Nothing_is_aimed_at_the_arms_because_arms_are_what_you_defend_with()
        {
            foreach (AttackDirection d in Enum.GetValues(typeof(AttackDirection)))
                Assert.NotEqual(ArmorSlot.Arms, Targeting.SlotFor(d));

            Assert.Equal(ArmorSlot.Arms, Targeting.GuardWearSlot);
        }

        // ── Guard resolution ─────────────────────────────────────────────

        [Fact]
        public void A_matching_guard_blocks()
        {
            Assert.Equal(GuardOutcome.Blocked,
                Targeting.Resolve(AttackDirection.Overhead, AttackDirection.Overhead));
        }

        [Fact]
        public void An_adjacent_guard_turns_the_blow_partly()
        {
            // Being nearly right should be worth something.
            Assert.Equal(GuardOutcome.Glancing,
                Targeting.Resolve(AttackDirection.Overhead, AttackDirection.UpperLeft));
            Assert.Equal(GuardOutcome.Glancing,
                Targeting.Resolve(AttackDirection.LowerLeft, AttackDirection.UpperLeft));
        }

        [Fact]
        public void A_guard_on_the_wrong_side_does_nothing()
        {
            Assert.Equal(GuardOutcome.Clean,
                Targeting.Resolve(AttackDirection.LowerRight, AttackDirection.UpperLeft));
        }

        [Fact]
        public void Only_a_thrust_guard_stops_a_thrust()
        {
            foreach (AttackDirection guard in Enum.GetValues(typeof(AttackDirection)))
            {
                var outcome = Targeting.Resolve(AttackDirection.Thrust, guard);

                if (guard == AttackDirection.Thrust)
                    Assert.Equal(GuardOutcome.Blocked, outcome);
                else
                    Assert.Equal(GuardOutcome.Clean, outcome);
            }
        }

        [Fact]
        public void The_wheel_wraps_so_the_outer_arcs_are_neighbours()
        {
            Assert.True(Targeting.AreAdjacent(AttackDirection.UpperLeft, AttackDirection.LowerLeft));
        }

        [Fact]
        public void A_direction_is_not_adjacent_to_itself()
        {
            foreach (AttackDirection d in Enum.GetValues(typeof(AttackDirection)))
                Assert.False(Targeting.AreAdjacent(d, d));
        }

        // ── Blocking is a stamina war, not an off switch (L56) ───────────

        [Fact]
        public void Blocking_reduces_damage_without_erasing_it()
        {
            var blocked = Targeting.DamageMultiplier(GuardOutcome.Blocked);

            Assert.True(blocked > 0f,
                "a blocked blow must still carry something through, or blocking is an off switch");
            Assert.True(blocked < Targeting.DamageMultiplier(GuardOutcome.Glancing));
        }

        [Fact]
        public void Outcomes_are_ordered_the_way_a_fighter_would_expect()
        {
            Assert.True(
                Targeting.DamageMultiplier(GuardOutcome.Blocked) <
                Targeting.DamageMultiplier(GuardOutcome.Glancing));
            Assert.True(
                Targeting.DamageMultiplier(GuardOutcome.Glancing) <
                Targeting.DamageMultiplier(GuardOutcome.Clean));
            Assert.Equal(1f, Targeting.DamageMultiplier(GuardOutcome.Clean), 3);
        }

        // ── The whole point: aim decides what breaks ─────────────────────

        [Fact]
        public void Fighting_someone_overhead_all_day_ruins_their_helm_and_nothing_else()
        {
            var set = ArmorSet.Of(ArmorClass.Mail);
            var slot = Targeting.SlotFor(AttackDirection.Overhead);

            while (set.At(slot).IsWorn)
                set.TakeHit(slot, 5f);

            Assert.Equal(ArmorClass.None, set.ProtectionAt(ArmorSlot.Head));
            Assert.Equal(ArmorClass.Mail, set.ProtectionAt(ArmorSlot.Torso));
            Assert.Equal(ArmorClass.Mail, set.ProtectionAt(ArmorSlot.Legs));
            Assert.Equal(3, set.IntactPieces);
        }

        [Fact]
        public void Once_the_helm_is_gone_overhead_blows_become_devastating()
        {
            var set = ArmorSet.Of(ArmorClass.Plate);

            var before = set.Resolve(ArmorSlot.Head, 40f, DamageType.Cut).Final;

            set.At(ArmorSlot.Head).Durability.WearFraction(1f);
            set.TakeHit(ArmorSlot.Head, 1f);

            var after = set.Resolve(ArmorSlot.Head, 40f, DamageType.Cut).Final;

            Assert.True(after > before * 2f,
                $"a bare head ({after:F1}) should be far worse than a helmed one ({before:F1})");
        }

        [Fact]
        public void Defending_all_day_wears_your_arms_out()
        {
            // The most grounded failure this system can produce: a fighter
            // whose vambraces give out because they parried everything.
            var set = ArmorSet.Of(ArmorClass.Mail);

            while (set.At(Targeting.GuardWearSlot).IsWorn)
                set.TakeHit(Targeting.GuardWearSlot, 5f);

            Assert.Equal(ArmorClass.None, set.ProtectionAt(ArmorSlot.Arms));
            Assert.Equal(ArmorClass.Mail, set.ProtectionAt(ArmorSlot.Torso));
        }

        [Fact]
        public void Unknown_directions_are_rejected()
        {
            Assert.Throws<ArgumentOutOfRangeException>(() =>
                Targeting.SlotFor((AttackDirection)99));
            Assert.Throws<ArgumentOutOfRangeException>(() =>
                Targeting.DamageMultiplier((GuardOutcome)99));
        }
    }
}
