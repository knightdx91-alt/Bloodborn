# Prototype — Godot

**`tech.md` §6 Stage 1, built.** A character you can walk and run
around a grey room, a roll with invulnerability frames that costs
stamina and punishes panic, a sword you can beat a training dummy down
with, **an enemy that fights back** with combat.md §6's three attack
shapes, and **a parry** that turns his chop aside and buys you a free
swing. Only step 4's tuning pass is outstanding, and it needs a
controller.

Built entirely headless — no editor was opened to make this. It exists
to answer a question that had been assumed settled: **whether the
engine work can happen without a capable PC.** It can.

## What it is

- A ground plane, three blocks to move around, and a dummy.
- **A rigged, skinned character** — a Mixamo X Bot placeholder — that
  idles, walks and runs, with the clip chosen and its rate set by how
  fast you are actually moving.
- WASD or arrow keys to move, Shift to sprint.
- The character turns toward its direction of travel; the camera
  follows, and pulls up and back on a portrait screen.
- **A dodge** — a roll that is invulnerable in the middle and
  punishable at the end, aimed wherever you are steering.
- **A stamina bar that is not always there.** It fades in when the bar
  moves and fades out once you are full and rested (`interface.md` §2:
  there is no persistent HUD).
- **An enemy** that closes, telegraphs and swings. It dies, you die,
  both get back up.
- **A parry.** A tight window, a refund if it lands and none if it
  misses, and a stagger that buys a genuinely free swing.

### The enemy (step 5)

It throws `combat.md` §6's three shapes, and they are meant to be told
apart on sight:

| Shape | Wind-up | Reach | Damage | Answer |
|---|---|---|---|---|
| Quick | 0.22s | 1.9m | ×0.6 | Dodge |
| Heavy | 0.62s | 2.3m | ×1.5 | Parry (step 6) |
| Committed | 1.00s | 2.8m | ×2.2 | Leave. **Unparryable** |

**This is the step that makes the dodge mean something.** Standing
still for 30 seconds costs 342 damage and two deaths; dodging each
wind-up costs none of it.

The enemy is not clever, deliberately. §6 claims a player reads all
three shapes in the first hour — an opponent that picked optimally
would jab forever and teach nothing, so it cycles with a bias instead
and is capped at three quick attacks in a row. It is seeded and
deterministic, because `combat.md` §7 makes damage server-authoritative
and the server has to be able to agree about what the enemy did.

> ⚠️ **The heavy and the committed currently share one clip** at
> different speeds, so they are told apart by timing rather than by
> shape. §6 calls animation readability a *hard requirement*, and
> confusing a parryable attack with an unparryable one is the worst
> confusion available here. `assets/SPEC-attack-clips.md` asks for the
> three distinct clips that close it.
- **A sword, and a training dummy that reacts.** The swing is
  committed, the blade is live for a tenth of a second, and the dummy
  rocks back, flashes, and eventually topples.

### On the animations

The character and every clip are **direct Mixamo downloads of the same
skeleton**, so the clips play exactly as they arrived — there is no
retargeting code, and there should never need to be. Three earlier
deliveries went through Blender, whose FBX exporter bakes a Z-up→Y-up
rotation into the rest pose, and every one of them was broken in a
different way. `assets/SPEC-character-v3.md` is the standing rule for
any character added later; it is worth reading before touching the
rig.

Two clips are still unused — a second sword slash and a hit reaction.
The hit reaction is waiting on step 5, where something finally swings
back.

## Playing it

**On a phone or any browser — no install.** The build is published from
`docs/` via GitHub Pages:

**https://knightdx91-alt.github.io/Bloodborn/**

*(Pages has to be switched on once: repo → Settings → Pages → Source
"Deploy from a branch" → branch `main`, folder `/docs` → Save. It takes
a minute to go live, and works from a phone browser.)*

Controls:

- **Touch** — press and drag anywhere to steer. How far you drag is how
  fast you go, so a small nudge walks and a full push runs. The ramp is
  squared on purpose: a linear one put nearly the whole range above
  walking pace, which made the walk unreachable by thumb.
- **Dodge** — **tap** to dodge where you stand, or **tap with a second
  finger** while steering to dodge that way. There is no dodge button
  and there will not be one: `interface.md` keeps the screen clear, and
  a thumb that is already steering cannot reach a button anyway.
- **Attack** — **tap** to swing. Attacking is the commonest thing you
  do, so it gets the commonest gesture; a swing is committed anyway, so
  lifting a steering thumb to tap costs nothing.
