# Spec: free character and creature packs

**For Muse.** Standalone — no prior context needed. Links verified
2026-09-16 (all pages live, all licences confirmed CC0).

---

## What to get, in priority order

### 1. Townsfolk — the biggest visual win in the game

Thornfield has **34 named and crowd NPCs** and every one of them is
`humanoid.fbx`, a blocky grey placeholder. They stand in a town built
from good Quaternius assets, and the player walks past them constantly.
Replacing them changes how the game looks more than anything else on
this list.

- **Ultimate Modular Characters** — 11 characters, 24 animations, each
  split into 4 swappable models so combinations multiply.
  https://quaternius.com/packs/ultimatemodularcharacters.html
- **RPG Characters** — 6 rigged, animated, textured fantasy characters.
  https://quaternius.com/packs/rpgcharacters.html
- **Universal Base Characters** — 6 bodies, 20 hairstyles, humanoid rig
  built for retargeting. (itch only, no direct link on the site.)
  https://quaternius.itch.io/universal-base-characters

### ⚠️ Ultimate Monsters arrived, and it is the wrong pack — 2026-09-16

**In the repo at `assets/monsters/` (50 glTF, 31 MB, CC0) and I would
not ship it.** Rendered beside the paladin, the verdict is quick:

- **Technically excellent.** 43-bone rigs, **14 animations each** —
  Idle, Walk, Run, Punch, HitReact, Death, Jump — imported clean into
  Godot 4.3 with no unit problem and their feet on the origin. This is
  what an asset delivery should look like.
- **Tonally wrong for this game.** They are bright cartoon platformer
  monsters: a grinning green goblin in a bowler hat, a red pantomime
  devil, a googly-eyed blue yeti, a pink-mohawk skeleton. The licence
  file says it plainly — "Ultimate Platformer Pack". Marrowmark is
  M-rated grounded dark fantasy (`art-audio.md`), and these would read
  as a different game.
- **About 3x too big.** ~3.2 m tall against the player's ~1.8 m. Any
  use needs ~0.55x scaling.

**That miss is mine.** I recommended the pack off its description — "50
fully animated monsters, CC0" — without looking at it. The lesson is the
same one this project keeps relearning: *look at the frame.*

A couple of the least cartoonish (`Big/Orc_Skull`, `Big/Demon`) could
serve as scaled placeholders if something is needed in the Hedges before
better art exists. Nothing else in the pack should go near the game.

### ⚠️ KayKit arrived, and I was wrong about it — 2026-09-16

**In the repo at `assets/kaykit/` (911 models, 74 MB, CC0). Do not ship
any of it.** The evidence is committed beside this file:

- `evidence/kaykit-characters-vs-paladin.png`
- `evidence/kaykit-props-vs-paladin.png`

**The characters are chibi.** Three heads tall, enormous round heads,
cute faces. Beside the paladin they read as a different game — the same
failure as Ultimate Monsters, in the same week. They are also oversized:
**2.17–2.44 m against the paladin's 1.73 m**, measured from visible
geometry.

**And it is not only the characters.** The props are authored to match
them, so the whole set carries the same cartoon language: a dungeon
barrel is **2.00 m — taller than the player**, `sword_A` is **1.77 m**,
the masonry is rounded pillows and the forest trees are lollipops.
There is no subset of this that sits next to a grim realistic knight.

Technically it is a good delivery, which is exactly what made it easy to
recommend blind:

- Nine rigged characters on **one 41-bone rig**, identical rest poses,
  **76–95 clips each**, feet on the origin, no unit problem.
- The `Rig_Medium` library's 23 bones are an **exact subset** of those
  41 (the rest are IK controls), so its ~139 clips retarget by
  construction.
- `handslot.l` / `handslot.r` are dedicated weapon-attachment bones.
- Every equipment variant ships **visible in the same file** — the
  Knight renders holding three swords and four shields until you hide
  them. Worth knowing for anyone who uses this pack for something else.

**The miss is mine, and it is the second one.** I put KayKit in this
document as *"grounded stylised medieval rather than cartoon"*, written
off the itch.io page — in the same edit where I apologised for
recommending Ultimate Monsters off its description. Muse then spent
real effort fetching 74 MB on that sentence.

### Rule, from paying for this twice

**Nothing goes in this document as a recommendation until it has been
rendered next to `paladin.fbx` and the frame has been looked at.**
Storefront copy describes *genre*, not *proportion*, and proportion is
what decides whether an asset can share a screen with the player. A pack
that is CC0, cleanly rigged, correctly scaled and well animated can
still be unusable, and none of the checks in this document catch it —
only the frame does.

Where a pack has not been rendered yet, it is listed below as a
**candidate**, never as a recommendation.

### ✅ RPG Characters, rendered — usable, with one number to change

