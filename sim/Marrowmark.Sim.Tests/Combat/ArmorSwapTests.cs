using System;
using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// L58: armour can be changed on the road, and the armour decides how
    /// long you are helpless doing it. These assert the relationships that
    /// make that a real decision, not the durations.
    /// </summary>
    public class ArmorSwapTests
    {
        private static ArmorSwap Wearing(ArmorClass a) => new ArmorSwap(a);

        [Fact]
        public void Starts_wearing_what_it_was_given_and_idle()
        {
            var s = Wearing(ArmorClass.Mail);
            Assert.Equal(ArmorClass.Mail, s.Current);
            Assert.False(s.IsSwapping);
        }

        [Fact]
        public void Heavier_armour_takes_longer_to_put_on()
        {
            var bare = Wearing(ArmorClass.None);

            var light = bare.SecondsToChangeTo(ArmorClass.Light);
            var mail = bare.SecondsToChangeTo(ArmorClass.Mail);
            var plate = bare.SecondsToChangeTo(ArmorClass.Plate);

            Assert.True(light < mail, "mail should take longer than light");
            Assert.True(mail < plate, "plate should take longer than mail");
        }

        [Fact]
        public void Stripping_down_is_faster_than_armouring_up()
        {
            // A hauler who needs to shed weight in a hurry should be able to.
            var plated = Wearing(ArmorClass.Plate);
            var bare = Wearing(ArmorClass.None);

            Assert.True(
                plated.SecondsToChangeTo(ArmorClass.None) <
                bare.SecondsToChangeTo(ArmorClass.Plate),
                "taking plate off should be faster than putting it on");
        }

        [Fact]
        public void Help_makes_it_faster()
        {
            var bare = Wearing(ArmorClass.None);

            Assert.True(
                bare.SecondsToChangeTo(ArmorClass.Plate, assisted: true) <
                bare.SecondsToChangeTo(ArmorClass.Plate, assisted: false),
                "a second pair of hands should speed up armouring");
        }

        [Fact]
        public void Swapping_completes_after_the_full_duration()
        {
            var s = Wearing(ArmorClass.None);
            var needed = s.SecondsToChangeTo(ArmorClass.Mail);

            s.Begin(ArmorClass.Mail);
            Assert.True(s.IsSwapping);
            Assert.Equal(ArmorClass.None, s.Current);

            Assert.False(s.Tick(needed / 2f));
            Assert.Equal(ArmorClass.None, s.Current);

            Assert.True(s.Tick(needed / 2f + 0.01f));
            Assert.Equal(ArmorClass.Mail, s.Current);
            Assert.False(s.IsSwapping);
        }

        [Fact]
        public void You_are_still_wearing_the_old_armour_until_it_completes()
        {
            // The vulnerability window is the whole point: mid-swap you have
            // the protection you started with, not the one you are reaching
            // for.
            var s = Wearing(ArmorClass.None);
            s.Begin(ArmorClass.Plate);
            s.Tick(s.SecondsToChangeTo(ArmorClass.Plate) * 0.95f);

            Assert.Equal(ArmorClass.None, s.Current);
            Assert.True(s.IsSwapping);
        }

        [Fact]
        public void Interruption_loses_all_progress()
        {
            var s = Wearing(ArmorClass.None);
            var needed = s.SecondsToChangeTo(ArmorClass.Plate);

            s.Begin(ArmorClass.Plate);
            s.Tick(needed * 0.9f);
            s.Interrupt();

            Assert.False(s.IsSwapping);
            Assert.Equal(ArmorClass.None, s.Current);

            // Starting again starts from the beginning — that is what makes
            // armouring up a gamble rather than a free action.
            s.Begin(ArmorClass.Plate);
            Assert.False(s.Tick(needed * 0.9f));
            Assert.Equal(ArmorClass.None, s.Current);
        }

        [Fact]
        public void Progress_reports_sensibly_for_onlookers()
        {
            var s = Wearing(ArmorClass.None);
            Assert.Equal(0f, s.Progress, 3);

            var needed = s.SecondsToChangeTo(ArmorClass.Mail);
            s.Begin(ArmorClass.Mail);
            s.Tick(needed / 2f);

            Assert.InRange(s.Progress, 0.4f, 0.6f);
        }

        [Fact]
        public void Changing_to_what_is_already_worn_does_nothing()
        {
            var s = Wearing(ArmorClass.Mail);
            Assert.False(s.Begin(ArmorClass.Mail));
            Assert.False(s.IsSwapping);
        }

        [Fact]
        public void A_new_swap_abandons_the_one_in_progress()
        {
            var s = Wearing(ArmorClass.None);
            s.Begin(ArmorClass.Plate);
            s.Tick(10f);

            s.Begin(ArmorClass.Light);
            Assert.Equal(ArmorClass.Light, s.Target);

            s.Tick(s.SecondsToChangeTo(ArmorClass.Light) + 0.01f);
            Assert.Equal(ArmorClass.Light, s.Current);
        }

        [Fact]
        public void Being_caught_unarmoured_is_a_meaningful_gap()
        {
            // The L57/L58 scenario in one assertion: a hauler travelling
            // unarmoured cannot simply become a knight when trouble
            // appears. If this ever drops to a couple of seconds, the whole
            // armour-versus-cargo tradeoff stops mattering.
            var hauler = Wearing(ArmorClass.None);

            Assert.True(hauler.SecondsToChangeTo(ArmorClass.Plate) > 30f,
                "armouring into plate from nothing must be slow enough that " +
                "an ambush catches you in what you are wearing");
        }

        [Fact]
        public void Negative_doff_fraction_is_rejected()
        {
            var bad = ArmorTimes.Default;
            bad.DoffFraction = -1f;
            Assert.Throws<ArgumentOutOfRangeException>(() => new ArmorSwap(ArmorClass.None, bad));
        }
    }
}
