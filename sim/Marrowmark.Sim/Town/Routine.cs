using System.Collections.Generic;
using System.Linq;

namespace Marrowmark.Sim.Town
{
    /// <summary>Somewhere a person is, and the hours they are there.</summary>
    public sealed class Posting
    {
        /// <summary>A name the town understands — "forge", "inn", "board",
        /// "home". Where that actually IS on the ground is the scene's
        /// business, not this layer's.</summary>
        public string Place = "";

        /// <summary>Inclusive start, exclusive end, on a 24-hour dial.
        /// Wraps past midnight when From > To, which is the normal case
        /// for anybody who sleeps.</summary>
        public float From;
        public float To;

        public bool Covers(float hour)
        {
            if (From <= To) return hour >= From && hour < To;
            // Wraps midnight: 21:00–06:00 is two arcs of one day.
            return hour >= From || hour < To;
        }
    }

    /// <summary>What one person does with their day.</summary>
    public sealed class Routine
    {
        public string NpcId = "";
        public List<Posting> Postings = new List<Posting>();

        /// <summary>Where they are when nothing else covers the hour.</summary>
        public string Fallback = "home";
    }

    /// <summary>
    /// The town keeps hours (L89's clock, put to work).
    ///
    /// **A town is alive when it has a life that does not depend on you.**
    /// Thornfield had a sun crossing the sky and thirty-four people
    /// standing in exactly the same spots at three in the morning as at
    /// noon, which reads as a diorama however good the light is.
    ///
    /// This is deliberately a RULE and not a scene behaviour, for the
    /// same reason the clock is: the server decides where people are.
    /// Two players walking into the inn at dusk have to find the same
    /// innkeeper there, and a client inventing its own schedule cannot
    /// promise that. The scene's only job is knowing where "the forge"
    /// is on the ground and walking somebody there.
    /// </summary>
    public static class TownRoutine
    {
        /// <summary>Where this person should be at this hour.</summary>
        public static string PlaceFor(Routine routine, float hour)
        {
            if (routine == null) return "home";
            var h = Wrap(hour);
            foreach (var p in routine.Postings)
                if (p.Covers(h)) return p.Place;
            return routine.Fallback;
        }

        public static string PlaceFor(IEnumerable<Routine> routines, string npcId, float hour)
        {
            var r = routines?.FirstOrDefault(x => x.NpcId == npcId);
            return PlaceFor(r, hour);
        }

        /// <summary>
        /// Everyone whose place changes between two hours — the people who
        /// should be walking somewhere right now.
        ///
        /// Asked as a DIFFERENCE rather than "who is due at the inn",
        /// because the scene needs to know who to move, and a person whose
        /// posting has not changed should not be re-walked to where they
        /// already stand.
        /// </summary>
        public static List<string> Moving(IEnumerable<Routine> routines, float fromHour, float toHour)
        {
            var moved = new List<string>();
            if (routines == null) return moved;
            foreach (var r in routines)
                if (PlaceFor(r, fromHour) != PlaceFor(r, toHour))
                    moved.Add(r.NpcId);
            return moved;
        }

        /// <summary>
        /// Is the town awake? Used for the things that are about the town
        /// rather than about one person — whether the market has anybody
        /// in it, whether a bark about the weather makes sense.
        /// </summary>
        public static bool Waking(float hour)
        {
            var h = Wrap(hour);
            return h >= 6f && h < 22f;
        }

        private static float Wrap(float hour)
        {
            var h = hour % 24f;
            return h < 0f ? h + 24f : h;
        }
    }
}
