# Marrowmark — Where things stand

Short, current, and written to be read on a phone. Updated at the end
of each working session.

**Last updated:** 2026-09-08

---

## The one-line version

Design is **79 locked decisions** and, apart from two documents, done.
The engine is chosen (Unity). Every system a player touches in their
first hundred hours is specified, and most of it is **written, tested
and running** as engine-free C# — 185 tests. The development Mac cannot
run Unity, so work continues in pure C# until there is better hardware.

## Device check

`CLAUDE.md` instructs the assistant to ask which device you are on at
the start of every session, and to plan around it. If it forgets, say
"phone" or "Mac" and it will adjust — replies get shorter and more
scannable on a phone, and it stops suggesting things you cannot run.

## Working from the phone

Everything below can be done from the Claude Code app with no laptop.

**What still works on a phone:**
- Reading and discussing any design doc.
- Answering open questions and locking decisions (this is the highest
  value use of a phone session — see the queue below).
- **Writing and testing C# code.** The assistant has a .NET 9 SDK in
  its own environment and builds and runs the test suite there, so new
  simulation code can be written and verified without your machine
  being involved at all.
- Reviewing diffs and commits.

**What needs the Mac:**
- Running `dotnet test` yourself.
- Anything involving Unity, whenever that becomes possible.

**Good phone-session prompts:**
- "Read STATUS.md and let's continue."
- "Answer the next batch of open questions."
- "Write the durability system into the sim library."
- "What's left before the game can be built?"

## Where the work is

| | |
|---|---|
| **Design** | `design/` — 55 locks in `pillars.md`, which is the map to everything |
| **Code** | `sim/` — the rules of the game as engine-free C#, 185 tests |
| **The plan** | `design/tech.md` §6 (build order), §8 (how the work divides) |
| **Blocking** | `design/naming.md` §5 — trademark clearance, before anything public |

## Done this session

**Design.** Raised **P12** (the Incarnate marks and the Age of Gods)
from an idea to a written pillar. Locked **L40–L79** — the ascension
gate, epoch advancement, P12's rules, five of P11's calls, Switch 2
only, the title, PC-first, Unity, stamina as exertion, combat mobility
and archetypes, the encumbrance budget, armour on the road, durability
and breakage, directional combat, the crafting model, recipe discovery,
onboarding, skill-by-use, moderation, and live-ops.

**Renamed the project.** Bloodborn → **Marrowmark** (trademark
conflict), and the in-world term for the awakened to **the Quickened**.

**Seven documents written**, all of which did not exist: `combat.md`,
`tech.md`, `naming.md`, `crafting.md`, `onboarding.md`,
`moderation.md`, `liveops.md`.

**Built the simulation library** — the rules of the game as engine-free
C#, **185 tests**: the stamina economy with movement and encumbrance,
the damage triangle, health, a time-to-kill guard that simulates real
fights against the actual systems, armour changes on the road, per-slot
armour that breaks off piece by piece, directional targeting and guard
resolution, durability with permanent wear and earned breakage, the
crafting system with material properties and pipelines, recipe
discovery and schematics, and skill-by-use with the L40 ascension gate.

### Three design bugs the tests caught

Worth recording, because none of them would have surfaced until much
later:

- **Plate was nearly pointless against maces.** Blunt did 1.30 against
  bare flesh and 1.25 against plate — nobody would have worn it.
- **Crafting pipeline order didn't matter.** The first stage model was
  additive, so quench-then-temper equalled temper-then-quench.
- **Bought billets lost to raw ore** on the measure being tested —
  which turned out to be the test asserting the wrong thing, not the
  code.

## The second-year answer

`liveops.md` (L77–L79) resolved the gap P12 left open. Two things
closed it, and both were already in the design:

- **The Arc is an overture.** War, the economy, Incarnate seats and the
  Interior are all cyclical by construction, so a finished Arc leaves
  the game running rather than an empty world.
- **Rebirth carries your marks.** Starting again on a young world is a
  step toward P12's six, not a loss — so the second-year problem and
  the Age of Gods are the same mechanism seen from two ends.

## Two risks the combat locks created

- **Animation volume** is the largest content risk in the project
  (~300–400 clips for combat alone, from L64's five arcs across six
  weapon families). `tech.md` §1's buy-don't-make strategy is no longer
  optional. Mitigation on file: per-weapon-family direction sets.
- **P11's per-turn cost** remains an open collision with L27's
  buy-to-play lock. Subscription is on the table. Deferred until the
  slice measures real numbers.

## Next, in order

1. **UI and information design** — with no markers, no global auction
   house and rumour as discovery, the interface *is* the usability.
   Also covers the companion app (L31), which has a feature list and no
   design.
2. **Art and audio direction** — `combat.md` §6 and L65 make animation
   and sound readability a **hard requirement**, not polish, and
   nothing describes the target.

Those are the last two uncovered documents. After them the design side
is complete, and everything remaining is tuning, content, or the
prototype.

## Open questions worth a phone session

Roughly 25 remain. The ones that unblock the most:

- **Technique design (L56).** Techniques are now the main expression of
  progression and the main source of mobility — how many per weapon
  family, and how they unlock. This is a content-volume question as
  much as a design one.

- **P11's cost ceiling vs L27** — the open collision that may turn the
  game subscription-based. Deferred until real numbers exist, but the
  thinking can happen any time.
- **P12's last two** — how much secret canon a playable prequel spends,
  and whether the Age of Gods writes per-server history.
- **The currency name** — forced by L52, since "marks" is now the
  title.
- **The six town names**, "the Interior", spell naming.

## Known constraints

- **Hardware.** MacBook Air 2017, Monterey 12.7.6, dual-core i5, 8GB,
  Intel HD Graphics 6000. Runs C# comfortably; cannot realistically run
  Unity, and Unity removes Intel Mac support at 6.8 regardless. A
  different machine is needed before `tech.md` §6 Stage 1. A Windows PC
  is the better buy — PC is the first ship target (L53) and console
  SDKs are Windows-only later.
- **Solo developer, new to gamedev, AAA ambition, multi-year horizon.**
  The strategy that makes that viable is `tech.md` §1: build systems to
  full ambition, buy or generate content volume.
