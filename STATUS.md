# Marrowmark — Where things stand

Short, current, and written to be read on a phone. Updated at the end
of each working session.

**Last updated:** 2026-09-17

---

## The one-line version

Design is **93 locked decisions** and **complete** — every structural
question locked, every missing document written. Every system a player
touches in their first hundred hours is specified, and most of it is
**written, tested and running** as engine-free C# — 335 tests.

**Stage 1 is built and playable in any browser**: a character who walks
and runs, a dodge with invulnerability frames, a sword, a training
dummy, an enemy that fights back with three readable attack shapes, and
a parry that staggers him and buys a free punish. That is every
construction step of `tech.md` §6.

**What is left of Stage 1 is step 4, the stamina tuning — and it needs
you rather than me.** See the finding below: right now the dodge
answers everything for free, which means nothing else has a reason to
exist. **The instrument exists and has been used**: an Android APK and
a wired Xbox pad, so the scheme being judged is the one that ships
rather than touch, which ships nowhere.

**The first real play session happened 2026-09-14, and it found five
things I could not have found from here** — see "What play found"
below. Four were bugs, two of them genuine faults in `sim/` rather
than presentation. **The stamina numbers themselves are still
unjudged**: play kept hitting things that were broken before it could
get to whether the economy feels right.

**The engine is Godot** (L54, revised 2026-09-14 from Unity). Decided
on the evidence in `tech.md` §2a, not on preference — see the L54
section below.

## Done 2026-09-16 — the NPC menus, and L90

The conversation with an NPC was default Godot in a hardcoded 520×300
box. Rebuilding it found four things that were not cosmetic:

- **The script did not compile.** `UI.scale_for()` took a `CanvasItem`;
  every panel hangs off a `CanvasLayer`, which is not one.
- **B did nothing.** Nothing listened for `ui_cancel`, so the only way
  out of a conversation was to find "Leave" with the stick.
- **The L49 confirm gate could be stepped around.** The topic buttons
  behind it stayed focusable, so the d-pad walked the highlight off the
  gate and A pressed a button hidden behind the panel — i.e. signed a
  contract by accident.
- **The walker never stopped.** The left stick moved the menu highlight
  *and* walked you away mid-sentence; the right stick swung the camera
  round behind the dialogue box.

Also: the contract board's list is longer than its panel and its only
focusable control is "Step back", so a pad reached the fifth contract
and stopped. Up and down scroll it now.

All of it is one specification — `interface.md` §8, **L90** — with one
implementation, `prototype/ui.gd`, and a harness (`qacheck.gd`) that
checks three viewport shapes, the focus trap, and B backing out one
layer at a time. Nothing sized in fixed pixels, nothing focusable that
isn't visibly focused, every choice at least 48px tall.

**Not yet seen on the phone.** It is verified by harness and by looking
at rendered frames at 900×600, 1080×2400 and 640×360 — which is exactly
the kind of verification that has been wrong before. Next APK is the
test.

## Done 2026-09-16 — the game notices what you are holding (L91)

The prototype had no idea what it was being played with. The town drew a
thumbstick whether or not a controller was plugged in; the launcher
reported a pad but nothing else changed; and both scenes bound "leave
this place" to Escape and to Start, which a phone without a controller
does not have — **so a touch player could walk into Thornfield and never
walk out.**

`InputMode` (an autoload) now watches every event and reports *pad*,
*touch* or *keyboard*. **It follows the last input you actually used**,
not the platform: platform only picks the opening guess. Plug the pad in
and the thumb controls leave the screen; unplug it and they come back.
No menu, no restart, nothing to declare — `interface.md` §9 / **L91**
says why that matters.

The touch controls themselves were the fixed-pixel fault again: a 60px
stick and a 190x100 button positioned in absolute pixels. Both now scale
to the viewport, inset out of the notch (properly mapped from the screen
safe area rather than a percentage that happened to look right), and
both scenes have a Back chip on touch.

Checked by `inputcheck.gd`: 13 checks covering each scheme being
detected, a resting stick NOT counting as a pad, a browser's synthetic
mouse-after-touch being ignored, and the thumb controls actually leaving
and returning as a pad comes and goes.

**Still unseen on real hardware.** The detection logic is verified by
feeding it synthetic events, which is not the same as a GameSir-T7 over
OTG.

## ⚠️ Reported from play, 2026-09-16 — "I'm touching it but it's not registering any touches"

**True, and it had been true since the drill yard's third commit.**

`project.godot` carried `pointing/emulate_mouse_from_touch=false`. Godot
activates a `Button` from **mouse** events; a raw `InputEventScreenTouch`
does not press a Control at all. So that one line meant **no button
anywhere in the game could be pressed with a finger** — not the
launcher, not a conversation, not the contract board, not the Back chip
added the same day.

It was switched off for a real reason: the emulated click arrives
*before* the touch that caused it, which fired a swing on press in the
drill yard and blocked the second-finger dodge. The mistake was the
scope. A fix for one scene was applied to the whole project, and took
every menu in the game with it.

It survived months of play because **the pad did all the pressing** and
the desktop build used a mouse. It surfaced the moment a controller was
put down.

Fixed by turning emulation back on and dropping the emulated click where
it actually causes harm: an emulated event carries
`device == InputEvent.DEVICE_ID_EMULATION` (-1), so `world.gd` ignores
exactly those and nothing else.

**What the harness could and could not settle.** It confirms emulation
is on, that a finger presses the launcher, a conversation's Leave and
the board's Step back, that a press alone does not swing, that a click
marked emulated is dropped, and that a real mouse click still swings. It
does **not** confirm the touch tap→swing path: a synthetic two-frame tap
produces no swing on this build *or on the one before the change*, so
the harness cannot drive it, and asserting on it would only be measuring
the harness. That one is checked on a phone.

## Done 2026-09-16 — the contract board became usable

From the first session where touch actually worked: **"when I click 'any
work going', the other menu doesn't close, and I can't click on any job
to accept it."** Both true.

- The conversation panel stayed drawn behind the board — the modal stack
  took its focus away but never hid it. It hides now and returns when
  the board closes, so B still takes you back to the person.
- The board was read-only. Every row was a label, and the only way to
  accept a job was to ask the right NPC about it — backwards, since the
  board is where the work is pinned. Rows are choices now: a pad walks
  them, a thumb hits them, the first job is selected on open, and taking
  one goes through L49's gate before anything is signed.

**There is one gate now** (`UI.confirm`), shared by the conversation and
the board. Two copies of L49 that behaved differently depending on where
you found the job would not be a gate.

## ⚠️ Reported from play, 2026-09-16 — waist-deep townsfolk

The `-1.0` model offset again, copied from `fighter.gd` into `npc.gd`
with its comment. Correct for a `CharacterBody3D` (capsule centred on
the origin, so the model hangs a metre below to stand on its feet),
wrong for a `TownNPC` (plain `Node3D` at ground level, capsule 0 → 1.8,
labels at 1.95 — all measured from the feet). Exactly one metre down on
a 1.8m figure is the waist.

