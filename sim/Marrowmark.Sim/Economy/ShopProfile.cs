namespace Marrowmark.Sim.Economy
{
    /// <summary>
    /// The numbers behind a shop: what it costs to keep one open.
    ///
    /// economy.md §4 lists NPC staff wages and property rent among the
    /// coin sinks that are "non-negotiable for a player economy", and a
    /// sink is only a sink if it is charged whether or not the owner is
    /// looking. These are placeholders in copper pennies, on the same
    /// scale as town.json (a drink is 2, a cull pays 4 plus pressure).
    /// </summary>
    public struct ShopProfile
    {
        /// <summary>Game hours in a day. Wages and rent fall due on the
        /// day, not continuously, so a shopkeeper can plan around it.</summary>
        public float HoursPerDay;

        /// <summary>What an NPC shopkeeper costs per day. They sell while
        /// the owner is away (economy.md §2), and they are paid from the
        /// till whether or not anything sold.</summary>
        public int StaffWagePerDay;

        /// <summary>Rent on the building (L5). Charged daily; unpaid rent
        /// goes into arrears rather than closing the shop, because what
        /// an unpaid landlord does about it is property's business, not
        /// retail's.</summary>
        public int RentPerDay;

        /// <summary>Days of unpaid wages staff will tolerate before they
        /// walk. Two: one missed day is a bad week, two is a shop nobody
        /// is minding.</summary>
        public int StaffQuitAfterUnpaidDays;

        public static ShopProfile Default => new ShopProfile
        {
            HoursPerDay = 24f,
            StaffWagePerDay = 6,
            RentPerDay = 4,
            StaffQuitAfterUnpaidDays = 2,
        };
    }
}
