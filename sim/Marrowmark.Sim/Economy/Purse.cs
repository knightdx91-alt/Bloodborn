namespace Marrowmark.Sim.Economy
{
    /// <summary>
    /// Coin that belongs to somebody — a buyer, a seller, a shop's till,
    /// a charter's war chest.
    ///
    /// Exists so that a rule can move coin between two parties and refuse
    /// when one cannot pay, instead of returning a number and trusting
    /// the caller to debit someone. "Rules that trust their caller" is
    /// the bug class the town port found three times, and coin is the
    /// place it would cost most.
    /// </summary>
    public sealed class Purse
    {
        public Purse(int coin = 0) { Coin = coin < 0 ? 0 : coin; }

        /// <summary>Copper pennies.</summary>
        public int Coin { get; private set; }

        public bool CanPay(int amount) => amount >= 0 && Coin >= amount;

        /// <summary>Move coin to another purse. All or nothing.</summary>
        public bool TryPay(Purse to, int amount)
        {
            if (!CanPay(amount)) return false;
            Coin -= amount;
            to.Coin += amount;
            return true;
        }

        /// <summary>Coin that leaves the world — a wage to an NPC, rent to
        /// a landlord nobody plays. The sinks economy.md §4 asks for.</summary>
        public bool TrySink(int amount)
        {
            if (!CanPay(amount)) return false;
            Coin -= amount;
            return true;
        }

        /// <summary>Coin arriving from outside the simulation: a bounty, a
        /// contract paid by the town. The faucets.</summary>
        public void Receive(int amount)
        {
            if (amount > 0) Coin += amount;
        }
    }
}
