# Spec: humanoid v2 — rebuild request

**Standalone brief.** Everything needed is below; no prior context
required.

---

## The ask, in one line

**Replace `models/humanoid.fbx` with a character that carries the
Mixamo skeleton and is exported at correct scale**, so the seven clips
in `animations/` play on it with no retargeting.

---

## Why

The current `humanoid.fbx` has two defects. Both were found by
importing it into Godot 4.3 and measuring, not by eye.

### Defect 1 — the skeleton does not match the animations

| | `humanoid.fbx` | `animations/*.fbx` |
|---|---|---|
| Bone count | 22 | 65 |
| Naming | `Hips`, `Spine`, `Chest`, `UpperArm.L` | `mixamorig_Hips`, `mixamorig_Spine`, `mixamorig_LeftArm` |
| **Exact name matches** | **0 of 22** | |

Dropped into a scene as delivered, **not one clip animates the
character.**

`README.md` says to "retarget via bone-map retarget (Godot)". That was
attempted — four iterations, each verified by rendering a frame:

1. Copying all track types → character collapsed to a point.
2. Rotation tracks only → character laid on its side.
3. Plus rest-pose delta correction → upright, facing wrong.
4. Plus global-frame conjugation → facing correct, **arms splayed and
   legs scissored**.

The textbook formula is now in `prototype/tools/retarget_mixamo.gd` and
still does not produce a clean pose, because the clips are authored
against a T-pose rig and this one rests in A-pose with different bone
axis conventions.

**Retargeting is the wrong fix for placeholder art.** A character that
already carries the Mixamo skeleton needs none of it.

### Defect 2 — the export is 100× too small

Measured in Godot, in skeleton space:

```
MAX bone distance from origin:  0.015 m
mesh AABB size:                 0.0069 x 0.00355 x 0.01735
```

`README.md` claims a "1.735 m playable humanoid". The mesh is
**1.735 cm**. It looks right on screen only because Godot's FBX
importer scales the root node to compensate.

This will break anything that measures the character — collision
capsule sizing, weapon socket offsets, camera framing, movement speed
tuning against `design/combat.md`.

---

## What to produce

### 1. A Mixamo-rigged humanoid

- Take the existing humanoid mesh (or an equivalent placeholder body of
  similar blockiness — shipping art is not wanted here).
- Upload it to **mixamo.com** and run the **auto-rigger**.
  - Mesh must be a single watertight body in **T-pose or A-pose**, arms
    clear of the torso.
  - Skeleton LOD: **standard (65 bones, with fingers)** — this matches
    the clips already in `animations/`.
- Download the rigged character as **FBX**.

### 2. Re-download the seven clips *for that character*

This is the step that guarantees a match. On Mixamo, with the rigged
character selected, download each animation as **FBX, "Without Skin",
30 fps**:

```
Idle
Walking
Running
Quick Roll To Run
Stable Sword Outward Slash
Sword And Shield Slash
Hit Reaction
```

Same filenames as now (`anim_Idle.fbx`, etc.), replacing the existing
files. Selecting the character before downloading is what makes the
bone hierarchy identical by construction.

### 3. Correct scale

The exported character must measure **approximately 1.7 m from foot to
crown in its own units** — not 1.7 cm.

In Blender: Scene units Metric, Unit Scale 1.0, and on FBX export set
**Apply Scalings: FBX All**, Scale 1.0. Verify before committing (see
below).

### 4. What is *not* needed

- **No `WeaponSocket` bone.** Godot attaches weapons with a
  `BoneAttachment3D` tracking `mixamorig_RightHand`; no rig
  modification required. Adding one to the armature only risks
  breaking the Mixamo match.
- **No changes to** `weapon_*.fbx`, `dummy.fbx` or `arena.fbx` — though
  if they share the same unit bug, fixing it is welcome. Check them the
  same way.

---

## Acceptance checks

Run these before committing. They are the exact checks that found the
defects.

**1. Scale** — in Blender, with the character selected, the Item panel
should report a Z dimension of roughly **1.7**, not 0.017.

**2. Bone names** — the rigged character's armature must contain bones
named `mixamorig_Hips`, `mixamorig_Spine`, `mixamorig_LeftArm`,
`mixamorig_RightHand` and so on. If the bones are named `Hips` or
`UpperArm.L`, the auto-rig step was skipped or the export renamed them.

**3. Bone count** — 65, matching the clips.

**4. The real test** — open the character and any one clip in Blender
or Godot together. The character should animate. **If it does not move,
the skeletons still do not match and the rest is irrelevant.**

---

## Done looks like

- `models/humanoid.fbx` — Mixamo-rigged, 65 bones, ~1.7 m, `mixamorig_*`
  naming.
- `animations/*.fbx` — the same seven clips, re-downloaded for that
  character, without skin, 30 fps.
- `README.md` updated with the real measurements rather than intended
  ones.

At that point the clips play directly, `tools/retarget_mixamo.gd`
becomes unnecessary, and the Stage 1 combat prototype can use a
character that walks instead of a capsule.
