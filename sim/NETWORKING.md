# Stage 2 — the latency spike

The first thing in the project to collect on `tech.md`'s bet that
"everything in `sim/` was written to run on that server unchanged".

`sim/Marrowmark.Sim/Net/` is a **deterministic model of L39 /
`combat.md` §7**: no sockets, no threads, no clocks. A fight is a
function of (state, claims, time), so the identical fight can be
replayed at 0ms and at 400ms and the results compared. That is the
whole point — a promise you can re-run is worth more than one you argue.

| Piece | What it is |
|---|---|
| `LatencyProfile` | The contract as numbers: tolerance, the clamp, the tick |
| `Link<T>` | A one-way delay with no randomness, so a failure replays |
| `DefensiveClaim` | "I parried at t" — and deliberately nothing else |
| `ToleranceEnvelope` | Whether a claim is honoured, too old, or from the future |
| `CombatServer` | Authoritative health, damage and death; counts refusals |
| `Duel` | A scripted fight, run at a chosen latency |

## What it proves

§7 was a paragraph. It is now four promises with tests that fail if
they break.

1. **A defender never dies to a hit they avoided on their own screen.**
   The claim is judged against an envelope of one one-way trip plus the
   tolerance, so a parry that was true on the defender's screen is true
   on the server.
2. **The envelope is clamped, so latency is never an advantage.** Without
   this the cheapest exploit in the game is to add some.
3. **Attackers get no client authority**, asserted structurally: there is
   no field on `DefensiveClaim` that can express a hit, a target or a
   kill. The absence is the security property.
4. **No rollback of death.** A claim arriving after a death is refused as
   `AlreadyDead`, and an honoured claim prevents the death rather than
   reversing it, which is §7's ordering requirement made real.

Refusals are counted rather than dropped, because §7's anti-cheat
posture is to "detect statistically ... never by tightening the
envelope", and you cannot detect what you did not count.

## The differential result

A defender who parries every blow correctly, the same fight each time:

```
one-way   turned  landed   damage   refused
     0ms      10       0        0        0
    50ms      10       0        0        0
   100ms      10       0        0        0
   150ms      10       0        0        0
   200ms      10       0        0        0
   300ms       0      10      200       10
   400ms       0      10      200       10
```

**100ms plays identically to 0ms.** That is L39's central claim and the
top half of the table is it, measured. `combat.md` §9's gate — "does a
parry land right at 100ms" — is answered *yes* for the half that does
not need a human.

## ⚠️ What the spike found: the clamp is a cliff, not a slope

§7 says that beyond the clamp a player "gets a fair-feeling game against
monsters and a disadvantaged one in PvP. That is the correct trade."

**What actually happens is not a disadvantage. It is a wall.** Past the
threshold *every* defence fails — there is no band where a defender
turns some blows and eats others. The transition happens within a single
tick of latency, and a test measures the boundary and asserts that
shape, so it cannot move quietly.

The arithmetic is unavoidable given the rule as written. An honest
claim is dated exactly one one-way trip back, and it is honoured while
`age <= min(delay + tolerance, MaxEnvelope)`. The first term always
passes, so the clamp alone decides — and one millisecond past it a
player can never parry anything again, forever.

**This is a design decision, not a bug to fix here.** L39 is a lock and
§7 is explicit, so it is recorded rather than quietly redesigned. Three
directions, for whoever settles it:

- **Accept it and say so.** Rewrite §7's sentence: past the clamp you
  cannot defend at all, so there is a hard playable ceiling on latency.
  Honest, and it makes the support burden explicit.
- **Clamp the delay, not the envelope.** `min(delay, maxDelay) +
  tolerance` keeps the honest part of the envelope and caps only the
  slack an exploiter would want. Softens the wall; does not remove it.
- **Give partial credit past the clamp.** A defence that misses the
  envelope glances rather than fails — `combat.md` §1b already has the
  concept, where "an adjacent arc glances it partly aside". This is the
  only one of the three that produces an actual slope.

## What this does NOT prove

**Feel.** Whether 100ms is *indistinguishable* from 0 needs two machines
and a person, and `combat.md` §9 says so plainly. Everything here is the
half that can be settled without one: that the rules agree, not that the
fight feels the same.

It is also not a network stack. There are no sockets, no serialisation,
no reconnection, no interest management and no prediction — a second
client is a second entry in a dictionary. Those are Stage 2 proper; this
is the contract they will have to satisfy.