- **Aim by where you tap.** High and centred is an overhead and goes for
  the helm; low goes for the legs; either side is a cut to the body.
  L64 gives five arcs chosen by free aim rather than a menu, and a
  screen is already an aiming surface. **There is no reticle and there
  will not be one** (L65) — you learn where you are aiming by watching
  where the blow lands.
- **Parry** — **hold a finger still.** A tap is a swing, a drag is a
  steer, and a press that does neither is a brace. It fires while the
  finger is down rather than on release, because a guard that appeared
  after you let go would be useless.
- **Keyboard** — WASD or arrows, Shift to sprint, **Space** to dodge,
  **J** or left-click to swing, **K** or right-click to parry.

### The parry (step 6)

0.28 seconds of open window — wide enough to survive `combat.md` §7's
~100ms latency envelope, which L39 makes the gate the project turns on.
It refunds most of its cost when it lands and nothing when it misses,
and being caught out of position costs 0.55s against the dodge's 0.35s.
**Failing has to cost more than not trying**, or mashing it would be
correct play.

A landed parry staggers the attacker for 0.9s and frees you in 0.12s,
which is what makes §6's "free punish" free rather than merely fast.
**The committed attack cannot be parried** — perfect timing included.

> ⚠️ **The guard has no pose of its own yet.** It borrows the hit
> reaction at half speed. L65 reads the guard *off the body* and
> forbids any UI element to rescue it, which makes this a placeholder
> for the most load-bearing pose in the design.
> `assets/SPEC-attack-clips.md` asks for the real one.

### The swing

0.87 seconds: 0.30 winding up, 0.12 with a live blade, 0.45 recovering.
The wind-up is the telegraph (`combat.md` §6) and is harmless; the
recovery is the longest phase, because a whiffed swing has to leave
something to punish — which is what the dodge's repositioning is *for*.

It is paid for on startup, so **a swing that hits nothing still costs
stamina**, and it is committed: you cannot steer, cancel it, or dodge
out of it. One swing lands at most one blow, however many frames the
blade is live for.

The damage triangle (`combat.md` §4) is built and tested in `sim/` and
is **deliberately not wired in yet**. It resolves a blow against armour
class and hit location, and a straw dummy has neither; it arrives at
step 5 with an enemy that wears something. For the same reason the
sword's damage and the dummy's health are constants in `world.gd` and
are *not* in `shared/tuning/combat.json` — L4 has weapons coming from
players, so there is no such thing in the design as "the damage of a
sword".

The sword is placed by measurement, not by guesswork: the blade axis
comes from the longest side of the weapon's own bounding box, and the
grip from the line across the character's knuckles. Both hold for any
weapon and any hand, which matters because assuming the blade ran along
+Y put it straight through the character's hip.

### The dodge

The rules live in `sim/` as tested C# and are mirrored in
`prototype/rules/` as GDScript, because **Godot's web export cannot run
C#** — see `design/tech.md` §2. The tuning is not mirrored: every
number lives once in `shared/tuning/combat.json`, which both sides
read, and a test in `sim/` fails the build if the prototype's copy
drifts.

A dodge is 0.70 seconds: 0.05s committed, 0.30s invulnerable, 0.35s
recovering. **Rather more than half of it is spent hittable**, which is
the whole design — recovery is the punishable part (`combat.md` §1),
and an unpaid dodge goes less far and recovers slower still. Dodges
cost 20 stamina and each one in a chain costs 10 more, so panic-rolling
empties you in four.

There is one roll clip, so the character turns to face the direction it
dodges. That is wrong for L56's circling and
`assets/SPEC-dodge-clips.md` asks for the four directional clips that
fix it.

### The sparring bot (`spar.gd`)

```
godot --path prototype --headless --fixed-fps 60 spar.tscn
```

Fights the same seeded enemy several ways and reports what each is
worth. It exists to answer one question after any tuning change: **is
one answer strictly better than the others?** §6 promises three shapes
with three answers, and that promise is falsifiable.

Four seeds, forty seconds each, striking into openings only:

| Strategy | Kills | Dealt | Taken | Openings |
|---|---|---|---|---|
| Dodge everything, **away** | **0** | 56 | 26 | 2 |
| Dodge everything, **around** | 4 | 524 | 59 | 21 |
| §6's answers, dodging away | 4 | 826 | 176 | 31 |
| §6's answers, dodging **around** | 8 | 1020 | 176 | 40 |
| Parry everything you can | 10 | 1376 | 66 | 51 |

**L56 is measurably right.** Dodging *away* kills nothing; dodging
*around* — the same mechanic, aimed differently — kills four and makes
ten times the openings.