**Third body that line has sunk**, so it is measured now rather than
trusted: `qacheck.gd` transforms each NPC's mesh corners into world
space and compares the lowest against the node's ground position. The
check was proved to fail first — with the bug restored it names all 34
townsfolk at `1.00m under`. A rendered frame confirms it by eye.

## Done 2026-09-16 — the town pays attention

Two more from play:

- **Carter kept offering a job already taken off the board.** Topics
  were static cards. Now a **standing rule — L92**, `brainstorm.md`
  §9.2b: every line an NPC offers is resolved against world state at the
  moment it is shown, for every NPC and everything they offer. A taken
  contract becomes "— taken" and the job-giver tells you where to be; an
  apprenticeship already sworn says so, from your master and from a
  rival who declines to poach; a drink with no coin says "— no coin",
  because completion is not the only contradiction. **You can carry as
  many jobs as you can find** — "one piece of work at a time" was read
  into a play report, implemented, and corrected the same session; the
  rule is about the offer the world has *answered*, not about the player
  being busy. Every effect must
  declare its availability rule in one table, and the harness fails on
  any effect that does not — prose alone did not hold L49's whitelist
  and will not hold this. The list rebuilds live, so taking a job on the
  board opened *from* a conversation updates the man you are still
  talking to.
- **The confirm gate covered the offer it was asking about.** It now
  hides the panel it belongs to AND states the terms itself — either
  alone is useless, since hiding without restating just loses them.

## Done 2026-09-16 — the work loop closes

**Take a cull off the board, walk to the Hedges, kill the boars, walk
back, hand the paper to the clerk, get paid — and the boars are thinner,
so the next posting for that wood is a smaller job at a smaller price.**

The first time anything a player does has changed Thornfield. Four
pieces, each with its own checks:

1. **`TownState`** — the town survives leaving the scene, and the app
   closing. Fields persisted by reflection so a new one cannot be
   silently forgotten.
2. **`ContractWork`** (C#, 12 tests) and its GDScript mirror (12
   matching) — progress, discharge, payment, and the consequence.
   Finishing a cull drops the region's pressure, and the board is
   *generated from* that pressure, so the work thinning is visible
   without anybody being told.
3. **The Hedges** — a mode on the drill yard rather than a fork of it,
   with a boar built from primitives because every model in the asset
   set is humanoid and a blood-warped boar wearing a Mixamo rig would be
   a lie in the wrong direction.
4. **The hand-in** — L92's third case: a topic the world *creates*.
   Who pays is declared by content (`pays_contracts` on the clerk's
   card), never known by code.

19 end-to-end checks, plus 363 C# tests.

## Done 2026-09-16 — the first sound

**L87 says a cut biting flesh, a cut skipping off plate and a mace
finding mail are different sounds, and that is how the damage triangle
reaches a player who is never shown a number.** That is a testable
claim. It is now tested, with placeholders rather than waited on.

There are no audio assets and no budget for any, so
`assets/tools/build_audio.py` synthesises nine WAVs from pure stdlib
Python — no numpy, no samples, no dependencies. They are ugly and they
are meant to be replaced. What they are for is proving the channel
carries the information:

| | flesh | mail | plate |
|---|---|---|---|
| rings for | 196 ms | 346 ms | **950 ms** |
| brightness | 0.125 | **1.283** | 0.339 |

Meat is dull and over with. Mail is small links moving against each
other. Plate rings on for nearly a second. Those are told apart by ear
with no numbers anywhere, which is the whole of L87.

Wired into the game: room tone that crossfades day to night on the
shared clock, an impact on every landed blow, a whoosh when the blade
goes live, and a footstep every 1.55 m walked. `soundcheck.gd` is 25
checks and measures the files themselves, in ratios rather than
absolute numbers, so replacing the placeholders with real recordings
still passes and a swap that makes two of them interchangeable still
fails.

**Two real bugs came out of wiring it, both of the kind that stay
invisible:**

- `Sound._one_shot` positioned players in **parent-local** space.
  Harmless only for as long as every impact hung off `World`, which
  sits at the origin — the first fighter to play its own swing put it
  32 m away.
- **`ArmourSet.resolve()` wears the piece down as it computes.** Ask a
  slot what it is wearing *after* the blow and a hit that broke the
  last of the mail reads back as `none`: the single loudest tell in the
  fight would have played as a hit on bare meat. `Fighter.hurt()` now
  reports `class` itself, read before the wear lands, so no caller has
  to know the ordering. Both faults were restored on purpose and the
  checks watched to fail on them before either was trusted.

And two harness bugs of my own, which is the recurring theme of this
project: I counted footstep players as *children*, but a 100 ms clip
frees itself long before the count; and I drove the fighter with
`move()` by hand while `world.gd` was also calling `move(ZERO)` every
physics frame, resetting the stride accumulator. That one reported
"3.4 m covered in silence" for a walk that was working — the test was
walking against the game instead of through it.

## ⚠️ KayKit arrived and cannot be used — 2026-09-16

**911 CC0 models, 74 MB, in `assets/kaykit/`. None of it should ship,
and the reason it was fetched at all is my mistake.**

I listed KayKit in `assets/SPEC-asset-packs-v1.md` as *"grounded
stylised medieval rather than cartoon"*, written off the itch.io page.
Rendered next to the paladin, it is **chibi** — three heads tall, huge
round heads, cute faces — and oversized with it, 2.17–2.44 m against the
player's 1.73 m. Evidence committed at
`assets/evidence/kaykit-characters-vs-paladin.png`.

The props match the characters, so the whole set goes the same way: a
dungeon barrel is **2.00 m, taller than the player**, `sword_A` is
1.77 m, the masonry is rounded pillows, the trees are lollipops. There
is no subset that shares a screen with a grim realistic knight.

It is a *good delivery* technically — nine characters on one 41-bone
rig, 76–95 clips each, feet on the origin, no unit problem, a shared
clip library whose 23 bones are an exact subset of the character rig,
and dedicated `handslot` weapon bones. That is what made it easy to
recommend blind.

**This is the second time in one week.** Ultimate Monsters was the
first, and I wrote the KayKit recommendation in the same edit as that
apology. So the spec now carries a rule rather than another apology:
**nothing is listed as a recommendation until it has been rendered next
to `paladin.fbx` and the frame looked at.** Everything not yet rendered
is demoted to *candidate*. Storefront copy describes genre; it does not
describe proportion, and proportion is what decides whether an asset can
stand next to the player. None of the other checks in that document
catch it — only the frame does.

The files are left in place rather than deleted: they are already in
git history, so removing them reclaims nothing, and the spec now marks
them clearly. Say the word if you would rather they go.

## Fixed 2026-09-16 — Thornfield was wearing the wrong century