**In the repo at `assets/rpg-characters/` (6 characters, CC0) and this
one passes.** Evidence: `evidence/rpg-characters-vs-paladin.png`, shown
scaled to the paladin's height rather than at their authored size,
because a wide shot of oversized models flatters everything.

Adult proportions, muted palette — leather, steel, teal, brown. Stylised
rather than realistic, so they read as a lighter register than the
paladin, but they are the same *kind* of thing and could share a screen
with him. Nothing about them is anachronistic or cartoon.

- **Scale: authored at ~3.0 m, needs a uniform 0.58x.** That is a plain
  scale, not a unit mismatch — nothing like the centimetre armatures
  below, which need converting rather than scaling.
- **32-bone rig, 11–15 clips each**, including `Idle` and `Run`.
- **No `Walk` clip**, which is what `npc/npc.gd` plays. Anything using
  these as townsfolk needs that gap closed first.

### ❌ Knight Character — 5.60 m and untextured

Same render. `KnightCharacter.fbx` is the undressed base body — the
helmets, shoulder pads and weapons are separate files — so on its own it
is a featureless grey mannequin, and it is **5.60 m** against the
paladin's 1.73. Not usable without the dressing work, and the dressing
work is only worth doing if something needs it.

### 2. Enemies — candidates, none rendered yet

`brute.fbx` and `raider.fbx` work but are procedural placeholders.

- **Ultimate Monsters** — 50 fully animated monsters.
  https://quaternius.com/packs/ultimatemonsters.html
- **Knight Character** — one knight, many animations, swords and helmets.
  https://quaternius.com/packs/knightcharacter.html

### 3. Animals — candidates, none rendered yet

The boar is in use and fine. A pack would give a wolf that matches it,
and more animals for later.

- **Ultimate Animated Animals** — 12 animals, 12+ animations each
  (attack, death, gallop, walk, jump).
  https://quaternius.com/packs/ultimateanimatedanimals.html

### 4. Animation library, if a shared clip set is wanted — candidate

- **Universal Animation Library** — 120+ humanoid animations.
  https://quaternius.itch.io/universal-animation-library
- **Universal Animation Library 2**
  https://quaternius.itch.io/universal-animation-library-2

Downloads on `quaternius.com` are behind a Google Drive folder reached
from the page's Download button. The itch.io ones are name-your-price.

---

## The rules these have to satisfy

**Everything below is a lesson this project already paid for.**

### CC0, and recorded

The town kit is already Quaternius CC0 (`assets/town/LICENSE-QUATERNIUS-CC0.txt`).
Keep the licence file with anything new, in the same shape.

### Metres, never centimetres

`brute.fbx` and `raider.fbx` were delivered with armatures in
**centimetres** — pelvis rest at 104.27, with a 0.01 scale on the
armature node to compensate. That looks perfectly correct standing
still, and folds the body into a heap the instant a metre-authored clip
drives the pelvis. The engine converts them now
(`Fighter._match_units()`), but the file is still wrong.

**Check before delivering:** the pelvis bone's rest position should be
about **1.0**, not about **100**.

### The rig and its clips must come from the same place

`SPEC-character-v3.md` is the standing rule and it is worth re-reading.
Its short form is "every file must be a direct download from
mixamo.com", but the reason is more general: **a rig and the clips that
drive it have to agree about rest orientation and units**, and the only
reliable guarantee is that they were authored together.

So a pack that ships its characters *and* its animations is ideal, and
is why the Quaternius packs above are preferred over mixing sources.
A Mixamo character must still never pass through Blender — that bakes a
Z-up→Y-up rotation into the rest pose and the mesh explodes.

### Format

FBX or glTF. Godot 4.3 imports both. glTF is generally less trouble.

### How to check it worked

`prototype/rigcheck.gd` renders every humanoid walking and measures the
pelvis in world space. A collapsed rig sits near zero; a correct one is
about a metre above the feet. It runs the two known-good Mixamo
downloads as controls so it cannot pass vacuously.

### ⚠️ RPG Characters committed — rig note for integration, 2026-09-16

The pack is in the repo at `prototype/assets/rpg-characters/` (6 class
glTFs + 6 weapon FBXs, commit `702cb0f`, CC0). They look right for the
game, but one integration constraint matters:

**They use Quaternius's simple ~33–39-bone rig, NOT the 65-bone
Mixamo/humanoid rig.** Mixamo clips and the Universal Animation Library
clips will not retarget onto them — different bone counts, different
hierarchy. Use each class's baked clips (11–15 per character: attacks,
spell casts, bow draw/shoot, dagger combos, roll — full lists in
`prototype/assets/README.md`).

The pack also ships separate "Humanoid Rig Versions" FBXs built for the
65-bone family — kept in the workspace asset library, not committed, in
case a future pass wants to swap skeletons. The committed glTFs were
judged more immediately useful as-is.
