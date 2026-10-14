using System;
using System.Collections.Generic;
using System.Linq;
using Marrowmark.Sim.Town;

namespace Marrowmark.Sim.Ecology
{
    /// <summary>
    /// A named horror: what a pooling births when it is left alone too
    /// long (content.md §2). Specific, with generated traits and a
    /// growing bounty, and remembered when it dies — the year the Hollow
    /// Sow broke the Thornfield hedges (L23).
    /// </summary>
    public sealed class Horror
    {
        public string Name = "";
        public string Pooling = "";
        public float BornHour;
        public List<string> Traits = new List<string>();

        /// <summary>Pennies, and growing. A reason to go.</summary>
        public int Bounty;
    }

    /// <summary>A line of server history: who killed what, where, when.</summary>
    public sealed class Slaying
    {
        public string HorrorName = "";
        public string Pooling = "";
        public string By = "";
        public float Hour;
        public int Bounty;
    }

    /// <summary>
    /// One warped population around one pooling. Population is the truth;
    /// pressure is what the board reads off it.
    /// </summary>
    public sealed class Territory
    {
        public string Pooling = "";

        /// <summary>The named place the town's board talks about.</summary>
        public string Region = "";

        public float Population;
        public float HoursSinceCull;
        public Horror? Horror;

        /// <summary>Pennies posted on the horror, growing while it lives.</summary>
        public float BountyAccumulator;
    }

    public sealed class CullResult
    {
        public int Killed;

        /// <summary>Warped parts, for the crafters (L4).</summary>
        public int Parts;

        /// <summary>The horror died in this cull.</summary>
        public Slaying? Slaying;
    }

    /// <summary>
    /// The monster ecology (content.md §2): not spawn-timer decorations.
    /// Warped populations grow if unculled and push out toward roads and
    /// farms; culls are real maintenance; parts are materials; and a
    /// pooling left alone births something with a name.
    ///
    /// Everything generated here is a pure function of the world seed and
    /// the pooling's id — the generator's rule, kept: a horror is the same
    /// horror whichever server tick first looks at it.
    /// </summary>
    public sealed class Wilds
    {
        private readonly EcologyProfile _p;
        private readonly List<Territory> _territories = new List<Territory>();
        private readonly List<Slaying> _history = new List<Slaying>();

        private static readonly string[] Epithets =
            { "Hollow", "Red", "Grey", "Weeping", "Hedge", "Marrow", "Black", "Lame" };
        private static readonly string[] Beasts =
            { "Sow", "Boar", "Stag", "Hound", "Heron", "Wolf", "Bull", "Ram" };

        /// <summary>combat.md §6: the warped things break the grammar
        /// deliberately. A trait is a broken rule, not a bigger number.</summary>
        private static readonly string[] TraitPool =
        {
            "its heavy has no weight shift",
            "it charges twice",
            "an armoured flank that turns a cut",
            "it hunts after dark",
            "it does not bleed",
            "its quick comes from the off side",
            "it will not leave the water",
        };

        public Wilds(int worldSeed, EcologyProfile profile)
        {
            Seed = worldSeed;
            _p = profile;
        }

        public Wilds(int worldSeed) : this(worldSeed, EcologyProfile.Default) { }

        public int Seed { get; }
        public IReadOnlyList<Territory> Territories => _territories;
        public IReadOnlyList<Slaying> History => _history;

        public Territory? Find(string pooling) => _territories.FirstOrDefault(t => t.Pooling == pooling);

        /// <summary>Content's door: a pooling, the region it threatens, and
        /// what lives there now.</summary>
        public Territory Pooling(string id, string region, int population)
        {
            var t = new Territory { Pooling = id, Region = region, Population = Math.Max(0, population) };
            _territories.Add(t);
            return t;
        }

        /// <summary>0 to MaxPressure, read off the population.</summary>
        public int PressureOf(Territory t) =>
            Math.Min(_p.MaxPressure, (int)Math.Floor(t.Population / _p.PopulationPerPressure));

