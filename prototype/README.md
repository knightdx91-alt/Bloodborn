# Prototype — Godot

`tech.md` §6 Stage 1, **steps 1 and 2: move and look, then dodge**. A
character you can walk and run around a grey room, and a roll with
invulnerability frames that costs stamina and punishes panic.

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

### On the animations

The character and every clip are **direct Mixamo downloads of the same
skeleton**, so the clips play exactly as they arrived — there is no
retargeting code, and there should never need to be. Three earlier
deliveries went through Blender, whose FBX exporter bakes a Z-up→Y-up
rotation into the rest pose, and every one of them was broken in a
different way. `assets/SPEC-character-v3.md` is the standing rule for
any character added later; it is worth reading before touching the
rig.

Four more clips are in `assets/animations/` — a roll, two sword
slashes and a hit reaction — unused until step 2, where the dodge
brings in the stamina and i-frame rules from `sim/`.

Nothing from the game design is in it — that is deliberate.
`tech.md` §6 makes step 1 the tutorial rung, and the dodge in step 2 is
where the design starts.

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
- **Keyboard** — WASD or arrows, Shift to sprint, **Space** to dodge.

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

### The debug readout

The top-left line — phase, stamina, dodge count, fps — is scaffolding,
not design. There is nothing to dodge yet, so the invulnerable window
(the character flashes blue) would otherwise be invisible. It comes out
at step 3, when the dummy swings back. `SHOW_DEBUG` in `world.gd` turns
it off.

**The fps number is worth a look on a real phone.** The verification
browser here has no GPU and renders this at 3–4 fps, which says nothing
about real hardware — but it also means nothing about *feel* can be
judged from this environment.

**Or run the source.** Download Godot 4.3 (about 100MB, runs fine on
the 2017 Air), open this folder as a project, press Play.

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

This is a **prototype**, not a commitment. `design/tech.md` §2 locks
Unity (L54), and that lock is under review — see the challenge recorded
there. This folder exists to make the comparison concrete rather than
theoretical.
