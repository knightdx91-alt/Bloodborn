using System;
using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    public class HealthTests
    {
        [Fact]
        public void Starts_full_and_alive()
        {
            var h = new Health(200f);
            Assert.Equal(200f, h.Current, 3);
            Assert.True(h.IsAlive);
            Assert.Equal(1f, h.Fraction, 3);
        }

        [Fact]
        public void Taking_damage_reduces_health()
        {
            var h = new Health(100f);
            Assert.Equal(30f, h.Take(30f), 3);
            Assert.Equal(70f, h.Current, 3);
        }

        [Fact]
        public void Damage_is_capped_at_what_is_left()
        {
            var h = new Health(100f);
            Assert.Equal(100f, h.Take(500f), 3);
            Assert.Equal(0f, h.Current, 3);
            Assert.True(h.IsDead);
        }

        [Fact]
        public void Healing_cannot_exceed_max()
        {
            var h = new Health(100f);
            h.Take(20f);
            Assert.Equal(20f, h.Heal(50f), 3);
            Assert.Equal(100f, h.Current, 3);
        }

        [Fact]
        public void Healing_cannot_raise_the_dead()
        {
            // Shrines do that (L32), and they are a different system.
            var h = new Health(100f);
            h.Take(100f);
            Assert.Equal(0f, h.Heal(50f), 3);
            Assert.True(h.IsDead);
        }

        [Fact]
        public void Negative_values_are_rejected()
        {
            var h = new Health(100f);
            Assert.Throws<ArgumentOutOfRangeException>(() => h.Take(-1f));
            Assert.Throws<ArgumentOutOfRangeException>(() => h.Heal(-1f));
            Assert.Throws<ArgumentOutOfRangeException>(() => new Health(0f));
        }
    }
}
