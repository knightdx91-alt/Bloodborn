using System.Linq;
using Marrowmark.Sim.Magic;
using Xunit;

namespace Marrowmark.Sim.Tests.Magic
{
    /// <summary>
    /// The hidden system: L8 ranks, L9/L33 teaching and lineage, L10/L34/
    /// L35 seats and succession, L36's valve. brainstorm.md §5.
    /// </summary>
    public class SpellcraftTests
    {
        private static readonly MagicProfile P = MagicProfile.Default;

        /// <summary>A server with one discoverer of Mending at Master.</summary>
        private static (Spellcraft craft, Mage founder) Server(Epoch epoch = Epoch.Myth)
        {
            var c = new Spellcraft(P, epoch);
            var f = c.Enrol("Quill");
            c.Awaken(f, 0f, guaranteedPath: true);
            c.Discover(f, "mending");
            f.Standing("mending")!.OwnXp = P.MasterAt;
            return (c, f);
        }

        private static Mage Grandmaster(Spellcraft c, string name, string spell)
        {
            var m = c.Enrol(name);
            m.Awakened = true;
            var s = m.StandingOrNew(spell);
            s.OwnXp = P.GrandmasterAt;
            s.Graduates = P.GraduatesForGrandmaster;
            return m;
        }

        // ── Ranks (L8) ──────────────────────────────────────────────────

        [Fact]
        public void The_ladder_climbs_with_use()
        {
            var (c, f) = Server();
            var m = c.Enrol("Chris");
            c.Teach(f, m, "mending", 0f);
            Assert.Equal(SpellRank.Novice, c.RankOf(m, "mending"));
            c.Practice(m, "mending", P.AdeptAt, 1f);
            Assert.Equal(SpellRank.Adept, c.RankOf(m, "mending"));
            c.Practice(m, "mending", P.ExpertAt - P.AdeptAt, 1f);
            Assert.Equal(SpellRank.Expert, c.RankOf(m, "mending"));
            c.Practice(m, "mending", P.MasterAt - P.ExpertAt, 1f);
            Assert.Equal(SpellRank.Master, c.RankOf(m, "mending"));
        }

        [Fact]
        public void Grandmaster_wants_power_and_lineage_both()
        {
            var (c, f) = Server();
            f.Standing("mending")!.OwnXp = P.GrandmasterAt;
            Assert.Equal(SpellRank.Master, c.RankOf(f, "mending"));      // no graduates yet
            f.Standing("mending")!.Graduates = P.GraduatesForGrandmaster;
            Assert.Equal(SpellRank.Grandmaster, c.RankOf(f, "mending"));
        }

        [Fact]
        public void The_hermits_road_reaches_grandmaster_by_their_own_hand()
        {
            // L96: somebody who never teaches can still reach the top,
            // further on, and with nothing but their own casting.
            var (c, f) = Server();
            var s = f.Standing("mending")!;
            Assert.Equal(0, s.Graduates);
            s.OwnXp = P.SoloGrandmasterAt - 1f;
            Assert.Equal(SpellRank.Master, c.RankOf(f, "mending"));
            s.OwnXp = P.SoloGrandmasterAt;
            Assert.Equal(SpellRank.Grandmaster, c.RankOf(f, "mending"));
            Assert.Equal(SeatResult.Taken, c.AcceptSeat(f, "mending"));
        }

        [Fact]
        public void The_hermits_bar_is_higher_than_the_teachers()
        {
            Assert.True(P.SoloGrandmasterAt > P.GrandmasterAt);
        }

        [Fact]
        public void Lineage_xp_never_carries_anyone_down_the_hermits_road()
        {
            var (c, f) = Server();
            var s = f.Standing("mending")!;
            s.OwnXp = P.MasterAt;
            s.LineageXp = P.SoloGrandmasterAt * 10f;
            Assert.Equal(SpellRank.Master, c.RankOf(f, "mending"));    // no graduates, so not the teacher's road either
            s.Graduates = P.GraduatesForGrandmaster;
            Assert.Equal(SpellRank.Grandmaster, c.RankOf(f, "mending")); // but it does count on the teacher's
        }

