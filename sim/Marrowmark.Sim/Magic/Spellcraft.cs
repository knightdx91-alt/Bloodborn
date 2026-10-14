using System;
using System.Collections.Generic;
using System.Linq;

namespace Marrowmark.Sim.Magic
{
    public enum TeachResult
    {
        Taught,
        NoSuchMage,
        /// <summary>L9: teaching unlocks at Master.</summary>
        MasterDoesNotMaster,
        /// <summary>One master per spell per disciple.</summary>
        AlreadyHasALineage,
        /// <summary>L33: slots are capped, and some may be locked.</summary>
        NoFreeSlot,
        CannotTeachYourself,
    }

    public enum AwakenResult
    {
        Awakened,
        AlreadyAwake,
        /// <summary>L36: the valve is closed for today.</summary>
        Throttled,
    }

    public enum SeatResult
    {
        Taken,
        Declined,
        NotGrandmaster,
        SeatHeld,
        /// <summary>L10: one Incarnation per character.</summary>
        AlreadyIncarnate,
        /// <summary>You declined this one; the offer does not return.</summary>
        AlreadyDeclined,
        NotHolder,
    }

    public enum SeatOpenedBecause { Fallen, Lapsed, Forsaken }

    /// <summary>
    /// "The Incarnate of Fireball has fallen." L10: the surface form is
    /// epoch-gated. Pre-Unveiling only the awakened hear it; the public
    /// version exists only afterwards.
    /// </summary>
    public sealed class Announcement
    {
        public string Spell = "";
        public SeatOpenedBecause Because;
        public float Hour;
        public bool ReachesPublic;
        public float TrialAtHour;
    }

    /// <summary>L35: the Succession Trial. Any qualified grandmaster may
    /// enter; the seat lands on exactly one head.</summary>
    public sealed class Trial
    {
        public string Spell = "";
        public float AtHour;
        public List<string> Entrants = new List<string>();
        public bool Resolved;
        public string Winner = "";
    }

    /// <summary>
    /// The hidden system as rules: ranks, teaching, lineage, the Incarnate
    /// seats and their succession, and the valve that decides how fast
    /// any of it spreads. L7–L10, L22, L33–L36.
    ///
    /// Nothing here is a spell's effect. What Fireball does is content and
    /// a combat rule; this is who may cast it, who taught them, and whose
    /// name it carries.
    /// </summary>
    public sealed class Spellcraft
    {
        private readonly MagicProfile _p;
        private readonly Dictionary<string, Mage> _mages = new Dictionary<string, Mage>();
        private readonly Dictionary<string, string> _discoverers = new Dictionary<string, string>();
        private readonly Dictionary<string, string> _seats = new Dictionary<string, string>();
        private readonly List<Announcement> _announcements = new List<Announcement>();
        private readonly List<Trial> _trials = new List<Trial>();
        private int _awakeningsToday;
        private float _dayStartHour;

        public Spellcraft(MagicProfile profile, Epoch epoch = Epoch.Myth)
        {
            _p = profile;
            Epoch = epoch;
        }

        public Spellcraft() : this(MagicProfile.Default) { }

        public Epoch Epoch { get; set; }
        public IReadOnlyList<Announcement> Announcements => _announcements;
        public IReadOnlyList<Trial> Trials => _trials;
        public int AwakeningsToday => _awakeningsToday;

        public Mage Enrol(string name)
        {
            if (!_mages.TryGetValue(name, out var m)) { m = new Mage(name); _mages[name] = m; }
            return m;
        }

        public Mage? Find(string name) => _mages.TryGetValue(name, out var m) ? m : null;

        // ── Ranks ───────────────────────────────────────────────────────

