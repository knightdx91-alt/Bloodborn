namespace Marrowmark.Sim.Society
{
    /// <summary>
    /// The numbers behind a declared war (war-society.md §2–§3). Every one
    /// of them is listed there as a working value, and the open tuning
    /// questions at the end of that document are mostly this struct.
    /// </summary>
    public struct WarProfile
    {
        /// <summary>From declaration to the first battle. "Both sides
        /// recruit; betting books open." Working: 3 real days.</summary>
        public float LeadTimeHours;

        /// <summary>How long the war window stays open once it opens.
        /// Working: 7 days.</summary>
        public float WindowHours;

        /// <summary>How long a right is held once won, before it can be
        /// challenged again. Working: a season of 3 months.</summary>
        public float SeasonHours;

        /// <summary>The smallest enrolment cap a declaration may ask for.</summary>
        public int MinEnrolment;

        /// <summary>The largest. 150 is aspirational and depends on the
        /// crowd budget (feasibility-review.md T2); the cap is negotiated
        /// at declaration and clamped to this range.</summary>
        public int MaxEnrolment;

        /// <summary>No stake, no war. The least a challenger escrows at
        /// the capitol, in pennies. Flat for now; whether it should scale
        /// with the right's income is an open question in
        /// war-society.md.</summary>
        public int StakeMinimum;

        public static WarProfile Default => new WarProfile
        {
            LeadTimeHours = 72f,
            WindowHours = 168f,
            SeasonHours = 2160f,
            MinEnrolment = 30,
            MaxEnrolment = 150,
            StakeMinimum = 200,
        };
    }
}