**Smith Odo hammered iron in a yellow hard hat and a hi-vis safety vest.
Clerk Fenwick kept the boards in a navy business suit. Brewer Tammas was
in hi-vis too, and so were the wardens, the drovers, the granary hands
and half the market crowd.**

`modular-characters` is a **modern** character pack with a few fantasy
extras — of its 21 bodies there is a spacesuit, a SWAT officer, beach
shorts and flip-flops, a business suit, two mohawks and two hi-vis
workers in hard hats. `npc.gd` picked from it **by filename**:
`Male_Worker` sounds like a man who works, so it was used for the smith,
the brewer, the wardens and the drovers. Nobody had ever looked at it.
Found while rendering something else entirely, which is the point — a
name in a dictionary does not look like anything.

It survived because the fix for *variety* was to reach further into the
pack, and the pack only gets more modern the further you reach.

**Only three of the 21 bodies can dress a medieval town**:
`Male_Adventurer`, `Female_Adventurer`, `Female_Medieval`. Three outfits
for 34 people is a different problem, so the answer is the pack's own
modularity: every model is built on the **same 62-bone rig** and split
into the same four or five parts, so a head is portable. Reparent it and
it deforms with the rest.

On this rig a head is a face and hair and nothing else, so **11 of the 21
carry no period at all** and sit on any outfit. The other ten wear
something — hard hat, crown, witch's hat, visor, mohawk, dyed streak —
and are excluded on exactly that ground. Eleven heads across three
outfits is thirty-three distinguishable people, none of them in a hard
hat.

Evidence, because this is a class of bug that only a frame catches:

- `assets/evidence/townsfolk-catalogue.png` — all 21, why most are out
- `assets/evidence/townsfolk-heads.png` — the head slot on each
- `assets/evidence/townsfolk-after-fix.png` — the swap, close enough to
  see that the heads sit on the necks

And `qacheck.gd` now asserts every outfit and head is on the vetted list,
so the next person to add an NPC cannot reintroduce this by picking a
promising filename.

The heads are **cut once and shared**. A donor is a whole character —
every mesh, every clip — and the swap only wants one mesh off it, so
building one per townsperson meant 34 full character scenes instantiated
and thrown away to keep 34 heads, when there are only eleven distinct
heads to keep. Measured rather than guessed: building Thornfield's 34
people goes from **3214 ms to 2522 ms**, about 20%. (The first draft of
that comment claimed it saved "about eight minutes", which I had not
measured and which was wrong by two orders of magnitude.)

**Still open:** three outfits is thin, and the crowd reads uniform even
with the colour wash. The real answer is a townsfolk pack that is
actually medieval; this makes the town period-correct, not varied.

## Fixed 2026-09-16 — the boar fought like a swordsman

The Hedges shipped with the boar running `EnemyTactics` — the sparring
partner's brain. It circled at the edge of its reach and threw a heavy
overhead, a quick to the body and a whole-body sweep, because those are
the three shapes a man with a sword has. A boar has one: it runs at you.

