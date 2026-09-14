# Prototype asset set — Stage 1

Placeholder-grade models and animation clips for the Stage 1 combat
prototype (`tech.md` §6). Not shipping art.

## Models (`models/`)

**The character is a download; the props are generated.** That split is
the whole lesson of this folder — see `humanoid.fbx` below. The props
were built 2026-09-12 by `tools/build_assets.py` (Blender 4.5.1,
headless) and validated through FBX re-import (`tools/validate.py`).

- `humanoid.fbx` — **a stock Mixamo X Bot, downloaded 2026-09-13**, per
  `SPEC-character-v3.md`. Superseded as the player model 2026-09-14 by
  `paladin.fbx` below, but kept in the repo as the reference rest pose the
  clips were validated against. **Read `SPEC-character-v3.md` before
  touching any character.**
- `paladin.fbx` — **Paladin (J. Nordstrom), downloaded 2026-09-14.**
  Current player character (`Fighter.CHARACTER`). Standard Mixamo 65-bone
  rig, so all seven clips play with no retargeting.
- `skeleton_zombie.fbx` — **Skeletonzombie (T. Avelange), downloaded
  2026-09-14.** Current enemy character (`Fighter.ENEMY_CHARACTER`),
  driven by the existing `EnemyTactics` AI. Same Mixamo rig as the clips.
- `nightshade.fbx` — **Nightshade (J. Friedrich), downloaded 2026-09-14.**
  Inactive display model staged in the yard (`world.gd`); no AI yet.
- `drake.fbx` — **Ch25 non-PBR ("Drake"), downloaded 2026-09-14.** Spare
  demon-like character. **Not committed yet:** at 83 MB it exceeds the
  git-database blob API's size limit, so it waits for a different upload
  path. Nothing references it.
- `weapon_sword.fbx` — quick-attack silhouette.
- `weapon_axe.fbx` — heavy-attack silhouette.
- `weapon_spear.fbx` — committed/thrust silhouette.
- `dummy.fbx` — training dummy.
- `arena.fbx` — 24 m test room.

`preview.png` is a Blender render of the set.

## Animations (`animations/`)

**Re-downloaded 2026-09-13** from Mixamo with the X Bot character
selected, per `SPEC-character-v3.md`: plain **FBX**, **Without Skin**,
**30 fps**, **In Place** on the walk and run, everything else default.
Mixamo assets are free to use in commercial and non-commercial projects
per Adobe's Mixamo terms; credited here, not redistributed as a
standalone asset pack.

> **Download settings, for next time.** Plain **FBX**, not Mixamo's
> "FBX for Unity" option — the engine is Godot (L54) and that option
> applies Unity-specific conventions. **Select the character first**;
> that is what makes the clip skeleton identical to the character's
> rather than merely similarly named, and it is the whole reason these
> play with no retargeting.

> ⚠️ **Pull down what this project needs while Mixamo is up.** It is
> still running as of mid-2026, but with repeated multi-day outages
> through 2025, its companion product Fuse already discontinued, and no
> published roadmap. The animation plan (`tech.md` §1: ~300–400 clips)
> rests on it. See `tech.md` §2a.

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