        public SpellRank RankOf(Mage m, string spell)
        {
            var s = m.Standing(spell);
            if (s == null) return SpellRank.Novice;
            if (m.IncarnateOf == spell) return SpellRank.Incarnate;
            // Two roads to Grandmaster (L96): the teacher's, power and
            // lineage both; or the hermit's, own hands only, further on.
            if (s.Xp >= _p.GrandmasterAt && s.Graduates >= _p.GraduatesForGrandmaster) return SpellRank.Grandmaster;
            if (s.OwnXp >= _p.SoloGrandmasterAt) return SpellRank.Grandmaster;
            if (s.Xp >= _p.MasterAt) return SpellRank.Master;
            if (s.Xp >= _p.ExpertAt) return SpellRank.Expert;
            if (s.Xp >= _p.AdeptAt) return SpellRank.Adept;
            return SpellRank.Novice;
        }

        public bool Masters(Mage m, string spell) => RankOf(m, spell) >= SpellRank.Master;

        // ── Awakening (L36) ─────────────────────────────────────────────

        /// <summary>
        /// A seeded event awakens somebody. The valve decides how many a
        /// day, by epoch; the guaranteed slow path (deep faith, long
        /// rumour chains) is never throttled, which is the casual guard
        /// rail.
        /// </summary>
        public AwakenResult Awaken(Mage m, float nowHour, bool guaranteedPath = false)
        {
            if (m.Awakened) return AwakenResult.AlreadyAwake;
            RollDay(nowHour);
            if (!guaranteedPath && _awakeningsToday >= _p.AwakeningsPerDay(Epoch))
                return AwakenResult.Throttled;
            m.Awakened = true;
            if (!guaranteedPath) _awakeningsToday++;
            return AwakenResult.Awakened;
        }

        private void RollDay(float nowHour)
        {
            if (nowHour - _dayStartHour >= _p.HoursPerDay)
            {
                _dayStartHour = nowHour - ((nowHour - _dayStartHour) % _p.HoursPerDay);
                _awakeningsToday = 0;
                foreach (var m in _mages.Values)
                    foreach (var s in m.Spells) s.TrickleToday = 0f;
            }
        }

        // ── Discovery and use ───────────────────────────────────────────

        /// <summary>The first caster of a spell on this server. Every spell
        /// traces to them (brainstorm.md §5.4, lineage as history).</summary>
        public bool Discover(Mage m, string spell)
        {
            if (!m.Awakened || _discoverers.ContainsKey(spell)) return false;
            _discoverers[spell] = m.Name;
            m.StandingOrNew(spell);
            return true;
        }

        public string DiscovererOf(string spell) =>
            _discoverers.TryGetValue(spell, out var d) ? d : "";

        /// <summary>The chain of masters from this caster back to the
        /// discoverer.</summary>
        public List<string> LineageOf(Mage m, string spell)
        {
            var chain = new List<string>();
            var cur = m.Standing(spell)?.Master ?? "";
            while (cur.Length > 0 && !chain.Contains(cur))
            {
                chain.Add(cur);
                cur = Find(cur)?.Standing(spell)?.Master ?? "";
            }
            return chain;
        }

        /// <summary>
        /// A meaningful cast. XP to the caster; to their master, a
        /// trickle under a daily cap and a windfall on a rank-up — and
        /// nothing once the master is Grandmaster (L33: lineage XP stops
        /// there; the seat is never XP).
        /// </summary>
        public SpellRank Practice(Mage m, string spell, float xp, float nowHour)
        {
            var s = m.Standing(spell);
            if (s == null || xp <= 0f) return RankOf(m, spell);
            RollDay(nowHour);

            var before = RankOf(m, spell);
            s.OwnXp += xp;
            var after = RankOf(m, spell);

            var master = s.Master.Length > 0 ? Find(s.Master) : null;
            var ms = master?.Standing(spell);
            if (master != null && ms != null && RankOf(master, spell) < SpellRank.Grandmaster)
            {
                var room = _p.LineageTrickleDailyCap - ms.TrickleToday;
                var trickle = Math.Min(Math.Max(0f, room), _p.LineageTrickleXp);
                ms.LineageXp += trickle;
                ms.TrickleToday += trickle;
                if (after > before) ms.LineageXp += _p.LineageRankUpXp;
            }

            if (after >= SpellRank.Master && before < SpellRank.Master && master != null && ms != null)
            {
                // Graduation: the slot frees at once (L33).
                ms.Disciples.Remove(m.Name);
                ms.Graduates++;
            }
            return after;
        }

