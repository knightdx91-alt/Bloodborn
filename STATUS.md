# Marrowmark — Where things stand

Short, current, and written to be read on a phone. Updated at the end
of each working session.

**Last updated:** 2026-09-13

---

## The one-line version

Design is **87 locked decisions** and **complete** — every structural
question locked, every missing document written. **There is a playable
prototype** with an animated character in it, reachable from any
browser (see the build loop below). The engine lock (Unity, L54) is
**under review** — the prototype is Godot. Every system a player touches in their
first hundred hours is specified, and most of it is **written, tested
and running** as engine-free C# — 218 tests. Unity 6.6 is installed on the
development Mac and **Stage 1 is now unblocked**.

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
- **Building and playing the prototype.** It is authored, built,
  exported, driven with simulated touch and looked at entirely in the
  assistant's environment, then published — so you play the result in
  a browser on the phone itself.
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
| **Design** | `design/` — 87 locks in `pillars.md`, which is the map to everything |
| **Code** | `sim/` — the rules of the game as engine-free C#, 218 tests |
| **Tuning** | `shared/tuning/combat.json` — every combat number, once, read by both `sim/` and the prototype |
| **The plan** | `design/tech.md` §6 (build order), §8 (how the work divides) |
| **Blocking** | `design/naming.md` §5 — trademark clearance, before anything public |

## Done 2026-09-13 — attack and hit (step 3)

**`tech.md` §6 Stage 1 step 3 is done and playable.** Tap to swing.
There is a sword in the character's hand and a training dummy you can
beat down; it rocks back, flashes, topples at zero and rights itself.

- **0.87 seconds**: 0.30 winding up, 0.12 with a live blade, 0.45
  recovering. The wind-up is the telegraph and is harmless; recovery is
  the longest phase, because a whiffed swing has to leave something to
  punish — which is what the dodge's repositioning is *for*.
- **A swing that hits nothing still costs stamina.** Paid on startup,
  never on connection.
- **One swing, one blow**, however many frames the blade is live for.
- **Committed**: no steering, no cancelling, no dodging out of it.
- **15 new tests**, `sim/` now at 218.

**The damage triangle is deliberately not wired in.** It resolves a
blow against armour class and hit location, and a straw dummy has
neither — it arrives at step 5 with an enemy that wears something. For
the same reason the sword's damage and the dummy's health are constants
in `world.gd` rather than shared tuning: L4 has weapons coming from
players, so "the damage of a sword" is not a thing the design has.

### Three bugs, and a lesson that keeps repeating

- **Godot turns every touch into a left click too.** The emulated press
  arrives *before* the touch, so it fired a swing on press and then
  blocked the second-finger dodge.
- **The fix for that silently did nothing**, because comments in
  `project.godot` must start with `;` — a `#` line is a parse error
  that drops the key beneath it.
- **Taps were being eaten below about 10 fps.** The tap window now
  counts frames as well as milliseconds. This one is not just a testing
  artefact: a phone having a bad moment would have lost inputs too.

Two asset assumptions were also wrong in *both* directions — the dummy
already stands up on its own (a rotation knocked it over) and the
sword's blade runs along −Z, not +Y (assuming +Y put it through the
character's hip). Both are now measured rather than assumed: the blade
axis comes from the longest side of the weapon's bounding box and the
grip from the line across the knuckles, which will hold for the axe and
the spear too.

**The lesson, three sessions running: put the numbers on screen.**
Every one of these was solved the moment something printed what it
actually saw, and two of them cost an extra round because I guessed
first.

## Done 2026-09-13 — the dodge (step 2)

**`tech.md` §6 Stage 1 step 2 is done and playable.** Tap to dodge; tap
with a second finger while steering to dodge that way; Space on a
keyboard. It is the first thing in the engine that comes from the
design rather than from a tutorial.

- **0.70 seconds**: 0.05 committed, 0.30 invulnerable, 0.35 recovering.
  Rather more than half of it is spent hittable, which is the point —
  recovery is the punishable part.
- **Panic-rolling drains you.** 20 stamina, +10 for each dodge in a
  chain, empty in four. A dodge you cannot pay for still happens, goes
  45% as far, and recovers 1.6× slower.
- **The stamina bar obeys `interface.md` §2** — it fades in when the
  bar moves and is gone once you are full and rested. Verified: it is
  at zero alpha standing still, and back to zero 5.3 seconds after
  recovering.