        [Fact]
        public void Practice_is_own_xp_and_tithe_is_lineage_xp()
        {
            var (c, f) = Server();
            var d = c.Enrol("d0");
            c.Teach(f, d, "mending", 0f);
            var own = f.Standing("mending")!.OwnXp;

            c.Practice(d, "mending", P.AdeptAt, 1f);

            Assert.Equal(own, f.Standing("mending")!.OwnXp);
            Assert.True(f.Standing("mending")!.LineageXp > 0f);
            Assert.Equal(P.AdeptAt, d.Standing("mending")!.OwnXp);
        }

        [Fact]
        public void Incarnate_is_never_xp()
        {
            var (c, f) = Server();
            f.Standing("mending")!.OwnXp = P.GrandmasterAt * 100f;
            f.Standing("mending")!.Graduates = 100;
            Assert.Equal(SpellRank.Grandmaster, c.RankOf(f, "mending"));
        }

        // ── Teaching (L9, L33) ──────────────────────────────────────────

        [Fact]
        public void Teaching_unlocks_at_master()
        {
            var (c, f) = Server();
            var expert = c.Enrol("Pell"); expert.Awakened = true;
            expert.StandingOrNew("mending").OwnXp = P.ExpertAt;
            Assert.Equal(TeachResult.MasterDoesNotMaster, c.Teach(expert, c.Enrol("Chris"), "mending", 0f));
            Assert.Equal(TeachResult.Taught, c.Teach(f, c.Enrol("Chris"), "mending", 0f));
        }

        [Fact]
        public void Teaching_a_never_awakened_player_is_their_awakening()
        {
            var (c, f) = Server();
            var chris = c.Enrol("Chris");
            Assert.False(chris.Awakened);
            c.Teach(f, chris, "mending", 0f);
            Assert.True(chris.Awakened);
            Assert.Equal(0, c.AwakeningsToday);     // and it does not touch the valve
        }

        [Fact]
        public void Three_slots_at_master_and_one_master_per_spell()
        {
            var (c, f) = Server();
            for (var i = 0; i < P.SlotsAtMaster; i++)
                Assert.Equal(TeachResult.Taught, c.Teach(f, c.Enrol("d" + i), "mending", 0f));
            Assert.Equal(TeachResult.NoFreeSlot, c.Teach(f, c.Enrol("one-more"), "mending", 0f));

            var other = Grandmaster(c, "Sarella", "mending");
            Assert.Equal(TeachResult.AlreadyHasALineage, c.Teach(other, c.Find("d0")!, "mending", 0f));
        }

        [Fact]
        public void A_grandmaster_has_one_more_slot_and_so_does_declining_the_seat()
        {
            var (c, _) = Server();
            var gm = Grandmaster(c, "Sarella", "mending");
            Assert.Equal(P.SlotsAtMaster + P.ExtraSlotAtGrandmaster, c.SlotsOf(gm, "mending", 0f));
            c.DeclineSeat(gm, "mending");
            Assert.Equal(P.SlotsAtMaster + P.ExtraSlotAtGrandmaster + P.ExtraSlotForDeclining,
                c.SlotsOf(gm, "mending", 0f));
        }

        [Fact]
        public void Graduation_frees_the_slot_at_once()
        {
            var (c, f) = Server();
            for (var i = 0; i < P.SlotsAtMaster; i++) c.Teach(f, c.Enrol("d" + i), "mending", 0f);
            Assert.Equal(0, c.SlotsOf(f, "mending", 0f));

            c.Practice(c.Find("d0")!, "mending", P.MasterAt, 1f);

            Assert.Equal(1, c.SlotsOf(f, "mending", 1f));
            Assert.Equal(1, f.Standing("mending")!.Graduates);
        }

