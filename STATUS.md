# Marrowmark — Where things stand

Short, current, and written to be read on a phone. Updated at the end
of each working session.

**Last updated:** 2026-09-13

---

## The one-line version

Design is **88 locked decisions** and **complete** — every structural
question locked, every missing document written. Every system a player
touches in their first hundred hours is specified, and most of it is
**written, tested and running** as engine-free C# — 254 tests.

**Stage 1 is built and playable in any browser**: a character who walks
and runs, a dodge with invulnerability frames, a sword, a training
dummy, an enemy that fights back with three readable attack shapes, and
a parry that staggers him and buys a free punish. That is every
construction step of `tech.md` §6.

**What is left of Stage 1 is step 4, the stamina tuning — and it needs
you rather than me.** See the finding below: right now the dodge
answers everything for free, which means nothing else has a reason to
exist.

**The engine is Godot** (L54, revised 2026-09-14 from Unity). Decided
on the evidence in `tech.md` §2a, not on preference — see the L54
section below.

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
- Opening the Godot editor, if you ever want to — it runs fine there,
  though nothing so far has required it.

**Good phone-session prompts:**
- "Read STATUS.md and let's continue."
- "Answer the next batch of open questions."
- "Write the durability system into the sim library."
- "What's left before the game can be built?"

## Where the work is

| | |
|---|---|
| **Design** | `design/` — 88 locks in `pillars.md`, which is the map to everything |
| **Code** | `sim/` — the rules of the game as engine-free C#, 254 tests |
| **Tuning** | `shared/tuning/combat.json` — every combat number, once, read by both `sim/` and the prototype |
| **The plan** | `design/tech.md` §6 (build order), §8 (how the work divides) |
| **Blocking** | `design/naming.md` §5 — trademark clearance, before anything public |

## Done 2026-09-14 — the parry (step 6), and what it exposed

**`tech.md` §6 Stage 1 step 6 is done. Every construction step of
Stage 1 is now built and playable.** Hold a finger still to raise the
guard (K or right-click on a keyboard).

- **A 0.28s window**, wide enough to survive §7's ~100ms latency
  envelope — L39 is the claim that 100ms feels like zero, and a window
  near 100ms would be a lottery.
- **Refunds most of its cost on success, nothing on failure.** That
  asymmetry is the whole design.
- **Failing costs more than not trying**: 0.55s caught out of position,
  against the dodge's 0.35s.
- **The committed attack cannot be parried**, even perfectly timed.
- **0.9s stagger and a genuinely free punish.** Measured end to end:
  parry a heavy, free again in 0.12s, punish lands for a quarter of his
  health.
- **15 new tests**, `sim/` now at 254.

## Done 2026-09-14 — the look, for free

`art-audio.md` §5 (L85) already said where to spend: **the look lives
in the treatment, not the assets.** So `prototype/look.gd` now carries
a sky, haze, a low sun with long shadows, a cool fill light, filmic
tonemapping and a grade pulled off full saturation — all code, against
the same grey mannequin, costing nothing. The palette lives in one
place because **L86** makes each of the six wedges a different one of
these and nothing else.

Also: a textured ground rather than a flat colour, a fence and
scattered stones so the eye has something to measure distance against,
and the visible ground extended to 420m — it used to stop at the yard
wall and leave a hard black band of nothing beyond the fence.

**What is still free and not yet done**, roughly by value:

- **Sound.** `art-audio.md` §4 makes audio carry the damage triangle to
  a player who is never shown a number. CC0 libraries are free, and
  footsteps and impacts do more for perceived quality than any shader.
- **Hitstop** — a few frames of freeze when a blow lands. Ten lines,
  and one of the largest game-feel wins available anywhere.
- **Impact and footstep particles**, which Godot makes without assets.
- **Camera work** — a shove on impact, a small push-in on a parry.
- The Mixamo specs already written: characters, attack shapes, a guard
  pose, directional dodges. All free downloads.

