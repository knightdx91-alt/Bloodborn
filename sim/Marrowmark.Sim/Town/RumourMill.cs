using System;

namespace Marrowmark.Sim.Town
{
    /// <summary>What a search turned up, and whether the teller vouches.</summary>
    public struct RumourResult
    {
        public bool Found;
        public Rumour? Rumour;

        /// <summary>True when the rumour is bent enough that the teller
        /// hedges rather than vouches. The prose layer decides what
        /// hedging sounds like; the rule only says that it does.</summary>
        public bool Hedged;

        /// <summary>False when the drink could not be paid for.</summary>
        public bool Paid;
    }

    /// <summary>
    /// Rumour as a search interface (content.md §3) — "content discovery
    /// *is* the fireside story (L22)". Buying somebody a drink is how you
    /// run a query, and what comes back carries who said it, how old it
    /// is and how bent it has got.
    ///
    /// This part-answers an open question content.md still lists: the
    /// rumour data model, epoch plus history plus noise mixing.
    /// </summary>
    public static class RumourMill
    {
        /// <summary>
        /// The best thing anyone will tell you right now.
        ///
        /// Freshest-first, with bent rumours pushed down — so a fresh lie
        /// still loses to a slightly older truth, which is what keeps the
        /// mill worth consulting rather than merely noisy.
        /// </summary>
        public static RumourResult Search(TownState state) =>
            Search(state, TownProfile.Default);

        public static RumourResult Search(TownState state, TownProfile p)
        {
            Rumour? best = null;
            var bestScore = float.NegativeInfinity;

            foreach (var r in state.Rumours)
            {
                var score = p.FreshnessWeight / (1f + r.AgeHours)
                            - r.Distortion * p.DistortionPenalty;
                if (score <= bestScore) continue;
                bestScore = score;
                best = r;
            }

            if (best == null) return new RumourResult { Found = false, Paid = true };

            return new RumourResult
            {
                Found = true,
                Rumour = best,
                Hedged = best.Distortion >= p.HedgeAbove,
                Paid = true,
            };
        }

        /// <summary>
        /// Buy the drink that buys the talk. Spends coin, so it is binding
        /// and the conversation layer confirms first (L49).
        /// </summary>
        public static RumourResult BuyDrink(TownState state) =>
            BuyDrink(state, TownProfile.Default);

        public static RumourResult BuyDrink(TownState state, TownProfile p)
        {
            if (state.Coin < p.DrinkPrice)
                return new RumourResult { Found = false, Paid = false };

            state.Coin -= p.DrinkPrice;
            return Search(state, p);
        }

        /// <summary>
        /// Time passes. Rumours age and bend.
        ///
        /// Distortion is capped below 1 deliberately: a rumour that is
        /// pure noise is not a rumour, it is a lie, and the person telling
        /// it would know. What ageing produces is a story that is still
        /// *about* something and no longer reliable about the details.
        /// </summary>
        public static void AgeAll(TownState state, float hours) =>
            AgeAll(state, hours, TownProfile.Default);

        public static void AgeAll(TownState state, float hours, TownProfile p)
        {
            if (hours <= 0f) return;
            foreach (var r in state.Rumours)
            {
                r.AgeHours += hours;
                r.Distortion = Math.Min(p.MaxDistortion,
                    r.Distortion + hours * p.DistortionPerHour);
            }
        }
    }
}
