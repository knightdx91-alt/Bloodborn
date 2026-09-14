# Spec: three attack clips that read differently, and a guard

**Read `SPEC-character-v3.md` first.** Its one rule applies without
exception:

> ### Every file must be a direct download from mixamo.com.
> ### Do not open Blender. Do not rebuild, convert or re-export anything.

Same X Bot character as before. This asks for **four clips**, and it is
the most design-critical asset request so far.

---

## Why this one matters more than the others

`design/combat.md` §6 is unusually blunt about it:

> Readability comes from animation and sound only. No glowing weapons,
> no red flash, no on-screen prompt... **This is a hard art and audio
> requirement, not a stretch goal — if the animation doesn't read, the
> combat doesn't work, and no UI band-aid will save it.**

The enemy now throws three different attacks, and the player is
supposed to answer each one differently:

| Shape | Wind-up | Answer |
|---|---|---|
| **Quick** | 0.22s | Dodge |
| **Heavy** | 0.62s | Parry — highly rewarded |
| **Committed** | 1.00s | Get out of the way. **Cannot be parried** |

**Right now the heavy and the committed play the same clip at
different speeds.** The timing difference is real and does carry some
of the read — but two attacks that differ only in speed are two
attacks a player will confuse under pressure, and confusing a
parryable attack with an unparryable one is the worst possible
confusion in this design.

---

## What to do

With the **same X Bot character selected** on mixamo.com, download
three clips. Each one: **FBX**, **Without Skin**, **30 fps**, **In
Place** if offered, everything else default.

**Plain FBX — not the "FBX for Unity" option.** The engine is Godot.

| Save as | What it needs to be |
|---|---|
| `animations/attack_quick.fbx` | A short, sharp one-handed jab or slash. Minimal wind-up. It should look *cheap* — like something thrown away, not committed to |
| `animations/attack_heavy.fbx` | A big overhead or diagonal chop with a clear **weight shift** — a shoulder dropping, a foot planting. The wind-up is the whole point and should be over half the clip |
| `animations/attack_committed.fbx` | A whole-body swing: a spin, a lunge, a two-handed horizontal sweep. It should look like something that **cannot be stopped once started**, and like it would hurt |
| `animations/guard.fbx` | A braced defensive stance — see below |

Mixamo names that tend to fit (use your judgement, and say what you
picked):

- Quick — "Sword And Shield Slash", "Stable Sword Outward Slash",
  "Sword And Shield Attack"
- Heavy — "Great Sword Slash", "Sword And Shield Kick"... anything with
  a visible rear-back
- Committed — "Great Sword Spinning Slash", "Sword And Shield Jump
  Attack", "Mma Kick"... anything whole-body

---

## And one more: the guard

`animations/guard.fbx` — **a braced defensive stance.** Weight back,
blade or shield up across the body, ready to turn something aside. A
short loop or a still pose both work; it gets held rather than played
through.

This one is load-bearing for a different reason. `design/combat.md`
§1 (L65) says the guard is read **off the body**:

> No indicator, no marker, nothing on screen... **This makes animation
> quality load-bearing rather than decorative**: if a guard pose does
> not read at a glance, the combat does not work, and no UI element may
> be added to rescue it.

Right now the parry borrows the hit-reaction clip played at half speed,
which is a placeholder for **the single most load-bearing pose in the
design**. Any Mixamo clip with a clear braced stance will do far better
— "Sword And Shield Block", "Sword And Shield Block Idle", or any
guarding idle.

---

## The test that matters

**Play the three side by side and freeze each one 80% of the way
through its wind-up — before the blade moves.** At that frozen moment,
**could you tell which is which?**

That is exactly the decision a player has to make, with less time and
under pressure. If two of them look the same frozen, they are the same
attack as far as the game is concerned.

If you cannot play them, say so — it will be checked downstream either
way.

---

## Not wanted

- No Blender step, for any reason.
- No changes to the character or any existing clip.
- **No glowing, no colour, no effects.** §6 forbids them by name. The
  read has to come out of the body.
- Don't worry about the clips being different lengths. They get
  windowed and re-timed in engine — `fighter.gd` places each clip's
  fastest moment inside its live-blade window automatically.
