# Marrowmark — Simulation Library

The rules of Marrowmark as plain C#, with **no engine dependency at
all**. Stamina, damage, crafting properties, durability, skill curves —
anything that is logic rather than rendering lives here.

## Why this exists separately

1. **It runs anywhere.** No GPU, no Unity licence, no editor. It builds
   and tests on any machine, which means the rules of the game can be
   written and proven before there is a game to put them in.
2. **The server needs the same code.** `design/tech.md` §3 puts
   authoritative simulation on zone servers. Those servers run this
   library — literally these files — so client and server can never
   disagree about how much a dodge costs.
3. **It is testable.** Feel is judged with a controller
   (`design/combat.md` §9); *rules* are judged with tests. This is where
   the rules get pinned down.

`Marrowmark.Sim` targets **netstandard2.1**, which Unity 6 consumes
directly. When the Unity project exists, this drops in unchanged.

## Rules

- **Nothing here may reference `UnityEngine`.** Ever. That is the whole
  point. If something needs the engine, it belongs in `game/`, not here.
- **Time is passed in, never read from a global clock.** Every method
  that advances state takes `deltaSeconds`. This keeps the library
  deterministic, testable, and safe to run on a server tick.
- **Tests assert relationships, not tuning numbers.** Values in
  `StaminaProfile.Default` are placeholders and will change constantly
  once someone is holding a controller. That panic-rolling costs more
  than spaced dodging is a *rule*; that a dodge costs 20 is not.

## Running it

Requires the .NET SDK (9.0 or later).

```
cd sim
dotnet test
```

Expected: all tests pass, in well under a second.

## What is here

| Area | Files | Design source |
|------|-------|---------------|
| Stamina economy | `Combat/Stamina.cs`, `Combat/StaminaProfile.cs`, `Combat/SpendResult.cs` | `design/combat.md` §2, §3 |

Next candidates, all pure logic and all buildable before Unity exists:
the damage triangle (`combat.md` §4), durability and repair (L3/L32),
crafting material properties (L4), and the skill-by-use curve
(L18/L40).
