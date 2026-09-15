using Marrowmark.Sim.Town;
using Xunit;

namespace Marrowmark.Sim.Tests.Town
{
    /// <summary>
    /// onboarding.md §1 — you begin as somebody's hired hand.
    /// </summary>
    public class ApprenticeshipTests
    {
        [Fact]
        public void A_master_takes_you_on()
        {
            var s = new TownState();

            Assert.Equal(HireResult.Hired, Apprenticeship.Hire(s, "odo", "odo", "pell"));
            Assert.True(s.Hired);
            Assert.Equal("odo", s.ApprenticeMaster);
        }

        [Fact]
        public void You_get_one_master()
        {
            // Refused rather than silently swapped: §1 makes the first one
            // a relationship, and a second master should be a conversation,
            // not an overwrite.
            var s = new TownState();
            Apprenticeship.Hire(s, "odo", "odo", "pell");

            Assert.Equal(HireResult.AlreadyHired,
                Apprenticeship.Hire(s, "pell", "odo", "pell"));
            Assert.Equal("odo", s.ApprenticeMaster);
        }

        [Fact]
        public void Nobody_else_hires_here()
        {
            // The gate that matters once a model is proposing intents: it
            // may reach for any master it likes (L49), and only the ones
            // who actually hire can take you on.
            var s = new TownState();

            Assert.Equal(HireResult.NoSuchMaster,
                Apprenticeship.Hire(s, "the king", "odo", "pell"));
            Assert.False(s.Hired);
        }

        [Fact]
        public void An_empty_name_hires_nobody()
        {
            var s = new TownState();

            Assert.Equal(HireResult.NoSuchMaster, Apprenticeship.Hire(s, ""));
            Assert.False(s.Hired);
        }
    }
}
