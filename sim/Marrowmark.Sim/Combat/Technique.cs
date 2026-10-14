using System;
using System.Collections.Generic;
using System.Linq;

namespace Marrowmark.Sim.Combat
{
    /// <summary>Where a technique carries the body, relative to facing.</summary>
    public enum Bearing
    {
        /// <summary>Closes distance.</summary>
        Forward,
        /// <summary>Opens it.</summary>
        Backward,
        /// <summary>Carries you sideways, out of a heavy.</summary>
        Lateral,
        /// <summary>Puts you behind someone.</summary>
        Around,
        /// <summary>Crosses a gap or an obstacle — a leap, a vault.</summary>
        Over,
    }

    /// <summary>
    /// The numbers behind every technique that are not the technique's
    /// own. L95: a technique is taught, never gated, so what keeps a
    /// day-one student from being a master is here — hands that have not
    /// practised pay more for the move and telegraph it longer.
    /// </summary>
    public struct TechniqueProfile
    {
        /// <summary>Stamina multiplier at zero family skill, falling to 1
        /// at mastery. combat.md §3: skill buys stamina efficiency.</summary>
        public float UnskilledCostMultiplier;

        /// <summary>Wind-up multiplier at zero family skill, falling to 1
        /// at mastery. A move you cannot yet do well is a move everyone
        /// can see coming.</summary>
        public float UnskilledWindupMultiplier;

        /// <summary>How many each family has. Decided 2026-10-14: three.</summary>
        public int PerFamily;

        /// <summary>L56's ceiling — anything a trained human body could
        /// do. No technique carries you further than this in one move.</summary>
        public float MaxDistance;

        public static TechniqueProfile Default => new TechniqueProfile
        {
            UnskilledCostMultiplier = 1.6f,
            UnskilledWindupMultiplier = 1.5f,
            PerFamily = 3,
            MaxDistance = 4f,
        };
    }

    /// <summary>
    /// One technique: a committed move that carries the body somewhere
    /// and lands a blow on arrival. L56 and combat.md §3 — "techniques are
    /// primarily how you move... learning a weapon expands where your body
    /// can go in a fight."
    ///
    /// Still a commitment, still stamina-priced, still readable: it has a
    /// wind-up like any attack, so §6's grammar survives. The numbers are
    /// placeholders; the names are too (lore.md §8).
    /// </summary>
    public sealed class Technique
    {
        public string Id = "";
        public WeaponFamily Family;

        /// <summary>1 is shown first; 3 is a master's. Order, not a gate.</summary>
        public int Tier;

        public Bearing Bearing;

        /// <summary>Metres the body travels.</summary>
        public float Distance;

        /// <summary>Which arc the blow on arrival follows. Must be one the
        /// family can throw.</summary>
        public AttackDirection Strike;

        public float StaminaCost;
        public float WindupSeconds;
        public float DamageMultiplier;

        public float CostFor(float familySkill, TechniqueProfile p) =>
            StaminaCost * Lerp(p.UnskilledCostMultiplier, 1f, familySkill);

        public float WindupFor(float familySkill, TechniqueProfile p) =>
            WindupSeconds * Lerp(p.UnskilledWindupMultiplier, 1f, familySkill);

        private static float Lerp(float a, float b, float t)
        {
            t = t < 0f ? 0f : (t > 1f ? 1f : t);
            return a + (b - a) * t;
        }
    }

    /// <summary>
    /// Every technique in the game. Three per family, eighteen in all,
    /// each with a bearing — because mobility is the point, a technique
    /// that does not move you is not one.
    /// </summary>
    public static class TechniqueBook
    {
        private static Technique T(string id, WeaponFamily f, int tier, Bearing b, float dist,
            AttackDirection strike, float cost, float windup, float dmg) => new Technique
        {
            Id = id, Family = f, Tier = tier, Bearing = b, Distance = dist, Strike = strike,
            StaminaCost = cost, WindupSeconds = windup, DamageMultiplier = dmg,
        };

