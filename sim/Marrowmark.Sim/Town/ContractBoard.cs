using System.Collections.Generic;
using System.Linq;

namespace Marrowmark.Sim.Town
{
    public enum ContractKind { Cull, Escort, Harvest, Smithing }

    /// <summary>
    /// One posting on the board — the FACTS of it, and no prose.
    ///
    /// The GDScript this was ported from built a title and a paragraph of
    /// detail here. Those stayed behind on purpose: what work exists and
    /// what it pays is a rule, how a Thornfield carter phrases it is
    /// content, and L88's split is only worth having if it is drawn in
    /// the right place. A second town, or a localisation, changes the
    /// prose and none of this.
    /// </summary>
    public sealed class Contract
    {
        public string Id = "";
        public ContractKind Kind;

        /// <summary>What the work is about — the region for a cull, the
        /// destination for an escort. Empty where it does not apply.</summary>
        public string Subject = "";

        /// <summary>The severity the pay was computed from: boar pressure,
        /// or guards wanted, or hands wanted. Carried so the prose layer
        /// can say "pressure 3 of 5" without recomputing it.</summary>
        public int Magnitude;

        public int Pay;
        public bool Taken;
    }

    /// <summary>
    /// The town's contract and market boards (content.md §3).
    ///
    /// **The board never lies.** Every posting is generated from state
    /// that is actually true: a cull exists because boars are actually
    /// pressing, an escort exists because a wagon is actually mustering,
    /// the harvest exists because hands are actually wanted. Set the
    /// pressure to zero and the contract is not on the board — there is
    /// no quest-hub filler and no marker over anyone's head.
    /// </summary>
    public static class ContractBoard
    {
        public static List<Contract> Generate(TownState state) =>
            Generate(state, TownProfile.Default);

        public static List<Contract> Generate(TownState state, TownProfile p)
        {
            var open = new List<Contract>();

            foreach (var boars in state.BoarPressure)
            {
                // No pressure, no contract. This is the whole point.
                if (boars.Pressure <= 0) continue;
                open.Add(new Contract
                {
                    Id = "cull-" + Slug(boars.Region),
                    Kind = ContractKind.Cull,
                    Subject = boars.Region,
                    Magnitude = boars.Pressure,
                    Pay = p.CullBasePay + boars.Pressure * p.CullPayPerPressure,
                    Taken = state.ContractsTaken.Contains("cull-" + Slug(boars.Region)),
                });
            }

            foreach (var caravan in state.Caravans)
            {
                if (caravan.Status != Caravan.Mustering) continue;
                var id = "escort-" + caravan.Id;
                open.Add(new Contract
                {
                    Id = id,
                    Kind = ContractKind.Escort,
                    Subject = caravan.Destination,
                    Magnitude = caravan.Guards,
                    Pay = p.EscortBasePay + caravan.Guards * p.EscortPayPerGuard,
                    Taken = state.ContractsTaken.Contains(id),
                });
            }

            if (state.HarvestDemand > 0)
            {
                open.Add(new Contract
                {
                    Id = "harvest",
                    Kind = ContractKind.Harvest,
                    Magnitude = state.HarvestDemand,
                    Pay = p.HarvestPay,
                    Taken = state.ContractsTaken.Contains("harvest"),
                });
            }

            foreach (var job in state.SmithingJobs)
            {
                open.Add(new Contract
                {
                    Id = job.Id,
                    Kind = ContractKind.Smithing,
                    Pay = job.Pay,
                    Taken = state.ContractsTaken.Contains(job.Id),
                });
            }

            return open;
        }

        /// <summary>
        /// Take a contract. Binding, so the conversation layer confirms
        /// first — L49: "the panel is the gate, never a receipt for
        /// something already done."
        /// </summary>
        public static bool Take(TownState state, string contractId)
        {
            if (state.ContractsTaken.Contains(contractId)) return false;
            // Refuse anything that is not actually posted. Otherwise a
            // mistyped id, or a model reaching for a contract that was
            // withdrawn, quietly books work nobody is offering.
            if (!Generate(state).Any(c => c.Id == contractId)) return false;
            state.ContractsTaken.Add(contractId);
            return true;
        }

        /// <summary>What the market board shows: only what is actually
        /// warehoused here (economy.md §3).</summary>
        public static List<WarehousedGood> Market(TownState state) =>
            state.Warehoused.Where(g => g.Quantity > 0).ToList();

        private static string Slug(string s) => s.Replace(" ", "-");
    }
}
