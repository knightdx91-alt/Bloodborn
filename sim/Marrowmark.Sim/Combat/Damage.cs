using System;

namespace Marrowmark.Sim.Combat
{
    /// <summary>One blow, described before it is resolved.</summary>
    public struct DamageRequest
    {
        /// <summary>
        /// The weapon's raw damage. design/combat.md §3: raw damage comes
        /// from the weapon, and weapons come from players (L4). Skill does
        /// not meaningfully raise this — that is what keeps combat from
        /// becoming a stat check and what makes crafters famous.
        /// </summary>
        public float WeaponDamage;

        public DamageType Type;
        public ArmorClass Armor;
        public HitLocation Location;
    }

    /// <summary>
    /// A resolved blow, with its parts kept separate. The breakdown exists
    /// so tuning can be inspected — when a matchup feels wrong, you want to
    /// see which multiplier caused it.
    /// </summary>
    public struct DamageResult
    {
        public float Final;
        public float ArmorMultiplier;
        public float LocationMultiplier;
    }

    /// <summary>
    /// Resolves blows against the damage triangle (design/combat.md §4).
    /// Pure and deterministic — no randomness, no engine, no global state.
    /// </summary>
    public static class Damage
    {
        public static DamageResult Resolve(DamageRequest request, DamageTable table)
        {
            if (table == null) throw new ArgumentNullException(nameof(table));
            if (request.WeaponDamage < 0f)
                throw new ArgumentOutOfRangeException(
                    nameof(request), "Weapon damage cannot be negative.");

            var armor = table.Against(request.Type, request.Armor);
            var location = table.At(request.Location);

            return new DamageResult
            {
                Final = request.WeaponDamage * armor * location,
                ArmorMultiplier = armor,
                LocationMultiplier = location,
            };
        }

        /// <summary>
        /// Convenience overload using the launch table.
        /// </summary>
        public static DamageResult Resolve(DamageRequest request) =>
            Resolve(request, DamageTable.Default);
    }
}