- **18 new tests**, `sim/` now at 203.

### The thing this turned up: Godot's web export cannot run C#

Godot 4 lost C# everywhere except Windows, macOS and Linux when it
moved from Mono to .NET. **This does not affect shipping** — PC and
console both run C# fine. It affects the *development loop*, which is
the only reason Godot is a candidate at all: the web build is how you
play anything without a PC, so anything the prototype does has to exist
in GDScript too.

Handled, for now, by mirroring: `sim/` stays the authority, and
`prototype/rules/` is a deliberate GDScript copy. **The tuning is not
copied** — every number lives once in `shared/tuning/combat.json`, and
a test fails the build if the prototype's copy drifts. Logic diverging
is a bug someone notices; numbers diverging is a month of tuning
against the wrong game.

It is affordable at the size of a dodge and not at the size of a game.
Recorded in `tech.md` §2 as a fourth consideration under L54.

### Two bugs the browser found

- **A player standing still could not dodge at all.** Their only finger
  became the steering finger. A quick tap now dodges.
- **The tap test read the release event's position**, which a touchend
  does not reliably carry — it put the release 694 pixels from the
  press and silently ate every tap. It now measures how far the finger
  moved while down.

### And one number worth knowing

The verification browser renders this at **3–4 fps** — no GPU, software
rasterisation. It says nothing about a real phone, but it is a hard
limit on what this loop can check: it made a 70ms tap measure as 959ms
held. The debug readout in the corner now shows fps, so **it is worth
glancing at on the actual phone**.

## Done 2026-09-13 — the character

The prototype has a **rigged, skinned, animated character**, and it
took three rounds with Muse to get there. The first two failed the same
way for the same reason and passed every check that was being run.

- **The cause:** the character had been through Blender, whose FBX
  exporter bakes a Z-up→Y-up rotation into the skeleton's rest pose.
  Mixamo's clips do not expect it. Bone names and counts were *always*
  correct; **rest orientation** was the whole problem.
- **The wrong fix** was four rounds of increasingly clever retargeting
  code. Every one printed `22 tracks retargeted, 0 errors` and produced
  a character that was, in turn, a speck, on its side, facing the wrong
  way, and scissor-legged. **Every single one was caught by looking at
  a render, and none by a check.**
- **The right fix** was `SPEC-character-v3.md`: *every file must be a
  direct download from mixamo.com; do not open Blender.* The
  retargeter was then **deleted**, not improved — `prototype/tools/` is
  gone.
- Worst rest-pose mismatch went from **90° to 1.1°**, and the clips
  play exactly as downloaded.

Also this round: idle/walk/run blended by ground speed, the camera
reframed for a person rather than a capsule, shadows on, and the touch
speed ramp squared so that a gentle drag actually walks.

**Lesson worth keeping:** a spec should lead with the *mechanism*, not
the outcome. v2 asked for "a Mixamo-compatible rig" and got a Blender
rebuild, which is exactly what breaks it.

## Done in the design sessions

**Design.** Raised **P12** (the Incarnate marks and the Age of Gods)
from an idea to a written pillar. Locked **L40–L87** — the ascension
gate, epoch advancement, P12's rules, five of P11's calls, Switch 2
only, the title, PC-first, Unity, stamina as exertion, combat mobility
and archetypes, the encumbrance budget, armour on the road, durability
and breakage, directional combat, the crafting model, recipe discovery,
onboarding, skill-by-use, moderation, live-ops, the interface, and art direction.

**Renamed the project.** Bloodborn → **Marrowmark** (trademark
conflict), and the in-world term for the awakened to **the Quickened**.

**Nine documents written**, none of which existed: `combat.md`,
`tech.md`, `naming.md`, `crafting.md`, `onboarding.md`,
`moderation.md`, `liveops.md`, `interface.md`, `art-audio.md`. **Every
gap identified in the 2026-09-08 review is now closed.**

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

## The build loop (working)

**Playable now, on anything, with nothing installed:**
**https://knightdx91-alt.github.io/Bloodborn/**

Touch and drag to steer on a phone; WASD or arrows with Shift to sprint
on a keyboard. **There is a character in it now** — a Mixamo X Bot
placeholder that idles, walks and runs, with the clip picked by how
fast you are moving. It is not a capsule any more.

The loop, with no PC involved at any point:

1. Assistant writes the Godot project as text — scenes, scripts,
   config. No editor.