        /// <summary>Pushing out of the wedge toward roads and farms.</summary>
        public bool Spilling(Territory t) => PressureOf(t) >= _p.SpillPressure;

        /// <summary>
        /// Let the hours pass. Populations grow toward capacity; poolings
        /// left alone long enough birth a horror; a living horror's bounty
        /// grows by the day.
        /// </summary>
        public void Advance(float hours, float nowHour)
        {
            if (hours <= 0f) return;
            foreach (var t in _territories)
            {
                // Logistic growth: r * P * (1 - P/K), per hour.
                var room = 1f - t.Population / _p.CarryingCapacity;
                if (room < 0f) room = 0f;
                var seedling = t.Population < 1f ? 1f : t.Population;   // nothing grows from nothing, but a pooling is never quite empty
                t.Population = Math.Min(_p.CarryingCapacity,
                    t.Population + _p.GrowthPerHour * seedling * room * hours);

                t.HoursSinceCull += hours;

                var born = false;
                if (t.Horror == null && t.HoursSinceCull >= _p.HorrorAfterHours)
                {
                    t.Horror = Birth(t, nowHour);
                    born = true;
                }

                // The bounty counts from the birth, not from the start of
                // the tick that birthed it: a horror that appeared at the
                // end of a long quiet stretch has not been at large for it.
                if (t.Horror != null && !born)
                {
                    t.BountyAccumulator += _p.HorrorBountyPerDay * hours / _p.HoursPerDay;
                    t.Horror.Bounty = (int)Math.Floor(t.BountyAccumulator);
                }
            }
        }

        /// <summary>
        /// Kill some of it. The population falls, parts come back, the
        /// clock on the pooling resets, and if the horror is among the
        /// dead it enters history with the name of who did it.
        /// </summary>
        public CullResult Cull(Territory t, int kills, string by, float nowHour, bool slayHorror = false)
        {
            var r = new CullResult();
            if (kills <= 0) return r;
            var killed = (int)Math.Min(kills, Math.Floor(t.Population));
            t.Population -= killed;
            t.HoursSinceCull = 0f;
            r.Killed = killed;
            r.Parts = killed * _p.PartsPerKill;

            if (slayHorror && t.Horror != null)
            {
                var s = new Slaying
                {
                    HorrorName = t.Horror.Name, Pooling = t.Pooling, By = by,
                    Hour = nowHour, Bounty = t.Horror.Bounty,
                };
                _history.Add(s);
                r.Slaying = s;
                r.Parts += _p.PartsPerKill * 5;    // a horror is a rare supply run
                t.Horror = null;
                t.BountyAccumulator = 0f;
            }
            return r;
        }

        /// <summary>What the town's board should say. The board reads
        /// pressure; this is where pressure comes from.</summary>
        public void WriteInto(TownState state)
        {
            foreach (var t in _territories)
            {
                var entry = state.BoarPressure.FirstOrDefault(b => b.Region == t.Region);
                if (entry == null)
                {
                    entry = new BoarPressure { Region = t.Region };
                    state.BoarPressure.Add(entry);
                }
                entry.Pressure = PressureOf(t);
            }
        }

        /// <summary>Deterministic from seed and pooling: the same pooling
        /// births the same horror on every server that shares the seed.</summary>
        public Horror Birth(Territory t, float nowHour)
        {
            var h = Hash(Seed, t.Pooling);
            var name = "the " + Epithets[h % Epithets.Length] + " " + Beasts[(h / 7) % Beasts.Length];
            var traits = new List<string>();
            var first = (h / 13) % TraitPool.Length;
            var second = (h / 17) % TraitPool.Length;
            traits.Add(TraitPool[first]);
            if (second != first) traits.Add(TraitPool[second]);
            return new Horror { Name = name, Pooling = t.Pooling, BornHour = nowHour, Traits = traits, Bounty = 0 };
        }

        private static int Hash(int seed, string s)
        {
            unchecked
            {
                var h = 2166136261u ^ (uint)seed;
                foreach (var c in s) { h ^= c; h *= 16777619u; }
                return (int)(h & 0x7fffffff);
            }
        }
    }
}
