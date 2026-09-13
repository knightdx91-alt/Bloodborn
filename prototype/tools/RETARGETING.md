# Retargeting the Mixamo clips

**The asset set does not work out of the box, and the gap is not
obvious from inspection.** `assets/README.md` says to "retarget via
bone-map"; this file is what that actually takes, and what it looked
like when it went wrong.

## The problem

| | Humanoid | Animation clips |
|---|---|---|
| Bones | **22** | **65** |
| Naming | `Hips`, `Spine`, `Chest`, `UpperArm.L` … | `mixamorig_Hips`, `mixamorig_Spine`, `mixamorig_Spine1` … |
| Exact name matches | **0 of 22** | |

Not one bone name is shared. Dropped into a scene as-is, **no clip
animates the character at all.**

## Three failures, in the order they happened

Each looked like success at the code level and was only caught by
rendering a frame and looking at it.

**1. Copying every track type.** Retargeting 22 tracks reported clean.
The character rendered as a **speck** — bone *positions* belong to the
source rig's proportions, and applying Mixamo's to a differently
proportioned skeleton collapses it.
→ **Rotation tracks only.**

**2. Copying rotations raw.** Proportions came back, and the character
rendered **lying on its side.** The two rigs rest at different angles,
so an absolute rotation from one lands wrong on the other.
→ **Take the delta from each rig's own rest pose:**
`out = target_rest * (source_rest⁻¹ * animated)`

**3. Root yaw.** Still outstanding — the character stands correctly but
faces roughly 90° off. Same class of problem at the hips.

## What the mapping drops

21 of 65 source bones map. The 44 dropped are Mixamo's fingers, its
extra spine joints (`Spine1`/`Spine2` collapse into one `Chest`), and
its head-top helper. `WeaponSocket` correctly receives no animation —
it is a static attachment point, not a joint.

## Usage

```
godot --headless --path . --script tools/retarget_mixamo.gd
```

Writes a retargeted `.tres` clip. The bone map is a dictionary at the
top of the script; extend it if the humanoid gains bones.

## The lesson worth keeping

**"22 tracks retargeted, 0 errors" was printed by all three broken
versions.** Nothing in the logs distinguished the speck, the corpse and
the standing character. The only thing that caught them was rendering a
frame and looking — which is the argument for the headless render loop
in `STATUS.md`, made concrete.
