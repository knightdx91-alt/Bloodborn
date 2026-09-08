using System;

namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// Answers "how long does this fight last?" by actually simulating it
    /// against the real <see cref="Stamina"/>, <see cref="Damage"/> and
    /// <see cref="Health"/> systems — not by dividing health by damage.
    ///
    /// That distinction is the whole point. Sustained damage in Marrowmark
    /// is capped by the stamina economy (combat.md §2), so a formula would
    /// give an answer the game never produces. Simulating means the
    /// time-to-kill target in combat.md §4 — 5 to 15 seconds between
    /// comparable players — becomes a test that fails when tuning drifts,
    /// wherever the drift happened.
    /// </summary>
    public static class TimeToKill
    {
        /// <summary>Returned when the defender never dies inside the cap.</summary>
        public const float NeverKills = float.PositiveInfinity;

        /// <summary>
        /// Seconds for <paramref name="attacker"/> to kill
        /// <paramref name="defender"/>, assuming every blow lands on the
        /// torso and neither side disengages. A deliberate best case: real
        /// fights include misses, dodges and spacing, so this is the floor
        /// a matchup can produce, which is the number worth guarding.
        /// </summary>
        public static float Estimate(
            FighterSpec attacker,
            FighterSpec defender,
            DamageTable table = null,
            float stepSeconds = 1f / 60f,
            float capSeconds = 120f)
        {
            if (stepSeconds <= 0f)
                throw new ArgumentOutOfRangeException(nameof(stepSeconds), "Step must be positive.");
            if (capSeconds <= 0f)
                throw new ArgumentOutOfRangeException(nameof(capSeconds), "Cap must be positive.");

            table = table ?? DamageTable.Default;

            var stamina = new Stamina(attacker.Stamina);
            var health = new Health(defender.Health);

            var perHit = Damage.Resolve(
                new DamageRequest
                {
                    WeaponDamage = attacker.WeaponDamage,
                    Type = attacker.WeaponType,
                    Armor = defender.Armor,
                    Location = HitLocation.Torso,
                },
                table).Final;

            if (perHit <= 0f) return NeverKills;

            var elapsed = 0f;
            var untilNextAttack = 0f;

            while (elapsed < capSeconds)
            {
                if (untilNextAttack <= 0f)
                {
                    stamina.Spend(attacker.AttackCost);
                    health.Take(perHit);

                    if (health.IsDead) return elapsed;

                    // Exhaustion lengthens recovery rather than stopping the
                    // fighter — combat.md §2. This is what stops a duellist
                    // from swinging at full pace forever.
                    untilNextAttack = stamina.IsExhausted
                        ? attacker.AttackInterval * attacker.ExhaustedIntervalMultiplier
                        : attacker.AttackInterval;
                }

                stamina.Tick(stepSeconds);
                untilNextAttack -= stepSeconds;
                elapsed += stepSeconds;
            }

            return NeverKills;
        }

        /// <summary>
        /// Time to kill between two identical fighters — the "comparable
        /// players" case combat.md §4 puts a number on.
        /// </summary>
        public static float Mirror(FighterSpec spec, DamageTable table = null) =>
            Estimate(spec, spec, table);
    }
}
