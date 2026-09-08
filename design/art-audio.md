# Marrowmark — Art & Audio Direction

**Art here is not decoration. It is the interface.**

Every information channel this design refused — the guard indicator
(L65), the HUD (L80), the stat sheet (L81), the quest marker (L29), the
glowing attack tell (`combat.md` §6) — was refused on the assumption
that a picture and a sound would carry it instead. This document is the
bill for those decisions.

The test for any art or audio choice is therefore not *does it look
good* but **does it tell the player what they need to know.**

---

## 1. Functional requirements — what art must deliver **[core — L84]**

These are load-bearing. If any one fails, a locked system fails with
it and there is no interface fallback to add.

| Must read at a glance | Serves |
|---|---|
| **Attack shape** — quick, heavy, or committed | `combat.md` §6 |
| **Attack arc** — which of five directions, plus thrust | L64 |
| **Guard direction** — how the weapon is held | L65 |
| **Exhaustion** — an opponent has no stamina bar | L80 |
| **Weapon wear** — nicks, notches, a dulled edge | L60, L62 |
| **Armour loss** — a piece breaking and falling away | L63 |
| **Disposition** — an NPC's regard, never a number | L47 |
| **Material character** — heavy, dirty, fine | L66, L81 |
| **Maker's marks** — findable on the object | L68 |
| **Where you are** — no minimap exists | L82 |

**None of this may be rescued with UI.** That is the whole point: if a
guard pose does not read, the answer is a better pose, never an
indicator.

## 2. Readability rules

- **Silhouette carries the shape.** A heavy wind-up must be
  identifiable from the outline alone, at distance, in poor light,
  against a crowd.
- **Weight is the vocabulary.** Foot plants, shoulder drops, hips
  leading the blade. `combat.md` §6 names the weight shift as the tell,
  and that means animation is authored for legibility before beauty.
- **No emissive tells.** No glowing weapons, no red flashes, no
  outlines. L20 is grounded, and a game that resorts to a coloured
  flash has admitted its animation failed.
- **Contrast over saturation.** Dark here means *low light*, not
  desaturated mud. The grey-brown cliché is both a visual dead end and
  genuinely worse for reading a fight.
- **The camera is a participant.** Framing, shake and depth of field
  are information channels — an exhausted character's camera behaves
  differently. Cheap, and it does work no HUD element is allowed to.

## 3. Regional palette replaces the minimap **[L86]**

L82 removed the minimap and made maps player-made goods. Something has
to carry orientation, and **the land does it.**

Each of the six wedges gets a distinct palette, light quality,
vegetation, stone and architecture — enough that **a screenshot is
locatable**. You know which wedge you are in the way you know which
county you are in: it looks like itself.

This is not decoration either. It serves:

- **Navigation** without an interface (L82).
- **Regional materials** (L21) — ore from a red-stone wedge should
  *look* like it came from there, and a finished blade should carry a
  hint of where its metal was dug.
- **The capitol as a mixing point** — the one place all six palettes
  meet, which is what a capitol should feel like.

## 4. Audio carries what the eye cannot **[L87]**

Audio is the second information channel, and in one case it is the
primary one.

- **Impact tells you what happened.** A cut biting flesh, a cut
  skipping off plate, a mace finding mail — these are different sounds,
  and **that is how the damage triangle (L66/`combat.md` §4) reaches a
  player who is never shown a number.** You hear that your weapon is
  wrong for this armour before you have worked it out.
- **Attack shapes have audio tells** — the scrape of a heavy draw, the
  breath before a committed swing. Redundancy with the visual is
  deliberate: it survives a crowded battle where silhouettes overlap.
- **Exhaustion is audible.** Breathing is the stamina bar your opponent
  does not get.
- **Wear is audible.** A ruined blade rings wrong. A player who is not
  looking at their weapon still knows.
- **Per-town accent families** (`brainstorm.md` §9.3), so a voice
  places a person before they say anything about themselves.
- **Silence is affordable.** No wall-to-wall score. Music is rare and
  earned, which makes the world feel large and makes the moments that
  do carry music land.

## 5. Achievability: the look comes from treatment **[core — L85]**

`tech.md` §1 commits to **buying content volume and building systems**,
because a solo developer cannot author thousands of assets. That
constrains the art direction absolutely, and the constraint is worth
stating plainly rather than discovering late:

**The identity must live in the treatment, not the assets.**

- **One lighting model, one post chain, one material response**,
  applied to everything. A coherent bought look beats an incoherent
  handmade one, and coherence is a property of the treatment.
- **Naturalistic, not stylised.** A bespoke stylisation cannot be
  matched by purchased assets, so every new asset would need
  hand-reworking — which is precisely the labour being avoided.
  Naturalistic assets from different sources can be unified by
  lighting; stylised ones cannot.
- **Grade for identity.** Palette, contrast curve and atmosphere carry
  more of the look than geometry does, and they are cheap to change
  globally and late.
- **Modular kits over bespoke geometry** (`tech.md` §1). The six towns
  differ by palette, layout, faith and trade — not by unique
  architecture.
- **Spend bespoke effort only where it is functional**: the animation
  set (§1), weapon and armour wear states, and the handful of
  landmarks players navigate by.

> **The one place to overspend: combat animation.** It is the largest
> content risk in the project (~300–400 clips, `combat.md` §1b) *and*
> the channel every refused interface element depends on. Buy the
> world; author or heavily rework the fighting.

## 6. Magic has no visual language yet — deliberately

**Nothing in the launch presentation depicts magic** (L7, L36). No
effects in trailers, no glow on a screenshot, no suspicious light in a
cellar. The game looks like what it says it is: a grounded medieval
world of trade and war.

When magic does appear it should look **wrong rather than
spectacular.** L56 caps the mortal world at what a human body can do,
precisely so that the first genuine violation lands hard. A spell
should read as a rule being broken, not as a firework.

**Incarnate true forms** (L34) mark the body with a visible tell that a
folklore-literate observer can read — which means these are *design*
work as much as art: each must be recognisable, describable in a
rumour, and unmistakable once seen.

## 7. What this costs

- **Animation is the budget.** §5's overspend is not optional, and it
  is the line item most likely to be underestimated.
- **Wear states multiply asset work.** Every weapon and armour piece
  needs readable damage stages (L60/L62/L63), which is a cost L80 and
  L81 added by refusing to show condition numerically.
- **Voice direction is a real discipline.** Per-town accents, NPC voice
  cards (§9.3), and the sparring teacher (L70) are performance work,
  not audio implementation.
- **Naturalism ages faster than stylisation.** Accepted knowingly: a
  stylised look would last longer but cannot be bought, and buying is
  what makes the project possible at all.

---

## Open questions

- [ ] The six regional palettes: what each wedge actually looks like.
      Content work, but it should be decided before any environment
      art is bought.
- [ ] How many wear stages per item class before the difference stops
      reading?
- [ ] Does the god's blood have a visual signature in the land, or is
      the world simply a world? (Leaning: barely — a hint in the stone
      near the Godsgrave, nothing a player would name without knowing.)
- [ ] Music: what earns it, and who writes it?
- [ ] Which marketplace ecosystems, and what the unifying treatment
      concretely is — the open question `tech.md` §1 already carries,
      now with an art-direction answer attached.
- [ ] Do NPC voice cards get authored performances, synthesis, or a
      mix? Ties directly to P11's open cost question against L27.