        // ── Teaching (L9, L33) ──────────────────────────────────────────

        public int SlotsOf(Mage master, string spell, float nowHour)
        {
            var rank = RankOf(master, spell);
            if (rank < SpellRank.Master) return 0;
            var s = master.Standing(spell)!;
            var slots = _p.SlotsAtMaster;
            if (rank >= SpellRank.Grandmaster) slots += _p.ExtraSlotAtGrandmaster;
            if (master.Declined.Contains(spell)) slots += _p.ExtraSlotForDeclining;
            s.LockedUntil.RemoveAll(h => h <= nowHour);
            return slots - s.Disciples.Count - s.LockedUntil.Count;
        }

        /// <summary>
        /// A lesson. Teaching a never-awakened player IS their awakening
        /// (brainstorm.md §5.3), which is what makes early mages powerful
        /// figures — and it does not touch the valve, because the valve
        /// throttles the seeded events, not the social spread the slots
        /// already throttle.
        /// </summary>
        public TeachResult Teach(Mage master, Mage student, string spell, float nowHour)
        {
            if (ReferenceEquals(master, student)) return TeachResult.CannotTeachYourself;
            if (!Masters(master, spell)) return TeachResult.MasterDoesNotMaster;
            if (student.Knows(spell)) return TeachResult.AlreadyHasALineage;
            if (SlotsOf(master, spell, nowHour) <= 0) return TeachResult.NoFreeSlot;

            student.Awakened = true;
            var s = student.StandingOrNew(spell);
            s.Master = master.Name;
            master.Standing(spell)!.Disciples.Add(student.Name);
            return TeachResult.Taught;
        }

        /// <summary>Send a disciple away. The slot locks for the cooldown,
        /// so nobody churn-teaches through bodies.</summary>
        public bool Dismiss(Mage master, Mage student, string spell, float nowHour)
        {
            var ms = master.Standing(spell);
            if (ms == null || !ms.Disciples.Remove(student.Name)) return false;
            ms.LockedUntil.Add(nowHour + _p.DismissalCooldownHours);
            var ss = student.Standing(spell);
            if (ss != null) ss.Master = "";   // they keep what they learned; the lineage is cut
            return true;
        }

        public int LivingMastersOf(string spell) =>
            _mages.Values.Count(m => Masters(m, spell));

        /// <summary>A spell the server can lose.</summary>
        public bool AtRiskOfExtinction(string spell) =>
            LivingMastersOf(spell) < _p.ExtinctionBelowMasters;

        // ── The seats (L10, L34, L35) ───────────────────────────────────

        public string HolderOf(string spell) => _seats.TryGetValue(spell, out var h) ? h : "";
        public bool SeatOpen(string spell) => HolderOf(spell).Length == 0;

        /// <summary>Take the seat. One per spell per server, one per
        /// character — ever.</summary>
        public SeatResult AcceptSeat(Mage m, string spell)
        {
            if (RankOf(m, spell) < SpellRank.Grandmaster) return SeatResult.NotGrandmaster;
            if (m.Declined.Contains(spell)) return SeatResult.AlreadyDeclined;
            if (m.IncarnateOf.Length > 0) return SeatResult.AlreadyIncarnate;
            if (!SeatOpen(spell)) return SeatResult.SeatHeld;
            _seats[spell] = m.Name;
            m.IncarnateOf = spell;
            return SeatResult.Taken;
        }

