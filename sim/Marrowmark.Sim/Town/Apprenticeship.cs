namespace Marrowmark.Sim.Town
{
    /// <summary>Why a hire did or did not happen.</summary>
    public enum HireResult
    {
        Hired,

        /// <summary>You already have a master. onboarding.md §1 makes the
        /// first one a relationship rather than a menu, so taking a second
        /// is refused rather than silently swapped.</summary>
        AlreadyHired,

        /// <summary>Nobody by that name hires here.</summary>
        NoSuchMaster,
    }

    /// <summary>
    /// onboarding.md §1: you begin as somebody's hired hand. The hire is a
    /// flag and a first errand — and the errand is spoken as a landmark
    /// direction, never a marker, because L29 forbids markers outright.
    ///
    /// The errand text itself is content and lives with the town. What is
    /// a rule is that you have one master, and that taking one is binding.
    /// </summary>
    public static class Apprenticeship
    {
        public static HireResult Hire(TownState state, string master,
            params string[] mastersWhoHire)
        {
            if (state.Hired) return HireResult.AlreadyHired;

            if (mastersWhoHire.Length > 0)
            {
                var known = false;
                foreach (var m in mastersWhoHire)
                    if (m == master) { known = true; break; }
                if (!known) return HireResult.NoSuchMaster;
            }

            if (string.IsNullOrEmpty(master)) return HireResult.NoSuchMaster;

            state.ApprenticeMaster = master;
            return HireResult.Hired;
        }
    }
}