## Next after step 4: characters that look like people

The prototype uses X Bot, a grey mannequin. It was the right call and it
animates perfectly, but the game should look like the game.

**`prototype/assets/SPEC-character-v4.md` is written and ready for
Muse.** The cheap path first: Mixamo has ~70 of its own characters
already on the skeleton every clip here uses, so it is the v3 path
exactly. Two characters, visibly different in silhouette — the player
and the opponent should not be the same person. If none fit, Mixamo's
**auto-rigger** will rig an uploaded mesh onto the same skeleton, which
is still a direct mixamo.com download and so does not break v3's rule.
That path has never been tried here.

**The engine side is already done.** Which model a fighter uses is a
parameter, every surface of a character gets its own tinted material
(X Bot turned out to have two, so the old code had only ever been
painting half of it), and the tint multiplies into the albedo rather
than replacing it — on a textured character, replacing would flatten it
to a solid colour.

### ⚠️ But do not buy an armour set yet — L63 says why

L63 tracks armour across head, torso, arms and legs, and **a broken
piece comes off**: a fighter who started the day in plate finishes it
half bare, legibly, to everyone watching.

**A character with its armour baked into one mesh cannot do that** —
and that is most bought characters, and all of Mixamo's. Fine for now,
since there is no armour system. **Not** fine as the basis for buying a
wardrobe: modular equipment has to be settled first, or the money is
thrown away.

Nothing about that blocks the two characters above, which are wanted
either way.

## ⚠️ The most useful thing Stage 1 produced: the dodge is dominant

With all six steps in, a bot fought the same seeded enemy three ways.
Over 30 seconds:

| Strategy | Damage taken |
|---|---|
| Nothing at all | 342, died twice |
| Parry everything | 188 — all of it from committed attacks |
| **Dodge everything** | **0** |
| §6's answers (dodge / parry / leave) | 0 |

**Dodging answers all three shapes perfectly.** So on defence there is
never a reason to parry, and §6's three answers collapse into one.
Parry's justification has to be the punish rather than the defence —
and no bot can settle whether that punish is worth the risk, because
§9 says that is a controller question.

**The likely cause is that one slow enemy applies no stamina
pressure.** Dodges more than 1.2s apart never trigger the chain
escalation, so they are free, and nothing ever forces a second dodge
inside that window.

**This makes step 4 a specific problem instead of a vague one:** find
the pressure that makes a free answer stop being free. Untested
candidates — a faster or a second enemy, a longer dodge recovery, a
wider escalation window, a cost that does not fully reset.

It is exactly the kind of finding Stage 1 exists to produce, and it
arrived on schedule.

## Done 2026-09-14 — an enemy that fights back (step 5)

**`tech.md` §6 Stage 1 step 5 is done and playable.** There is someone
in the yard who closes, telegraphs and swings, and who can kill you.

It throws `combat.md` §6's three shapes:

| Shape | Wind-up | Reach | Damage | Answer |
|---|---|---|---|---|
| Quick | 0.22s | 1.9m | ×0.6 | Dodge |
| Heavy | 0.62s | 2.3m | ×1.5 | Parry (step 6) |
| Committed | 1.00s | 2.8m | ×2.2 | Leave. **Unparryable by rule** |

**This is the step that makes the dodge mean something.** Measured:
standing still for 30 seconds costs **342 damage and two deaths**;
dodging each wind-up costs **none of it**.

- **The enemy is not clever, on purpose.** §6 claims a player reads all
  three shapes in the first hour — an opponent that picked optimally
  would jab forever and teach nothing. So it cycles with a bias, leans
  on quick attacks up close and long ones at range, and is capped at
  three quick attacks in a row.
- **Seeded and deterministic**, because §7 makes damage
  server-authoritative and the server has to agree about what the enemy
  did.
- **Being hit interrupts your swing.** Most of what makes reading a
  telegraph worth anything.
- **21 new tests**, `sim/` now at 239.

