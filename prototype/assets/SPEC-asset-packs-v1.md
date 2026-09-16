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

### Better fit: KayKit (Kay Lousberg), all CC0

Grounded stylised medieval rather than cartoon — knights, barbarians,
rogues, skeleton warriors. Verified live and CC0, 2026-09-16.

- **KayKit Adventurers** — https://kaylousberg.itch.io/kaykit-adventurers
- **KayKit Skeletons** — https://kaylousberg.itch.io/kaykit-skeletons
- **KayKit Character Animations** — https://kaylousberg.itch.io/kaykit-character-animations
- Everything, bundled — https://kaylousberg.itch.io/kaykit-complete

The characters and the animation pack are from the same author and built
for each other, which is the rig-and-clips rule below satisfied by
construction.

### 2. Enemies

`brute.fbx` and `raider.fbx` work but are procedural placeholders.

- **Ultimate Monsters** — 50 fully animated monsters.
  https://quaternius.com/packs/ultimatemonsters.html
- **Knight Character** — one knight, many animations, swords and helmets.
  https://quaternius.com/packs/knightcharacter.html

### 3. Animals

The boar is in use and fine. A pack would give a wolf that matches it,
and more animals for later.

- **Ultimate Animated Animals** — 12 animals, 12+ animations each
  (attack, death, gallop, walk, jump).
  https://quaternius.com/packs/ultimateanimatedanimals.html

### 4. Animation library, if a shared clip set is wanted

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
