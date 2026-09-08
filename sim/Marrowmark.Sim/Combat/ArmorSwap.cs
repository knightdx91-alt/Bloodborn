using System;

namespace Marrowmark.Sim.Combat
{
    /// <summary>How long each armour class takes to get into. L58.</summary>
    public struct ArmorTimes
    {
        public float DonNone;   // stripping to nothing still takes a moment
        public float DonLight;
        public float DonMail;
        public float DonPlate;

        /// <summary>
        /// Taking armour off as a fraction of putting it on. Always faster —
        /// buckles come undone quicker than they go on, and a hauler who
        /// needs to shed weight in a hurry should be able to.
        /// </summary>
        public float DoffFraction;

        /// <summary>
        /// Time multiplier when someone helps. Historically plate genuinely
        /// needed a second pair of hands; here it gives a caravan crew a
        /// reason to stop together rather than each person fending for
        /// themselves.
        /// </summary>
        public float AssistedMultiplier;

        public float DonSeconds(ArmorClass armor)
        {
            switch (armor)
            {
                case ArmorClass.None: return DonNone;
                case ArmorClass.Light: return DonLight;
                case ArmorClass.Mail: return DonMail;
                case ArmorClass.Plate: return DonPlate;
                default: throw new ArgumentOutOfRangeException(nameof(armor));
            }
        }

        public static ArmorTimes Default => new ArmorTimes
        {
            DonNone = 0f,
            DonLight = 6f,
            DonMail = 25f,
            DonPlate = 75f,
            DoffFraction = 0.35f,
            AssistedMultiplier = 0.6f,
        };
    }

    /// <summary>
    /// Changing armour on the road (L58). You can do it anywhere; the
    /// armour decides how long you are helpless doing it.
    ///
    /// This is what makes L57's tradeoff a live decision rather than a
    /// loadout screen. A guard escorting a caravan is either armoured and
    /// carrying nothing, or carrying goods and seventy-five seconds away
    /// from being ready — and an ambusher can read which, at a distance,
    /// before choosing the moment.
    /// </summary>
    public sealed class ArmorSwap
    {
        private readonly ArmorTimes _times;
        private ArmorClass _target;
        private float _remaining;
        private bool _swapping;

        public ArmorSwap(ArmorClass startingArmor, ArmorTimes times)
        {
            if (times.DoffFraction < 0f)
                throw new ArgumentOutOfRangeException(nameof(times), "Doff fraction cannot be negative.");

            Current = startingArmor;
            _times = times;
        }

        public ArmorSwap(ArmorClass startingArmor) : this(startingArmor, ArmorTimes.Default) { }

        /// <summary>What is actually being worn right now.</summary>
        public ArmorClass Current { get; private set; }

        /// <summary>True while mid-change — and therefore vulnerable.</summary>
        public bool IsSwapping => _swapping;

        /// <summary>What the swap is heading towards. Meaningless when idle.</summary>
        public ArmorClass Target => _target;

        public float RemainingSeconds => _swapping ? _remaining : 0f;

        public float TotalSeconds { get; private set; }

        /// <summary>Progress as 0..1, for a progress ring or an onlooker's read.</summary>
        public float Progress =>
            !_swapping || TotalSeconds <= 0f ? 0f : 1f - (_remaining / TotalSeconds);

        /// <summary>
        /// How long changing into <paramref name="target"/> would take from
        /// what is currently worn: shed the old, then put on the new.
        /// </summary>
        public float SecondsToChangeTo(ArmorClass target, bool assisted = false)
        {
            var doff = _times.DonSeconds(Current) * _times.DoffFraction;
            var don = _times.DonSeconds(target);
            var total = doff + don;
            return assisted ? total * _times.AssistedMultiplier : total;
        }

        /// <summary>
        /// Begin changing armour. Returns false if already wearing the
        /// target. Starting a new swap mid-swap abandons the old one.
        /// </summary>
        public bool Begin(ArmorClass target, bool assisted = false)
        {
            if (target == Current && !_swapping) return false;

            _target = target;
            TotalSeconds = SecondsToChangeTo(target, assisted);
            _remaining = TotalSeconds;
            _swapping = true;

            if (_remaining <= 0f) Complete();
            return true;
        }

        /// <summary>
        /// Advance the swap. Returns true on the tick it completes.
        /// </summary>
        public bool Tick(float deltaSeconds)
        {
            if (!_swapping || deltaSeconds <= 0f) return false;

            _remaining -= deltaSeconds;
            if (_remaining > 0f) return false;

            Complete();
            return true;
        }

        /// <summary>
        /// Cancel the swap — being struck, or choosing to fight in what you
        /// have. **Progress is lost.** You keep wearing whatever you had on,
        /// and starting again starts from the beginning. That is what makes
        /// the decision to armour up a gamble rather than a free action.
        /// </summary>
        public void Interrupt()
        {
            _swapping = false;
            _remaining = 0f;
            TotalSeconds = 0f;
        }

        private void Complete()
        {
            Current = _target;
            _swapping = false;
            _remaining = 0f;
        }
    }
}