        public static IReadOnlyList<Technique> All { get; } = new List<Technique>
        {
            // Sword & shield — balanced; the shield buys the forward step.
            T("shield-shove-step", WeaponFamily.SwordAndShield, 1, Bearing.Forward, 1.5f, AttackDirection.UpperRight, 18f, 0.35f, 0.9f),
            T("pivot-cut",         WeaponFamily.SwordAndShield, 2, Bearing.Lateral, 2.0f, AttackDirection.LowerLeft,  22f, 0.40f, 1.0f),
            T("step-through",      WeaponFamily.SwordAndShield, 3, Bearing.Around,  2.5f, AttackDirection.UpperLeft,  26f, 0.45f, 1.1f),

            // Two-handed — slow commitments, high reward. No thrust, so
            // every arrival is a cut.
            T("driving-overhead",  WeaponFamily.TwoHanded, 1, Bearing.Forward, 2.0f, AttackDirection.Overhead,   26f, 0.60f, 1.3f),
            T("sweeping-turn",     WeaponFamily.TwoHanded, 2, Bearing.Lateral, 1.5f, AttackDirection.UpperRight, 28f, 0.55f, 1.2f),
            T("leaping-overhead",  WeaponFamily.TwoHanded, 3, Bearing.Over,    3.0f, AttackDirection.Overhead,   34f, 0.80f, 1.6f),

            // Spear & polearm — reach and spacing.
            T("lunge",             WeaponFamily.SpearAndPolearm, 1, Bearing.Forward,  2.5f, AttackDirection.Thrust,    20f, 0.40f, 1.1f),
            T("withdrawing-point", WeaponFamily.SpearAndPolearm, 2, Bearing.Backward, 2.0f, AttackDirection.Thrust,    22f, 0.35f, 0.9f),
            T("vaulting-point",    WeaponFamily.SpearAndPolearm, 3, Bearing.Over,     3.0f, AttackDirection.Overhead,  30f, 0.70f, 1.3f),

            // Dagger & short blade — fast, low commitment, wins on recovery.
            T("darting-step",      WeaponFamily.DaggerAndShortBlade, 1, Bearing.Forward, 2.0f, AttackDirection.Thrust,     12f, 0.25f, 0.7f),
            T("slip-behind",       WeaponFamily.DaggerAndShortBlade, 2, Bearing.Around,  2.0f, AttackDirection.LowerRight, 16f, 0.30f, 0.8f),
            T("rolling-cut",       WeaponFamily.DaggerAndShortBlade, 3, Bearing.Lateral, 2.5f, AttackDirection.UpperLeft,  18f, 0.30f, 0.9f),

            // Axe & mace — guard-breakers, slow recovery.
            T("hooking-step",      WeaponFamily.AxeAndMace, 1, Bearing.Forward, 1.5f, AttackDirection.LowerRight, 22f, 0.45f, 1.1f),
            T("hewing-turn",       WeaponFamily.AxeAndMace, 2, Bearing.Lateral, 1.5f, AttackDirection.UpperLeft,  26f, 0.50f, 1.2f),
            T("crashing-overhead", WeaponFamily.AxeAndMace, 3, Bearing.Over,    2.5f, AttackDirection.Overhead,   32f, 0.75f, 1.5f),

            // Bow & crossbow — the same shape as everyone else's, decided
            // 2026-10-14: archers are mobile, not turrets. The shot is a
            // thrust (it lands where a thrust lands).
            T("backstep-draw",     WeaponFamily.BowAndCrossbow, 1, Bearing.Backward, 2.0f, AttackDirection.Thrust, 20f, 0.60f, 1.0f),
            T("snap-on-the-move",  WeaponFamily.BowAndCrossbow, 2, Bearing.Lateral,  2.0f, AttackDirection.Thrust, 22f, 0.45f, 0.8f),
            T("roll-and-loose",    WeaponFamily.BowAndCrossbow, 3, Bearing.Around,   2.5f, AttackDirection.Thrust, 28f, 0.70f, 1.1f),
        };