`BeastTactics` (C#, 13 tests) and its GDScript mirror. The shape is
different rather than tuned differently:

- **A run cannot be steered.** Once it commits, the heading is captured
  and never revised, so stepping aside works. That is the only reason a
  charge is beatable, and it is the first thing the tests check.
- **Every spent run ends in a wheel** — the punish window.
- **Knife range means tusks**, because a charge needs room to build.
- **An exhausted boar stops charging** and is reduced to its tusks: a
  state change a player can *see*, rather than a number going down,
  which is what `interface.md` §2 asks for.

**A test found a real flaw in the rule, not just in itself.** The wheel
was left to the caller — `Spent()` was right there — so a run that went
its full distance without hitting anything simply started another, and
the boar never turned round: one charge a minute instead of twenty. A
punish window that exists only while every caller remembers to ask for
it is not a rule, so the wheel now arrives by itself in `Tick`.

`boarcheck.gd` is 12 checks and measures the fight in the Hedges: it
closes from 8.1 m to 1.7 m peaking at **6.2 m/s**. Put back on the
swordsman's brain, the same check reports 2.4 m/s — a walk — and fails.

387 C# tests, ten Godot harnesses.

## Fixed 2026-09-16 — the APK had 60 MB of things the game never loads

The playtest APK went from **106 MB to 199 MB** the moment the KayKit
packs landed. Godot exports everything under the project folder unless
told otherwise, so 74 MB of models established the same day as unusable
were being downloaded onto a phone.

Both export presets now carry an exclude filter. Six directories, every
one of them with **zero references** from any `.gd`, `.tscn` or
`.godot` — checked rather than assumed:

    assets/kaykit/        the chibi packs
    assets/monsters/      Ultimate Monsters, tonally wrong
    assets/rpg-characters/  usable but not used yet
    assets/knight/        the 5.6m untextured base body
    assets/evidence/      render evidence — documentation, not content
    assets/tools/         build_audio.py

Verified by exporting a pack before and after and **parsing the .pck
file tables**, rather than by trusting the filter: 3258 files and
149.9 MB before, 670 files and 89.9 MB after. Every directory the game
actually loads is unchanged — townsfolk 21/21, audio 9/9, animations
15/15, models 25/25, town kit 139/139 — and nothing outside the six was
removed.

(The first attempt at that verification ran `strings` over the packs and
produced nonsense in both directions, because a binary pack is full of
fragments that look like paths. Parsing the real file table was the
difference between a check and a guess.)

## Done 2026-09-16 — the work loop opens both ways

**Taking a contract was a one-way door.** A cull taken by mistake, or one
whose wood turned out to be further than it looked, stayed on your name
for good. That is not difficulty, it is a dead end.

You can now give the paper back — and the design is that it is
**possible and remembered**, not that it is free:

- **The progress goes with it.** Whatever you killed toward that contract
  is not banked for a later attempt. Retaking it starts again, which is
  what stops abandoning being a way to pause a job you are losing.
- **No coin changes hands.** There is no fee and no reputation number.
- **The town counts it.** `contracts_abandoned`, and a new bark condition
  `you_gave_work_back` — so the market, the farmers and the wardens each
  have something they only say once you have done it. That is where this
  world keeps its opinions.
- **It meets the same L49 gate as signing**, because it is exactly as
  irreversible in the other direction, and the gate names the price:
  *"the 3 you have already done goes with it"*.
- **A withdrawn posting can still be dropped.** Refusing to let go of
  work nobody is offering would be the same dead end in a smaller room.

8 xUnit tests, 9 matching GDScript checks, and 6 more in `qacheck` that
drive the actual player path — the topic appearing, the gate opening on
the refusal, nothing happening until you confirm.

**L92 caught my own mistake on the way.** The new `give_back` effect was
not in `RESOLVERS`, so the topic rendered as *"— give it back —
unavailable"* and did nothing when pressed. That is the rule working:
an effect the game cannot honour is shown as a visible gap rather than
offered. It cost one probe to find and one line to fix, and it would
have been a silent dead button in any system without that table.

**Still only culls close the loop.** Escort and smithing refuse honestly
— there is nowhere to walk a wagon to and no forge to stand at — so the
board is period-correct but one-note. That is the next thing.

## ⚠️ Reported from play, 2026-09-16 — "there isn't a way to do combat without a controller"

**In the Hedges and in the town. Both true, for different reasons.**

**The Hedges.** The touch scheme was a tap to swing, a second finger to
dodge and a hold to guard, and **L81 kept all three off the screen**.
Nothing was broken in the fight — the machinery works, and the new
checks prove it — but nothing on a phone SAYS those gestures exist, so
a thumb has no way to find them. An input you cannot discover is not an
input.

`Attack`, `Dodge` and `Guard` are now chips in the yard and the Hedges,
touch only, **alongside** the gestures rather than replacing them. L81
is revised to exempt combat controls, at the user's call, with the
buttons explicitly there to make the scheme testable.

They are also the first combat input **a harness can drive**. A
synthetic tap has never produced a swing in this project, in any build
— which is why the tap path is still unverified and why a check that
only ever looked at the yard could not have caught this. 10 new checks,
run in both scenes, attack/dodge/guard each proved to fire.

### ✅ EXPLAINED — the Hedges, 2026-09-16

**`world.gd:910`. Every player swing in the Hedges aborted before it
ever considered the boar.**

`_resolve_swing` builds its target list by reading the TRAINING DUMMY's
position first. The dummy is created in `_build_yard()` and **does not
exist in the Hedges** — so that line threw on every live frame of every
swing, and a GDScript runtime error abandons the rest of the function.
The enemy below it was never reached. Swings animated, stamina was
spent, the sound played, and **the animal could not be hurt at all**.

That is the report, exactly: tapping *does* swing in the yard and does
nothing in the Hedges. The input was arriving the whole time.

Two things kept it hidden for as long as it lasted:

- **No harness could swing in the Hedges** until the touch buttons gave
  it a way to. Every combat check ran in the drill yard, where the dummy
  exists — so the one scene with the fault was the one nothing tested.
- `_tick_dummy` has carried `if dummy == null: return` from the start.
  The absence was *known*. It simply was not handled in the second
  place that needed it.

`boarcheck` now asserts a swing can hurt the boar: 110 → 61 fixed, and
110 → 110 with the guard removed — eight swings from a metre away
landing nothing, which is what play felt.

**The earlier candidate was wrong, and worth recording as wrong.** The
boar does pin you (unable to act 62% of the time, 9 of 30 swings
refused, 120 → 65 health standing still) and that measurement is real
— but it was not the cause. It was a plausible story that fit the
symptom, and believing it would have cost a tuning pass on a boar that
was not the problem.

**The town is a different fault.** `town_player.gd` says in its own
header: *"never touches combat"*. `TownWalker` is a `CharacterBody3D`
with a model, a camera and a Talk chip — no `Fighter`, no sword, no
attack or dodge for **any** input scheme, pad included. So this was
never a touch problem there; combat simply does not exist in the town.

**Decided from play: no place is excluded — and done.** `TownWalker`
now extends `Fighter` rather than `CharacterBody3D`, so the town gets
attack, dodge, parry, stamina, health, the harness and the sound from
the one implementation that already had them. `combat.md` §8 promises
ONE ruleset rather than two, and a second implementation in the town
would have been a second ruleset the day after it was written.

Deleted rather than kept: the walker's own body build, its own model
load and its own idle/walk clips — all of which `Fighter` already does,
including the model offset this file once copied wrongly and buried the
walker to the waist. One answer instead of two.

**A is shared on the pad**: it talks when there is somebody to talk to
and dodges when there is not, because A is the dodge in the yard and a
player should not have to remember which building they are standing in.
The chips sit in the same corner as the yard's, above Talk.

Both wrappers refuse while a menu is open. A conversation is not a
fight, and a sword coming out behind a panel would be the town
answering an input meant for the menu.

8 more checks, run against the real town scene.

**Nothing to fight there yet.** Combat exists in Thornfield; enemies do
not. Whether anything hostile comes into the town, and what happens if
you swing at a townsperson, is a content and design question rather
than a mechanical one, and is not answered here.

## Done 2026-09-16 — the board honours a second kind of work

**The harvest closes now.** The board has always offered four kinds of
job — cull, escort, harvest, smithing — and honoured exactly one,
because the Hedges was the only place the world gave you to do anything
in. The Vance farm was already built, so the harvest is the one that
could stop refusing.

**The verb is the sword.** The player carries one in the town as of
today, so reaping is a swing that lands on standing wheat rather than a
new interaction nobody has been taught. `Reaping` reads the same three
things a blow against a fighter reads — is the blade live, does it
reach, has this swing already spent its hit — so a sheaf costs a real
swing and the recovery after it, and mashing is no faster than the
attack it is made of. The sheaves are further apart than a sword is
long, so a day's work is walking as well as swinging.

Finishing it has **the cull's shape**: `HarvestDemand` drops by one pair
of hands, and at zero the posting is simply not on the board, because
the farm is not asking. Nothing announces it.

One deliberate asymmetry, and it is the interesting one. A cull's
magnitude is the size of the problem and all of it is yours; a
harvest's is how many *people* the farm wants — **and turning up does
not make the field bigger**. So a day's work is a flat
`harvestSheaves`, not `magnitude × anything`.

10 xUnit tests, 16 GDScript checks — including the one that matters,
that a contract can be **finished by playing** rather than by calling
the rule directly: 6 sheaves in 10 swings, then hand-in-able.

### ⚠️ And a bug that was already there

**Vance offered `harvest-vance`. The board generates `harvest`.**
Taking harvest work from him put an id into `contracts_taken` that
matched no posting: the offer never read as taken, no work could be
recorded against it, and handing it in answered *"no such contract"*.
Nothing failed loudly — the job stopped existing the moment it was
accepted.

It survived because harvest could not be finished at all, so nobody
ever reached the part that breaks. The moment harvest became real work,
so did the bug.

`qacheck` now checks every contract the roster OFFERS against the ones
the board can actually generate — the sibling of L92's resolver rule,
and for the same reason: two files agreeing by hand is not a rule.
Proved by putting `harvest-vance` back and watching the check name it.

### ⚠️ And the frame said what the numbers could not

The first reaping field stood twenty-one sheaves on the farm's lawn and
passed every check. Rendered, it was **yellow posts scattered on
grass** — dropped timber, not a crop. Fixed by tilling the ground under
the strip and rebuilding each sheaf as fourteen thin stalks splaying at
the top instead of five thick boxes at a wide spread. The checks could
not have caught that, and did not.

## Done 2026-09-16 — the Hedges is somewhere you walk to

**Reported from play:** *"the hedges is a whole different place, it
should be a place you can travel to from the main town."* Exactly right,
and it was true in two ways at once:

- The only way in was **a button on the launcher**. A scene menu, not a
  road. The town it belongs to had no way out to it.
- Coming back **dropped you in the middle of the square**, however far
  out you had walked. Somewhere you cannot reach on foot and cannot
  return from on foot is a level, whatever it is called.

Now there is a **signpost on the north road, nine metres past the
gate**, where the main road already leaves town — and the road itself,
which used to stop dead at the hedge, runs on to meet it. Standing at it
turns the Talk chip into "Take the west road", and A on the pad does
here what it does in front of a person: the thing in front of you. No
new button, no map screen, nothing over anybody's head.

Travelling records the way home, so coming back puts you **on that road,
facing the gate**. `TownState` holds that on the autoload rather than in
`TownWorldState`, so it is not written to disk: where you are standing
mid-journey is a handoff between two scenes, not a fact about
Thornfield, and it should not survive a restart.

`roadcheck.gd`, 13 checks.

### Three things found by looking rather than reasoning

- **The first placement was inside the gate.** Three metres past the
  arch is among its posts, leaves and fence wings; standing there threw
  the body sixty-four metres into the air. Found by a check that tried
  to stand there.
- **`travel()` could not be tested at all**, because it changes the
  scene and so tore down the harness asking the question — the run
  simply died mid-check. Split into `remember_way_home()` and the
  journey: of the two things a departure does, only the second one is
  untestable.
- **The sign faced the wrong way.** Turned so its board pointed back up
  the road, it showed its blank back to everyone walking out of town,
  and its arm pointed east when the Hedges are west. Every check passed.
  Only the frame said so.

### And a reading that was about the harness

These checks first sat at the end of `qacheck`, after a long sequence
that stands up and tears down several towns. There the walker reported
itself **thirty-eight metres in the air** at a spot where a ray down
finds nothing but flat ground, and where a freshly built town puts it at
y=1.000, on the floor, stable for as long as you watch. The number was
about the harness, not the game. It now lives in its own file with one
fresh town — because a check that lies is worse than no check, and this
project has paid for that lesson more than once.

## Done 2026-09-16 — one world, and the first region moved into it

**Reported from play:** *"i want the whole thing to just be a big world,
where you can go to the arena, and where ever else from the main town."*
And, on the signpost added an hour earlier: *"not using another menu."*

Fair. A sign that changes scenes is better than a launcher button and is
still a door. **The Hedges now stands in the same scene as Thornfield**,
190 m north up the road. You walk out of the gate, past the burnt mill,
and the wood is there. Nothing loads. The town is still behind you the
whole way — checked, not assumed.

### What had to move for that to be possible

**`Skirmish`** — combat resolution, lifted out of `world.gd`. It was
`_resolve_swing`, `_land` and `_impact` reaching straight for that
scene's `player`, `enemy` and `dummy` fields. That is the real reason
the town had no enemies: combat WORKED there the moment `TownWalker`
became a `Fighter`, but nothing existed to notice a live blade passing
through anybody, and nothing could — the code that notices only knew how
to look at one scene's three names. It holds a **list** now, and any
region enlists its own.

**`Fighter.weapon_damage`** — was two constants in `world.gd` handed to
a resolve function per call, which works exactly as long as there is one
player and one enemy.

**`HedgeWood`** — the wood as a *region*: the hedge on three sides, the
scrub, the boar and its tactics. It no longer builds its own ground, sky
or clock, because those belong to the world. A region that brought its
own clock would be a second answer to a question L89 settled with one.

**`Feel` in the town.** Hit-stop, kick and shake were `world.gd`'s, so a
blow in Thornfield moved nothing. A hit that does not move the view is a
number changing somewhere, which is what `interface.md` §2 exists to
prevent.

The boar **minds its own wood**: walk out and it does not follow you
home. That is what makes the wood a place rather than a room you are
locked in.

`worldcheck.gd` is 12 checks on the thing itself — one scene, one combat
field, the town still standing while you are in the wood, and a swing
out there that hurts the boar (110 → 61). `roadcheck` now walks the
whole road at 20 m intervals and asserts the body is on its feet at
every one.

### And the frame again

At 150 m the wood's hedge **enclosed the burnt mill** — a charred
windmill and its dead trees standing inside the boar field. Every check
passed. Moving the wood north of it makes the ruin a landmark on the way
out instead, which is what it should have been.

**Still to do:** the drill yard is still a scene. When it moves in the
same way, `world.gd`'s hedges mode and `hedges.tscn` become a second
copy of the wood and must be deleted — `hedgecheck` and `boarcheck` move
to the region. The launcher's Hedges entry is already gone, so no player
can reach the duplicate; only the harnesses still use it.

## Fixed 2026-09-17 — everyone in Thornfield was walking backwards

**Reported from play:** *"the walking controls are inverted, and the
npcs are walking backwards."* Both true, both mine, and both the same
mistake made twice: assuming a facing convention instead of measuring
one.

### The controls

`Fighter.move()` takes a **world-space heading** and multiplies it
straight into velocity. It works the facing out for itself, at the far
end, with `atan2(-desired.x, -desired.z)`. `town_player.gd` negated both
axes on the way in, under a comment claiming that was "Fighter's facing
convention" — so every direction in the town came out reversed. In the
drill yard the same code is not used, which is why this only ever
appeared once you walked through the gate.

One line. The comment was the actual bug: it described a convention that
does not exist, convincingly enough that I read past it twice.

### The townsfolk

The bodies in `assets/townsfolk/modular-characters` **face +Z in their
own files** — rendered, with the paladin as a control, because the last
time I asserted what an asset looked like without opening it the user
paid 74 MB for the answer. `_build_person` turns them 180°, so a
townsperson's face points along its node's **−Z**. Both places that aimed
one — `_keep_hours` for the walk to work, `_walk_away` for leaving by the
gate — aimed +Z.

They have walked to work backwards since the day they were given legs.

### The check that could not have caught it

My first attempt at a regression check computed the expected angle with
the *fixed* formula and compared it to the node. It passed on the broken
build. A check that restates the answer is not evidence of anything.

Both checks now drive the real `_keep_hours` and `_walk_away` on a real
`TownNPC`, and the walking one holds `KEY_W` through `_input_dir` and the
camera rotation — the path a thumb actually takes. With the bugs put
back: `walking (-1, 0, -1) while facing (1, 0, 1)`, and forward moves
`(0, 0, 3)` instead of `(0, 0, -3)`. Both FAIL. That is what makes them
worth keeping.

### And the frame

`facingshot.gd` takes two photographs of the fixed build, because the bug
was visible and every check passed:

- `assets/evidence/facing-npc-walking.png` — a townsperson in profile,
  camera square to whichever way `_keep_hours` actually walked them. The
  face leads the stride.
- `assets/evidence/facing-player-forward.png` — forward held, camera
  behind. Their back is to you and they are running up the road toward
  the Hedges sign.

**Noticed in that second frame and not chased:** the ground has a visible
edge on the horizon, a grey band where the world stops. It is well past
the wood, so nothing you can walk to, but it will need a skirt or fog
before anyone else looks at this.

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
| **Code** | `sim/` — the rules of the game as engine-free C#, 267 tests |
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

**And the characters are wearing armour now** — a helm, pauldrons, a
cuirass, vambraces, tassets and greaves, built from primitives in
`armour.gd` and hung on the skeleton. They still have mannequin bodies,
but they read as fighters rather than shop dummies.

**The geometry is a placeholder; the structure is not.** L63 tracks
head, torso, arms and legs separately because a broken piece *comes
off*, and `shed(slot)` does exactly that — so **L63 is visible in the
prototype for the first time**. It also means the earlier warning stands
with a solution attached: a fused bought character still cannot do this,
but the slots now exist for real pieces to drop into.

**And blows land like they mean something now.** `feel.gd` adds
hitstop — a few frames of hesitation scaled to the weight of the blow —
a camera shove along the hit, a rattle on a parry, and a sway that
starts when stamina runs low, which is `art-audio.md` §2's "an
exhausted character's camera behaves differently".

**None of it touches the rules**, and that was the thing to get right:
`combat.md` §7 adjudicates defensive windows against a tolerance
envelope, so a freeze that stopped the clocks would mean the 0.28s
parry window was not 0.28s on the client. Hitstop pauses *animation*
only — verified at 55 frames of parry window with a 0.12s freeze in the
middle of it, and 55 without.

**A grade correction, caught by re-reading the doc.** `art-audio.md` §2
says "Contrast over saturation. Dark here means *low light*, not
desaturated mud. The grey-brown cliché is both a visual dead end and
genuinely worse for reading a fight." The first look pass pulled
saturation to 0.82 and produced exactly that cliché. Saturation is back
at 0.98 and the mood comes out of exposure and the contrast curve.

**What is still free and not yet done**, roughly by value:

- **Sound.** `art-audio.md` §4 makes audio carry the damage triangle to
  a player who is never shown a number. CC0 libraries are free, and
  footsteps and impacts do more for perceived quality than any shader.
  **This is now the biggest free win left.**
- **Impact and footstep particles**, which Godot makes without assets.
- The Mixamo specs already written: characters, attack shapes, a guard
  pose, directional dodges. All free downloads.

## The controls are settled — 2026-09-15/16, thirteen commits of play

**Both prototypes are now playable on a phone with a wired pad**, which
they were not at the start of the day. What follows is the list, kept
because almost none of it was findable from this side.

**Nothing could be installed twice.** The build signed every APK with a
freshly generated key, so Android refused every update and each one
meant uninstall-then-reinstall. The keystore step was guarded by
`if [ ! -f ... ]`, which does nothing on a clean runner. A stable key
lives in `ci/` now, with its own README on why a signing key is
committed to a public repo and the rule that keeps that acceptable.

**Thornfield had no floor.** A 500×500 plane mesh and no collision:
153 static bodies, none of them ground, and the walker fell through the
world on arrival. Then, once there was a floor to stand on, it stood
**waist deep** in it — a −1.0 model offset copied from the yard, where
the capsule is 2m centred on the origin and the offset is correct.

**Thornfield had no camera**, either. A fixed follow at a hardcoded
offset that never read a stick. Pad support was added here for walking
and talking and the camera was simply forgotten.

**Menus could not be operated by a pad at all.** Two faults stacked:
nothing held focus, and Godot's default `ui_accept` has **no gamepad
button** — it carries Enter, Keypad Enter and Space and nothing else.
So a pad could move a highlight nobody could see and press nothing.

**Picking a scene was a one-way door**, both directions, with no way
back to the menu short of killing the app.

**Character textures were costing ~256 MB of VRAM.** Twelve 2048×2048
textures set to Lossless, which decompresses to full RGBA in video
memory whatever the file size. Now VRAM-compressed: ~64 MB. The
download barely moved (107 → 101 MB), and the prediction that it would
was wrong — PNG is variable-rate and ETC2/ASTC are fixed-rate at 8 bpp,
so the saving was never going to be on disk.

### Where the camera and the aim landed, after three attempts

The **right stick is the camera and nothing borrows it** — it keeps
working mid-swing. **The arc is read off the camera's own pitch**: up
for the head, level for the body, down for the legs.

Losing the left/right choice costs nothing mechanically, which is the
part worth remembering: `combat.md` §1b's table has upper-left and
upper-right both landing on the torso, lower-left and lower-right both
on the legs. **Which side a cut came from never changed what it hit.**
So the side alternates on its own and every bit of the depth L63's
per-slot armour needs survives.

**Invert is a setting now, not a constant.** It was flipped twice from
the code side and reported inverted both times, which is the point at
which it stops being a number to get right: whether a stick feels
inverted is a preference, and it belongs to whoever holds the pad.
`interface.md` §7 asked for remappable controls anyway; this is the
first of them.

### ⚠️ The lesson, and it repeated all day

**Three times I named a cause, fixed it, and was wrong.** Lighting was
"not the problem" until one rendered frame showed a black cut-out. The
camera jerk was "the parenting" until it kept jerking — the real cause
was which callback the camera ran in, and the drill yard had the answer
sitting in it the whole time. Each time the fix that worked came from
**looking at the thing itself** rather than reasoning about it.

The corollary, learnt the same way: a test that cannot fail is not a
test. One ground-clamp check pushed the stick the direction that could
never reach the clamp, and passed without exercising anything.

## Stage 2 started — the latency spike, 2026-09-15

`sim/Marrowmark.Sim/Net/` is a **deterministic model of L39 /
`combat.md` §7** — no sockets, no threads, no clocks, so the identical
fight replays at 0ms and 400ms and the results compare. First thing to
collect on `tech.md`'s bet that everything in `sim/` runs on the server
unchanged. Full write-up in `sim/NETWORKING.md`.

§7 was a paragraph; it is now four promises with tests that fail if
they break — the defender wins inside the envelope, the envelope is
clamped so latency is never an advantage, attackers have no way to
even *express* a hit claim, and death never rolls back.

**The headline result:** a defender who parries perfectly takes **zero
damage at 0, 50, 100, 150 and 200ms one-way** — identical fights.
`combat.md` §9's gate, "does a parry land right at 100ms", is answered
*yes* for the half that does not need a human.

### ⚠️ And the thing the spike was worth building for

**Past the clamp it is a cliff, not a slope.** §7 promises "a
fair-feeling game against monsters and a disadvantaged one in PvP".
What happens is that *every* defence fails — there is no band where a
defender turns some blows and eats others, and the whole transition
happens inside one tick of latency.

The arithmetic is unavoidable as written: an honest claim is dated
exactly one one-way trip back, and it is honoured while `age <=
min(delay + tolerance, MaxEnvelope)`. The first term always passes, so
the clamp alone decides — and a millisecond past it, a player can never
parry anything again.

**Recorded, not fixed.** L39 is a lock and §7 is explicit, so this is a
decision rather than a bug. Three directions are written up in
`sim/NETWORKING.md`: accept it and rewrite §7 to say there is a hard
playable ceiling; clamp the *delay* rather than the envelope; or give
partial credit past the clamp, which is the only one that produces an
actual slope — and `combat.md` §1b already has the concept, where "an
adjacent arc glances it partly aside".

**Still not proven: feel.** Whether 100ms is *indistinguishable* from 0
needs two machines and a person. §9 says so, and it remains true.

## Thornfield landed — 2026-09-15, from a parallel session

**There is a town now**, built in a separate line of work (`[acheron]`
commits) while combat was being fixed. `project.godot` now boots a
**launcher** that offers the Drill Yard or Thornfield; combat files were
left untouched and the yard still runs exactly as before. Both scenes
were verified to instantiate cleanly — 91 nodes and 439 nodes.

What is in it, from the code rather than from a document:

- **`town.gd`** — harvest-town geometry and dressing from real CC0
  Quaternius kits, with the licence evidence recorded beside them.
- **`npc/`** — 9 conversational townsfolk plus ~25 for crowd barks,
  standing where their work is (`onboarding.md` §5). Conversation is
  text: walk up, hold to talk, pick a topic. The model emits an intent
  from a **whitelist** and the game validates it; anything binding ends
  in a confirm panel.
- **`town_systems/`** — the two market-square boards generating
  contracts **from actual world state** (`content.md` §3), rumours that
  carry source, age and distortion, the shrine as respawn (`lore.md`
  §3), and apprenticeship as `onboarding.md` §1's "you begin as
  somebody's hired hand". All reading one seeded `world_state.gd`.

It is grounded work — it cites the design documents throughout and
honours L29 by giving directions as landmarks rather than markers.

### ⚠️ Three things about it that need a decision, not a fix

1. ~~It arrived with no documentation.~~ **Written 2026-09-15:**
   `prototype/TOWN.md`, from the code.
2. ~~Two files cite a "plan §4" that does not exist.~~ **Resolved, and
   it was our bug, not the town's.** The real source is
   `brainstorm.md` §9.1 and §9.2 — and §9.2 still carried the
   **pre-L49 intent whitelist**, naming `offer_contract`,
   `share_rumor`, `refuse`, `set_disposition`, `none`, with no note
   that L49 had removed it. Thornfield implemented that paragraph
   faithfully and verbatim. §9.2 is now annotated, because a superseded
   passage that does not say so gets implemented again by the next
   person who reads it.
3. ~~**It puts game RULES in GDScript only, which inverts L88.**~~
   **Settled 2026-09-15 — the rules moved.** `sim/Marrowmark.Sim/Town/`
   now owns the world state, contract generation, rumour ranking and
   ageing, apprenticeship and the shrine's toll, with **27 tests** where
   there were none, and `shared/tuning/town.json` guarded against drift
   like `combat.json`. `prototype/rules/` mirrors it; the town systems
   are now thin prose layers. See `prototype/TOWN.md`.

   The port found three real bugs, all of the same shape — **rules that
   trusted their caller.** `take()` appended any string handed to it, so
   a withdrawn contract could still be booked; `hire()` accepted any
   master, including one who does not hire; the market listed goods at
   zero quantity, which is the same lie about the world that
   `content.md` §3 forbids the board from telling. Each matters
   specifically because **L49 lets a model reach for anything**, so the
   gate has to be in the rule rather than in the caller.

## What play found — 2026-09-14, first session with a pad

Five reports, in the order they came. Worth reading as a group, because
the pattern is that **none of them were visible from this side of the
loop** and two were faults in the rules rather than the presentation.

1. **"It seems like it automatically parries."** It did. The guard rose
   on a 260ms timer after any touch, so the moment was never yours and
   resting a thumb cost 15 stamina. Now held, not fired — and holding
   it past the window is `combat.md` §1/§2's **blocking**, which had
   been specified and never built.
2. **"The swinging doesn't feel smooth."** The animation seeked *past
   the wind-up* to line the clip's fastest moment up with the live
   window — half a second into a two-second clip, which is mid-slash.
   Every swing began by teleporting the arm. Measuring the clips to fix
   it also proved the wind-up was tuned faster than the animation can
   honestly play, so it went 0.30s → 0.40s.
3. **"When you get hit your sword comes up like you're parrying."** The
   guard had no clip and borrowed the **hit reaction**, so bracing and
   being struck looked identical. Exactly the failure L65 warns about.
4. **"When stamina is depleted you should slow to a walk, and swings
   should get slower."** Two faults. The exhausted speed was a 0.6
   multiplier that landed *above* the run threshold, so a spent fighter
   kept running. And **sustained drain never set the exhausted flag at
   all** — sprinting the bar flat, the commonest way to run out, did
   nothing until you next tried to pay for something outright.
5. **"I don't like that you can't move the camera"**, then **"with the
   sun behind them the character is really dark."** Both fixed, and the
   second one twice: see below.

### ⚠️ The lesson, because it repeated twice in one session

**I twice told you a thing was fine after measuring it, and was twice
wrong.** On the backlighting I ran three aggregate measurements, called
lighting "not the problem", and was flatly wrong — rendering the worst
case showed a **pure black cut-out**. The aggregates missed it because
the silhouette only appears where the background is *sky*, which needs
a low camera angle none of the sweeps used.

**Look at the frame before averaging over it.** An aggregate can only
answer the question you thought to ask.

## Where the camera and the arcs landed — 2026-09-14

The camera is **Skyrim's**, by request: the right stick is always the
camera, it never recentres, and you aim by pointing it. That one clause
decides the rest — a camera never taken away cannot also be the aim, so
**the five arcs come from the LEFT stick**, the direction you step as
you commit. Back for the overhead, in for the thrust, sides for the
level cuts.

That is Skyrim's own scheme (its power attacks take direction from
movement) and Mount & Blade's keyboard layout, and it lands on L56 —
techniques are *primarily how you move*. **The cost is recorded in
`combat.md` §1b:** you cannot step one way and cut another, so chasing
someone means thrusting.

