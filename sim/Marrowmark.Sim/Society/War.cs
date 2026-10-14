using System;
using System.Collections.Generic;
using System.Linq;
using Marrowmark.Sim.Economy;

namespace Marrowmark.Sim.Society
{
    public enum WarSide { Challenger, Defender }

    public enum WarPhase
    {
        /// <summary>Declared; both sides recruit; no battle yet.</summary>
        LeadTime,
        /// <summary>Battles count.</summary>
        Window,
        /// <summary>Over, one way or another.</summary>
        Ended,
    }

    public enum WarOutcome
    {
        Undecided,
        /// <summary>Best-of went to the challenger: the right and the
        /// stake are theirs.</summary>
        ChallengerWon,
        /// <summary>Best-of went to the defender, or was tied: the right
        /// stays and the stake is forfeit to them.</summary>
        DefenderHeld,
        /// <summary>The challenger walked away. The stake is forfeit.</summary>
        ChallengerWithdrew,
        /// <summary>The defender conceded. The right passes; the stake
        /// goes home.</summary>
        DefenderConceded,
        /// <summary>Settled by tribute. The right stays with whoever had
        /// it; the stake goes home; the tribute changed hands.</summary>
        Treaty,
    }

    public enum DeclareResult
    {
        Declared,
        NoSuchRight,
        NoSuchCharter,
        /// <summary>Only a Company or an Order fields a banner.</summary>
        CannotWar,
        /// <summary>Nobody holds it. Claim it; there is nobody to fight.</summary>
        NothingToContest,
        /// <summary>The holder's season has not turned.</summary>
        SeasonNotTurned,
        /// <summary>Somebody got there first.</summary>
        AlreadyContested,
        /// <summary>You cannot declare against yourself.</summary>
        OwnRight,
        /// <summary>No stake, no war.</summary>
        StakeTooSmall,
        CannotPayStake,
    }

    public enum EnrolResult
    {
        Enrolled,
        /// <summary>Not during lead time or the window.</summary>
        NotOpen,
        AlreadyEnrolled,
        /// <summary>One banner per war.</summary>
        EnrolledOnOtherSide,
        CapReached,
    }

    /// <summary>What a finished war leaves behind: a line of history
    /// (L23), and nothing that fights on.</summary>
    public sealed class WarRecord
    {
        public string RightId = "";
        public string Challenger = "";
        public string Defender = "";
        public WarOutcome Outcome;
        public int BattlesFought;
        public int Stake;
        public float DeclaredHour;
        public float EndedHour;
    }

    /// <summary>
    /// A war: a contract between two sides over a named right, fought in
    /// scheduled battles, with stakes posted up front (war-society.md §3,
    /// L25).
    ///
    /// The shape is what carries the design, and each line of §3 is a
    /// rule here. A stake is escrowed before anything else happens, so
    /// griefing declarations are priced out. Lead time comes before the
    /// window. War rules apply ONLY to the enrolled, so bystanders keep
    /// ordinary death (L17) and cannot be dragged in. Walking away
    /// forfeits the stake; a treaty does not, because a treaty is a
    /// settlement and a withdrawal is a default. The winner takes the
    /// right for a fresh season and the stake, and the war becomes a
    /// record rather than a thing that fights on.
    ///
    /// What is NOT here: what a battle is. §3 leaves objective types
    /// open, and this type only counts who won each one.
    /// </summary>
    public sealed class War
    {
        private readonly WarProfile _p;
        private readonly HashSet<string> _challengerSide = new HashSet<string>();
        private readonly HashSet<string> _defenderSide = new HashSet<string>();

        internal War(WarProfile p, Right right, string challenger, int stake,
            int enrolmentCap, float declaredHour)
        {
            _p = p;
            Right = right;
            Challenger = challenger;
            Defender = right.Holder;
            Stake = stake;
            EnrolmentCap = Math.Clamp(enrolmentCap, p.MinEnrolment, p.MaxEnrolment);
            DeclaredHour = declaredHour;
            Escrow = new Purse();
        }

        public Right Right { get; }
        public string Challenger { get; }
        public string Defender { get; }
        public int Stake { get; }

        /// <summary>Held at the capitol until the war ends.</summary>
        public Purse Escrow { get; }

        /// <summary>Per side. Negotiated at declaration, clamped to the
        /// profile's range.</summary>
        public int EnrolmentCap { get; }

        public float DeclaredHour { get; }
        public float WindowOpensHour => DeclaredHour + _p.LeadTimeHours;
        public float WindowClosesHour => WindowOpensHour + _p.WindowHours;