        public static Technique? Find(string id) => All.FirstOrDefault(t => t.Id == id);

        public static IEnumerable<Technique> Of(WeaponFamily family) =>
            All.Where(t => t.Family == family).OrderBy(t => t.Tier);
    }

    public enum TeachResult
    {
        Taught,
        /// <summary>You cannot show what you do not know.</summary>
        TeacherDoesNotKnow,
        AlreadyKnown,
        /// <summary>Nobody learns a technique from themselves. That is
        /// what being shown means.</summary>
        SameFighter,
        NoSuchTechnique,
    }

    public enum AttemptResult
    {
        Started,
        /// <summary>Nobody has shown you this.</summary>
        NotKnown,
        /// <summary>An empty bar refuses movement, as it refuses the
        /// dodge (combat.md §2, amended 2026-09-27). A technique is the
        /// thing you have to have kept something back for.</summary>
        Exhausted,
        NoSuchTechnique,
    }

    public sealed class Attempt
    {
        public AttemptResult Result;
        public float Cost;
        public float WindupSeconds;
        public float Distance;
        public Bearing Bearing;
        public bool Afforded;
    }

    /// <summary>
    /// What one fighter has been shown. L95: a technique is known or it
    /// is not, and the only way from one to the other is a person who
    /// knows it showing you. There is no skill gate on learning; the skill
    /// shows in the doing.
    /// </summary>
    public sealed class Repertoire
    {
        private readonly HashSet<string> _known = new HashSet<string>();
        private readonly TechniqueProfile _p;

        public Repertoire(TechniqueProfile profile) { _p = profile; }
        public Repertoire() : this(TechniqueProfile.Default) { }

        public IReadOnlyCollection<string> Known => _known;
        public bool Knows(string techniqueId) => _known.Contains(techniqueId);

        /// <summary>Be shown a technique by somebody who has it.</summary>
        public TeachResult LearnFrom(Repertoire teacher, string techniqueId)
        {
            if (TechniqueBook.Find(techniqueId) == null) return TeachResult.NoSuchTechnique;
            if (ReferenceEquals(teacher, this)) return TeachResult.SameFighter;
            if (!teacher.Knows(techniqueId)) return TeachResult.TeacherDoesNotKnow;
            if (_known.Contains(techniqueId)) return TeachResult.AlreadyKnown;
            _known.Add(techniqueId);
            return TeachResult.Taught;
        }

        /// <summary>
        /// Content's door: a technique that was always known — a master's
        /// at the drill yard, a bandit's. The rules do not ask where a
        /// non-player's knowledge came from.
        /// </summary>
        public void Grant(string techniqueId)
        {
            if (TechniqueBook.Find(techniqueId) != null) _known.Add(techniqueId);
        }

        /// <summary>
        /// Try the move. Pays from the bar at the price the fighter's
        /// family skill sets; an exhausted fighter is refused outright.
        /// What the body then does with the bearing and distance is the
        /// engine's.
        /// </summary>
        public Attempt Try(string techniqueId, Stamina stamina, float familySkill)
        {
            var a = new Attempt();
            var t = TechniqueBook.Find(techniqueId);
            if (t == null) { a.Result = AttemptResult.NoSuchTechnique; return a; }
            if (!_known.Contains(techniqueId)) { a.Result = AttemptResult.NotKnown; return a; }
            if (stamina.IsExhausted) { a.Result = AttemptResult.Exhausted; return a; }

            a.Cost = t.CostFor(familySkill, _p);
            a.WindupSeconds = t.WindupFor(familySkill, _p);
            a.Distance = t.Distance;
            a.Bearing = t.Bearing;
            a.Afforded = stamina.Spend(a.Cost).Afforded;
            a.Result = AttemptResult.Started;
            return a;
        }
    }
}