### ⚠️ The five arcs are currently invisible

**The arc decides which armour slot takes the blow, and nothing else.**
The swing clip is chosen by *shape* — quick or heavy — so an overhead,
a low cut and a thrust all play the same animation. Nothing on the body
distinguishes them.

That is not cosmetic. L64 aims freely and **L65 forbids a reticle**, so
the design's stated way of learning where you are aiming is to *watch
where the blow lands*. Right now there is nothing to watch, which makes
the whole directional system unlearnable rather than merely unpolished.
It is the strongest argument yet for `SPEC-attack-clips.md`, and it did
not exist as an argument before the arcs moved to the stick.

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

## Done 2026-09-14 — the guard, fixed, and blocking

**The parry used to raise itself on a timer** — 260ms after any touch,
whether you meant it or not — so you could never choose the moment, and
resting a thumb on the screen cost 15 stamina. It felt automatic
because it was. Caught by playing it, not by any test.

**Now the guard goes up on press and stays up while held.** The moment
is yours. The input layer has to commit before it knows whether a touch
is a tap, a steer or a guard, so it raises one speculatively and hands
it back — refused once the guard has turned a blow, and only possible
during the 0.06s it takes to raise. **A guard that is properly up has
been paid for, including a mistimed one**, because §2 says a failed
parry refunds nothing.

