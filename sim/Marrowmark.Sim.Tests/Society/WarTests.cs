using Marrowmark.Sim.Economy;
using Marrowmark.Sim.Society;
using Xunit;

namespace Marrowmark.Sim.Tests.Society
{
    /// <summary>
    /// war-society.md §3 / L25: a war is a contract between two sides
    /// over a named right, fought in scheduled battles, with stakes posted
    /// up front. Each numbered line of §3 is a test here.
    /// </summary>
    public class WarTests
    {
        private static readonly WarProfile P = WarProfile.Default;

        private sealed class Fixture
        {
            public Charters Charters = new Charters();
            public WarOffice Office;
            public Right Mine;
            public Purse BladesChest = new Purse(10_000);
            public Purse HawksChest = new Purse(10_000);

            public Fixture()
            {
                Charters.Found("blades", CharterKind.Company, "Ban");
                Charters.Found("hawks", CharterKind.Company, "Hal");
                Charters.Found("house-kettle", CharterKind.House, "Marta");
                Office = new WarOffice(Charters, P);
                Mine = Office.Register("redstone-mine", RightKind.Resource);
                Office.Claim("redstone-mine", "hawks", nowHour: 0f);
            }

            /// <summary>The hawks' season has turned and the blades file.</summary>
            public War Declared(int stake = 0, int cap = 60)
            {
                var r = Office.Declare("redstone-mine", "blades",
                    stake == 0 ? P.StakeMinimum : stake, BladesChest, cap, SeasonTurned, out var war);
                Assert.Equal(DeclareResult.Declared, r);
                return war!;
            }

            public float SeasonTurned => P.SeasonHours;
        }

        // ── 1. Declaration ──────────────────────────────────────────────

        [Fact]
        public void No_stake_no_war()
        {
            var f = new Fixture();
            var r = f.Office.Declare("redstone-mine", "blades", P.StakeMinimum - 1,
                f.BladesChest, 60, f.SeasonTurned, out var war);

            Assert.Equal(DeclareResult.StakeTooSmall, r);
            Assert.Null(war);
            Assert.Equal(10_000, f.BladesChest.Coin);
        }

        [Fact]
        public void The_stake_is_escrowed_at_declaration()
        {
            var f = new Fixture();
            var war = f.Declared(stake: 500);

            Assert.Equal(10_000 - 500, f.BladesChest.Coin);
            Assert.Equal(500, war.Escrow.Coin);
        }

        [Fact]
        public void A_chest_that_cannot_cover_the_stake_cannot_declare()
        {
            var f = new Fixture();
            var poor = new Purse(P.StakeMinimum - 1);
            var r = f.Office.Declare("redstone-mine", "blades", P.StakeMinimum,
                poor, 60, f.SeasonTurned, out _);
            Assert.Equal(DeclareResult.CannotPayStake, r);
        }

        [Fact]
        public void Only_a_banner_charter_declares()
        {
            var f = new Fixture();
            var r = f.Office.Declare("redstone-mine", "house-kettle", P.StakeMinimum,
                f.BladesChest, 60, f.SeasonTurned, out _);
            Assert.Equal(DeclareResult.CannotWar, r);
        }

        [Fact]
        public void A_held_right_cannot_be_challenged_until_the_season_turns()
        {
            var f = new Fixture();
            var r = f.Office.Declare("redstone-mine", "blades", P.StakeMinimum,
                f.BladesChest, 60, nowHour: P.SeasonHours - 1f, out _);
            Assert.Equal(DeclareResult.SeasonNotTurned, r);
        }

        [Fact]
        public void An_unheld_right_is_claimed_not_fought_over()
        {
            var f = new Fixture();
            var quarry = f.Office.Register("chalk-quarry", RightKind.Resource);

            var r = f.Office.Declare("chalk-quarry", "blades", P.StakeMinimum,
                f.BladesChest, 60, 0f, out _);
            Assert.Equal(DeclareResult.NothingToContest, r);

            Assert.True(f.Office.Claim("chalk-quarry", "blades", 0f));
            Assert.Equal("blades", quarry.Holder);
            Assert.False(f.Office.Claim("chalk-quarry", "hawks", 1f));   // it is held now
        }

        [Fact]
        public void One_war_per_right_at_a_time()
        {
            var f = new Fixture();
            f.Charters.Found("wolves", CharterKind.Company, "Wulf");
            f.Declared();

            var r = f.Office.Declare("redstone-mine", "wolves", P.StakeMinimum,
                new Purse(10_000), 60, f.SeasonTurned, out _);
            Assert.Equal(DeclareResult.AlreadyContested, r);
        }

        [Fact]
        public void You_cannot_declare_on_your_own_right()
        {
            var f = new Fixture();
            var r = f.Office.Declare("redstone-mine", "hawks", P.StakeMinimum,
                f.HawksChest, 60, f.SeasonTurned, out _);
            Assert.Equal(DeclareResult.OwnRight, r);
        }

        // ── 2. Lead time ────────────────────────────────────────────────

