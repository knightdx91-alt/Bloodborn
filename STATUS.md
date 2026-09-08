# Marrowmark — Where things stand

Short, current, and written to be read on a phone. Updated at the end
of each working session.

**Last updated:** 2026-09-08

---

## The one-line version

Design is 55 locked decisions and essentially complete. The engine is
chosen (Unity). Two combat systems are **written, tested, and running**
as plain C# — the combat loop now closes: stamina, damage, health and a
clock. The development Mac cannot run Unity, so work continues in pure
C# until there is better hardware.

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
| **Code** | `sim/` — the rules of the game as engine-free C#, 64 tests |
| **The plan** | `design/tech.md` §6 (build order), §8 (how the work divides) |
| **Blocking** | `design/naming.md` §5 — trademark clearance, before anything public |

## Done this session

- Raised **P12** (Incarnate marks / the Age of Gods) from an idea to a
  written pillar.
- Locked **L40–L57**: ascension gate, epoch advancement, P12's rules,
  four of P11's calls, Switch 2 only, the title, PC-first, Unity, and
  stamina as exertion, combat mobility, and the encumbrance budget.
- Retitled the project **Bloodborn → Marrowmark** (trademark), and the
  in-world term to **the Quickened**.
- Wrote `combat.md`, `tech.md`, `naming.md` — the three documents that
  stood between the design and building anything.
- Built the simulation library: **stamina economy**, the **damage
  triangle**, **health**, and a **time-to-kill guard** that simulates
  real fights and fails when tuning drifts outside `combat.md` §4's
  5–15 second window. 64 tests passing.

## Next, in order

1. **Durability and repair** (L3/L32) — the ~10% hit per death that
   feeds the whole crafting economy.
2. **Crafting material properties** (L4) — the flagship system, and the
   largest single piece of design in the repo.
3. **Skill-by-use curve** (L18/L40).

All three are pure logic and need no engine.

## Open questions worth a phone session

Roughly 25 remain. The ones that unblock the most:

- **Technique design (L56).** Techniques are now the main expression of
  progression and the main source of mobility — how many per weapon
  family, and how they unlock. This is a content-volume question as
  much as a design one.
- **Confirm or correct L55's boundaries** — `combat.md` §2 flags that
  the walking/riding/crafting exemptions are an interpretation, and
  that encumbrance currently shrinks the bar rather than raising costs.
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
