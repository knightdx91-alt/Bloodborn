using Marrowmark.Sim.Combat;
using Xunit;

namespace Marrowmark.Sim.Tests.Combat
{
    /// <summary>
    /// Exhaustion on the swing itself, not only on its recovery.
    ///
    /// §2 says "at zero stamina you are not stunned — you are slow", and
    /// then spends that idea entirely on recovery frames. Recovery-only
    /// exhaustion is invisible: the swing looks identical, and the first
    /// time you learn you are tired is when you are punished for it. A
    /// windup that visibly labours is the thing §2 actually asks for —
    /// "a fighter running out of breath, not a status effect with an
    /// icon."
    ///
    /// Reported from play rather than derived: "when your stamina is
    /// depleted you should slow to a walk, and your swings should get
    /// slower."
    /// </summary>
    public class LabouredSwingTests
    {
        private static Attack New() => new Attack(AttackProfile.Default);
        private static Stamina Bar() => new Stamina(StaminaProfile.Default);

        private static Stamina EmptyBar()
        {
            var s = Bar();
            s.Spend(s.Max);
            return s;
        }

        [Fact]
        public void A_rested_swing_is_not_slowed()
        {
            var a = New();
            a.TryStart(Bar());

            Assert.False(a.IsLabouring);
            Assert.Equal(AttackProfile.Default.WindupSeconds, a.WindupSeconds, 4);
        }

        [Fact]
        public void An_exhausted_swing_winds_up_slower()
        {
            var rested = New();
            rested.TryStart(Bar());

            var tired = New();
            tired.TryStart(EmptyBar());

            Assert.True(tired.IsLabouring);
            Assert.True(tired.WindupSeconds > rested.WindupSeconds);
        }

        [Fact]
        public void The_whole_swing_lengthens_not_only_the_recovery()
        {
            var rested = New();
            rested.TryStart(Bar());
            var restedWindup = rested.WindupSeconds;
            var restedTotal = rested.TotalSeconds;

            var tired = New();
            tired.TryStart(EmptyBar());

            // Both ends move. If only the total grew, the tell would still
            // look identical and the opponent would read a rested fighter.
            Assert.True(tired.WindupSeconds > restedWindup);
            Assert.True(tired.TotalSeconds > restedTotal);
        }

        [Fact]
        public void The_blade_goes_live_later_when_you_are_tired()
        {
            var p = AttackProfile.Default;
            var a = New();
            a.TryStart(EmptyBar());

            // At the moment a rested swing would be live, this one is not.
            for (var t = 0f; t < p.WindupSeconds + 0.001f; t += 1f / 240f)
                a.Tick(1f / 240f);

            Assert.Equal(AttackPhase.Windup, a.Phase);
        }

        [Fact]
        public void The_swing_that_empties_you_is_itself_slow()
        {
            // Not the swing after. Attacks cost on startup (§2), so the
            // blow that overspends is the one that should labour — paying
            // for it next time would let a player spend their last
            // stamina at full speed for free.
            var s = Bar();
            s.Spend(s.Max - AttackProfile.Default.StaminaCost * 0.5f);

            var a = New();
            a.TryStart(s);

            Assert.True(s.IsExhausted);
            Assert.True(a.IsLabouring);
        }

        [Fact]
        public void A_tired_swing_still_finishes()
        {
            // Slow is not stuck. §2 is explicit that exhaustion is not a
            // stun, so the swing must still return to Ready on its own.
            var a = New();
            a.TryStart(EmptyBar());

            for (var t = 0f; t < a.TotalSeconds + 0.1f; t += 1f / 120f)
                a.Tick(1f / 120f);

            Assert.Equal(AttackPhase.Ready, a.Phase);
        }

        [Fact]
        public void The_unaffordable_penalty_stacks_on_top_of_being_tired()
        {
            // Two different punishments: being out of breath slows the
            // whole swing, and swinging with nothing left adds §2's
            // recovery penalty on top of that.
            var p = AttackProfile.Default;
            var a = New();
            a.TryStart(EmptyBar());

            var slowed = (p.WindupSeconds + p.ActiveSeconds) * p.ExhaustedSwingMultiplier;
            var recovery = p.RecoverySeconds
                * p.ExhaustedRecoveryMultiplier
                * p.ExhaustedSwingMultiplier;

            Assert.Equal(slowed + recovery, a.TotalSeconds, 3);
        }

        [Fact]
        public void Recovering_mid_swing_does_not_speed_the_blow_back_up()
        {
            // The opponent is reading a commitment (§1). A blow that sped
            // up halfway because the bar ticked over a threshold would be
            // unanswerable, so the scale is fixed when the swing starts.
            var s = EmptyBar();
            var a = New();
            a.TryStart(s);
            var length = a.TotalSeconds;

            for (var t = 0f; t < 0.05f; t += 1f / 120f)
            {
                a.Tick(1f / 120f);
                s.Tick(1f / 120f);
            }

            Assert.Equal(length, a.TotalSeconds, 4);
        }

        [Fact]
        public void Sprinting_the_bar_flat_exhausts_you()
        {
            // The bug behind "when your stamina is depleted you should slow
            // to a walk": only an unaffordable Spend used to set the flag,
            // so a player who ran themselves empty kept full speed and a
            // full-speed swing until they next tried to pay for something.
            var s = Bar();
            for (var t = 0f; t < 30f; t += 1f / 60f)
                s.Sprint(1f / 60f);

            Assert.Equal(0f, s.Current);
            Assert.True(s.IsExhausted);
        }

        [Fact]
        public void A_swing_after_sprinting_yourself_out_labours()
        {
            var s = Bar();
            for (var t = 0f; t < 30f; t += 1f / 60f)
                s.Sprint(1f / 60f);

            var a = New();
            a.TryStart(s);

            Assert.True(a.IsLabouring);
        }

        [Fact]
        public void Sprinting_without_emptying_the_bar_does_not_exhaust_you()
        {
            // The flag must mean "spent", not "spent anything".
            var s = Bar();
            s.Sprint(0.5f);

            Assert.True(s.Current > 0f);
            Assert.False(s.IsExhausted);
        }

        [Fact]
        public void Every_shape_labours_including_the_enemy_ones()
        {
            foreach (var p in new[]
            {
                AttackProfile.Default, AttackProfile.Quick,
                AttackProfile.Heavy, AttackProfile.Committed,
            })
            {
                Assert.True(p.ExhaustedSwingMultiplier > 1f);
            }
        }
    }
}
