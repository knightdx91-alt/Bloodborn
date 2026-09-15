using Marrowmark.Sim.Net;
using Xunit;

namespace Marrowmark.Sim.Tests.Net
{
    /// <summary>
    /// L39 / combat.md §7, asserted rather than assumed.
    ///
    /// §7 is the contract the whole project turns on, and until now it
    /// was a paragraph. These are the four promises it makes, each as a
    /// test that fails if the promise is broken:
    ///
    ///   1. A defender never dies to a hit they clearly avoided on their
    ///      own screen.
    ///   2. The envelope is clamped, so latency is never an advantage.
    ///   3. Attackers get no client authority at all.
    ///   4. No rollback of death, ever.
    ///
    /// What these do NOT prove is feel — whether 100ms is
    /// *indistinguishable* from 0 needs two machines and a person, and
    /// combat.md §9 says so. This is the half that can be settled
    /// without one.
    /// </summary>
    public class LatencyContractTests
    {
        private static LatencyProfile P => LatencyProfile.Default;

        // ── 1. Favour the defender ────────────────────────────────────

        [Fact]
        public void A_parry_that_landed_on_your_screen_lands_on_the_server()
        {
            // The gate from §9: "does a parry land right at 100ms".
            // The client parries; the blow reaches the server 100ms later.
            var oneWay = 0.100f;
            var server = new CombatServer(P);
            server.Add("defender", oneWay);

            for (var i = 0; i < 30; i++) server.Tick();
            var parriedAt = server.Now - oneWay;

            var r = server.Resolve("defender", 40f, new DefensiveClaim
            {
                PlayerId = "defender", Kind = Defence.Parry, ClientTime = parriedAt,
            });

            Assert.Equal(ClaimVerdict.Honoured, r.Verdict);
            Assert.True(r.Defended);
            Assert.Equal(0f, r.DamageDealt);
            Assert.False(server.IsDead("defender"));
        }

        [Theory]
        [InlineData(0f)]
        [InlineData(0.050f)]
        [InlineData(0.100f)]
        [InlineData(0.150f)]
        public void The_defender_wins_at_every_latency_inside_the_clamp(float oneWay)
        {
            // The property that matters: the SAME play succeeds whatever
            // the connection, up to the clamp. If this ever fails for one
            // value, high-latency players are playing a different game.
            var server = new CombatServer(P);
            server.Add("defender", oneWay);
            for (var i = 0; i < 30; i++) server.Tick();

            var r = server.Resolve("defender", 40f, new DefensiveClaim
            {
                ClientTime = server.Now - oneWay, Kind = Defence.Parry,
            });

            Assert.True(r.Defended);
        }

        [Fact]
        public void A_claim_dated_before_the_envelope_is_refused()
        {
            var server = new CombatServer(P);
            server.Add("defender", 0.100f);
            for (var i = 0; i < 60; i++) server.Tick();

            var tooLate = server.Now - ToleranceEnvelope.Width(0.100f, P) - 0.05f;
            var r = server.Resolve("defender", 40f,
                new DefensiveClaim { ClientTime = tooLate, Kind = Defence.Parry });

            Assert.Equal(ClaimVerdict.TooOld, r.Verdict);
            Assert.False(r.Defended);
            Assert.Equal(40f, r.DamageDealt);
        }

        [Fact]
        public void A_claim_from_the_future_is_refused()
        {
            // Closes pre-declaration: a client cannot bank a parry for a
            // blow it has not seen yet.
            var server = new CombatServer(P);
            server.Add("defender", 0.100f);
            for (var i = 0; i < 30; i++) server.Tick();

            var r = server.Resolve("defender", 40f, new DefensiveClaim
            {
                ClientTime = server.Now + 0.5f, Kind = Defence.Parry,
            });

            Assert.Equal(ClaimVerdict.FromTheFuture, r.Verdict);
            Assert.False(r.Defended);
        }

        // ── 2. The clamp ──────────────────────────────────────────────

        [Fact]
        public void The_envelope_stops_widening_at_the_clamp()
        {
            // §7: "beyond the clamp the envelope stops widening, so a
            // player on a 400ms connection gets a fair-feeling game
            // against monsters and a disadvantaged one in PvP."
            var fair = ToleranceEnvelope.Width(0.100f, P);
            var awful = ToleranceEnvelope.Width(0.400f, P);

            Assert.Equal(P.MaxEnvelopeSeconds, awful);
            Assert.True(awful >= fair);
        }