        [Fact]
        public void Lead_time_comes_before_the_window()
        {
            var f = new Fixture();
            var war = f.Declared();
            var t = f.SeasonTurned;

            Assert.Equal(WarPhase.LeadTime, war.Phase(t));
            Assert.Equal(WarPhase.LeadTime, war.Phase(t + P.LeadTimeHours - 1f));
            Assert.Equal(WarPhase.Window, war.Phase(t + P.LeadTimeHours));
            Assert.Equal(WarPhase.Window, war.Phase(t + P.LeadTimeHours + P.WindowHours - 1f));
            Assert.Equal(WarPhase.Ended, war.Phase(t + P.LeadTimeHours + P.WindowHours));
        }

        [Fact]
        public void Battles_count_only_inside_the_window()
        {
            var f = new Fixture();
            var war = f.Declared();
            var t = f.SeasonTurned;

            Assert.False(war.RecordBattle(WarSide.Challenger, t + 1f));            // lead time
            Assert.True(war.RecordBattle(WarSide.Challenger, war.WindowOpensHour + 1f));
            Assert.False(war.RecordBattle(WarSide.Challenger, war.WindowClosesHour + 1f));
            Assert.Equal(1, war.BattlesFought);
        }

        // ── 3. Enrolment ────────────────────────────────────────────────

        [Fact]
        public void Enrolment_is_capped_per_side_at_what_was_negotiated()
        {
            var f = new Fixture();
            var war = f.Declared(cap: 30);
            var t = f.SeasonTurned;

            for (var i = 0; i < 30; i++)
                Assert.Equal(EnrolResult.Enrolled, war.Enrol("c" + i, WarSide.Challenger, t));
            Assert.Equal(EnrolResult.CapReached, war.Enrol("one-more", WarSide.Challenger, t));
            Assert.Equal(EnrolResult.Enrolled, war.Enrol("d0", WarSide.Defender, t)); // other side is separate
        }

        [Fact]
        public void The_cap_is_clamped_to_the_range()
        {
            var f = new Fixture();
            Assert.Equal(P.MinEnrolment, f.Declared(cap: 1).EnrolmentCap);

            var g = new Fixture();
            Assert.Equal(P.MaxEnrolment, g.Declared(cap: 10_000).EnrolmentCap);
        }

        [Fact]
        public void One_banner_per_war()
        {
            var f = new Fixture();
            var war = f.Declared();
            war.Enrol("Chris", WarSide.Challenger, f.SeasonTurned);
            Assert.Equal(EnrolResult.EnrolledOnOtherSide,
                war.Enrol("Chris", WarSide.Defender, f.SeasonTurned));
            Assert.Equal(EnrolResult.AlreadyEnrolled,
                war.Enrol("Chris", WarSide.Challenger, f.SeasonTurned));
        }

        [Fact]
        public void War_rules_apply_only_to_the_enrolled_and_only_in_the_window()
        {
            // Bystanders keep ordinary death (L17) and cannot be dragged in.
            var f = new Fixture();
            var war = f.Declared();
            war.Enrol("Ban", WarSide.Challenger, f.SeasonTurned);
            var inWindow = war.WindowOpensHour + 1f;

            Assert.True(war.AppliesTo("Ban", inWindow));
            Assert.True(war.DeathDropsEquipment("Ban", inWindow));
            Assert.False(war.AppliesTo("Chris", inWindow));         // not enrolled
            Assert.False(war.DeathDropsEquipment("Chris", inWindow));
            Assert.False(war.AppliesTo("Ban", f.SeasonTurned + 1f)); // enrolled, but lead time
        }

        // ── 6. Resolution ───────────────────────────────────────────────

        [Fact]
        public void Best_of_the_windows_battles_takes_the_right_and_the_stake()
        {
            var f = new Fixture();
            var war = f.Declared(stake: 500);
            var mid = war.WindowOpensHour + 1f;
            war.RecordBattle(WarSide.Challenger, mid);
            war.RecordBattle(WarSide.Challenger, mid);
            war.RecordBattle(WarSide.Defender, mid);
            var after = war.WindowClosesHour;

            Assert.False(war.Resolve(f.BladesChest, f.HawksChest, mid));   // not yet
            Assert.True(war.Resolve(f.BladesChest, f.HawksChest, after));

            Assert.Equal(WarOutcome.ChallengerWon, war.Outcome);
            Assert.Equal("blades", f.Mine.Holder);
            Assert.Equal(after + P.SeasonHours, f.Mine.SeasonEndsHour);   // a fresh season
            Assert.Equal(10_000, f.BladesChest.Coin);                     // stake home
            Assert.Equal(0, war.Escrow.Coin);
        }

        [Fact]
        public void A_defender_who_holds_keeps_the_right_and_takes_the_stake()
        {
            var f = new Fixture();
            var war = f.Declared(stake: 500);
            var mid = war.WindowOpensHour + 1f;
            war.RecordBattle(WarSide.Defender, mid);

            war.Resolve(f.BladesChest, f.HawksChest, war.WindowClosesHour);

            Assert.Equal(WarOutcome.DefenderHeld, war.Outcome);
            Assert.Equal("hawks", f.Mine.Holder);
            Assert.Equal(10_500, f.HawksChest.Coin);
            Assert.Equal(9_500, f.BladesChest.Coin);
        }

