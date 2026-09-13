# Spec v3: a character that animates

**Supersedes `SPEC-humanoid-v2.md`.** Standalone — no prior context
needed.

---

## The one rule

> ### Every file must be a direct download from mixamo.com.
> ### Do not open Blender. Do not rebuild, convert or re-export anything.

Two previous attempts failed for the same reason: the character passed
through Blender, and Blender's FBX exporter bakes a Z-up→Y-up rotation
into the skeleton's rest pose. Mixamo's clips do not expect it, so the
mesh explodes when animated.

**The bone names were never the problem.** v2 had all 65 names correct
and still did not work, because rest *orientation* also has to match.
The only reliable way to guarantee that is for the character and the
clips to come out of the same place. Anything that re-exports the
character breaks it again, however careful the settings.

---

## What to do

**1. Pick a character on mixamo.com.**

Use any of Mixamo's own free characters — `X Bot` or `Y Bot` are ideal
(plain grey mannequins, exactly right for a placeholder). Do **not**
upload or auto-rig a custom mesh; that is a slower path to the same
place and adds a failure mode.

**2. Download the character.**

- Format: **FBX**
- Pose: **T-pose**
- Save as `models/humanoid.fbx`, replacing the existing file.

**3. With that character still selected, download these seven clips.**

Each one: **FBX**, **Without Skin**, **30 fps**, all other settings
default.

| Save as | Mixamo animation |
|---|---|
| `animations/anim_Idle.fbx` | Idle |
| `animations/anim_Walking.fbx` | Walking |
| `animations/anim_Running.fbx` | Running |
| `animations/anim_Quick_Roll_To_Run.fbx` | Quick Roll To Run |
| `animations/anim_Stable_Sword_Outward_Slash.fbx` | Stable Sword Outward Slash |
| `animations/anim_Sword_And_Shield_Slash.fbx` | Sword And Shield Slash |
| `animations/anim_Hit_Reaction.fbx` | Hit Reaction |

**Selecting the character before downloading is the step that makes
this work.** It is what makes the clips' skeleton identical to the
character's rather than merely similarly named.

**4. For the walk and run, also tick "In Place"** if the option is
offered. Movement comes from the game's own character controller; root
motion in the clip fights it.

**5. Commit all eight files.** Nothing else needs to change.

---

## The only test that matters

**Open the character and any one clip together and confirm the
character animates cleanly — limbs attached, standing upright.**

That is the whole acceptance criterion. Do not rely on bone counts,
names, or scale: **v2 passed every one of those checks and still did
not work.** If a viewer is not to hand, say so rather than assuming —
it will be verified downstream either way.

---

## What is explicitly *not* wanted

- **No `WeaponSocket` bone.** Weapons attach in-engine to
  `mixamorig_RightHand`. Adding a bone risks breaking the match.
- **No Blender step of any kind**, including "just to check the scale"
  or "just to re-export cleanly". Opening and saving the file is what
  breaks it.
- **No changes** to `weapon_*.fbx`, `dummy.fbx` or `arena.fbx`.
- **No custom mesh.** The body Muse built in v2 is good work, and it
  can come back later through Mixamo's auto-rigger once the pipeline is
  known to work. For now the goal is a character that moves, not a
  character that is ours.

---

## Why this is worth doing exactly as written

The prototype currently has a capsule that slides. Everything else —
the combat rules, stamina, damage, durability — is written and tested.
A rigged character that plays a walk and a roll is the single missing
piece between that and something recognisable as a game.

Two rounds have been spent on this. The third should be four downloads
and a commit.
