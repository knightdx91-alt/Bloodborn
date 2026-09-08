# Marrowmark — Crafting

The specification behind L4 (the flagship system) and L38 (depth in the
ceiling, never the floor). Implemented and tested in
`sim/Marrowmark.Sim/Crafting/`.

Crafting is not a side activity in Marrowmark. **Every finished good in
the world is player-made** (L26), which means this system is the supply
side of the entire economy, the reason master crafters are famous, and
half of what the box is selling.

---

## 1. Materials have properties, not quality **[core — L66]**

Two lumps of iron differ along four continuous axes, each rolled within
the range its source allows. **Every axis costs something**; there is
no configuration that is simply best.

| Property | Buys | Costs |
|---|---|---|
| **Hardness** | takes and holds an edge — cutting and piercing power | brittleness; it fights toughness |
| **Toughness** | the item's life (L59's ceiling); resists shattering | nothing directly — but stages that buy it charge hardness |
| **Density** | blunt force, the answer to plate | weight, which eats stamina headroom (L55/L57) |
| **Purity** | nothing on its own | — it is a *multiplier on skill's reach* |

**Purity is the subtle one.** Clean stock does not make a better blade
by itself; it lets a good hand realise more of what the material
offers. That is why master smiths bid for clean ore and beginners
should not — and why the ore market has a shape more interesting than
"expensive is better."

**Density cutting both ways is the model in miniature.** A dense billet
makes a maul that ruins plate and a needle that pierces nothing, and
you carry the weight in your stamina bar all day. One number, three
consequences, no right answer.

## 2. Stages are trades, and skill decides your share **[core — L67]**

A pipeline is a sequence of hands-on operations — smelt, fold, quench,
temper, grind. **Every stage offers something and charges something.**

The crucial asymmetry: **skill scales what you collect; the charge is
the same for everyone.** A master and a beginner quenching the same
billet both lose the same toughness; the master walks away with far
more hardness for it.

That is L38 made mechanical:

- **No stage can hard-fail a patient beginner.** An unskilled hand that
  follows the steps still ends up with a better blade than it started
  with — guaranteed by a floor on realisation, and asserted by test.
- **The ceiling is enormous.** Same ore, same pipeline: a novice gets a
  serviceable sword, a master gets close to what the material was
  capable of.

Measured on current tuning, one ore through the standard blade
pipeline:

```
skill 0.00   H0.45 T0.45 D0.46 P0.45   cut 0.45   life x0.95
skill 0.50   H0.53 T0.52 D0.46 P0.54   cut 0.53   life x1.02
skill 1.00   H0.62 T0.59 D0.46 P0.63   cut 0.62   life x1.09
```

### Order is part of the craft

Gains meet diminishing returns — a stage moves a property towards its
ceiling — and costs scale with what is there to lose. So **each stage
acts on what the last one left**, and quench-then-temper is not the
same blade as temper-then-quench. A smith who understands why
tempering an unquenched billet is a wasted heat knows something worth
knowing, and no wiki can hand it to them as a number.

### The intermediate market

Because stages are separable, **a casual player can buy a well-made
billet and run only the stages they enjoy** — and still finish with
something better than doing every stage badly themselves (asserted by
test). L38 asks for exactly this, and it is why half-worked goods are a
market rather than an inconvenience.

## 3. Everything is signed **[core — L68]**

**Every finished item carries its maker's name — good work and bad.**
There is no anonymous path; the code has no overload that permits one.

- Reputation is **earned and losable**. Flooding a market board with
  rubbish costs a smith their name.
- Second-hand gear is **legible**: a buyer reads the mark and knows
  what they are getting, which matters enormously in an economy where
  goods physically travel and wear out (L59).
- Marks are **permanent and outlive their makers** (`tech.md` §4). A
  blade signed by someone long dead is a real object with a history.

## 4. How crafting reaches the rest of the game

- **Combat** — properties become damage by type (`combat.md` §4): cut
  from hardness, blunt from density, pierce from a hard *fine* point.
  Choosing a material is choosing a position in the damage triangle.
- **Durability** — toughness multiplies the item's ceiling (L59), so
  material choice decides how long a thing lives and how many repairs
  it has in it.
- **Encumbrance** — density is weight, and weight is stamina headroom
  (L55/L57). A heavy weapon is a standing cost, not a stat.
- **Wear** — a worn blade hits softer (L60), so the same item is a
  different weapon at 30% condition.

---

## Open tuning questions

- [ ] Property ranges per material source, and how regions differ
      (L21 makes materials regional — this is where that becomes real).
- [ ] Whether the novice-to-master gap (~1.4× on cutting power) is
      wide enough to build reputations on, or should be steeper.
- [ ] Order-dependence is currently real but subtle. Should a badly
      ordered pipeline be more punishing?
- [ ] Non-metal pipelines: leather, cloth, wood, bowyery.
- [ ] Recipe **discovery** (L4) — the system is built, but how a
      player learns that a stage exists is untouched.
- [ ] Failure states above the floor: a beginner cannot ruin a piece,
      but should they be able to waste *materials*?
- [ ] How maker's marks surface in the UI and on the companion app
      (L31) without becoming a stat readout.
