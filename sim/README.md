# Marrowmark — Simulation Library

The rules of Marrowmark as plain C#, with **no engine dependency at
all**. Stamina, damage, crafting properties, durability, skill curves —
anything that is logic rather than rendering lives here — now including
the shop, charters and declared wars.

## Why this exists separately

1. **It runs anywhere.** No GPU, no engine, no editor. It builds and
   tests on any machine, which means the rules of the game can be
   written and proven before there is a game to put them in.
2. **The server needs the same code.** `design/tech.md` §3 puts
   authoritative simulation on zone servers. Those servers run this
   library — literally these files — so client and server can never
   disagree about how much a dodge costs.
3. **It is testable.** Feel is judged with a controller
   (`design/combat.md` §9); *rules* are judged with tests. This is where
   the rules get pinned down.

`Marrowmark.Sim` targets **netstandard2.1**, which both Godot's .NET
build and Unity consume directly. The engine is Godot (L54).

> ⚠️ **Godot's web export cannot run C#**, and the web build is how the
> prototype is played without a PC. So `prototype/rules/` mirrors the
> parts of this library the prototype exercises, in GDScript. **This
> library stays the authority** — it is what the zone servers will run
> and what the tests cover — and **the tuning is never mirrored**:
> every number lives once in `shared/tuning/combat.json`, guarded in
> both directions by `TuningFileTests`.
>
> **L88 governs this, including the exit:** when native builds become
> routine, the prototype moves to Godot's .NET build and
> `prototype/rules/` is deleted the same day. Mirror nothing the
> prototype does not actually exercise.

## Rules

- **Nothing here may reference an engine.** Not `UnityEngine`, not
  `Godot`. Ever. That is the whole point. If something needs the
  engine, it belongs in `prototype/`, not here.
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
| Directional targeting & guards | `Combat/Targeting.cs`, `Combat/AttackDirection.cs` | L64, L65 |
| **Weapon families**: direction sets, the triangle, pace, reach, guard-break, the viability floor | `Combat/WeaponFamily.cs` | `design/combat.md` §1b, §5; L38 |
| **Techniques**: three per family, taught not unlocked, priced by skill | `Combat/Technique.cs` | `design/combat.md` §3; L56, L95 |
| Crafting: materials, stages, marks | `Crafting/` | `design/crafting.md`, L4, L38, L66–L68 |
| Skill-by-use & the ascension gate | `Progression/` | L18, L40, L71 |
| Recipe discovery & schematics | `Crafting/Knowledge.cs`, `Crafting/Schematic.cs` | L4, L72, L73 |
| The town: boards, work, rumour, shrine, apprenticeship | `Town/` | `design/content.md` §3, `onboarding.md` §1, L92 |
| The latency contract | `Net/` | `design/combat.md` §7, L39 — see `NETWORKING.md` |
| The one clock | `World/WorldClock.cs` | L89 |
| **The shop**: stock, prices, staff, standing orders, the books, wages and rent | `Economy/Shop.cs`, `Economy/Ledger.cs`, `Economy/Purse.cs` | `design/economy.md` §2, §4; L26, L31 |
| **The order book**: escrow at posting, bids under budget, delivery signed and on time, a cancel fee, nothing to dispute | `Economy/Commission.cs` | `design/economy.md` §2; L49, L68 |
| **Local markets, the road, and what falls on it**: scarce is dear, goods travel, wrecks are owner-only then open then gone; armour and cargo on one budget | `Economy/Market.cs`, `Economy/Shipment.cs`, `Economy/Cargo.cs` | `design/economy.md` §3, §3.5; L17, L32, L57 |
| **Charters**: one banner, one house, any circles; the register | `Society/Charter.cs` | `design/war-society.md` §1; L24 |
| **Rights and declared wars**: stake, lead time, enrolment, the window, resolution, history | `Society/Right.cs`, `Society/War.cs` | `design/war-society.md` §2–§3; L11, L17, L25 |

### Progression pacing

L71 makes learning come from difficulty rather than repetition, with a
daily soft cap behind it. Measured on current tuning, days to reach a
skill level by how much someone plays:

```
            casual(20)  regular(60)  heavy(200)   uses/day
  skill 0.25         5            4           2
  skill 0.50        12            8           5
  skill 0.75        26           14           8
  skill 0.90        55           23          12
  skill 0.95        88           34          15
```

A tenfold difference in playtime buys a sixfold difference in days —
the soft cap compressing that gap is what stops a marathon replacing
months. And L40's gate needs **eight** skills, so the endgame is
months of play on any schedule.

The anti-grind guarantee has its own test: ten thousand trivial
repetitions move a skill by exactly nothing.

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

### The shop, and what it costs to keep open