2. Builds it headless against a software rasteriser, no GPU.
3. Exports to web.
4. **Verifies it by loading the real build in a browser at phone
   viewport size, firing simulated touch events, and screenshotting.**
5. Commits to `docs/`; GitHub Pages serves it.
6. Developer opens a URL on any device.

Step 4 is the part that matters — it is real testing, not assumption.
It has already caught a GDScript parse error, a character that walked
off the edge of the world, a camera angle that was fine on a laptop and
showed nothing but sky on a phone, a walking speed that no thumb could
reach, and **three separate broken character deliveries that every
structural check had passed**.

**Rebuilding:** export to `docs/`, commit, push. Pages redeploys
automatically. `.gitattributes` unsets LFS filters under `docs/`,
because Pages serves LFS pointers rather than files.

**What this does not solve:** feel. Screenshots are not playtesting.
`combat.md` §9's gate — does a parry land right at 100ms — still needs
a human holding a controller.

## ⚠️ L54 is under review

A Godot project was built, exported and play-tested **entirely inside
the assistant's environment** — authored as text, built headless with
no GPU, exported to web, driven with simulated keypresses, and visually
verified. The full development loop, with nothing done on the
developer's machine. That is not possible with Unity.

**One of the three open questions is now half answered.** The loop was
only ever proven on capsules. It has now imported a rigged, skinned
character, blended three clips against ground speed, exported, and
verified the result in a phone-sized browser — and it *diagnosed* three
broken asset deliveries by measurement rather than by opening them.
What is still unproven is combat feel, which no engine choice fixes.
The two questions that actually decide L54 — asset-ecosystem depth and
the console porting cost — are untouched.

This undermines one of the two reasons L54 chose Unity. The other —
asset marketplace depth for `tech.md` §1's buy-the-content strategy —
still stands, along with the console path (L53). **The trade is about
timing:** Unity's advantages land at Stage 3+, a year out; Godot's
lands today.

Recorded in `tech.md` §2 with what would settle it. **Not decided.**
`prototype/` is Godot because that is what can be built now, and is
explicitly not a commitment.

## Next, in order

**The design side is complete.** Every document identified as missing
has been written, and every structural question is locked. What remains
falls into three piles, and none of it is design:

1. **Stage 1 — steps 1 to 3 are done.** `tech.md` §6, six steps from a
   character controller to a working parry. Move, look, **dodge** and
   **attack** are finished and playable in a browser. **Step 4 is the
   stamina economy** — attacks, dodges and sprint all draw on it
   already, so this is the tuning pass: make panic-rolling actually
   punish, and find out whether a fight has a shape. It is the first
   step that is mostly judgement rather than construction, and the
   first that would really rather have a controller.
   - **Step 5 is one enemy with three attack shapes**, and it is the
     one that makes the dodge mean something: nothing has ever swung
     back. The hit-reaction clip is already in the repo.
   - Unity versions of step 1 remain staged in `unity/Scripts/` against
     L54 landing that way.
   - Waiting on Muse: `prototype/assets/SPEC-dodge-clips.md`, four
     directional dodge clips. Not blocking anything.
2. **Trademark clearance on "Marrowmark"** (`naming.md` §5) — blocks
   anything public. Classes 9 and 41, plus a common-law sweep, plus an
   attorney.
3. **Tuning and content** — numbers that need a controller in hand
   (`combat.md` §9), the six town names and the currency, per-spell
   rule-breaks, regional palettes. All of it downstream of something
   playable existing.

Meanwhile the simulation library can keep growing: the economy (shops,
ledgers, commissions, caravans), war and charters, and the rumour
model are all pure logic and all buildable without an engine.

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
  Intel HD Graphics 6000, **Unity 6.6 installed**. Corrected
  2026-09-08: this machine **can** run Unity for Stage 1. Grey-box
  scenes and code are fine; iteration is slow and 8GB is the pinch
  point, but it is not a blocker. It becomes one around Stage 3.
  **Pin Unity 6.6** — Intel Mac support is deprecated there and removed
  at 6.8. A better machine is wanted eventually, and a Windows PC is
  the right buy when it happens (PC is the first ship target, L53, and
  console SDKs are Windows-only later) — but it is no longer blocking
  anything.
- **Solo developer, new to gamedev, AAA ambition, multi-year horizon.**
  The strategy that makes that viable is `tech.md` §1: build systems to
  full ambition, buy or generate content volume.
