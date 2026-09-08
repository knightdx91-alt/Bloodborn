using System;

namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// A fighter's life. Deliberately plain: design/combat.md §4 rules out
    /// wound systems and dismemberment — L20 is grounded, not
    /// simulationist — so there is nothing here but a number and a floor.
    ///
    /// Death consequences live elsewhere. What dying *costs* is the death
    /// ladder (L17/L32: durability, cargo, war loot, the Interior), and
    /// that is an economy concern, not a combat one.
    /// </summary>
    public sealed class Health
    {
        private float _current;

        public Health(float max)
        {
            if (max <= 0f)
                throw new ArgumentOutOfRangeException(nameof(max), "Max health must be greater than zero.");

            Max = max;
            _current = max;
        }

        public float Max { get; }

        public float Current => _current;

        public float Fraction => _current / Max;

        public bool IsDead => _current <= 0f;

        public bool IsAlive => !IsDead;

        /// <summary>
        /// Apply damage. Returns the amount actually taken, which is capped
        /// at what was left — overkill is not tracked, because nothing in
        /// the design rewards it.
        /// </summary>
        public float Take(float amount)
        {
            if (amount < 0f)
                throw new ArgumentOutOfRangeException(nameof(amount), "Damage cannot be negative.");

            var taken = Math.Min(amount, _current);
            _current -= taken;
            return taken;
        }

        /// <summary>
        /// Restore health. Cannot raise the dead — that is what shrines are
        /// for (L32), and it is a different system entirely.
        /// </summary>
        public float Heal(float amount)
        {
            if (amount < 0f)
                throw new ArgumentOutOfRangeException(nameof(amount), "Healing cannot be negative.");
            if (IsDead) return 0f;

            var healed = Math.Min(amount, Max - _current);
            _current += healed;
            return healed;
        }

        /// <summary>Restore to full. For respawns and tests.</summary>
        public void Reset() => _current = Max;
    }
}
