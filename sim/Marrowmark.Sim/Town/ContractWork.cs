using System.Collections.Generic;
using System.Linq;

namespace Marrowmark.Sim.Town
{
    public enum HandInResult
    {
        Paid,
        /// <summary>You never took this one.</summary>
        NotTaken,
        /// <summary>Taken, but the work is not done.</summary>
        NotFinished,
        /// <summary>No such posting — withdrawn, or never existed.</summary>
        NoSuchContract,
        /// <summary>Taken and finishable in principle, but this KIND of
        /// work has no way to record progress yet. Honest refusal beats a
        /// contract that pays for nothing.</summary>
        NotYetPossible,
    }

    public sealed class HandIn
    {
        public HandInResult Result;
        public int Paid;

        /// <summary>The region's pressure after the cull, or -1 where the
        /// contract had no such consequence.</summary>
        public int PressureAfter = -1;
    }

    /// <summary>
    /// Doing the work, and being paid for it.
    ///
    /// The half of the board that did not exist: contracts could be taken
    /// and never discharged, so ContractsTaken only ever grew and the
    /// town's work economy was a one-way door.
    ///
    /// **Finishing a cull changes the world, and the world is what the
    /// board is generated from.** Thin the boars and the region's pressure
    /// drops; the next posting for that wood is smaller and pays less, and
    /// at zero it is not posted at all. Nothing announces this. The board
    /// simply says something different because something different is
    /// true — which is content.md §3's "the board never lies" doing real
    /// work rather than being a slogan.
    /// </summary>
    public static class ContractWork
    {
        /// <summary>How much work a contract wants before it can be handed
        /// in. Zero means this kind cannot yet be progressed at all.</summary>
        public static int Required(Contract c, TownProfile p)
        {
            switch (c.Kind)
            {
                case ContractKind.Cull:
                    // Scales with the problem, exactly as the pay does.
                    return System.Math.Max(1, c.Magnitude * p.CullKillsPerPressure);
                default:
                    // Escort, harvest and smithing are honest gaps: there
                    // is nowhere to walk a wagon to or a forge to stand
                    // at. They refuse rather than pay for nothing.
                    return 0;
            }
        }

        public static int Required(TownState state, string contractId, TownProfile p)
        {
            var c = ContractBoard.Generate(state, p).FirstOrDefault(x => x.Id == contractId);
            return c == null ? 0 : Required(c, p);
        }

        public static int Done(TownState state, string contractId)
        {
            var row = state.ContractProgress.FirstOrDefault(r => r.ContractId == contractId);
            return row == null ? 0 : row.Done;
        }

        /// <summary>
        /// Record boars killed in a named region, against whichever cull
        /// contract the player is actually carrying for it.
        ///
        /// Keyed on the region rather than on a contract id because that
        /// is what the world can actually report: something died in a
        /// place. The town works out whether that was work.
        /// </summary>
        public static int RecordCull(TownState state, string region, int killed)
            => RecordCull(state, region, killed, TownProfile.Default);

        public static int RecordCull(TownState state, string region, int killed, TownProfile p)
        {
            if (killed <= 0) return 0;
            var contract = ContractBoard.Generate(state, p).FirstOrDefault(
                c => c.Kind == ContractKind.Cull && c.Subject == region && c.Taken);
            // Killing boars you were not paid to kill is allowed; it is
            // simply not progress. The town does not owe you for it.
            if (contract == null) return 0;

            var row = state.ContractProgress.FirstOrDefault(r => r.ContractId == contract.Id);
            if (row == null)
            {
                row = new ContractProgress { ContractId = contract.Id };
                state.ContractProgress.Add(row);
            }
            // Capped at what was asked for, so a long hunt does not bank
            // credit against the NEXT contract for the same wood.
            var want = Required(contract, p);
            row.Done = System.Math.Min(want, row.Done + killed);
            return row.Done;
        }

        public static bool CanHandIn(TownState state, string contractId)
            => CanHandIn(state, contractId, TownProfile.Default);

        public static bool CanHandIn(TownState state, string contractId, TownProfile p)
        {
            if (!state.ContractsTaken.Contains(contractId)) return false;
            var want = Required(state, contractId, p);
            return want > 0 && Done(state, contractId) >= want;
        }

        public static HandIn Hand(TownState state, string contractId)
            => Hand(state, contractId, TownProfile.Default);

        public static HandIn Hand(TownState state, string contractId, TownProfile p)
        {
            if (!state.ContractsTaken.Contains(contractId))
                return new HandIn { Result = HandInResult.NotTaken };

            var contract = ContractBoard.Generate(state, p).FirstOrDefault(c => c.Id == contractId);
            if (contract == null)
                return new HandIn { Result = HandInResult.NoSuchContract };

            var want = Required(contract, p);
            if (want <= 0)
                return new HandIn { Result = HandInResult.NotYetPossible };
            if (Done(state, contractId) < want)
                return new HandIn { Result = HandInResult.NotFinished };

            state.Coin += contract.Pay;
            // The paper goes back. Not "taken" any more — and because the
            // board is generated from the world rather than from a list,
            // whether it is posted again is decided by the consequence
            // below, not by this line.
            state.ContractsTaken.Remove(contractId);
            state.ContractProgress.RemoveAll(r => r.ContractId == contractId);

            var after = -1;
            if (contract.Kind == ContractKind.Cull)
            {
                state.CullsCompleted++;
                var region = state.BoarPressure.FirstOrDefault(b => b.Region == contract.Subject);
                if (region != null)
                {
                    region.Pressure = System.Math.Max(0, region.Pressure - p.CullPressureRelief);
                    after = region.Pressure;
                }
            }

            return new HandIn
            {
                Result = HandInResult.Paid,
                Paid = contract.Pay,
                PressureAfter = after,
            };
        }
    }
}
