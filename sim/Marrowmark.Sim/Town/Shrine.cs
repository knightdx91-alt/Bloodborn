namespace Marrowmark.Sim.Town
{
    /// <summary>
    /// The shrine stone: where the dying are knitted back (lore.md §3).
    /// Mechanically the respawn point and spiritually the same stone,
    /// which is the whole trick — the death ladder is taught from its
    /// bottom rung (onboarding.md §3) by a toll you feel.
    ///
    /// Where the player's body goes is the engine's business. What it
    /// costs is this.
    /// </summary>
    public static class Shrine
    {
        /// <summary>
        /// Knit them back, and take what the stone is owed.
        ///
        /// The toll takes what it can rather than refusing or going into
        /// debt: a player who cannot pay still comes back, and the unpaid
        /// part is remembered in the respawn count instead. Death that can
        /// be *blocked* by poverty is a trap, and L17's ordinary death is
        /// meant to be a cost, never a wall.
        /// </summary>
        public static int Respawn(TownState state) =>
            Respawn(state, TownProfile.Default);

        public static int Respawn(TownState state, TownProfile p)
        {
            var paid = state.Coin < p.ShrineToll ? state.Coin : p.ShrineToll;
            state.Coin -= paid;
            state.Respawns += 1;
            state.LastTollPaid = paid;
            return paid;
        }
    }
}
