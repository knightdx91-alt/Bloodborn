# Spec: four directional dodge clips

**Read `SPEC-character-v3.md` first.** Its one rule applies here without
exception:

> ### Every file must be a direct download from mixamo.com.
> ### Do not open Blender. Do not rebuild, convert or re-export anything.

The character delivered under v3 works perfectly. Nothing about it
should change. This asks only for four more clips against **the same
character**.

---

## Why

The dodge is in the game now and you can play it. It uses the roll out
of `anim_Quick_Roll_To_Run.fbx`, which is the only roll in the repo, so
the character is **turned to face wherever it is dodging** before it
rolls. Dodging left means spinning left and rolling forward.

That is wrong, and it is wrong in a way that matters. `design/combat.md`
§1 (L56) says:

> A dodge repositions, it does not merely evade. Dodging *toward*,
> *around* and *through* are all real options, so exchanges circle
> rather than shuffling back and forth on a line.

Circling around someone requires dodging sideways **while still facing
them**. With one forward roll, you cannot keep your eyes on an opponent
while moving around them — which is most of what the design wants the
dodge to be for.

---

## What to do

With the **same X Bot character selected** on mixamo.com — the one
already delivered — download these four clips.

Each one: **FBX**, **Without Skin**, **30 fps**, **In Place** ticked if
offered, all other settings default.

| Save as | Mixamo animation |
|---|---|
| `animations/dodge_forward.fbx` | Standing Dodge Forward |
| `animations/dodge_backward.fbx` | Standing Dodge Backward |
| `animations/dodge_left.fbx` | Standing Dodge Left |
| `animations/dodge_right.fbx` | Standing Dodge Right |

**If those exact names are not in the library**, any four short
sidestep, dive or roll clips that move in the four directions will do.
Say which ones you used. What matters is:

- **All four from the same character**, same as last time.
- **Each moves in a different direction** — forward, back, left, right.
- **Each is short**, ideally under a second. The dodge is 0.70 seconds
  of game time and the clip gets stretched to fit; a three-second clip
  will look like slow motion.
- **The character faces the same way throughout.** A clip that turns to
  face its direction of travel is the thing being replaced and is no
  use.

Keep `anim_Quick_Roll_To_Run.fbx`. It stays as the roll for a dodge
taken at a sprint, which is a different move from a standing sidestep.

---

## The only test that matters

**Play each clip on the character and confirm it moves in the direction
its name claims, without turning to face that direction.**

Same as last time: bone counts and file sizes prove nothing. If you
cannot play them, say so — it will be checked downstream either way.

---

## Not wanted

- No Blender step, for any reason, including checking the scale.
- No changes to `models/humanoid.fbx` or any existing clip.
- No new character.