**And holding it now does something: blocking**, which was specified in
§1 and §2 and had never been built. 35% of the blow still comes
through — "a stamina war, never an off switch" — the bar pays in
proportion, and emptying it breaks your guard and leaves you open. The
committed attack is unblockable as well as unparryable.

**11 new tests, `sim/` at 267.**

⚠️ **What the measurement did not show:** turtling for 30 seconds saved
72 damage and two deaths, and the bar only dipped to 82%. Blocking is
meant to bleed you *under pressure*, and one enemy swinging every second
or so is not pressure — regeneration outruns it. Same gap step 5 found.
The answer is more enemies, not a bigger number, which would
over-punish a crowd to fix a duel.

## Done 2026-09-14 — armour that matters, and aiming

**The damage triangle is live.** `combat.md` §4 now decides every blow,
and it bites:

| 28 of cut, on the body | | | 28 of blunt, on the body | |
|---|---|---|---|---|
| Through plate | 18.2 | | **Through plate** | **35.0** |
| Through mail | 22.4 | | Through mail | 28.0 |
| **Bare** | **49.0** | | Bare | 42.0 |

**A mace is worse against plate than against mail.** That is the
triangle working, and it is exactly the sort of thing L81 wants a
player to learn by being hit rather than by reading a number.

**And you aim now.** Where you tap is the arc — high and centred is an
overhead and goes for the helm, low goes for the legs, either side is a
cut to the body. That is L64's free aim, and a screen is already an
aiming surface, so it cost nothing. **No reticle, and there will not be
one** (L65).

