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

**Option A — run the source.** Download Godot 4.3 (about 100MB, runs
fine on the 2017 Air), open this folder as a project, press Play.

**Option B — a web build**, which needs nothing installed. Unpack the
build, then in Terminal:

```
cd <the unpacked folder>
python3 -m http.server 8000
```

Open `http://localhost:8000` in Safari. Ctrl-C in Terminal to stop.

Web builds are not committed — they are 35MB of wasm and would bloat
the repository. Ask and one gets sent over.

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