`world.gd` was 762 lines and would have been past a thousand, so the
body, rig, clips and combat state came out into **`fighter.gd`**. The
player and the enemy are the same type — `combat.md` §8 promises one
ruleset rather than two, and the cheapest way to keep that promise is
for nothing in the body to know which it is.

### A bug worth recording

The enemy has a rule that it will not reach for an expensive swing while
broke, and a rule that it must stop after three quick attacks in a row.
**The first silently defeated the second**: every forced heavy got
downgraded straight back to a quick, chains ran to five and beyond, and
**a player fighting a tired enemy would never have been taught to
parry at all.** A test caught it, not a playthrough.

The fix was to let the chain cap win. An enemy overextending into a
heavy it cannot afford is *good* — that is the punish window a player
is supposed to learn to wait for.

### ⚠️ Where step 5 does not yet meet §6

The heavy and the committed **share one clip** at different speeds, so
they are told apart by timing rather than by shape. §6 calls animation
readability a *hard requirement, not a stretch goal* — and confusing a
parryable attack with an unparryable one is the worst confusion this
design has. `prototype/assets/SPEC-attack-clips.md` asks Muse for the
three distinct clips that close it.

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
only, the title, PC-first, the engine, stamina as exertion, combat mobility
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
C#, **185 tests at the time** (218 now): the stamina economy with
movement and encumbrance,
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

  ⚠️ **And the plan rests on Mixamo, which may be quietly dying.**
  Still up as of mid-2026, but with repeated multi-day outages through
  2025, its companion product Fuse already discontinued, and no
  roadmap. **This costs the same on either engine, so it does not
  touch L54** — but it argues for pulling the clips this project needs
  down *now*, while it is up, rather than at Stage 3. Cheap insurance;
  see `tech.md` §2a.
- **P11's per-turn cost** remains an open collision with L27's
  buy-to-play lock. Subscription is on the table. Deferred until the
  slice measures real numbers.

## The build loop (working)

**Playable now, on anything, with nothing installed:**
**https://knightdx91-alt.github.io/Bloodborn/**

**Controls.** Drag anywhere to steer — how far you drag is how fast you
go. **Tap to swing. Tap with a second finger to dodge.** On a keyboard:
WASD or arrows, Shift to sprint, Space to dodge, J to swing.

**Hold a finger still to raise your guard** (K or right-click on a
keyboard). Time it against a chop and you turn it aside, stagger him,
and get a free swing.

**There is someone in the yard, and he will kill you.** Watch his
wind-up: a short one is a jab (dodge it), a long one is a chop (parry
it), a very long one is a whole-body swing you *cannot* parry and
should simply not be standing in front of. The training dummy is still
there for practice.

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
What it has caught so far, none of which would have come out of reading
the code:

- A GDScript parse error, and a character that walked off the edge of
  the world into empty space.
- A camera angle that was fine on a laptop and showed nothing but sky
  on a phone, and later one framed for a capsule that left a person 80
  pixels tall.
- A walking speed no thumb could reach.
- **Three separate broken character deliveries that every structural
  check had passed** — bone counts, names, scale, all correct, all
  useless.
- An attack that fired on press instead of release, because Godot
  turns every touch into a mouse click as well.
- A project setting that silently did nothing, because its comment
  started with `#` instead of `;`.
- **Taps being eaten below about ten frames a second** — the one that
  was not merely a testing artefact.

**Rebuilding:** export to `docs/`, commit, push. Pages redeploys
automatically. `.gitattributes` unsets LFS filters under `docs/`,
because Pages serves LFS pointers rather than files.

**What this does not solve:** feel. Screenshots are not playtesting.
`combat.md` §9's gate — does a parry land right at 100ms — still needs
a human holding a controller.

