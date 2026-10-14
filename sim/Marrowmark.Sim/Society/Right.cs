namespace Marrowmark.Sim.Society
{
    /// <summary>war-society.md §2: what war fights over. Never a town.</summary>
    public enum RightKind
    {
        /// <summary>A named mine, quarry, hunting range, herb fen, vein.</summary>
        Resource,
        /// <summary>Tolls on a rim-road segment; caravan protection.</summary>
        Road,
        /// <summary>Market-day priority, bout scheduling, militia
        /// contracts — granted by a council, challengeable by war.</summary>
        TownGrant,
    }

    /// <summary>
    /// A right: held for a season, generating income or materials while
    /// held, re-challengeable when the season turns. Nothing is owned
    /// forever; the map's wealth circulates without the map changing
    /// hands.
    /// </summary>
    public sealed class Right
    {
        public string Id = "";
        public RightKind Kind;

        /// <summary>Charter id, or empty if nobody holds it.</summary>
        public string Holder = "";

        /// <summary>When the current holding runs out. Meaningless while
        /// unheld.</summary>
        public float SeasonEndsHour;

        public bool Held => Holder.Length > 0;

        /// <summary>Unheld, or the season has turned.</summary>
        public bool Challengeable(float nowHour) => !Held || nowHour >= SeasonEndsHour;
    }
}