        [Fact]
        public void Latency_is_never_an_advantage()
        {
            // The exploit this closes: if the envelope grew without
            // limit, adding latency would buy a wider window to parry in,
            // and lagging on purpose would be correct play.
            var honest = ToleranceEnvelope.Width(0.050f, P);
            var laggy = ToleranceEnvelope.Width(5.000f, P);

            Assert.True(laggy - honest < P.MaxEnvelopeSeconds);
            Assert.Equal(P.MaxEnvelopeSeconds, laggy);
        }

        [Fact]
        public void Past_the_clamp_a_claim_that_would_fit_a_wider_envelope_fails()
        {
            var server = new CombatServer(P);
            server.Add("laggy", 0.400f);
            for (var i = 0; i < 60; i++) server.Tick();

            // Dated exactly one one-way trip back — honest, on a 400ms
            // link, and still outside the clamp. That is the disadvantage
            // §7 knowingly accepts.
            var r = server.Resolve("laggy", 40f, new DefensiveClaim
            {
                ClientTime = server.Now - 0.400f, Kind = Defence.Parry,
            });

            Assert.Equal(ClaimVerdict.TooOld, r.Verdict);
        }

        // ── 3. Attackers get nothing ──────────────────────────────────

        [Fact]
        public void A_client_cannot_claim_a_hit()
        {
            // Asserted structurally: there is no way to express it. §7's
            // asymmetry is the security argument, so the absence of an
            // offensive claim type is the thing to protect.
            var fields = typeof(DefensiveClaim).GetFields();
            foreach (var f in fields)
            {
                Assert.DoesNotContain("Damage", f.Name);
                Assert.DoesNotContain("Hit", f.Name);
                Assert.DoesNotContain("Kill", f.Name);
                Assert.DoesNotContain("Target", f.Name);
            }
        }

        [Fact]
        public void Damage_is_the_servers_alone()
        {
            var server = new CombatServer(P);
            server.Add("victim", 0.100f);
            for (var i = 0; i < 30; i++) server.Tick();

            server.Resolve("victim", 30f, null);

            Assert.Equal(70f, server.HealthOf("victim").Current);
        }

        // ── 4. No rollback of death ───────────────────────────────────

        [Fact]
        public void A_player_who_has_died_stays_dead()
        {
            // §7: "a player who has seen themselves die stays dead.
            // Reconciliation happens before the death resolves, never
            // after."
            var server = new CombatServer(P);
            server.Add("doomed", 0.100f);
            for (var i = 0; i < 30; i++) server.Tick();

            var killing = server.Resolve("doomed", 200f, null);
            Assert.True(killing.Killed);
            Assert.True(server.IsDead("doomed"));

            // A parry claim arrives late, perfectly dated, and must not
            // undo it.
            var late = server.Resolve("doomed", 0f, new DefensiveClaim
            {
                ClientTime = server.Now, Kind = Defence.Parry,
            });

            Assert.Equal(ClaimVerdict.AlreadyDead, late.Verdict);
            Assert.True(server.IsDead("doomed"));
        }

        [Fact]
        public void The_dead_take_no_further_damage()
        {
            var server = new CombatServer(P);
            server.Add("doomed", 0f);
            server.Resolve("doomed", 200f, null);
            var after = server.HealthOf("doomed").Current;

            server.Resolve("doomed", 50f, null);

            Assert.Equal(after, server.HealthOf("doomed").Current);
        }

        [Fact]
        public void Reconciliation_happens_before_the_death_resolves()
        {
            // The ordering §7 requires, as a test: an honoured claim on a
            // blow that WOULD have killed must prevent the death, not
            // reverse it.
            var server = new CombatServer(P);
            server.Add("defender", 0.100f);
            for (var i = 0; i < 30; i++) server.Tick();

            var r = server.Resolve("defender", 999f, new DefensiveClaim
            {
                ClientTime = server.Now - 0.100f, Kind = Defence.Parry,
            });

            Assert.True(r.Defended);
            Assert.False(r.Killed);
            Assert.False(server.IsDead("defender"));
        }

        // ── Anti-cheat posture ────────────────────────────────────────

        [Fact]
        public void Refused_claims_are_counted_not_silently_dropped()
        {
            // §7: "detect statistically (impossible parry rates,
            // impossible windows), never by tightening the envelope."
            // You cannot detect what you did not count.
            var server = new CombatServer(P);
            server.Add("suspect", 0.050f);
            for (var i = 0; i < 90; i++) server.Tick();

            for (var i = 0; i < 5; i++)
                server.Resolve("suspect", 1f, new DefensiveClaim
                {
                    ClientTime = server.Now - 2.0f, Kind = Defence.Parry,
                });

            Assert.Equal(5, server.Refusals[ClaimVerdict.TooOld]);
        }
    }
}
