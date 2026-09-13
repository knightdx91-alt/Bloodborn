# Prototype asset set — Stage 1

Placeholder-grade models and animation clips for the Stage 1 combat
prototype (`tech.md` §6). Not shipping art.

## Models (`models/`)

Built 2026-09-12 by `tools/build_assets.py` (Blender 4.5.1, headless),
structurally validated through FBX re-import (`tools/validate.py`):

- `humanoid.fbx` — 1.735 m playable humanoid, 1,236 verts, 21-bone
  Unity-Humanoid-style armature, A-pose, `WeaponSocket` on right hand.
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

All seven verified: 65-bone Mixamo rig, 52 animated bones, real keyframe
data. Retarget to the humanoid via Humanoid rig (Unity) or bone-map
retarget (Godot).

## Regenerating the models

```
blender -b -P tools/build_assets.py
blender -b -P tools/validate.py
```

Requires Blender 4.x on PATH. Animation clips are downloads, not
generated — see the table above for their Mixamo names.
