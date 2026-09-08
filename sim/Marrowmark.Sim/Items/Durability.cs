using System;

namespace Marrowmark.Sim.Items
{
    /// <summary>What a repair cost the item.</summary>
    public struct RepairResult
    {
        /// <summary>Condition restored.</summary>
        public float Restored;

        /// <summary>Permanent ceiling lost — the price of the repair (L59).</summary>
        public float CeilingLost;

        /// <summary>True if this repair was the one that finished the item off.</summary>
        public bool BecameScrap;
    }

    /// <summary>
    /// One item's condition over its whole life. L3, L32, L59, L60, L61.
    ///
    /// The design's most important economic object. `brainstorm.md` §2.6
    /// names three sinks that keep crafters in business — war losses,
    /// permadeath deletion, and wear — but only wear touches every player
    /// every day. Items that could be repaired forever would accumulate,
    /// and a masterwork blade forged in year one would still be circulating
    /// in year five. **Every repair costs the item a little of its life**,
    /// so gear genuinely leaves the world and someone has to make more.
    /// </summary>
    public sealed class Durability
    {
        private readonly DurabilityProfile _profile;
        private readonly float _originalMax;

        public Durability(DurabilityProfile profile)
        {
            if (profile.MaxCondition <= 0f)
                throw new ArgumentOutOfRangeException(
                    nameof(profile), "MaxCondition must be greater than zero.");

            _profile = profile;
            _originalMax = profile.MaxCondition;
            Ceiling = profile.MaxCondition;
            Condition = profile.MaxCondition;
        }

        public Durability() : this(DurabilityProfile.Default) { }

        /// <summary>Condition right now.</summary>
        public float Condition { get; private set; }

        /// <summary>
        /// The most condition this item can currently hold. Starts at the
        /// original maximum and shrinks with every repair — this falling
        /// number is the item's remaining life.
        /// </summary>
        public float Ceiling { get; private set; }

        /// <summary>What this item's ceiling was when it was made.</summary>
        public float OriginalMax => _originalMax;

        /// <summary>Condition as a fraction of the current ceiling.</summary>
        public float Fraction => Ceiling <= 0f ? 0f : Condition / Ceiling;

        /// <summary>
        /// Remaining life as a fraction — how much of the original ceiling
        /// survives. This is what a buyer inspecting second-hand gear cares
        /// about, and what a maker's mark is worth staking a name on.
        /// </summary>
        public float RemainingLife => Ceiling / _originalMax;

        /// <summary>
        /// True once the ceiling has fallen too far to be worth repairing.
        /// The item is materials now, not equipment.
        /// </summary>
        public bool IsScrap => Ceiling < _originalMax * _profile.ScrapCeilingFraction;

        /// <summary>
        /// How well the item currently performs, 0..1, applied to whatever
        /// the item does — weapon damage, armour protection.
        ///
        /// L60: full performance down to the threshold, then a decline to
        /// <see cref="DurabilityProfile.MinPerformance"/>. Never reaches
        /// zero, because L3 forbids anything breaking in your hands.
        /// </summary>
        public float Performance
        {
            get
            {
                var f = Fraction;
                if (f >= _profile.PerformanceThreshold) return 1f;
                if (_profile.PerformanceThreshold <= 0f) return 1f;

                var t = f / _profile.PerformanceThreshold; // 0..1 below the threshold
                return _profile.MinPerformance + (1f - _profile.MinPerformance) * t;
            }
        }

        /// <summary>Wear the item by an absolute amount.</summary>
        public void Wear(float amount)
        {
            if (amount < 0f)
                throw new ArgumentOutOfRangeException(nameof(amount), "Wear cannot be negative.");

            Condition = Math.Max(0f, Condition - amount);
        }

        /// <summary>Wear by a fraction of the current ceiling.</summary>
        public void WearFraction(float fraction)
        {
            if (fraction < 0f)
                throw new ArgumentOutOfRangeException(nameof(fraction), "Wear cannot be negative.");

            Wear(Ceiling * fraction);
        }

        /// <summary>
        /// The ~10% hit every death puts on every equipped item (L32). The
        /// casual player's contribution to the crafting economy, paid a
        /// little at a time without ever being asked.
        /// </summary>
        public void WearFromDeath() => WearFraction(_profile.DeathWearFraction);

        /// <summary>
        /// How much ceiling a repair by this smith would cost the item.
        /// </summary>
        /// <param name="smithSkill">0 for an untrained hand, 1 for a master.</param>
        public float RepairCostAtSkill(float smithSkill)
        {
            var s = smithSkill < 0f ? 0f : (smithSkill > 1f ? 1f : smithSkill);
            var lossFraction = _profile.NoviceRepairLoss
                               + (_profile.MasterRepairLoss - _profile.NoviceRepairLoss) * s;
            return _originalMax * lossFraction;
        }

        /// <summary>
        /// Restore the item to its ceiling, at the cost of some of that
        /// ceiling (L59). L61: anyone may do this; skill decides the price.
        /// A field patch by an amateur gets you home and shortens the
        /// blade's life; a master's bench repair costs it almost nothing.
        /// </summary>
        public RepairResult Repair(float smithSkill)
        {
            if (IsScrap)
                return new RepairResult { Restored = 0f, CeilingLost = 0f, BecameScrap = false };

            var lost = RepairCostAtSkill(smithSkill);
            var restored = Ceiling - Condition;

            Ceiling = Math.Max(0f, Ceiling - lost);
            Condition = Ceiling;

            return new RepairResult
            {
                Restored = restored,
                CeilingLost = lost,
                BecameScrap = IsScrap,
            };
        }
    }
}
