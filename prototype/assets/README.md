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
> ### ⚠️ `brute.fbx` and `raider.fbx` DO NOT WORK YET — 2026-09-16
>
> **Their armatures are authored in centimetres.** The pelvis rests at
> **104.27** with the parent node scaled to **0.01** to compensate, which
> looks correct standing still — and collapses the moment a Mixamo clip
> touches it, because the clips' position tracks are in **metres** (the
> walk puts the hips at **1.016**). The clip drives the pelvis to a
> hundredth of its height and the body folds up around it. Rendered and
> confirmed: the paladin walks, these two crumple into heaps.
>
> **The rest pose is fine** — 1.10° worst difference from the Mixamo
> reference, better than the working player model's 16°. So this is NOT
> the v2 Z-up bake; the builder avoided that exactly as it claims. It is
> a unit mismatch, and the README's "0.00000 m error, all frames" was
> verified in Blender against the model's own armature, which cannot see
> it.
>
> **The fix belongs at source**, per `SPEC-character-v3.md`: export the
> armature in metres so its rest matches the clips. `tools/build_enemies.py`
> is in this folder. Scaling the clips' position tracks by 100 at load
> time was tested and works — all three then walk — but that is
> compensating in the engine for an asset defect, which is the habit v3
> exists to break.
>
> `prototype/rigcheck.gd` is the check, and it runs the two shipped
> Mixamo downloads as controls so it cannot pass vacuously.

- `brute.fbx` — **built 2026-09-16** by `tools/build_enemies.py`
  (Blender 4.5.1, headless). Bulky hunched humanoid enemy, ~1.77 m,
  dark palette, glowing eyes. Its skeleton is the exact 65-bone Mixamo
  rig taken straight from `animations/anim_Walking.fbx` — the armature
  is never re-posed or transform-baked, so all seven clips below play
  with no retargeting. Verified 2026-09-16: every clip drives the model
  identically to its native armature (0.00000 m error, all frames).
- `raider.fbx` — **built 2026-09-16** by `tools/build_enemies.py`. Lean
  fast humanoid enemy, ~2.00 m, red/hooded palette. Same 65-bone rig
  and same verification as `brute.fbx`.
- `wolf.fbx` — **built 2026-09-16** by `tools/build_quadrupeds.py`.
  Dire wolf on a custom 20-bone quadruped rig (Root/Spine/Chest,
  Neck/Head/Jaw, 2-segment tail, 4 × Upper/Lower/Paw leg chains).
  ~1.47 m long, ~0.95 m at the shoulder. Armature + mesh, no animation.
  Wired in `Fighter.BEAST` and unused — putting a wolf somewhere is a
  one-line change.
- `boar.fbx` — **IN USE** as the Hedges enemy since 2026-09-16.
  **built 2026-09-16** by `tools/build_quadrupeds.py`.
  Stocky boar (barrel body, shoulder hump, snout disc, tusks, bristle
  ridge) on the same 20-bone rig layout with stockier proportions.
  Armature + mesh, no animation.

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

> **The quadrupeds are unaffected by the centimetre problem above.**
> Their rig and their clips were authored together by the same script in
> the same units, which is the principle `SPEC-character-v3.md` is
> actually protecting — "the only reliable way to guarantee that is for
> the character and the clips to come out of the same place." The rule
> says *don't put a Mixamo character through Blender*; a Blender animal
> with Blender clips never touches that. Verified in Godot: the boar
> loads, animates, stands on the ground and fights.

### Quadruped clips (procedural, 2026-09-16)

Built by `tools/build_quadrupeds.py` alongside the models above —
sampled procedural animation (diagonal-gait walk, breathing idle,
lunge-bite / charge-tusk attacks), baked to one action per file.
Rotations are keyed as quaternions; see the builder's header for why.

