# Spec v4: characters that look like people

**Read `SPEC-character-v3.md` first.** Its rule still holds, with one
addition that v3 did not cover — see "The auto-rigger" below.

The prototype currently uses **X Bot**, a grey mannequin. It was the
right choice: it proved the pipeline and it animates perfectly. It is
also obviously a mannequin, and the game should look like the game.

---

## Do the cheap thing first

**Mixamo has about seventy of its own characters, already rigged to the
skeleton every clip in this repo uses.** That is the v3 path exactly —
select the character, download it, download the clips against it — and
it is known to work because it is what we already did.

**Try this before anything else.** Two characters are wanted, and they
should not be the same person:

| Save as | Who |
|---|---|
| `models/player.fbx` | The player. A plain, capable-looking fighter |
| `models/enemy.fbx` | The opponent. Visibly a different silhouette |

Format: **FBX**, **T-pose**, plain FBX — *not* the "FBX for Unity"
option, because the engine is Godot (L54).

**Then re-download all the clips with each character selected**, same
as v3 — that is the step that makes them play with no retargeting.
Clips downloaded against X Bot may still work, but do not assume it;
selecting the character is cheap insurance.

### What to pick

`design/art-audio.md` (L85) is specific and it rules things out:

> **Naturalistic, never stylised.** A bespoke stylisation cannot be
> matched by purchased assets, so every new asset would need
> hand-reworking, which is exactly the labour being avoided.

So: **no cartoon proportions, no big heads, no bright colours.** The
game is grounded medieval — mud, wool, leather, iron. A knight, a
soldier, a plain armed traveller. Avoid anything sci-fi, modern, or
obviously superheroic. If Mixamo's fantasy characters look dated, a
plain human in ordinary clothes beats a dated fantasy hero.

Keep it **readable in silhouette** — `combat.md` §6 has the player
reading attacks off the body, and art-audio.md §4 says silhouettes
overlap in a crowded fight.

---

## The auto-rigger, if none of them fit

If nothing in Mixamo's library works, **Mixamo will rig a mesh you
upload** and hand it back on the same skeleton. **This is still a
direct download from mixamo.com**, so v3's rule is not broken — v3
forbade *Blender*, and the auto-rigger is not Blender.

1. Find a naturalistic humanoid mesh — T-pose or A-pose, no rig needed.
2. Upload it to mixamo.com and let the auto-rigger do the skeleton.
3. Download the result as FBX, then the clips with it selected.
4. **Still no Blender at any point.**

This path has never actually been tried here, so if you take it, say
so — it will be checked carefully rather than assumed.

---

## ⚠️ Do NOT buy an armour set yet

This is the important part, and it is why this spec asks for two
characters rather than a wardrobe.

`design/pillars.md` **L63** says armour is tracked across **head,
torso, arms and legs**, each with its own condition, and:

> A piece that breaks does not merely stop protecting — **it comes
> off**, and that slot is bare for the rest of the fight... a fighter
> who started the day in plate finishes it half bare and increasingly
> desperate. That progression is legible to everyone watching.

**A character with its armour baked into one mesh cannot do that at
all.** Most bought characters, and all of Mixamo's, are exactly that.
That is fine for now — there is no armour system yet — but it means
**any armour bought on the assumption of a fused character is money
thrown away.**

The modular question has to be settled before that purchase, not after.
It is flagged in `STATUS.md`.

---

## The test that matters

**Play the walk, the roll and a slash on each character and confirm it
moves cleanly with no retargeting** — same acceptance test as v3, and
for the same reason: bone counts and file sizes prove nothing.

Then look at the two of them standing side by side. **Could you tell
them apart at a glance, in silhouette, with the colour turned off?**
If not, pick a different pair.

---

## Not wanted

- **No Blender**, for any reason, at any point.
- No stylised or cartoon characters (L85).
- No visual effects, glow, or magic (L7/L36: nothing depicts magic).
- Don't worry about matching height exactly — the engine measures the
  character rather than assuming, and the capsule is 2m tall.
- If a character comes holding its own weapon, say so. The prototype
  puts a sword in the right hand itself and two swords will look
  ridiculous.
