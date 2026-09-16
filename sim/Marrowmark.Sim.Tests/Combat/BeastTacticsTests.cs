using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// A boar's fight is a series of passes, not a conversation at a fixed
    /// distance. These tests are about the two properties that make it one:
    /// a charge cannot be steered once it starts, and every spent run buys
    /// the player a window.
    ///
    /// The Hedges shipped with the boar running EnemyTactics — the
    /// swordsman's brain — so it circled at range and threw overhead and
    /// body swings. Nothing below would pass against that.
    /// </summary>
    public class BeastTacticsTests
    {
        private static BeastTactics New(uint seed = 7) =>
            new BeastTactics(BeastTacticsProfile.Boar, seed);

        private static Stamina Bar() => new Stamina(StaminaProfile.Default);

        [Fact]
        public void ClosesWhenTooFarToCharge()
        {
            var d = New().Decide(40f, Bar(), busy: false);
            Assert.Equal(BeastIntent.Stalk, d.Intent);
        }

        [Fact]
        public void ChargesFromChargingRange()
        {
            var d = New().Decide(6f, Bar(), busy: false);
            Assert.Equal(BeastIntent.Charge, d.Intent);
        }

        [Fact]
        public void GoresAtKnifeRangeBecauseAChargeNeedsRoom()
        {
            var d = New().Decide(1.0f, Bar(), busy: false);
            Assert.Equal(BeastIntent.Gore, d.Intent);
        }

        /// <summary>
        /// The whole reason a charge is beatable: once it commits, stepping
        /// out of the way works, because it cannot re-aim at the new
        /// position. If this fails the boar becomes a homing missile and
        /// the dodge stops meaning anything.
        /// </summary>
        [Fact]
        public void AChargeCannotBeSteeredOntoATargetThatMoved()
        {
            var t = New();
            var s = Bar();
            Assert.Equal(BeastIntent.Charge, t.Decide(6f, s, busy: false).Intent);

            // The player side-steps: now they are at knife range, off to
            // one side. A swordsman would gore. A committed boar cannot.
            for (var i = 0; i < 10; i++)
            {
                t.Tick(1f / 30f);
                Assert.Equal(BeastIntent.Charge, t.Decide(1.0f, s, busy: false).Intent);
            }
        }

        [Fact]
        public void TheChargeEventuallyRunsOut()
        {
            var t = New();
            var s = Bar();
            t.Decide(6f, s, busy: false);
            for (var i = 0; i < 120; i++) t.Tick(1f / 30f);
            Assert.False(t.IsCharging);
        }

        /// <summary>A spent run is the punish window — combat.md §6's trade.</summary>
        [Fact]
        public void ASpentChargeLeavesItWheeling()
        {
            var t = New();
            var s = Bar();
            t.Decide(6f, s, busy: false);
            t.Spent();
            Assert.True(t.IsWheeling);
            Assert.Equal(BeastIntent.Wheel, t.Decide(6f, s, busy: false).Intent);
        }

        [Fact]
        public void AndTheWindowCloses()
        {
            var t = New();
            var s = Bar();
            t.Decide(6f, s, busy: false);
            t.Spent();
            for (var i = 0; i < 120; i++) t.Tick(1f / 30f);
            Assert.False(t.IsWheeling);
            Assert.Equal(BeastIntent.Charge, t.Decide(6f, s, busy: false).Intent);
        }

        [Fact]
        public void GoresAreSpacedOut()
        {
            var t = New();
            var s = Bar();
            Assert.Equal(BeastIntent.Gore, t.Decide(1.0f, s, busy: false).Intent);
            t.Gored();
            Assert.Equal(BeastIntent.Wheel, t.Decide(1.0f, s, busy: false).Intent);
        }

        /// <summary>
        /// An exhausted boar stops charging and is reduced to its tusks.
        /// That is a state change a player can SEE — the thing stops
        /// running at them — rather than a number going down, which is
        /// what interface.md §2 wants.
        /// </summary>
        [Fact]
        public void AnExhaustedBoarCannotCharge()
        {
            var t = New();
            var s = Bar();
            s.Spend(s.Current);
            Assert.Equal(BeastIntent.Stalk, t.Decide(6f, s, busy: false).Intent);
        }

        [Fact]
        public void ChargingCostsStamina()
        {
            var t = New();
            var s = Bar();
            var before = s.Current;
            t.Charged(s);
            Assert.True(s.Current < before);
        }

        [Fact]
        public void BusyIsNeverInterrupted()
        {
            var d = New().Decide(1.0f, Bar(), busy: true);
            Assert.Equal(BeastIntent.Busy, d.Intent);
        }

        /// <summary>
        /// Same seed, same inputs, same fight. combat.md §7 makes damage
        /// server-authoritative, so the server has to be able to agree
        /// about what the beast did.
        /// </summary>
        [Fact]
        public void IsDeterministic()
        {
            var a = New(1234);
            var b = New(1234);
            var sa = Bar();
            var sb = Bar();
            for (var i = 0; i < 400; i++)
            {
                a.Tick(1f / 30f);
                b.Tick(1f / 30f);
                var da = a.Decide(5f, sa, busy: false);
                var db = b.Decide(5f, sb, busy: false);
                Assert.Equal(da.Intent, db.Intent);
                if (i % 97 == 0) { a.Spent(); b.Spent(); }
            }
        }

        /// <summary>
        /// The shape of the whole fight, driven the way the game drives
        /// it: a run, a resolution, a wheel, another run. A boar held at
        /// charging range spends its time coming at you and turning
        /// round, and never settles into circling the way a swordsman
        /// does.
        /// </summary>
        [Fact]
        public void ThePatternIsPassesRatherThanCircling()
        {
            var t = New();
            var s = Bar();
            const float step = 1f / 30f;

            var charges = 0;
            var wheels = 0;
            var wasCharging = false;

            for (var i = 0; i < 60 * 30; i++)
            {
                t.Tick(step);
                s.Tick(step);

                var d = t.Decide(5f, s, busy: false);

                if (d.Intent == BeastIntent.Charge)
                {
                    if (!wasCharging)
                    {
                        charges++;
                        t.Charged(s);
                    }
                    wasCharging = true;
                }
                else
                {
                    wasCharging = false;
                }

                if (d.Intent == BeastIntent.Wheel) wheels++;
            }

            Assert.True(charges >= 8,
                $"only {charges} charges in a minute — a boar held at range "
                + "should keep coming");
            Assert.True(wheels > 0,
                "it never turned round, so there is no punish window");
        }
    }
}
