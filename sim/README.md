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
| Stamina economy, movement & encumbrance | `Combat/Stamina.cs`, `Combat/StaminaProfile.cs`, `Combat/SpendResult.cs` | `design/combat.md` §2, §3; L55 |
| Damage triangle | `Combat/Damage.cs`, `Combat/DamageTable.cs`, `Combat/DamageKinds.cs` | `design/combat.md` §4 |
| Health | `Combat/Health.cs` | `design/combat.md` §4 |
| Time-to-kill guard | `Combat/TimeToKill.cs`, `Combat/FighterSpec.cs` | `design/combat.md` §4 |
| Armour changes on the road | `Combat/ArmorSwap.cs` | L57, L58 |
| Durability, wear, repair & breakage | `Items/Durability.cs`, `Items/DurabilityProfile.cs` | L3, L32, L59–L62 |
| Per-slot armour | `Items/ArmorSet.cs` | L63 |

### Item lifespan

L59 makes every repair cost the item some of its ceiling, so gear
eventually becomes scrap and crafters always have work. L61 makes the
smith's skill decide the price. Measured on the current tuning,
repairing only when the item is spent:

```
smith skill   repairs   deaths survived
0.00 novice        19       190
0.50               31       310
1.00 master        76       760
```

A fourfold difference in working life between a field patch and a
master's bench — enough that "who repairs your kit" is a relationship,
not a menu.

### The time-to-kill guard

`combat.md` §4 asks for fights of 5–15 seconds between comparable
players. `TimeToKill` enforces that by **simulating a fight against the
real stamina, damage and health systems** rather than dividing health
by damage — sustained damage is capped by the stamina economy, so a
formula would give an answer the game never produces.

Current tuning, torso hits, no misses:

```
           Light   Mail    Plate
Cut          5.50    9.70   12.60
Pierce       7.33    5.50    7.33
Blunt        7.33    7.33    5.50
```

The window covers **armoured** fighters. Unarmoured sits below it on
purpose and is tested separately: L57 makes armour compete with cargo,
so a hauler on the road is usually wearing nothing, and that tradeoff
only bites if being caught bare is genuinely dangerous.

Change weapon damage, health, attack pacing, the damage triangle or the
stamina economy in a way that pushes any matchup out of that window and
the tests fail, naming the matchup and the number. The drift usually
happens somewhere other than where it shows, which is the reason this
exists.

Next candidates, all pure logic and all buildable before Unity exists:
crafting material properties and rolled stats (L4) — the flagship
system — and the skill-by-use curve (L18/L40).
