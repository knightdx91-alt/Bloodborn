# Prototype asset set — Stage 1

Placeholder-grade models and animation clips for the Stage 1 combat
prototype (`tech.md` §6). Not shipping art.

## Models (`models/`)

**The character is a download; the props are generated.** That split is
the whole lesson of this folder — see `humanoid.fbx` below. The props
were built 2026-09-12 by `tools/build_assets.py` (Blender 4.5.1,
headless) and validated through FBX re-import (`tools/validate.py`).

- `humanoid.fbx` — **a stock Mixamo X Bot, downloaded 2026-09-13**, per
  `SPEC-character-v3.md`. Not built here and **not to be rebuilt**: two
  earlier Blender-made characters failed identically, because Blender's
  FBX exporter bakes a Z-up→Y-up rotation into the skeleton's rest pose
  and Mixamo's clips do not expect it. Bone names and counts were
  correct every time; rest *orientation* was the whole problem. Worst
  rest-pose mismatch is now 1.1° on a thumb bone, against 90° on the
  hips before, and the clips play exactly as downloaded. **Read
  `SPEC-character-v3.md` before touching any character.**
- `weapon_sword.fbx` — quick-attack silhouette.
- `weapon_axe.fbx` — heavy-attack silhouette.
- `weapon_spear.fbx` — committed/thrust silhouette.
- `dummy.fbx` — training dummy.
- `arena.fbx` — 24 m test room.

`preview.png` is a Blender render of the set.

## Animations (`animations/`)

Downloaded 2026-09-12 from Mixamo (free account, Adobe sign-in),
FBX-for-Unity, animation-only (no skin), 30 fps. Mixamo assets are free
to use in commercial and non-commercial projects per Adobe's Mixamo
terms; credited here, not redistributed as a standalone asset pack.

| File | Mixamo name | Notes |
|---|---|---|
| `anim_Idle.fbx` | Idle | |
| `anim_Walking.fbx` | Walking | |
| `anim_Running.fbx` | Running | |
| `anim_Quick_Roll_To_Run.fbx` | Quick Roll To Run | closest to a dodge roll |
| `anim_Stable_Sword_Outward_Slash.fbx` | Stable Sword Outward Slash | quick attack |
| `anim_Sword_And_Shield_Slash.fbx` | Sword And Shield Slash | one-handed downward power slash; heavy attack |
| `anim_Hit_Reaction.fbx` | Hit Reaction | |

All seven verified: 65-bone Mixamo rig, real keyframe data, and **no
root motion** in the walk and run ("In Place" was ticked). They play
directly on `humanoid.fbx` with **no retargeting at all** — the
retargeting tool that used to live in `prototype/tools/` has been
deleted rather than fixed, because the problem was never the
retargeter. Four increasingly clever versions of it each reported
"0 errors" and each produced a broken character.

**In use so far:** idle, walking and running drive locomotion by ground
speed; the roll is the dodge (windowed to 0.60–1.30s, which is the roll
itself rather than the run either side of it); the outward slash is the
swing (windowed to 0.49–1.36s, placed so the arm's 1800°/s peak lands
inside the live-blade window). The hit reaction waits for step 5, when
something swings back.

**Wanted next:** `SPEC-dodge-clips.md` — four directional dodges, so
that dodging sideways stops meaning "turn, then roll forward".

## Regenerating

**The character and the clips are downloads and must stay downloads.**
Do not put `humanoid.fbx` through Blender for any reason, including
checking its scale — opening and re-exporting it is what breaks it.
`SPEC-character-v3.md` is the standing rule.

The props are still generated, and can be rebuilt:

```
blender -b -P tools/build_assets.py
blender -b -P tools/validate.py
```

Requires Blender 4.x on PATH. `tools/build_humanoid_v2.py` remains
only as a record of the superseded approach; running it will reproduce
the bug.

## A note on the props

`weapon_*.fbx` and `dummy.fbx` carry a ×100 scale and a baked Z-up
rotation on their mesh nodes, which is harmless on a static prop — but
it means **their orientation cannot be assumed**. The sword's blade
runs along its own −Z, not +Y, and the dummy stands up on its own
without help. The prototype measures both rather than guessing: blade
direction from the longest side of the bounding box, grip from the line
across the character's knuckles.