| File | Clip | Frames | Notes |
|---|---|---|---|
| `wolf_Idle.fbx` | Idle | 61 | breathing, head sway, tail wag; loops |
| `wolf_Walk.fbx` | Walk | 31 | diagonal gait; loops |
| `wolf_Run.fbx` | Run | 21 | diagonal gait, extended; loops |
| `wolf_Attack.fbx` | Attack | 24 | crouch, lunge, bite |
| `boar_Idle.fbx` | Idle | 61 | breathing, sniffing dips, tail flicks; loops |
| `boar_Walk.fbx` | Walk | 31 | diagonal gait; loops |
| `boar_Run.fbx` | Run | 21 | diagonal gait, extended; loops |
| `boar_Attack.fbx` | Attack | 28 | paw, charge, tusk swipe left/right |

Verified 2026-09-16: each clip re-imports to exactly one action that
animates its model (Blender), and all twelve files import cleanly into
Godot 4.3 (Skeleton3D + bound Skin + AnimationPlayer).

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

The enemies and animals are generated too:

```
blender -b -P tools/build_enemies.py     # brute.fbx, raider.fbx
blender -b -P tools/build_quadrupeds.py  # wolf.fbx, boar.fbx + 8 clips
```

`build_enemies.py` takes the skeleton from
`../animations/anim_Walking.fbx` and must keep that armature's object
transform exactly as imported — baking it (`transform_apply`) changes
the animation coordinate space and makes the Mixamo location curves
explode. `build_quadrupeds.py` authors its own 20-bone rig and clips;
its header documents three Blender 4.5 FBX-exporter pitfalls it works
around (all actions exported as takes, euler rotations not baked on
slotted actions, euler component assignment in quaternion mode).

## A note on the props

`weapon_*.fbx` and `dummy.fbx` carry a ×100 scale and a baked Z-up
rotation on their mesh nodes, which is harmless on a static prop — but
it means **their orientation cannot be assumed**. The sword's blade
runs along its own −Z, not +Y, and the dummy stands up on its own
without help. The prototype measures both rather than guessing: blade
direction from the longest side of the bounding box, grip from the line
across the character's knuckles.

## Character textures are VRAM-compressed, and why that is not about download size

The twelve Mixamo character textures (paladin, skeleton zombie,
nightshade) are `compress/mode=2` — **VRAM Compressed**, not Lossless.

They arrived as Lossless, which sounds like the careful choice and is
the expensive one. Lossless means the texture is decompressed to full
RGBA *in video memory*, so what a file costs on disk says nothing about
what it costs to have on screen. All twelve are 2048×2048:

| | |
|---|---|
| Per texture, uncompressed in VRAM (RGBA8, with mipmaps) | ~21 MB |
| **All three characters, uncompressed** | **~256 MB** |
| The same textures as ETC2/ASTC (8 bpp, so exactly 4×) | ~64 MB |

The drill yard loads all three at once, so that was the full 255 MB
resident on a phone — where the GPU shares system RAM, and a number
like that buys stutter, thermal throttling, or the OS killing the app
on a mid-range device. `import_etc2_astc` was already true in
`project.godot`; the per-texture import mode was quietly overriding it.

**The download saving is small, and that is inherent rather than a
disappointment.** Web export 61.1 → 55.2 MB; APK 107 → 101 MB.

PNG is a good *variable-rate* lossless compressor, and ETC2/ASTC are
*fixed-rate* at 8 bits per pixel — so on disk a well-compressed PNG can
be smaller than its compressed form, and swapping them barely moves the
download. (A prediction that the APK would do "considerably better"
than the web build was made here and was wrong: both saved about 6 MB.)

**The ~192 MB of VRAM is the entire point.** Fixed-rate is exactly what
makes it a win in memory: 32 bpp becomes 8 bpp, always, which no amount
of PNG cleverness can do because the GPU cannot sample a PNG.

Checked by rendering all three side by side before and after: no
visible difference, which is the expected result at any distance a
fight happens from.

**To revert**, set `compress/mode=0` in the twelve
`assets/models/*_N.png.import` files and re-import.
