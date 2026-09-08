namespace Marrowmark.Sim.Combat
{
    /// <summary>
    /// The arc a blow travels along (L64). Five cutting directions plus the
    /// thrust, chosen by free aim rather than a menu — Kingdom Come's
    /// system, snapped to the nearest zone on a controller.
    ///
    /// Direction is not a separate system from the attack shapes in
    /// combat.md §6. It is the other half of the same telegraph: the weight
    /// shift says quick or heavy, the wind-up says where. One read, two
    /// pieces of information.
    /// </summary>
    public enum AttackDirection
    {
        Overhead,
        UpperLeft,
        UpperRight,
        LowerLeft,
        LowerRight,

        /// <summary>
        /// The gap-seeking attack. Guarded only by a matching thrust guard,
        /// which makes it strong against a swordsman reading cuts — and
        /// readable in its own right, because nothing else winds up like it.
        /// </summary>
        Thrust,
    }

    /// <summary>How well a guard answered a blow.</summary>
    public enum GuardOutcome
    {
        /// <summary>Guard matched the incoming arc. Absorbed.</summary>
        Blocked,

        /// <summary>Guard was adjacent. Turned, but not cleanly.</summary>
        Glancing,

        /// <summary>Guard was somewhere else entirely. Full contact.</summary>
        Clean,
    }
}