        /// <summary>Decline it: quiet power. A permanent extra slot in
        /// that spell, and every other seat stays open to you.</summary>
        public SeatResult DeclineSeat(Mage m, string spell)
        {
            if (RankOf(m, spell) < SpellRank.Grandmaster) return SeatResult.NotGrandmaster;
            if (m.Declined.Contains(spell)) return SeatResult.AlreadyDeclined;
            m.Declined.Add(spell);
            return SeatResult.Declined;
        }

        /// <summary>L10's regency: one pre-declared absence per holder.</summary>
        public bool DeclareRegency(Mage m, float nowHour)
        {
            if (m.IncarnateOf.Length == 0 || m.RegencyUsed) return false;
            m.RegencyUsed = true;
            m.RegencyUntilHour = nowHour + _p.RegencyHours;
            return true;
        }

        /// <summary>The holder died their permadeath upstairs.</summary>
        public bool HolderFell(Mage m, float nowHour)
        {
            if (m.IncarnateOf.Length == 0) return false;
            Open(m.IncarnateOf, SeatOpenedBecause.Fallen, nowHour);
            return true;
        }

        /// <summary>The holder forsakes it.</summary>
        public SeatResult Forsake(Mage m, float nowHour)
        {
            if (m.IncarnateOf.Length == 0) return SeatResult.NotHolder;
            Open(m.IncarnateOf, SeatOpenedBecause.Forsaken, nowHour);
            return SeatResult.Declined;
        }

        /// <summary>Let time pass: seats whose holders have not been seen
        /// lapse, unless a regency holds them.</summary>
        public void Tick(float nowHour)
        {
            RollDay(nowHour);
            foreach (var spell in _seats.Keys.ToList())
            {
                var holder = Find(_seats[spell]);
                if (holder == null) continue;
                var limit = holder.RegencyUntilHour > holder.LastSeenHour
                    ? holder.RegencyUntilHour
                    : holder.LastSeenHour + _p.SeatLapseHours;
                if (nowHour >= limit) Open(spell, SeatOpenedBecause.Lapsed, nowHour);
            }
        }

        private void Open(string spell, SeatOpenedBecause because, float nowHour)
        {
            var holder = Find(HolderOf(spell));
            if (holder != null) holder.IncarnateOf = "";
            _seats.Remove(spell);
            _announcements.Add(new Announcement
            {
                Spell = spell, Because = because, Hour = nowHour,
                ReachesPublic = Epoch >= Epoch.Unveiling,
                TrialAtHour = nowHour + _p.TrialLeadHours,
            });
            _trials.Add(new Trial { Spell = spell, AtHour = nowHour + _p.TrialLeadHours });
        }

        public Trial? PendingTrial(string spell) =>
            _trials.LastOrDefault(t => t.Spell == spell && !t.Resolved);

        /// <summary>Only a grandmaster of the spell may enter.</summary>
        public bool EnterTrial(Mage m, string spell)
        {
            var t = PendingTrial(spell);
            if (t == null || RankOf(m, spell) < SpellRank.Grandmaster) return false;
            if (m.IncarnateOf.Length > 0 || m.Declined.Contains(spell)) return false;
            if (!t.Entrants.Contains(m.Name)) t.Entrants.Add(m.Name);
            return true;
        }

        /// <summary>
        /// Midnight in the Veiled Ring. One entrant claims by walkover;
        /// several fight and exactly one wins; none, and the seat stays
        /// open for the next grandmaster to emerge.
        /// </summary>
        public string ResolveTrial(string spell, float nowHour, string winner = "")
        {
            var t = PendingTrial(spell);
            if (t == null || nowHour < t.AtHour) return "";
            if (t.Entrants.Count == 0) { t.Resolved = true; return ""; }
            var who = t.Entrants.Count == 1 ? t.Entrants[0] : winner;
            if (!t.Entrants.Contains(who)) return "";
            var m = Find(who)!;
            t.Resolved = true;
            t.Winner = who;
            _seats[spell] = who;
            m.IncarnateOf = spell;
            return who;
        }
    }
}