        [Fact]
        public void Dismissal_locks_the_slot_for_the_cooldown()
        {
            var (c, f) = Server();
            var d = c.Enrol("d0");
            c.Teach(f, d, "mending", 0f);
            Assert.True(c.Dismiss(f, d, "mending", 0f));

            Assert.Equal(P.SlotsAtMaster - 1, c.SlotsOf(f, "mending", P.DismissalCooldownHours - 1f));
            Assert.Equal(P.SlotsAtMaster, c.SlotsOf(f, "mending", P.DismissalCooldownHours));
            Assert.True(d.Knows("mending"));                 // they keep what they learned
            Assert.Equal("", d.Standing("mending")!.Master);  // the lineage is cut
        }

        [Fact]
        public void You_cannot_teach_yourself()
        {
            var (c, f) = Server();
            Assert.Equal(TeachResult.CannotTeachYourself, c.Teach(f, f, "mending", 0f));
        }

        // ── Lineage (L33) ───────────────────────────────────────────────

        [Fact]
        public void A_rank_up_pays_the_master_a_windfall()
        {
            var (c, f) = Server();
            var d = c.Enrol("d0");
            c.Teach(f, d, "mending", 0f);
            var before = f.Standing("mending")!.Xp;

            c.Practice(d, "mending", P.AdeptAt, 1f);

            Assert.True(f.Standing("mending")!.Xp - before >= P.LineageRankUpXp);
        }

        [Fact]
        public void Use_pays_a_trickle_under_a_daily_cap()
        {
            var (c, f) = Server();
            var d = c.Enrol("d0");
            c.Teach(f, d, "mending", 0f);
            var before = f.Standing("mending")!.Xp;

            for (var i = 0; i < 1000; i++) c.Practice(d, "mending", 0.01f, 1f);   // no rank-up

            Assert.Equal(P.LineageTrickleDailyCap, f.Standing("mending")!.Xp - before, 3);

            c.Practice(d, "mending", 0.01f, 1f + P.HoursPerDay);                   // a new day
            Assert.True(f.Standing("mending")!.Xp - before > P.LineageTrickleDailyCap);
        }

        [Fact]
        public void Lineage_xp_stops_at_grandmaster()
        {
            var (c, _) = Server();
            var gm = Grandmaster(c, "Sarella", "mending");
            var d = c.Enrol("d0");
            c.Teach(gm, d, "mending", 0f);
            var before = gm.Standing("mending")!.Xp;

            c.Practice(d, "mending", P.AdeptAt, 1f);

            Assert.Equal(before, gm.Standing("mending")!.Xp);
        }

        [Fact]
        public void Every_spell_traces_to_its_discoverer()
        {
            var (c, f) = Server();
            var d = c.Enrol("d0");
            c.Teach(f, d, "mending", 0f);
            d.Standing("mending")!.OwnXp = P.MasterAt;
            var e = c.Enrol("e0");
            c.Teach(d, e, "mending", 1f);

            Assert.Equal("Quill", c.DiscovererOf("mending"));
            Assert.Equal(new[] { "d0", "Quill" }, c.LineageOf(e, "mending").ToArray());
            Assert.False(c.Discover(e, "mending"));          // discovered once
        }

        [Fact]
        public void A_spell_with_too_few_masters_is_one_the_server_can_lose()
        {
            var (c, _) = Server();
            Assert.True(c.AtRiskOfExtinction("mending"));   // one master
            Grandmaster(c, "Sarella", "mending");
            Assert.False(c.AtRiskOfExtinction("mending"));
        }

        // ── The valve (L36) ─────────────────────────────────────────────