        [Fact]
        public void A_tie_holds()
        {
            // The defender was never beaten, and the challenger posted
            // the stake knowing that.
            var f = new Fixture();
            var war = f.Declared();
            var mid = war.WindowOpensHour + 1f;
            war.RecordBattle(WarSide.Challenger, mid);
            war.RecordBattle(WarSide.Defender, mid);

            war.Resolve(f.BladesChest, f.HawksChest, war.WindowClosesHour);

            Assert.Equal(WarOutcome.DefenderHeld, war.Outcome);
            Assert.Equal("hawks", f.Mine.Holder);
        }

        [Fact]
        public void Walking_away_forfeits_the_stake()
        {
            var f = new Fixture();
            var war = f.Declared(stake: 500);

            Assert.True(war.Withdraw(WarSide.Challenger, f.BladesChest, f.HawksChest, f.SeasonTurned + 1f));

            Assert.Equal(WarOutcome.ChallengerWithdrew, war.Outcome);
            Assert.Equal(10_500, f.HawksChest.Coin);
            Assert.Equal("hawks", f.Mine.Holder);
            Assert.False(war.RecordBattle(WarSide.Challenger, war.WindowOpensHour + 1f)); // it is over
        }

        [Fact]
        public void A_defender_who_concedes_loses_the_right_and_the_stake_goes_home()
        {
            var f = new Fixture();
            var war = f.Declared(stake: 500);

            war.Withdraw(WarSide.Defender, f.BladesChest, f.HawksChest, f.SeasonTurned + 1f);

            Assert.Equal(WarOutcome.DefenderConceded, war.Outcome);
            Assert.Equal("blades", f.Mine.Holder);
            Assert.Equal(10_000, f.BladesChest.Coin);
        }

        [Fact]
        public void A_treaty_is_a_settlement_not_a_default()
        {
            // Tribute to withdraw: the right stays, the stake goes home,
            // and the tribute changed hands.
            var f = new Fixture();
            var war = f.Declared(stake: 500);

            Assert.True(war.Treaty(WarSide.Challenger, tribute: 300,
                f.BladesChest, f.HawksChest, war.WindowOpensHour + 1f));

            Assert.Equal(WarOutcome.Treaty, war.Outcome);
            Assert.Equal("hawks", f.Mine.Holder);
            Assert.Equal(10_000 - 300, f.BladesChest.Coin);  // stake back, tribute paid
            Assert.Equal(10_000 + 300, f.HawksChest.Coin);
        }

        [Fact]
        public void A_treaty_nobody_can_pay_for_changes_nothing()
        {
            var f = new Fixture();
            var war = f.Declared();
            var broke = new Purse(10);

            Assert.False(war.Treaty(WarSide.Challenger, 300, broke, f.HawksChest, f.SeasonTurned + 1f));
            Assert.Equal(WarOutcome.Undecided, war.Outcome);
        }

        [Fact]
        public void Every_war_is_recorded()
        {
            // L23: named battles enter the server's living history.
            var f = new Fixture();
            var war = f.Declared(stake: 500);
            war.RecordBattle(WarSide.Challenger, war.WindowOpensHour + 1f);
            war.Resolve(f.BladesChest, f.HawksChest, war.WindowClosesHour);

            Assert.NotNull(f.Office.Archive(war, war.WindowClosesHour));
            var record = f.Office.History[0];

            Assert.Equal("redstone-mine", record.RightId);
            Assert.Equal("blades", record.Challenger);
            Assert.Equal("hawks", record.Defender);
            Assert.Equal(WarOutcome.ChallengerWon, record.Outcome);
            Assert.Equal(1, record.BattlesFought);
            Assert.Empty(f.Office.Wars);
        }

        [Fact]
        public void An_unfinished_war_cannot_be_archived()
        {
            var f = new Fixture();
            var war = f.Declared();
            Assert.Null(f.Office.Archive(war, f.SeasonTurned + 1f));
            Assert.Single(f.Office.Wars);
        }

        [Fact]
        public void The_won_right_is_safe_for_a_season_and_then_it_is_not()
        {
            var f = new Fixture();
            var war = f.Declared();
            war.RecordBattle(WarSide.Challenger, war.WindowOpensHour + 1f);
            war.Resolve(f.BladesChest, f.HawksChest, war.WindowClosesHour);
            f.Office.Archive(war, war.WindowClosesHour);

            var tooSoon = f.Office.Declare("redstone-mine", "hawks", P.StakeMinimum,
                f.HawksChest, 60, war.WindowClosesHour + 1f, out _);
            Assert.Equal(DeclareResult.SeasonNotTurned, tooSoon);

            var inTime = f.Office.Declare("redstone-mine", "hawks", P.StakeMinimum,
                f.HawksChest, 60, war.WindowClosesHour + P.SeasonHours, out _);
            Assert.Equal(DeclareResult.Declared, inTime);
        }
    }
}
