namespace Marrowmark.Sim.Magic
{
    /// <summary>L23's Revelation Arc. Epochs are cheap to represent and
    /// expensive to reach; the rules here only ask which one it is.</summary>
    public enum Epoch { Myth, Whispers, Unveiling, Scouring, Wonder }

    /// <summary>L8's ladder, per spell.</summary>
    public enum SpellRank { Novice, Adept, Expert, Master, Grandmaster, Incarnate }

    /// <summary>
    /// The numbers behind the hidden system. L9, L10, L33, L35, L36. Every
    /// one of these is a working value; the structure around them is the
    /// lock.
    /// </summary>
    public struct MagicProfile
    {
        /// <summary>Spell XP at which each rank is reached. Grandmaster
        /// also wants graduates (below). Incarnate is never XP (L33).</summary>
        public float AdeptAt;
        public float ExpertAt;
        public float MasterAt;
        public float GrandmasterAt;

        /// <summary>Disciples who reached Master under you, required for
        /// Grandmaster — "proven both power and lineage".</summary>
        public int GraduatesForGrandmaster;

        /// <summary>L33: disciple slots per spell at Master.</summary>
        public int SlotsAtMaster;

        /// <summary>L33: one more at Grandmaster.</summary>
        public int ExtraSlotAtGrandmaster;

        /// <summary>L10: one more, permanently, for declining the seat.</summary>
        public int ExtraSlotForDeclining;

        /// <summary>L33: a dismissed disciple's slot stays locked this long.
        /// Graduation frees a slot at once.</summary>
        public float DismissalCooldownHours;

        /// <summary>L33: the windfall a master gets when a disciple ranks
        /// the taught spell up. Finite per disciple, so unfarmable.</summary>
        public float LineageRankUpXp;

        /// <summary>L33: per meaningful cast by a disciple.</summary>
        public float LineageTrickleXp;

        /// <summary>L33: a full roster's trickle per day is about an hour
        /// of the master's own practice. The cap, in XP.</summary>
        public float LineageTrickleDailyCap;

        /// <summary>L10: a seat lapses after this long without the holder
        /// being seen. 30 real days.</summary>
        public float SeatLapseHours;

        /// <summary>L10: a declared absence holds the seat this long. 60
        /// days, once per holder.</summary>
        public float RegencyHours;

        /// <summary>L35: from the seat opening to the Trial. 3 real days.</summary>
        public float TrialLeadHours;

        /// <summary>L36's valve, as a dial (L79): seeded awakenings allowed
        /// per server per day, by epoch. Loosening as the Arc advances.</summary>
        public int AwakeningsPerDayMyth;
        public int AwakeningsPerDayWhispers;
        public int AwakeningsPerDayUnveiling;
        public int AwakeningsPerDayScouring;
        public int AwakeningsPerDayWonder;

        /// <summary>A spell with fewer living masters than this is one the
        /// server can lose.</summary>
        public int ExtinctionBelowMasters;

        public float HoursPerDay;

        public static MagicProfile Default => new MagicProfile
        {
            AdeptAt = 100f,
            ExpertAt = 300f,
            MasterAt = 700f,
            GrandmasterAt = 1500f,
            GraduatesForGrandmaster = 2,
            SlotsAtMaster = 3,
            ExtraSlotAtGrandmaster = 1,
            ExtraSlotForDeclining = 1,
            DismissalCooldownHours = 168f,
            LineageRankUpXp = 60f,
            LineageTrickleXp = 1f,
            LineageTrickleDailyCap = 20f,
            SeatLapseHours = 720f,
            RegencyHours = 1440f,
            TrialLeadHours = 72f,
            AwakeningsPerDayMyth = 1,
            AwakeningsPerDayWhispers = 3,
            AwakeningsPerDayUnveiling = 10,
            AwakeningsPerDayScouring = 20,
            AwakeningsPerDayWonder = 50,
            ExtinctionBelowMasters = 2,
            HoursPerDay = 24f,
        };

        public int AwakeningsPerDay(Epoch e)
        {
            switch (e)
            {
                case Epoch.Myth: return AwakeningsPerDayMyth;
                case Epoch.Whispers: return AwakeningsPerDayWhispers;
                case Epoch.Unveiling: return AwakeningsPerDayUnveiling;
                case Epoch.Scouring: return AwakeningsPerDayScouring;
                default: return AwakeningsPerDayWonder;
            }
        }
    }
}