        [Fact]
        public void Seeded_awakenings_are_throttled_by_epoch()
        {
            var c = new Spellcraft(P, Epoch.Myth);
            for (var i = 0; i < P.AwakeningsPerDayMyth; i++)
                Assert.Equal(AwakenResult.Awakened, c.Awaken(c.Enrol("a" + i), 1f));
            Assert.Equal(AwakenResult.Throttled, c.Awaken(c.Enrol("one-more"), 1f));

            c.Epoch = Epoch.Wonder;
            Assert.Equal(AwakenResult.Awakened, c.Awaken(c.Enrol("one-more"), 1f));
            Assert.True(P.AwakeningsPerDayWonder > P.AwakeningsPerDayMyth);
        }

        [Fact]
        public void The_valve_opens_again_each_day()
        {
            var c = new Spellcraft(P, Epoch.Myth);
            for (var i = 0; i < P.AwakeningsPerDayMyth; i++) c.Awaken(c.Enrol("a" + i), 1f);
            Assert.Equal(AwakenResult.Throttled, c.Awaken(c.Enrol("b"), 1f));
            Assert.Equal(AwakenResult.Awakened, c.Awaken(c.Enrol("b"), 1f + P.HoursPerDay));
        }

        [Fact]
        public void The_slow_reliable_path_is_never_throttled()
        {
            // L36's guard rail: not a playtime lottery.
            var c = new Spellcraft(P, Epoch.Myth);
            for (var i = 0; i < P.AwakeningsPerDayMyth; i++) c.Awaken(c.Enrol("a" + i), 1f);
            Assert.Equal(AwakenResult.Awakened, c.Awaken(c.Enrol("Chris"), 1f, guaranteedPath: true));
        }

        // ── The seats (L10, L34, L35) ───────────────────────────────────

        [Fact]
        public void One_seat_per_spell_and_one_per_character()
        {
            var (c, _) = Server();
            var a = Grandmaster(c, "A", "mending");
            var b = Grandmaster(c, "B", "mending");
            Grandmaster(c, "A", "fireball");

            Assert.Equal(SeatResult.Taken, c.AcceptSeat(a, "mending"));
            Assert.Equal(SeatResult.SeatHeld, c.AcceptSeat(b, "mending"));
            Assert.Equal(SeatResult.AlreadyIncarnate, c.AcceptSeat(a, "fireball"));
            Assert.Equal(SpellRank.Incarnate, c.RankOf(a, "mending"));
        }

        [Fact]
        public void Only_a_grandmaster_is_offered_a_seat()
        {
            var (c, f) = Server();
            Assert.Equal(SeatResult.NotGrandmaster, c.AcceptSeat(f, "mending"));
            Assert.Equal(SeatResult.NotGrandmaster, c.DeclineSeat(f, "mending"));
        }

        [Fact]
        public void Declining_is_quiet_power_and_leaves_the_other_seats_open()
        {
            var (c, _) = Server();
            var a = Grandmaster(c, "A", "mending");
            Grandmaster(c, "A", "fireball");

            Assert.Equal(SeatResult.Declined, c.DeclineSeat(a, "mending"));
            Assert.Equal(SeatResult.AlreadyDeclined, c.AcceptSeat(a, "mending"));
            Assert.Equal(SeatResult.Taken, c.AcceptSeat(a, "fireball"));
            Assert.True(c.SeatOpen("mending"));
        }

        [Fact]
        public void A_seat_lapses_after_thirty_days_unseen()
        {
            var (c, _) = Server();
            var a = Grandmaster(c, "A", "mending");
            c.AcceptSeat(a, "mending");
            a.LastSeenHour = 0f;

            c.Tick(P.SeatLapseHours - 1f);
            Assert.Equal("A", c.HolderOf("mending"));
            c.Tick(P.SeatLapseHours);
            Assert.True(c.SeatOpen("mending"));
            Assert.Equal("", a.IncarnateOf);
            Assert.Equal(SeatOpenedBecause.Lapsed, c.Announcements.Single().Because);
        }

