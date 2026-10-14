using System;
using System.Collections.Generic;
using System.Linq;
using Marrowmark.Sim.Combat;

namespace Marrowmark.Sim.Economy
{
    /// <summary>Goods on a back, a cart or a shelf. Physical, so they
    /// weigh something.</summary>
    public sealed class CargoLine
    {
        public string Good = "";
        public int Quantity;
        public float KgPerUnit;
        public float WeightKg => Quantity * KgPerUnit;
    }

    /// <summary>
    /// Goods being carried. economy.md §3: items are physical — no mail,
    /// no teleporting goods — so everything in here is somewhere, weighs
    /// something, and can be lost.
    /// </summary>
    public sealed class Cargo
    {
        private readonly List<CargoLine> _lines = new List<CargoLine>();

        public IReadOnlyList<CargoLine> Lines => _lines;
        public float WeightKg => _lines.Sum(l => l.WeightKg);
        public bool IsEmpty => _lines.Count == 0;

        public int QuantityOf(string good) => _lines.Where(l => l.Good == good).Sum(l => l.Quantity);

        public void Add(string good, int quantity, float kgPerUnit)
        {
            if (quantity <= 0) return;
            var line = _lines.FirstOrDefault(l => l.Good == good && Math.Abs(l.KgPerUnit - kgPerUnit) < 0.0001f);
            if (line == null) _lines.Add(new CargoLine { Good = good, Quantity = quantity, KgPerUnit = kgPerUnit });
            else line.Quantity += quantity;
        }

        public bool Remove(string good, int quantity)
        {
            if (quantity <= 0 || QuantityOf(good) < quantity) return false;
            foreach (var line in _lines.Where(l => l.Good == good).ToList())
            {
                var take = Math.Min(line.Quantity, quantity);
                line.Quantity -= take;
                quantity -= take;
                if (line.Quantity == 0) _lines.Remove(line);
                if (quantity == 0) break;
            }
            return true;
        }

        /// <summary>Everything, moved out of this cargo into another.</summary>
        public void TransferAll(Cargo to)
        {
            foreach (var l in _lines) to.Add(l.Good, l.Quantity, l.KgPerUnit);
            _lines.Clear();
        }
    }

    /// <summary>
    /// L57: one encumbrance budget, and armour and cargo compete for it.
    /// You cannot be both the cargo and the muscle.
    /// </summary>
    public static class Load
    {
        /// <summary>0 unburdened, 1 at capacity. Armour counts the same as
        /// a sack of ore, which is the whole rule.</summary>
        public static float Encumbrance(float cargoKg, float armourKg, float capacityKg)
        {
            if (capacityKg <= 0f) throw new ArgumentOutOfRangeException(nameof(capacityKg));
            var e = (Math.Max(0f, cargoKg) + Math.Max(0f, armourKg)) / capacityKg;
            return e > 1f ? 1f : e;
        }

        /// <summary>How much cargo is left to carry once the armour is on.</summary>
        public static float RoomForCargoKg(float armourKg, float capacityKg) =>
            Math.Max(0f, capacityKg - Math.Max(0f, armourKg));

        /// <summary>Put the load on the bar (L55: encumbrance shrinks it).</summary>
        public static void Apply(Stamina stamina, float cargoKg, float armourKg, float capacityKg) =>
            stamina.Encumbrance = Encumbrance(cargoKg, armourKg, capacityKg);
    }
}
