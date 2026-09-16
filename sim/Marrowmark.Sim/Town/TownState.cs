using System.Collections.Generic;

namespace Marrowmark.Sim.Town
{
    /// <summary>A blood-warped boar problem in one named place.</summary>
    public sealed class BoarPressure
    {
        public string Region = "";

        /// <summary>0–5. Grows if unculled; cull contracts are real
        /// maintenance (content.md §2), not busywork.</summary>
        public int Pressure;
    }

    /// <summary>A wagon actually mustering, which is what makes an escort
    /// contract honest (content.md §3).</summary>
    public sealed class Caravan
    {
        public string Id = "";
        public string Destination = "";
        public string Status = "";
        public int Guards;

        public const string Mustering = "mustering";
    }

    /// <summary>A commission a smith will actually pay for.</summary>
    public sealed class SmithingJob
    {
        public string Id = "";
        public int Pay;
    }

    /// <summary>Stock in the town warehouse. The market board lists this
    /// and nothing else (economy.md §3). Prices in copper pennies.</summary>
    public sealed class WarehousedGood
    {
        public string Good = "";
        public int Quantity;
        public int Price;
        public string Unit = "";
    }

    /// <summary>
    /// One rumour, with the three things that make rumour a search
    /// interface rather than a noticeboard (content.md §3): who said it,
    /// how old it is, and how bent it has got in the telling.
    ///
    /// The text is carried, never interpreted. Authoring prose is content
    /// and belongs to whoever is writing the town; the rules only rank.
    /// </summary>
    public sealed class Rumour
    {
        public string Text = "";
        public string Source = "";
        public float AgeHours;

        /// <summary>0–1. Past <see cref="RumourMill"/>'s hedge threshold
        /// the teller stops vouching for it.</summary>
        public float Distortion;
    }

    /// <summary>Work done toward one taken contract.</summary>
    public sealed class ContractProgress
    {
        public string ContractId = "";
        public int Done;
    }

    /// <summary>
    /// Everything a town's boards, shrine, rumours and apprenticeship
    /// read. Seeded by whoever is building the town — this type owns the
    /// shape and the rules that act on it, never the content.
    ///
    /// L88: this lives in sim/ because it is rules, and rules in the
    /// engine-facing copy cannot be tested or reused by the server. The
    /// prototype mirrors it in GDScript; the mirror is not the authority.
    /// </summary>
    public sealed class TownState
    {
        /// <summary>Epoch 0 is the first harvest. Barks and rumours filter
        /// on this, so the same town says different things as the world
        /// moves.</summary>
        public int Epoch;

        public List<BoarPressure> BoarPressure = new List<BoarPressure>();
        public List<Caravan> Caravans = new List<Caravan>();
        public List<SmithingJob> SmithingJobs = new List<SmithingJob>();
        public List<WarehousedGood> Warehoused = new List<WarehousedGood>();
        public List<Rumour> Rumours = new List<Rumour>();

        /// <summary>Hands wanted for the harvest. Zero means the contract
        /// is simply not on the board.</summary>
        public int HarvestDemand;

        public List<string> ContractsTaken = new List<string>();

        /// <summary>How far along each taken contract is. Separate from
        /// ContractsTaken because taking work and doing it are different
        /// facts, and only the second one can be lost.</summary>
        public List<ContractProgress> ContractProgress = new List<ContractProgress>();

        /// <summary>Copper pennies.</summary>
        public int Coin;

        /// <summary>onboarding.md §1 — you begin as somebody's hired hand.
        /// Empty until a master takes you on.</summary>
        public string ApprenticeMaster = "";

        public bool Hired => ApprenticeMaster.Length > 0;

        /// <summary>How many times the shrine has knitted you back
        /// (lore.md §3). What coin could not cover is remembered here.</summary>
        public int Respawns;

        /// <summary>Pennies taken by the shrine on the last death.</summary>
        public int LastTollPaid;

        /// <summary>How many culls have actually been finished and paid.
        ///
        /// Kept because handing a contract in REMOVES it — the paper goes
        /// back and the pressure drops, and neither of those is a record
        /// that the work was done by anybody in particular. The crowd
        /// needs to know somebody has been thinning the boars in order to
        /// say so.</summary>
        public int CullsCompleted;

        /// <summary>
        /// Papers given back unfinished.
        ///
        /// Counted rather than punished. content.md §3's board never lies,
        /// and a town that has watched you take three jobs and return
        /// three of them knows something about you that no reputation
        /// number needs to express — it comes out in what people say,
        /// which is where the world already keeps its opinions.
        /// </summary>
        public int ContractsAbandoned;
    }
}