        [Fact]
        public void A_regency_holds_the_seat_longer_once()
        {
            var (c, _) = Server();
            var a = Grandmaster(c, "A", "mending");
            c.AcceptSeat(a, "mending");
            a.LastSeenHour = 0f;

            Assert.True(c.DeclareRegency(a, 0f));
            Assert.False(c.DeclareRegency(a, 0f));
            c.Tick(P.SeatLapseHours);
            Assert.Equal("A", c.HolderOf("mending"));
            c.Tick(P.RegencyHours);
            Assert.True(c.SeatOpen("mending"));
        }

        [Fact]
        public void The_announcement_reaches_the_public_only_after_the_unveiling()
        {
            foreach (var (epoch, reaches) in new[] { (Epoch.Myth, false), (Epoch.Whispers, false),
                         (Epoch.Unveiling, true), (Epoch.Wonder, true) })
            {
                var (c, _) = Server(epoch);
                var a = Grandmaster(c, "A", "mending");
                c.AcceptSeat(a, "mending");
                c.HolderFell(a, 10f);
                var ann = c.Announcements.Single();
                Assert.Equal(reaches, ann.ReachesPublic);
                Assert.Equal(SeatOpenedBecause.Fallen, ann.Because);
                Assert.Equal(10f + P.TrialLeadHours, ann.TrialAtHour);
            }
        }

        [Fact]
        public void The_trial_is_three_days_later_and_only_grandmasters_enter()
        {
            var (c, f) = Server();
            var a = Grandmaster(c, "A", "mending");
            c.AcceptSeat(a, "mending");
            c.HolderFell(a, 0f);
            var b = Grandmaster(c, "B", "mending");
            var d = Grandmaster(c, "D", "mending");

            Assert.False(c.EnterTrial(f, "mending"));             // a Master, not a Grandmaster
            Assert.True(c.EnterTrial(b, "mending"));
            Assert.True(c.EnterTrial(d, "mending"));
            Assert.Equal("", c.ResolveTrial("mending", P.TrialLeadHours - 1f, "B"));   // too early
            Assert.Equal("", c.ResolveTrial("mending", P.TrialLeadHours, "nobody"));  // not an entrant
            Assert.Equal("B", c.ResolveTrial("mending", P.TrialLeadHours, "B"));
            Assert.Equal("B", c.HolderOf("mending"));
            Assert.Equal(SpellRank.Incarnate, c.RankOf(b, "mending"));
        }

        [Fact]
        public void One_entrant_claims_by_walkover_and_none_leaves_it_open()
        {
            var (c, _) = Server();
            var a = Grandmaster(c, "A", "mending");
            c.AcceptSeat(a, "mending");
            c.HolderFell(a, 0f);

            Assert.Equal("", c.ResolveTrial("mending", P.TrialLeadHours));   // nobody came
            Assert.True(c.SeatOpen("mending"));
            Assert.Null(c.PendingTrial("mending"));

            c.Forsake(a, 100f);   // not a holder any more
            var b = Grandmaster(c, "B", "mending");
            var d = Grandmaster(c, "D", "mending");
            c.AcceptSeat(b, "mending");
            c.Forsake(b, 200f);
            Assert.True(c.EnterTrial(d, "mending"));
            Assert.Equal("D", c.ResolveTrial("mending", 200f + P.TrialLeadHours));
        }

        [Fact]
        public void A_fallen_incarnate_can_never_hold_another_seat()
        {
            var (c, _) = Server();
            var a = Grandmaster(c, "A", "mending");
            Grandmaster(c, "A", "fireball");
            c.AcceptSeat(a, "mending");
            c.HolderFell(a, 0f);
            // L10: one Incarnation per character — and a permadeath is the end
            // of the character anyway. Here the rule is that the seat is gone
            // from them; whether the character persists is the Interior's.
            Assert.Equal("", a.IncarnateOf);
            Assert.Equal(SeatResult.Taken, c.AcceptSeat(a, "fireball"));
        }
    }
}
