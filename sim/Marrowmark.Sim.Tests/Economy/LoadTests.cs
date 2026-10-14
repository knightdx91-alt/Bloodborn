using Marrowmark.Sim.Combat;
using Marrowmark.Sim.Economy;
using Xunit;

namespace Marrowmark.Sim.Tests.Economy
{
    /// <summary>L57: one encumbrance budget, and armour and cargo compete
    /// for it. You cannot be both the cargo and the muscle.</summary>
    public class LoadTests
    {
        [Fact]
        public void Armour_and_cargo_draw_on_one_budget()
        {
            Assert.Equal(Load.Encumbrance(cargoKg: 30f, armourKg: 0f, capacityKg: 60f),
                         Load.Encumbrance(cargoKg: 0f, armourKg: 30f, capacityKg: 60f), 4);
            Assert.Equal(1f, Load.Encumbrance(30f, 30f, 60f), 4);
        }

        [Fact]
        public void A_fighter_in_plate_hauls_almost_nothing()
        {
            var bare = Load.RoomForCargoKg(armourKg: 0f, capacityKg: 60f);
            var plate = Load.RoomForCargoKg(armourKg: 45f, capacityKg: 60f);
            Assert.True(plate < bare * 0.3f);
        }

        [Fact]
        public void A_loaded_hauler_has_a_smaller_bar_and_dropping_the_load_gives_it_back()
        {
            var stamina = new Stamina(StaminaProfile.Default);
            var full = stamina.EffectiveMax;

            Load.Apply(stamina, cargoKg: 60f, armourKg: 0f, capacityKg: 60f);
            Assert.True(stamina.EffectiveMax < full);

            Load.Apply(stamina, 0f, 0f, 60f);
            Assert.Equal(full, stamina.EffectiveMax, 3);
        }

        [Fact]
        public void Cargo_weighs_what_it_holds()
        {
            var c = new Cargo();
            c.Add("iron", 10, 2.5f);
            c.Add("ale", 4, 1f);
            Assert.Equal(29f, c.WeightKg, 3);
            Assert.True(c.Remove("iron", 4));
            Assert.Equal(15f + 4f, c.WeightKg, 3);
            Assert.False(c.Remove("iron", 100));
        }
    }
}