**So L63 finally means something.** Which piece meets a blow depends on
where it was aimed, so which piece fails is a record of how its owner
was fought. Keep going overhead and the helm goes — ten blows in the
current tuning — and **the next overhead lands for 52.5 instead of
24.0**. "Increasingly desperate" is now literally true, and you can see
it: the helm is gone from the model.

The numbers are not duplicated. The whole triangle lives in
`shared/tuning/combat.json` and `DamageTableFileTests` fails the build
if it drifts from `DamageTable.Default` — including a test that every
unarmoured entry stays clear of every armoured one, because if any
armour were not clearly better than none, nobody would wear it.

### One thing this clarified about L63

Trying to film a helm being beaten off exposed that **it almost never
happens in a single fight** — a man dies through his helm long before
you wear it out. That looked like a tuning fault and is not one: **L59
says "wear touches everyone every day"**, so a harness degrades across a
day of fighting and gets repaired by a crafter, not inside one exchange.
A piece failing mid-fight should be rare and notable.

So no tuning changed. What changed was the demo, which now shows a man
arriving with a helm already nearly spent — which is exactly what
"started the day in plate, finishes it half bare" describes.

**257 tests.**

## ✅ Stage 1's real finding: the vocabulary works

**This replaces an earlier entry that said the opposite, and the
correction is the more useful half.**