        public WarOutcome Outcome { get; private set; } = WarOutcome.Undecided;
        public int ChallengerBattles { get; private set; }
        public int DefenderBattles { get; private set; }
        public int BattlesFought => ChallengerBattles + DefenderBattles;

        public IReadOnlyCollection<string> ChallengerSide => _challengerSide;
        public IReadOnlyCollection<string> DefenderSide => _defenderSide;

        public WarPhase Phase(float nowHour)
        {
            if (Outcome != WarOutcome.Undecided) return WarPhase.Ended;
            if (nowHour < WindowOpensHour) return WarPhase.LeadTime;
            if (nowHour < WindowClosesHour) return WarPhase.Window;
            return WarPhase.Ended;
        }

        /// <summary>War rules apply to this person. Everyone else keeps
        /// ordinary death (L17), whatever is happening around them.</summary>
        public bool AppliesTo(string character, float nowHour) =>
            Phase(nowHour) == WarPhase.Window
            && (_challengerSide.Contains(character) || _defenderSide.Contains(character));

        /// <summary>L11, interpreted: an enrolled combatant who dies in a
        /// war battle drops one random equipped piece where they fall.
        /// Which piece is the caller's roll; whether at all is this.</summary>
        public bool DeathDropsEquipment(string character, float nowHour) =>
            AppliesTo(character, nowHour);

        public EnrolResult Enrol(string character, WarSide side, float nowHour)
        {
            var phase = Phase(nowHour);
            if (phase == WarPhase.Ended) return EnrolResult.NotOpen;

            var mine = side == WarSide.Challenger ? _challengerSide : _defenderSide;
            var theirs = side == WarSide.Challenger ? _defenderSide : _challengerSide;
            if (mine.Contains(character)) return EnrolResult.AlreadyEnrolled;
            if (theirs.Contains(character)) return EnrolResult.EnrolledOnOtherSide;
            if (mine.Count >= EnrolmentCap) return EnrolResult.CapReached;

            mine.Add(character);
            return EnrolResult.Enrolled;
        }

        /// <summary>A battle happened and somebody won it. Only inside
        /// the window; anything else is a skirmish and counts for nothing.</summary>
        public bool RecordBattle(WarSide winner, float nowHour)
        {
            if (Phase(nowHour) != WarPhase.Window) return false;
            if (winner == WarSide.Challenger) ChallengerBattles++;
            else DefenderBattles++;
            return true;
        }

        /// <summary>
        /// Walk away. The stake is forfeit to the other side — that is
        /// what "no stake, no war" buys. A defender walking away concedes
        /// the right and the stake goes home.
        /// </summary>
        public bool Withdraw(WarSide side, Purse challengerChest, Purse defenderChest, float nowHour)
        {
            if (Phase(nowHour) == WarPhase.Ended) return false;
            if (side == WarSide.Challenger)
            {
                Escrow.TryPay(defenderChest, Escrow.Coin);
                Outcome = WarOutcome.ChallengerWithdrew;
            }
            else
            {
                Escrow.TryPay(challengerChest, Escrow.Coin);
                Outcome = WarOutcome.DefenderConceded;
                TakeRight(Challenger, nowHour);
            }
            return true;
        }

        /// <summary>
        /// A treaty: one side pays the other tribute to end it. The right
        /// stays where it is and the stake goes home, because a treaty is
        /// a settlement rather than a default.
        /// </summary>
        public bool Treaty(WarSide payer, int tribute, Purse challengerChest,
            Purse defenderChest, float nowHour)
        {
            if (Phase(nowHour) == WarPhase.Ended || tribute < 0) return false;
            var from = payer == WarSide.Challenger ? challengerChest : defenderChest;
            var to = payer == WarSide.Challenger ? defenderChest : challengerChest;
            if (!from.TryPay(to, tribute)) return false;
            Escrow.TryPay(challengerChest, Escrow.Coin);
            Outcome = WarOutcome.Treaty;
            return true;
        }

        /// <summary>
        /// Best-of over the window's battles, once the window has closed.
        /// Winner takes the right for the season and the stake. A tie
        /// holds: the defender was never beaten, and the challenger
        /// posted the stake knowing that.
        /// </summary>
        public bool Resolve(Purse challengerChest, Purse defenderChest, float nowHour)
        {
            if (Outcome != WarOutcome.Undecided) return false;
            if (nowHour < WindowClosesHour) return false;

            if (ChallengerBattles > DefenderBattles)
            {
                Escrow.TryPay(challengerChest, Escrow.Coin);
                Outcome = WarOutcome.ChallengerWon;
                TakeRight(Challenger, nowHour);
            }
            else
            {
                Escrow.TryPay(defenderChest, Escrow.Coin);
                Outcome = WarOutcome.DefenderHeld;
                TakeRight(Defender, nowHour);
            }
            return true;
        }

