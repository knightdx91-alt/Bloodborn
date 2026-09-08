using System;
using System.Collections.Generic;
using Marrowmark.Sim.Items;

namespace Marrowmark.Sim.Crafting
{
    /// <summary>
    /// A finished piece and the name it carries (L4, L68).
    ///
    /// **Every item is signed, good or bad.** Reputation is therefore
    /// earned and losable: flooding a market board with rubbish costs a
    /// smith their name, and a buyer reading a mark on second-hand gear
    /// knows exactly what they are getting. There is no anonymous work in
    /// Marrowmark.
    /// </summary>
    public sealed class CraftedItem
    {
        public CraftedItem(
            string makersMark,
            MaterialProperties properties,
            IReadOnlyList<string> pipeline,
            DurabilityProfile baseProfile)
        {
            if (string.IsNullOrWhiteSpace(makersMark))
                throw new ArgumentException(
                    "Every finished item carries its maker's name (L68).", nameof(makersMark));

            MakersMark = makersMark;
            Properties = properties;
            Pipeline = pipeline ?? new List<string>();

            var profile = baseProfile;
            profile.MaxCondition = baseProfile.MaxCondition * properties.DurabilityFactor;
            Durability = new Durability(profile);
        }

        /// <summary>Who made this. Permanent, and outlives them (`tech.md` §4).</summary>
        public string MakersMark { get; }

        /// <summary>The material as it ended up after every stage.</summary>
        public MaterialProperties Properties { get; }

        /// <summary>The stages it went through, in order. The item's history.</summary>
        public IReadOnlyList<string> Pipeline { get; }

        /// <summary>Condition, wear and eventual death (L59–L62).</summary>
        public Durability Durability { get; }

        /// <summary>
        /// Damage this piece deals of a given type, before the armour
        /// triangle and before wear. Which property carries the weapon is
        /// how material choice reaches combat.
        /// </summary>
        public float PowerFor(Combat.DamageType type)
        {
            switch (type)
            {
                case Combat.DamageType.Cut: return Properties.CutPower;
                case Combat.DamageType.Pierce: return Properties.PiercePower;
                case Combat.DamageType.Blunt: return Properties.BluntPower;
                default: throw new ArgumentOutOfRangeException(nameof(type));
            }
        }

        /// <summary>Effective power right now, after wear (L60).</summary>
        public float EffectivePowerFor(Combat.DamageType type) =>
            PowerFor(type) * Durability.Performance;
    }
}