`Economy/Shop.cs` is economy.md §2 as rules. The owner stocks and
prices from the counter; NPC staff sell while the owner is away and
follow standing orders ("buy iron under 2, up to 20"), and **never set
a price** — stock they buy lands on the shelf unpriced and waits for
the owner. That is what makes the companion app (L31) read-and-manage
in the rules rather than by policy: everything a phone can do to a
shop is a thing staff could have been told.

Wages and rent fall due daily from the till whether or not anyone is
there (economy.md §4's sinks). Unpaid staff leave after two days and
the shop closes behind them; unpaid rent goes into arrears and is
collected when it can be. The ledger records what sold, to whom, at
what price, and nothing in it can be edited — §6 calls good books a
smuggler's liability, which only holds if they are true.

Coin moves between `Purse`s and refuses when one cannot pay, so no
rule returns a number and trusts its caller to debit somebody. That
is the bug class the town port found three times.

### Markets are local, and the road is the risk

`Economy/Market.cs` is a town's board: it lists only what is in the
warehouse, and prices scarce dear and glutted cheap, bounded both
ends. Two towns can disagree about iron, and that disagreement is the
caravaner's living — a test buys in iron country, carries it to a
town that has none, and asserts the trip pays and the spread narrows
behind it.

`Economy/Shipment.cs` is economy.md §3's "no mail, no teleporting
goods" as a rule: a shipment is in its origin, on the road, or in its
destination, never two of those. The road takes distance over speed
(a horse is 2.5× a walk), and a shipment lost on the road leaves a
`Wreck` where it fell: owner-only for L32's grace, anyone's after,
gone after an hour. Goods that despawn leave the world, which is
L17's death ladder feeding crafting demand with something that
actually went.

`Economy/Cargo.cs` holds L57: armour and cargo on one encumbrance
budget, so a fighter in plate hauls almost nothing and a loaded
hauler has a smaller bar.

### The order book

`Economy/Commission.cs` is economy.md §2's commissions, and the
escrow question is answered by leaving no room for a dispute: the
budget is escrowed at posting or the order does not exist; a bid is
under the budget and before the deadline or it is not a bid; the
thing delivered carries the crafter's own mark (L68) or it is not
their work; the deadline passed or it did not. Cancelling agreed work
leaves the crafter a fee, backing out reopens the order, and a test
asserts coin is conserved through every path — escrow is a place, not
a sink.

### Charters, rights and wars

`Society/` is war-society.md §1–§3 as rules, built 2026-10-14 with 34
tests, each one mutation-proven (remove the rule, watch the test fail).

- One Company OR Order, one House, any Circles. Circles are absent
  from the register and their roster is empty to anyone asking.
- A right is held for a season and challengeable only when the season
  turns. An unheld right is claimed, not fought over.
- No stake, no war: the stake is escrowed at declaration or the
  declaration is refused. Lead time precedes the window; battles count
  only inside it; enrolment is capped per side at what was negotiated,
  clamped to the profile's range.
- War rules apply only to the enrolled, only inside the window.
  Everyone else keeps ordinary death (L17).
- Best-of takes the right for a fresh season and the stake. **A tie
  holds** — the defender was never beaten. Walking away forfeits the
  stake; a defender who concedes loses the right and the stake goes
  home; **a treaty returns the stake** and moves the tribute, because a
  treaty is a settlement and a withdrawal is a default. Those three
  readings of §3 were not spelt out there and are recorded here as
  the choices made.
- Every finished war is archived as a record (L23).

Not here, on purpose: what a battle is (§3 leaves objective types
open), councils as challengers on town grants, what claiming an unheld
right costs, and Circle exposure. `shared/tuning/society.json` and
`economy.json` carry the numbers, guarded like the others but with no
prototype copy — L88 mirrors only what the prototype exercises.

### Weapon families and techniques

`Combat/WeaponFamily.cs` holds §5's six families as profiles against
the baseline cut, and the part §1b made load-bearing is data: which
arcs each family can throw. A dagger has all six, a maul has no
thrust, the bow only the shot. L38's floor is a test — every family
kills an unarmoured fighter inside the time-to-kill window and gets
through plate eventually — and the triangle still decides who fears
whom (a mace beats plate faster than a dagger does).

`Combat/Technique.cs` is L56 and L95: eighteen techniques, three per
family, each a committed move that carries the body somewhere under a
human ceiling and lands a blow the family can throw. **Taught, never
unlocked** — a `Repertoire` learns only from one that knows, never
from itself — and **priced by skill**: at zero family skill a move
costs more and winds up longer, falling to its true price at mastery.
An empty bar refuses it, as it refuses the dodge. Names and distances
are placeholders; the structure is the lock.

Next candidates, all pure logic and none of them needing an engine:
charter-owned property
and councils (L5, war-society.md §1), the monster ecology behind boar
pressure (content.md §2), and magic (L7–L10).
