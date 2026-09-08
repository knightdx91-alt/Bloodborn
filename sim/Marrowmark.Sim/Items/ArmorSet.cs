using System;
using System.Collections.Generic;
using Marrowmark.Sim.Combat;

namespace Marrowmark.Sim.Items
{
    /// <summary>Where a piece of armour sits. L63.</summary>
    public enum ArmorSlot
    {
        Head,
        Torso,
        Arms,
        Legs,
    }

    /// <summary>
    /// One piece of armour: what it is, and how much life it has left.
    /// When it breaks it does not merely stop protecting — it comes off
    /// (L63), and that slot is bare for the rest of the fight.
    /// </summary>
    public sealed class ArmorPiece
    {
        public ArmorPiece(ArmorClass armorClass, DurabilityProfile profile)
        {
            Class = armorClass;
            Durability = new Durability(profile);
        }

        public ArmorPiece(ArmorClass armorClass)
            : this(armorClass, DurabilityProfile.Default) { }

        /// <summary>What this piece is made of, when it is still on you.</summary>
        public ArmorClass Class { get; }

        public Durability Durability { get; }

        /// <summary>False once the piece has broken and fallen away.</summary>
        public bool IsWorn => !Durability.IsBroken;

        /// <summary>
        /// The protection actually being provided. A piece that has fallen
        /// off protects nothing at all.
        /// </summary>
        public ArmorClass EffectiveClass => IsWorn ? Class : ArmorClass.None;
    }

    /// <summary>
    /// A full harness, tracked per slot (L63).
    ///
    /// Armour does not fail all at once. Pieces break and fall away one at
    /// a time, so protection degrades in visible steps: the vambrace goes,
    /// then the helm, and a fighter who started the day in plate finishes
    /// it half bare and increasingly desperate. That progression is legible
    /// to everyone watching, which is exactly the kind of no-UI information
    /// L20 wants — you can see how much fight someone has left in them.
    /// </summary>
    public sealed class ArmorSet
    {
        private readonly Dictionary<ArmorSlot, ArmorPiece> _pieces =
            new Dictionary<ArmorSlot, ArmorPiece>();

        /// <summary>An empty harness — every slot bare.</summary>
        public ArmorSet() { }

        /// <summary>A matching harness of one class in every slot.</summary>
        public static ArmorSet Of(ArmorClass armorClass, DurabilityProfile? profile = null)
        {
            var set = new ArmorSet();
            if (armorClass == ArmorClass.None) return set;

            foreach (ArmorSlot slot in Enum.GetValues(typeof(ArmorSlot)))
                set.Equip(slot, new ArmorPiece(armorClass, profile ?? DurabilityProfile.Default));

            return set;
        }

        /// <summary>Put a piece on, replacing whatever was there.</summary>
        public void Equip(ArmorSlot slot, ArmorPiece piece)
        {
            if (piece == null) throw new ArgumentNullException(nameof(piece));
            _pieces[slot] = piece;
        }

        /// <summary>Take a piece off. Returns what was removed, if anything.</summary>
        public ArmorPiece Unequip(ArmorSlot slot)
        {
            if (!_pieces.TryGetValue(slot, out var piece)) return null;
            _pieces.Remove(slot);
            return piece;
        }

        /// <summary>The piece in a slot, or null if the slot is bare.</summary>
        public ArmorPiece At(ArmorSlot slot) =>
            _pieces.TryGetValue(slot, out var piece) ? piece : null;

        /// <summary>
        /// What is actually protecting this slot right now — accounting for
        /// pieces that have broken and fallen away.
        /// </summary>
        public ArmorClass ProtectionAt(ArmorSlot slot)
        {
            var piece = At(slot);
            return piece == null ? ArmorClass.None : piece.EffectiveClass;
        }

        /// <summary>
        /// Where a blow to this slot lands for damage purposes
        /// (`combat.md` §4). Arms and legs are both limbs.
        /// </summary>
        public static HitLocation LocationOf(ArmorSlot slot)
        {
            switch (slot)
            {
                case ArmorSlot.Head: return HitLocation.Head;
                case ArmorSlot.Torso: return HitLocation.Torso;
                case ArmorSlot.Arms:
                case ArmorSlot.Legs: return HitLocation.Limb;
                default: throw new ArgumentOutOfRangeException(nameof(slot));
            }
        }

        /// <summary>
        /// Absorb a blow on one slot: wear the piece there, and report
        /// whether that blow was the one that broke it off (L62/L63).
        /// </summary>
        public bool TakeHit(ArmorSlot slot, float wear)
        {
            if (wear < 0f)
                throw new ArgumentOutOfRangeException(nameof(wear), "Wear cannot be negative.");

            var piece = At(slot);
            if (piece == null || !piece.IsWorn) return false;

            return piece.Durability.Use(wear);
        }

        /// <summary>
        /// Resolve a blow against this harness in one call: the protection
        /// on the struck slot, the hit location, and the wear it caused.
        /// </summary>
        public DamageResult Resolve(
            ArmorSlot slot,
            float weaponDamage,
            DamageType type,
            float wear = 0f,
            DamageTable table = null)
        {
            var result = Damage.Resolve(
                new DamageRequest
                {
                    WeaponDamage = weaponDamage,
                    Type = type,
                    Armor = ProtectionAt(slot),
                    Location = LocationOf(slot),
                },
                table ?? DamageTable.Default);

            if (wear > 0f) TakeHit(slot, wear);
            return result;
        }

        /// <summary>How many pieces are still being worn.</summary>
        public int IntactPieces
        {
            get
            {
                var count = 0;
                foreach (var piece in _pieces.Values)
                    if (piece.IsWorn) count++;
                return count;
            }
        }

        /// <summary>
        /// True when nothing is left. A fighter in this state is bare, and
        /// L57's damage table makes that genuinely dangerous.
        /// </summary>
        public bool IsStripped => IntactPieces == 0;

        /// <summary>
        /// The ~10% every death takes off every equipped item (L32),
        /// applied across the whole harness.
        /// </summary>
        public void WearFromDeath()
        {
            foreach (var piece in _pieces.Values)
                if (piece.IsWorn) piece.Durability.WearFromDeath();
        }
    }
}