**And the limit is sharper than "no controller".** This browser has no
GPU and renders at **3–4 fps**. At that rate input timing itself
misreports: a 70ms tap measures as a second-long press. That had to be
designed around rather than assumed away, and it is why the debug
readout shows fps — **worth a glance on the actual phone**, because
that number is the one thing here that cannot be checked from this
side.

## ✅ L54 is settled — the engine is Godot

**Revised 2026-09-14, from Unity.** The full reasoning and sources are
in `tech.md` §2 and §2a. The short version:

**What decided it.** The whole build-and-play loop runs on Godot with
nothing on your machine — authored as text, built headless with no GPU,
exported, driven with simulated input, looked at, published. Stage 1
steps 1–3 exist because of that. Unity cannot be operated this way.

**The two questions that were holding it, both researched, neither
favouring Unity:**

- **Asset ecosystem — mostly dissolved.** Unity's own documentation
  permits Asset Store assets in other engines, so the store is not
  Unity-only. Art, animation and audio transfer; materials and prefabs
  are rebuilt per pack; **editor tools and C# plugins never transfer.**
  That tooling gap is real — and it is the half this project is least
  exposed to, because §1 buys content and hand-writes systems.
- **Console cost — inverted.** W4 Consoles is **$2,000/yr for all three
  platforms**, no revenue share. Unity **requires Unity Pro to ship on
  console at all — $2,310 per seat per year.**

**What was given up, honestly:** a thinner tooling ecosystem; one small
vendor (W4) carrying all three console ports, with Switch 2 still in
beta there; and **C# not reaching the web export**, which is why rules
are written twice.

**That last one is now governed by L88**, with a named exit: when you
can routinely run native builds, the prototype moves to Godot's .NET
build and `prototype/rules/` is deleted the same day. Named on purpose
— it is exactly the kind of cost that becomes permanent by drift.

## Next, in order

**The design side is complete.** Every document identified as missing
has been written, and every structural question is locked. What remains
falls into three piles, and none of it is design:

1. **Stage 1 is built.** `tech.md` §6's six steps: move and look,
   dodge, attack and hit, an enemy that fights back, and the parry —
   all playable in a browser. **Only step 4 remains, and it is not
   construction.**
   - **Step 4 is the stamina tuning, and it needs you, not me.** The
     economy is wired; what is missing is *pressure*. The finding
     above makes it concrete: the dodge currently answers everything
     for free, so nothing else has a reason to exist. **This is the
     single highest-value thing left in Stage 1** — and `combat.md` §9
     is explicit that it cannot be settled from this side.
   - **Then Stage 2**, which is where L39 is actually passed or failed:
     two clients and a server, then a latency slider tuned until 100ms
     is indistinguishable from 0. Everything in `sim/` was written to
     run on that server unchanged.
   - Waiting on Muse, none of it blocking:
     **`SPEC-attack-clips.md`** — three distinct attack shapes *and* a
     guard pose; §6 and L65 both call these hard requirements rather
     than polish, so this is the highest-value one.
     **`SPEC-character-v4.md`** — characters that look like people
     instead of grey mannequins.
     `SPEC-dodge-clips.md` — four directional dodges.
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

- **L54 itself — the engine.** Both open questions are researched
  (`tech.md` §2a) and the recommendation is Godot. **All that is left
  is deciding**, and every week it stays open is another week of rules
  written twice.

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
  Intel HD Graphics 6000. **Godot 4 runs comfortably on it** — ~100MB,
  no compile cycle — but in practice nothing has needed it: Stage 1
  steps 1–3 were built without that machine being switched on. A better
  machine is still wanted eventually, and a **Windows PC** is the right
  buy when it happens (PC is the first ship target, L53, and console
  SDKs are Windows-only later). **It blocks nothing now.**
  *(The old Unity 6.6 / Intel-Mac-deprecation constraint is moot as of
  L54's revision.)*
- **Solo developer, new to gamedev, AAA ambition, multi-year horizon.**
  The strategy that makes that viable is `tech.md` §1: build systems to
  full ambition, buy or generate content volume.