⚠️ **It cannot tell you whether anything feels good.** §9 says that
needs a controller, and this bot is frame-perfect: it parries 0.22s
wind-ups no human could read, which is exactly why §6 gives the quick
attack to the dodge.

**Two ways it measured nothing before it measured something:** it
counted only damage *taken*, under which a bot that never tries to win
is optimal — and it swung freely, so the defensive choice drowned in
its own aggression. Both are in the file's header, because a tuning
instrument that lies is worse than none.

### The look (`look.gd`)

`art-audio.md` §5 (L85) says **the look lives in the treatment, not the
assets** — "palette, contrast curve and atmosphere carry more of the
look than geometry does, and they are cheap to change globally and
late." `look.gd` is that taken literally: a sky, haze, a low sun with
long shadows, a cool fill so a figure keeps its far edge, filmic
tonemapping, and a grade pulled off full saturation. All code, against
the same grey mannequin, costing nothing.

It also holds the palette in one place, because **L86** makes each of
the six wedges a different one of these and nothing else — "a
screenshot is locatable".

Three things it got wrong first, all worth knowing:

- **UV scale is tiles, not size.** Below 1 it zooms *into* one smooth
  patch of noise and produces a flat colour — indistinguishable from
  having no texture at all.
- **Raw noise runs black to white**, which multiplied into an albedo
  reads as camouflage. The colour ramp squeezes it to a narrow band:
  variation you notice only by its absence.
- **The first pass was lit like a product shot** and everything blew
  out to the same beige, which made every albedo choice pointless — a
  leather tint and a linen tint landed on the same white.

The visible ground runs 420m, far past the 30m yard. It used to stop at
the wall, leaving a hard black band of nothing beyond the fence. You
still cannot walk out there.

### Armour (`armour.gd`, `rules/armour_set.gd`)

Grey-box plate, built from primitives and hung on the skeleton — a helm,
pauldrons, a cuirass, vambraces, tassets, thigh guards and greaves. **It
is not decoration: it is the damage triangle.**

`combat.md` §4's triangle now decides every blow, and it bites:

| 28 damage of cut, on the body | |
|---|---|
| Through plate | 18.2 |
| Through mail | 22.4 |
| **Bare** | **49.0** |

| 28 damage of blunt, on the body | |
|---|---|
| **Through plate** | **35.0** |
| Through mail | 28.0 |
| Bare | 42.0 |

**A mace is worse against plate than against mail.** That is the
triangle doing its job, and it is the kind of thing a player learns by
being hit rather than by reading a number — which is what §4 and L81
both want.

**Where you aim decides which piece meets the blow** (L64), so which
piece fails is a record of how its owner was fought. Keep going overhead
and their helm goes — ten blows, in the current tuning — and **the next
overhead lands for 52.5 instead of 24.0.** L63's "increasingly
desperate" is now literally true.

**The geometry is a placeholder. The structure is not.** L63 tracks
armour across **head, torso, arms and legs**, each with its own
condition, and says a piece that breaks

> does not merely stop protecting — **it comes off**, and that slot is
> bare for the rest of the fight... a fighter who started the day in
> plate finishes it half bare and increasingly desperate.

A character with its armour baked into one mesh cannot do that — which
is most bought characters and all of Mixamo's — so the slots were worth
building before the meshes are worth buying. `shed(slot)` is that rule,
and when real pieces arrive they replace the boxes and nothing else
changes.

Two things it got wrong first:

- **`size` is a full extent, not a radius.** Reading it as a radius put
  a bucket on the character's head. Both primitives are now built at
  diameter 1 so scale and size are the same number.
- **Realistic metal rendered as a black silhouette.** A metal surface is
  lit almost entirely by what it reflects and there is nothing here to
  reflect but a procedural sky, so `metallic` sits at 0.18 rather than
  0.75. Grounded iron is not a mirror anyway (L20).

### Feel (`feel.gd`)

`art-audio.md` §2: **"The camera is a participant. Framing, shake and
depth of field are information channels — an exhausted character's
camera behaves differently. Cheap, and it does work no HUD element is
allowed to."**

- **Hitstop** — a few frames of hesitation on a blow, scaled to how
  heavy it was. Short on purpose: past about a tenth of a second it
  stops reading as impact and starts reading as a dropped frame.
- **A camera shove** along the blow, harder when you are the one taking
  it, and a directionless rattle on a parry because nothing moved.
- **Breathing.** Below about half stamina the view starts to sway. The
  bar is the one thing `interface.md` §2 allows on screen, and this
  says the same thing without it.

