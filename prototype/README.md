# Prototype — Godot

`tech.md` §6 Stage 1, **step 1: move and look**. A capsule you can walk
around a grey room with a few blocks and a training dummy.

Built entirely headless — no editor was opened to make this. It exists
to answer a question that had been assumed settled: **whether the
engine work can happen without a capable PC.** It can.

## What it is

- A ground plane, three blocks to move around, and a dummy.
- A capsule with a "nose" so you can see which way it faces.
- WASD or arrow keys to move, Shift to sprint.
- The capsule turns toward its direction of travel; the camera follows.

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
  fast you go, so a small nudge walks and a full push runs.
- **Keyboard** — WASD or arrows, Shift to sprint.

**Or run the source.** Download Godot 4.3 (about 100MB, runs fine on
the 2017 Air), open this folder as a project, press Play.

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