`prototype/spar.gd` is a sparring bot and a tuning instrument — it
fights the same seeded enemy several ways and reports what each is
worth. Four seeds, forty seconds each, striking into openings only:

| Strategy | Kills | Dealt | Taken | Openings made |
|---|---|---|---|---|
| Dodge everything, **away** | **0** | 56 | 26 | 2 |
| Dodge everything, **around** | 4 | 524 | 59 | 21 |
| §6's answers, dodging away | 4 | 826 | 176 | 31 |
| §6's answers, dodging **around** | 8 | 1020 | 176 | 40 |
| Parry everything you can | 10 | 1376 | 66 | 51 |

**L56 turns out to be measurably right.** It says "a dodge repositions,
it does not merely evade... dodging toward, around and through are all
real options, so exchanges circle rather than shuffling back and forth
on a line." Dodging *away* makes two openings in a hundred and sixty
seconds and kills nothing. Dodging *around* — same mechanic, aimed
differently — makes twenty-one and kills four.

**And parry is the high-reward answer §2 promises**, on every axis at
once. That is partly bot-flattery, since it parries 0.22s wind-ups no
human could read — which is precisely why §6 gives quick attacks to the
dodge. The realistic line is "§6's answers, dodging around", and it
comes second.

### ⚠️ The earlier finding was wrong, and here is why

I previously recorded — prominently, in `tech.md` and here — that **the
dodge was strictly dominant and §6's three answers collapsed into one.**

It was measured with a bot that counted only damage *taken* and never
tried to win. Under that metric, refusing to fight is optimal: the
boxer who runs away, declared champion. Counting kills reverses it
completely.

**The lesson is not about dodging.** A metric that leaves out the goal
will confidently rank the strategies that ignore the goal first. It
took a deliberately disciplined bot — one that strikes into openings
only — to see it.

**No tuning change came out of this**, which is the good outcome: the
numbers say the design works as written.

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

**There is now a controller.** A wired Xbox pad over OTG, into the
Android APK — and the pad is wired (left stick moves, right stick aims
the cut, RB swings, LB guards, A dodges, left trigger sprints). That
closes the "no controller" half of this limit: §9's gate is now
answerable, by you, on the actual shipping input scheme rather than a
thumb. What follows still stands for *my* side of the loop.

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
   - **Step 4 is the stamina tuning.** The economy is wired and
     `spar.gd` now answers the half that is not about feel — whether
     any one answer is strictly better — and says no. **What is left
     is genuinely feel**, and `combat.md` §9 is explicit that it needs
     a controller: run it, and tell me when a fight feels wrong.
     **Still unjudged as of 2026-09-15.** The first play session spent
     itself on five things that were broken before the economy could be
     felt at all; those are fixed, so the next session can actually
     reach the question.
   - **The arcs need animations before they mean anything** — see the
     warning above. This is now the highest-value blocked item, and it
     is blocked on Muse rather than on either of us.
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
- **Input for tuning: a wired Xbox pad, over OTG into the phone.** This
  matters more than it sounds. The ship targets are PC and three
  consoles (L15, L51) and none of them is a phone, so **touch was never
  the scheme whose feel had to be right** — it is how the game is
  reachable on the machine to hand. With the Android APK pipeline in
  place, the pad makes the *actual* shipping scheme playable, so feel
  tuned now transfers instead of being thrown away. Step 4's stamina
  numbers were waiting on exactly this.
- **Solo developer, new to gamedev, AAA ambition, multi-year horizon.**
  The strategy that makes that viable is `tech.md` §1: build systems to
  full ambition, buy or generate content volume.