> ⚠️ **All of it is presentation and none of it touches the rules.**
> `combat.md` §7 makes damage server-authoritative and defensive
> windows client-authoritative inside a tolerance envelope. A freeze
> that stopped the phase machines would mean the 0.28s parry window was
> not 0.28s on the client, and the server would be adjudicating against
> timings the player never experienced. So hitstop pauses *animation*
> and the clocks run on — verified: **55 frames of parry window with a
> 0.12s freeze dropped into the middle of it, and 55 without.**

### Where the code lives

- `world.gd` — the fight: who is where, who hit whom, input, camera.
- `fighter.gd` — one combatant, player or enemy. They are the same type
  on purpose: `combat.md` §8 promises one ruleset rather than two, and
  the cheapest way to keep that promise is for there to be nothing in
  the body that knows which it is.
- `look.gd` — light, sky, haze, grade and palette. See above.
- `armour.gd` — the per-slot harness. See above.
- `feel.gd` — hitstop and the camera. See above.
- `rules/` — the GDScript mirror of `sim/`. See L88.

### The debug readout

The top-left block — dodge and swing phase, stamina, the dummy's
health, counts, fps — is scaffolding, not design. In particular
`interface.md` §2 gives an opponent **no bars at all**; the dummy's
percentage is there to check the sums, and a player is meant to read a
hit off the body. The invulnerable window (the character
flashes blue) has nothing swinging at it yet, so it would otherwise be
invisible. It comes out when the dummy fights back at step 5.
`SHOW_DEBUG` in `world.gd` turns it off.

**The fps number is worth a look on a real phone.** The verification
browser here has no GPU and renders this at 3–4 fps, which says nothing
about real hardware — but it also means nothing about *feel* can be
judged from this environment. It is not only a testing problem: at that
frame rate a 70ms tap measures as a second-long press, which is why the
tap window counts frames as well as milliseconds.

**Or run the source.** Download Godot 4.3 (about 100MB, runs fine on
the 2017 Air), open this folder as a project, press Play.

## Recording a video of it

`demo.gd` plays a scripted run and writes every frame to disk.

```
godot --path prototype --resolution 800x450 --fixed-fps 24 demo.tscn
cat $(ls /tmp/demo/f*.jpg | sort) | ffmpeg -f image2pipe \
    -vcodec mjpeg -framerate 24 -i pipe: -c:v libvpx -b:v 2200k \
    -auto-alt-ref 0 -pix_fmt yuv420p file:out.webm
```

`--fixed-fps` is the part that makes it work: game time advances a
fixed step per *rendered* frame, so the capture comes out smooth no
matter how slowly the software rasteriser actually draws it. Without
it, a 3fps render produces a 3fps video of a game running at 3fps.

This exists because a video is the only way anyone sees this project
move — there is no PC to run it on, and a screenshot cannot show a
0.28s parry window mattering.

## Rebuilding it

```
godot --path prototype --import                       # first time only
godot --path prototype --headless \
      --export-release "Web" ../docs/index.html
```

The import step builds the class cache that `world.gd` needs to see
`Stamina` and `Dodge`; it lives in `.godot/`, which is not committed,
so a fresh clone needs it once. The export goes straight to `docs/`,
which GitHub Pages serves — do not stage it inside the project
directory, or Godot will re-import the exported PNGs on the next scan.
`.gitattributes` unsets the LFS filters under `docs/`, because Pages
hands out LFS pointer files rather than the real ones.

**Or serve the build locally:**

```
cd docs
python3 -m http.server 8000
```

Then open `http://localhost:8000`. Ctrl-C to stop.

## Verified how?

Built and tested entirely headless. The exported build is loaded in a
real browser with a phone-sized viewport, driven with **simulated touch
events**, and screenshotted — so movement, collision and camera framing
are checked by looking at the result, not assumed.

That loop has already caught three real bugs: a GDScript parse error, a
character that walked off the edge of the world into empty space, and a
camera angle that was fine on a laptop and showed nothing but sky on a
phone.

## Rebuilding

From this folder, with the Godot binary on PATH:

```
godot --headless --path . --export-release "Web" build/index.html
```

Export templates for the matching Godot version must be installed
first.

## Status

**This is the project now.** `design/tech.md` §2 locks Godot (L54,
revised 2026-09-14) — this folder started as an experiment to make the
engine comparison concrete, and it won the argument.

It is still a *prototype* in the sense that matters: `tech.md` §6
Stage 1 is a route to `combat.md` §9's gate, and nothing here is built
to last. But it is no longer a candidate for deletion.