        private void TakeRight(string holder, float nowHour)
        {
            Right.Holder = holder;
            Right.SeasonEndsHour = nowHour + _p.SeasonHours;
        }

        public WarRecord Record(float endedHour) => new WarRecord
        {
            RightId = Right.Id, Challenger = Challenger, Defender = Defender,
            Outcome = Outcome, BattlesFought = BattlesFought, Stake = Stake,
            DeclaredHour = DeclaredHour, EndedHour = endedHour,
        };
    }

    /// <summary>
    /// The capitol's war office: where rights are registered, stakes are
    /// escrowed and wars are declared. One per world.
    /// </summary>
    public sealed class WarOffice
    {
        private readonly WarProfile _p;
        private readonly List<Right> _rights = new List<Right>();
        private readonly List<War> _wars = new List<War>();
        private readonly List<WarRecord> _history = new List<WarRecord>();

        public WarOffice(Charters charters, WarProfile profile)
        {
            Charters = charters;
            _p = profile;
        }

        public WarOffice(Charters charters) : this(charters, WarProfile.Default) { }

        public Charters Charters { get; }
        public IReadOnlyList<Right> Rights => _rights;
        public IReadOnlyList<War> Wars => _wars;

        /// <summary>Every war is recorded; named battles enter the
        /// server's living history (L23).</summary>
        public IReadOnlyList<WarRecord> History => _history;

        public Right Register(string id, RightKind kind)
        {
            var r = new Right { Id = id, Kind = kind };
            _rights.Add(r);
            return r;
        }

        public Right? FindRight(string id) => _rights.FirstOrDefault(r => r.Id == id);

        public War? WarOver(string rightId) =>
            _wars.FirstOrDefault(w => w.Right.Id == rightId && w.Outcome == WarOutcome.Undecided);

        /// <summary>
        /// Take an unheld right for a season. No war, because there is
        /// nobody to fight. Placeholder: the real registration will cost
        /// something ("charter registration" is one of economy.md §4's
        /// sinks) and that number does not exist yet.
        /// </summary>
        public bool Claim(string rightId, string charterId, float nowHour)
        {
            var right = FindRight(rightId);
            var charter = Charters.Find(charterId);
            if (right == null || charter == null || !charter.CanWar) return false;
            if (!right.Challengeable(nowHour) || right.Held) return false;
            right.Holder = charterId;
            right.SeasonEndsHour = nowHour + _p.SeasonHours;
            return true;
        }

        /// <summary>
        /// File a challenge on a specific right. Requires a stake escrowed
        /// at the capitol; walking away forfeits it. No stake, no war.
        /// </summary>
        public DeclareResult Declare(string rightId, string challengerId, int stake,
            Purse warChest, int enrolmentCap, float nowHour, out War? war)
        {
            war = null;
            var right = FindRight(rightId);
            if (right == null) return DeclareResult.NoSuchRight;
            var challenger = Charters.Find(challengerId);
            if (challenger == null) return DeclareResult.NoSuchCharter;
            if (!challenger.CanWar) return DeclareResult.CannotWar;
            if (!right.Held) return DeclareResult.NothingToContest;
            if (right.Holder == challengerId) return DeclareResult.OwnRight;
            if (!right.Challengeable(nowHour)) return DeclareResult.SeasonNotTurned;
            if (WarOver(rightId) != null) return DeclareResult.AlreadyContested;
            if (stake < _p.StakeMinimum) return DeclareResult.StakeTooSmall;

            var w = new War(_p, right, challengerId, stake, enrolmentCap, nowHour);
            if (!warChest.TryPay(w.Escrow, stake)) return DeclareResult.CannotPayStake;

            _wars.Add(w);
            war = w;
            return DeclareResult.Declared;
        }

        /// <summary>Close the books on a finished war: it leaves the
        /// active list and enters history.</summary>
        public WarRecord? Archive(War war, float nowHour)
        {
            if (war.Outcome == WarOutcome.Undecided || !_wars.Remove(war)) return null;
            var record = war.Record(nowHour);
            _history.Add(record);
            return record;
        }
    }
}
