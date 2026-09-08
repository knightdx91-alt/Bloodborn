# Marrowmark — Interface & Information Design

**Players should be looking at the world, not at menus.** That is the
whole brief, and most of this document is working out how to hold that
line at the places where it is genuinely hard.

The design has been refusing interface for a long time already: no
quest markers (L29), no guard indicator (L65), no disposition number
(L47), no glowing attack tells (`combat.md` §6), no tutorial popups
(L69). This document makes that a rule rather than a series of
coincidences.

---

## 1. The order of preference **[core — L80]**

For any piece of information the player needs, in strict order:

1. **Put it in the world.** A blade with notches in it. A man breathing
   hard. A wagon riding low on its axles.
2. **If it cannot go in the world, put it on screen briefly.** A
   contextual element that appears when it matters and leaves when it
   does not.
3. **If it cannot be brief, put it in the companion app** (§5).
4. **If none of those work, do without it.** Some information the
   player simply does not get, and that is a legitimate answer here in
   a way it is not in most games.

**Nothing is permanently on screen.** There is no persistent HUD — no
always-visible bars, no minimap, no compass, no hotbar, no objective
tracker. The default state of the screen is *the world and nothing
else*, and every element that appears must justify its appearance and
then leave.

## 2. The hard case: stamina

Stamina is the entire combat economy (L55) and it is precise. "Read it
from his breathing" is romantic and unfair — a player who cannot judge
their own remaining bar cannot make the decisions the combat is built
on.

**Answer: it appears while it is moving.** The bar fades in the moment
you spend or recover and fades out once you are full and rested. In a
fight it is effectively always visible; walking down a road it is never
there. The information is exact when it matters and absent the rest of
the time.

**The same rule covers everything of this kind.** Your own health
appears when it changes. An item's condition appears when it is struck.
Nothing sits there waiting.

**Your opponent gets no bars at all.** You read them the way L64/L65
already require: posture, breathing, how they hold the weapon, whether
their vambrace is still on. That asymmetry is deliberate — precise
knowledge of yourself, judgement about everyone else.

## 3. Legibility is itself a skill **[core — L81]**

The hardest interface problem in the design is crafting. L66 gives
materials four continuous properties, and a stat sheet with four
sliders is exactly the menu this document exists to avoid.

**Answer: what you can perceive depends on what you know.** A novice
handling a billet is told what a novice would notice —

> *heavy, and there is dirt in it*

— while a master reads the same billet closely:

> *dense, near enough pure; it will take an edge but it will not
> forgive a hard quench*

Same object, same screen, different reader. **Appraisal is a skill
that grows by use** like any other (L18/L71), so the interface sharpens
as the character learns, and a beginner is never shown numbers they
have not earned the ability to read.

Three things this buys, none of which needed inventing:

- **Appraisal becomes a real profession.** Someone who can read
  materials and finished goods accurately is worth hiring, and worth
  lying to.
- **It explains second-hand markets.** Buying a used blade off a
  stranger is a genuine risk if you cannot read it, and reading the
  maker's mark (L68) is how you hedge.
- **It removes the tutorial problem.** Nobody has to be taught what
  "hardness 0.62" means, because nobody is ever shown it.

**No numbers anywhere in the fiction.** Not on materials, not on
weapons, not on damage dealt. Numbers are a developer's tool and belong
in `sim/`, not on a player's screen.

## 4. Maps are made by people **[L82]**

No minimap, no compass, no player marker, and **no map you were simply
given**.

A map is **a physical item somebody made** — a crafted good with a
maker's mark like anything else (L4/L68). It shows what its maker knew,
it is wrong in the places they never went, and a better one costs more.
Cartography is a trade.

This is not austerity for its own sake. It does more work for less than
almost anything else in the design:

- **It makes L28's distance real.** Travel is navigation rather than
  following a line.
- **It gives exploration a product.** A player who has been somewhere
  has something to sell.
- **It makes directions matter.** `onboarding.md` has NPCs giving
  landmark directions — *"up the north road, past the burnt mill"* —
  which only means something in a game where you do not already have a
  marker.
- **It fits the rumour layer.** A map is a physical rumour, with the
  same properties: sourced, dated, and possibly wrong.

## 5. The companion app absorbs the density **[L83]**

Some information is genuinely dense: shop ledgers, price histories,
commission queues, war declarations, arena odds, the Monument feed.
Presenting it in-world would mean building the menus this document
forbids.

**So it does not go in the world. It goes in the app** (L31), which
already exists for exactly this and was described as *"the shopkeeper's
evening glance, not a second job."*

This is the pressure valve that makes minimalism affordable. **The
in-game interface can stay clean precisely because there is somewhere
else for the spreadsheet to live** — and that somewhere is optional,
asynchronous, and never gameplay-critical (L31), so a player who never
touches it loses convenience rather than capability.

**Hard limit:** anything a player must consult *during play* cannot
live only in the app. The app is for the life you leave running, never
for the fight you are in.

## 6. Specific rulings

| Thing | Ruling |
|---|---|
| Damage numbers | **Never.** Not floating, not in a log |
| Minimap / compass | **Never.** Maps are items (§4) |
| Quest log | **Never** (L29). You remember, or you ask again |
| Objective markers | **Never** |
| Nameplates | Only within speaking distance, and only names you have actually been told. A stranger is a stranger |
| Hotbar | No. Weapons are drawn, not selected from a row |
| Inventory | A pack you open — things laid out, not a spreadsheet. Encumbrance is felt (L55/L57), not read |
| Item condition | Visible **on the item** — notches, rust, a cracked strap (L62/L63) |
| Loot notifications | No. You picked something up; it is in your pack |
| Skill-up notifications | No. `onboarding.md` L69 — a master notices you got better; a popup does not |
| Market board | A physical board in a town you walk to. A list, but a *diegetic* list on paper |
| Epoch changes | Announced by **how people talk** (§9.6), never by a banner |

## 7. What this costs

- **Some players will be lost.** Combined with L64/L65 and no markers,
  a player used to modern conveniences has a great deal to get used to
  at once. `onboarding.md` §6 already accepts this cost; this document
  adds to it and should be read as part of the same bet.
- **Accessibility must not be sacrificed to purism.** Subtitles,
  colourblind-safe cues, remappable controls, adjustable text size and
  audio cues for the visually impaired are **not HUD clutter** and are
  never traded away for minimalism. The rule is "no unnecessary
  interface," not "no accommodations."
- **Diegetic information is expensive.** Reading condition off a blade
  means modelling wear on the blade; reading exhaustion off a body
  means animating it. This pushes cost onto art, which is already the
  scarcest resource (`tech.md` §1).

---

## Open questions

- [ ] Where does the appraisal skill's descriptive vocabulary come
      from — authored bands per property, or generated phrasing (L48's
      noun-space constraint would apply)?
- [ ] How does a player track a commission they accepted, with no quest
      log? (Leaning: a physical contract in your pack, and the app.)
- [ ] Are maps consumable, copyable, or annotatable by their owner?
- [ ] What does the pack actually look like — a grid, a list, or
      something physical? The one place a real UI has to exist.
- [ ] Does the stamina bar's fade timing need to differ between combat
      and travel, or does one rule cover both?
- [ ] Controller-first navigation for the few menus that do exist
      (L15) — the pack, the market board, character creation.
