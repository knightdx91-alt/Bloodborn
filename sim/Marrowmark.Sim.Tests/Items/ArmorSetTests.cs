using System;
using Marrowmark.Sim.Combat;
using Marrowmark.Sim.Items;
using Xunit;

namespace Marrowmark.Sim.Tests.Items
{
    /// <summary>
    /// L63: armour is tracked per slot, and pieces break off one at a time
    /// so protection degrades in visible steps rather than vanishing.
    /// </summary>
    public class ArmorSetTests
    {
        [Fact]
        public void A_bare_fighter_has_no_protection_anywhere()
        {
            var set = new ArmorSet();

            foreach (ArmorSlot slot in Enum.GetValues(typeof(ArmorSlot)))
                Assert.Equal(ArmorClass.None, set.ProtectionAt(slot));

            Assert.True(set.IsStripped);
        }

        [Fact]
        public void A_matched_harness_protects_every_slot()
        {
            var set = ArmorSet.Of(ArmorClass.Plate);

            foreach (ArmorSlot slot in Enum.GetValues(typeof(ArmorSlot)))
                Assert.Equal(ArmorClass.Plate, set.ProtectionAt(slot));

            Assert.Equal(4, set.IntactPieces);
        }

        [Fact]
        public void Slots_map_to_the_right_hit_locations()
        {
            Assert.Equal(HitLocation.Head, ArmorSet.LocationOf(ArmorSlot.Head));
            Assert.Equal(HitLocation.Torso, ArmorSet.LocationOf(ArmorSlot.Torso));
            Assert.Equal(HitLocation.Limb, ArmorSet.LocationOf(ArmorSlot.Arms));
            Assert.Equal(HitLocation.Limb, ArmorSet.LocationOf(ArmorSlot.Legs));
        }

        [Fact]
        public void Mismatched_pieces_protect_their_own_slots_only()
        {
            // Piecemeal kit is normal for a poor fighter, and the model has
            // to represent it honestly.
            var set = new ArmorSet();
            set.Equip(ArmorSlot.Torso, new ArmorPiece(ArmorClass.Plate));
            set.Equip(ArmorSlot.Head, new ArmorPiece(ArmorClass.Light));

            Assert.Equal(ArmorClass.Plate, set.ProtectionAt(ArmorSlot.Torso));
            Assert.Equal(ArmorClass.Light, set.ProtectionAt(ArmorSlot.Head));
            Assert.Equal(ArmorClass.None, set.ProtectionAt(ArmorSlot.Arms));
        }

        // ── Pieces break off individually (L63) ──────────────────────────

        [Fact]
        public void A_piece_breaks_off_and_leaves_that_slot_bare()
        {
            var set = ArmorSet.Of(ArmorClass.Mail);
            var arm = set.At(ArmorSlot.Arms);

            arm.Durability.WearFraction(1f);
            Assert.True(set.TakeHit(ArmorSlot.Arms, 1f), "the piece should break");

            Assert.Equal(ArmorClass.None, set.ProtectionAt(ArmorSlot.Arms));
            Assert.False(arm.IsWorn);
        }

        [Fact]
        public void Losing_one_piece_leaves_the_rest_of_the_harness_intact()
        {
            // The whole point of per-slot: armour degrades in steps, it
            // does not vanish.
            var set = ArmorSet.Of(ArmorClass.Plate);

            set.At(ArmorSlot.Arms).Durability.WearFraction(1f);
            set.TakeHit(ArmorSlot.Arms, 1f);

            Assert.Equal(ArmorClass.None, set.ProtectionAt(ArmorSlot.Arms));
            Assert.Equal(ArmorClass.Plate, set.ProtectionAt(ArmorSlot.Torso));
            Assert.Equal(ArmorClass.Plate, set.ProtectionAt(ArmorSlot.Head));
            Assert.Equal(3, set.IntactPieces);
        }

        [Fact]
        public void A_harness_can_be_stripped_piece_by_piece()
        {
            var set = ArmorSet.Of(ArmorClass.Light);

            foreach (ArmorSlot slot in Enum.GetValues(typeof(ArmorSlot)))
            {
                set.At(slot).Durability.WearFraction(1f);
                set.TakeHit(slot, 1f);
            }

            Assert.True(set.IsStripped);
            Assert.Equal(0, set.IntactPieces);
        }

        [Fact]
        public void Losing_a_piece_makes_that_limb_dramatically_more_vulnerable()
        {
            var set = ArmorSet.Of(ArmorClass.Plate);

            var protectedHit = set.Resolve(ArmorSlot.Arms, 40f, DamageType.Cut).Final;

            set.At(ArmorSlot.Arms).Durability.WearFraction(1f);
            set.TakeHit(ArmorSlot.Arms, 1f);

            var bareHit = set.Resolve(ArmorSlot.Arms, 40f, DamageType.Cut).Final;

            Assert.True(bareHit > protectedHit * 2f,
                $"a bare limb ({bareHit:F1}) should be far more vulnerable than a plated one ({protectedHit:F1})");
        }

        [Fact]
        public void Resolving_a_blow_wears_the_piece_that_stopped_it()
        {
            var set = ArmorSet.Of(ArmorClass.Mail);
            var before = set.At(ArmorSlot.Torso).Durability.Condition;

            set.Resolve(ArmorSlot.Torso, 30f, DamageType.Blunt, wear: 5f);

            Assert.True(set.At(ArmorSlot.Torso).Durability.Condition < before);
        }

        [Fact]
        public void Hitting_a_bare_slot_breaks_nothing()
        {
            var set = new ArmorSet();
            Assert.False(set.TakeHit(ArmorSlot.Head, 100f));
        }

        [Fact]
        public void Death_wears_the_whole_harness(){
            var set = ArmorSet.Of(ArmorClass.Mail);
            var before = set.At(ArmorSlot.Head).Durability.Condition;

            set.WearFromDeath();

            foreach (ArmorSlot slot in Enum.GetValues(typeof(ArmorSlot)))
                Assert.True(set.At(slot).Durability.Condition < before);
        }

        [Fact]
        public void Equipping_replaces_and_unequipping_returns()
        {
            var set = new ArmorSet();
            var mail = new ArmorPiece(ArmorClass.Mail);
            set.Equip(ArmorSlot.Torso, mail);
            set.Equip(ArmorSlot.Torso, new ArmorPiece(ArmorClass.Plate));

            Assert.Equal(ArmorClass.Plate, set.ProtectionAt(ArmorSlot.Torso));

            var removed = set.Unequip(ArmorSlot.Torso);
            Assert.NotNull(removed);
            Assert.Equal(ArmorClass.None, set.ProtectionAt(ArmorSlot.Torso));
            Assert.Null(set.Unequip(ArmorSlot.Torso));
        }

        [Fact]
        public void Guards_reject_nonsense()
        {
            var set = ArmorSet.Of(ArmorClass.Mail);
            Assert.Throws<ArgumentNullException>(() => set.Equip(ArmorSlot.Head, null));
            Assert.Throws<ArgumentOutOfRangeException>(() => set.TakeHit(ArmorSlot.Head, -1f));
        }
    }
}
