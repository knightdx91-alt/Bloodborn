namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// How a weapon hurts. design/combat.md §4.
    /// A crafter choosing a harder alloy, a heavier head, or a finer edge is
    /// choosing a position in the damage triangle — this is where material
    /// properties (L4) reach combat.
    /// </summary>
    public enum DamageType
    {
        Cut,
        Pierce,
        Blunt,
    }

    /// <summary>
    /// What the defender is wearing. Armour choice is a read on what you
    /// expect to fight — and in war (L25) a read on what the other Company
    /// fields.
    /// </summary>
    public enum ArmorClass
    {
        Light,
        Mail,
        Plate,
    }

    /// <summary>
    /// Where the blow landed. Deliberately coarse: design/combat.md §4 —
    /// "No dismemberment, no wound systems. L20 is grounded, not
    /// simulationist."
    /// </summary>
    public enum HitLocation
    {
        Torso,
        Limb,
        Head,
    }
}
