# Bloodborn — Brainstorm (living document)

Expansions on the founding notes (`design/notes/2026-07-26-handwritten-brainstorm.md`).
Nothing here is locked. Ideas marked **[core]** trace directly to the
original page; everything else is riffing.

Platforms: full 3D, crossplay — PC, Xbox, PlayStation, Switch.

---

## 0. Decisions locked so far (2026-07-26)

- **Combat:** real-time action combat, Breath of the Wild feel — physical,
  readable, no tab-targeting.
- **World scale:** the six outer town areas are **large**; the capitol
  region is **extra-large** — it's the main hub.
- **Demigod death reward:** **Sainthood + the Monument** (both, always).
  Legacy-inheritance and relic-drop candidates are rejected.
- **Demigod realm is hard permadeath.** No exceptions, no living demigod
  ever leaves. Anything that shows a demigod in the mortal world is an
  **echo of a dead one** (see §7).
- **Magic is a secret.** Players are not told magic exists. It is
  discovered in the world (see §5).

---

## 1. World layout — the Wheel **[core]**

Six towns arranged in a ring around one enormous capitol. Each of the
six outer regions is a **large** zone in its own right — town plus its
surrounding wedge is a full adventuring area, not a waystation. The
capitol region is **extra-large**: the main hub, big enough to hold the
arena district, cathedral quarter, grand market, and ascension grounds
as distinct neighborhoods.

- **The Wheel as map structure.** The land between adjacent towns forms
  six wedge-shaped territories. Each wedge has its own biome and its own
  exclusive resources — the reason to fight over land, trade across it,
  and escort caravans through it.
- **Town identity.** Each town specializes: one is the smithing town
  (foundries, ore-rich wedge), one the beast-handling town (stables,
  plains wedge), one the mage town, one the port/trade town, etc.
  Specialization means no town is self-sufficient → trade routes between
  towns are the economy's bloodstream → mounted caravans, escorts,
  banditry.
- **The Capitol.** Neutral ground. Arena, grand auction house, banking,
  faction cathedrals, the ascension gate. No open PvP inside; politics
  and betting instead.
- **Spokes.** Six great roads from towns to capitol — safe-ish. The rim
  road connecting town to town — less safe. Off-road in the wedges —
  dangerous, where the good materials are.

## 2. Crafting — deep, physical, discovered **[core — flagship system]**

Directive from the notes: crafting must be *really involved*. Working
principle: **crafting is gameplay, not a menu.**

### 2.1 Materials have properties, not just names
- Every raw material rolls properties: ore purity, metal hardness vs
  flexibility, wood grain, hide thickness, monster-part potency,
  harvested-at-night vs day, wedge of origin.
- Item stats are **derived from inputs + process + crafter skill**, not
  from a fixed recipe table. Two swords from the same recipe are not the
  same sword.

### 2.2 Multi-stage pipelines with player agency at each stage
Example — a sword: prospect → mine → sort/refine → smelt → alloy →
forge (shape) → quench → grind/hone → hilt & assembly → (optional)
enchant. Each stage:
- has a short skill interaction (not a progress bar — heat management,
  hammer timing, quench timing),
- passes quality forward (a bad smelt caps how good the forge can be),
- can be done by *different players* — a refiner can sell ingots, a
  bladesmith can sell bare blades, a hilt-maker finishes them.

### 2.3 Discovery, not unlock menus
- No global recipe book. Recipes are **knowledge**: discovered by
  experimentation, found in ruins, or taught.
- Experimentation journal: the game records what you tried; near-misses
  give hints ("the alloy cracked — too much of something").
- Recipes can be written into **schematics** — tradeable, sellable
  items. Knowledge is an economy. (Deliberate parallel to spell
  teaching, §5.)

### 2.4 Mastery, marks, and reputation
- Specialization trees deep enough that nobody masters everything —
  forced interdependence.
- **Maker's mark:** every crafted item permanently carries its crafter's
  name. Famous smiths become famous *because their name is on the sword
  that won the arena grand final.*
- Masterwork moments: at high skill, rare crit-crafts produce named,
  one-of-a-kind items.
- Botched crafts aren't pure loss: partial material recovery, or
  occasionally a "flawed but strange" item with a quirk property.

### 2.5 Workshops tie into property **[core: buildings]**
- Tool quality and workshop tier gate the ceiling of what you can make.
  A field kit repairs; a rented town forge makes good gear; an owned,
  upgraded foundry with a legendary anvil makes the best.
- Owning the smithing-town's grand forge = renting bench time to other
  crafters. Property + crafting + economy in one loop.

### 2.6 Why crafters matter forever: the item sink loop
- War losers drop equipment **[core]** + gear wears and needs repair +
  the demigod zone permadeath-deletes entire kits **[core]** →
  equipment constantly leaves the world → crafters constantly refill it.
- This is the EVE lesson: destruction is what makes crafting an economy
  instead of a checklist. The notes already contain all three sinks.

## 3. Property & buildings **[core]**
- **Own** a deed or **buy rights/lease** — landlord gameplay is real
  gameplay.
- Uses: shop, smithy, tavern, inn, brothel, stable/breeding pen, chapel,
  betting parlor, training hall (spell-teaching venue, §5), warehouse,
  auction stall.
- NPC staff run your business while you're offline; you set prices,
  stock, and wages.
- Town councils: building owners in a town vote on tax rates, guard
  funding, town projects. Player politics without needing a guild system
  to carry it.
- Upkeep costs so property churns and new players can eventually buy in.

## 4. The Arena **[core]**
- PvP and PvM brackets; scheduled fight nights per server.
- **Betting** by players on outcomes **[core]** — odds move with the
  money like a real book; bookmaking licenses as a purchasable right.
- No equipment loss in the arena (sport), unlike wars (stakes) — clean
  contrast between the two PvP venues.
- Monster-wrangling: players capture creatures in the wedges and enter
  them as arena beasts; beast-handler as a career.
- **Echo bouts:** headline events where the arena summons the ghost of
  a dead demigod from the Monument (§7) — an AI reconstruction of their
  build and fighting style. Permadeath stays intact; the legend fights
  on as a ghost.
- Seasons, rankings, and arena fame feeding crafter fame via maker's
  marks on winning gear.
- Spectator mode with wagering from the stands — console-friendly,
  low-intensity play session.

## 5. Magic — hidden, earned, mastered, taught **[core]**

### 5.1 Magic is a secret
Players are never told magic exists. No mage class at character
creation, no mana bar, no spell tab, no magic in trailers or store
copy. The world at first presentation is martial: steel, horses, coin,
faith. Magic is **found**.

- **Awakening, not unlocking.** Somewhere in the world are quiet
  anomalies — a shrine that hums, a stain that doesn't wash out, an NPC
  who says something that only later makes sense. Following one far
  enough triggers a personal **awakening event**: only then does the
  magic UI even appear for that character.
- **Wiki-proofing.** In an MMO the secret will be on the internet in a
  week — design so that *knowing* isn't *having*. Reading a guide tells
  you where to stand; the awakening still demands the experience itself
  (a quest chain, a trial, choices made blind). You can't be told into
  magic — you can only be led to its door. Guides become treasure maps,
  not spoilers.
- **Magic spreads person-to-person.** The teaching system (§5.3) means
  the secret propagates socially in-world: the first awakened players
  become the first trainers, and word-of-mouth — "that guild has a
  *mage*" — is the marketing. Server-first awakenings are announced
  cryptically (the Monument, §7, might record them).
- **Visible before it's understood.** Other players *see* spells cast
  before they know how they're possible. Being watched is the hook.

### 5.2 Earned through quests
- Abilities come from **quest chains**, not level-ups **[core]** — every
  spell has a story; some spells are rare because the quest is hidden or
  brutal.
### 5.3 Mastered and taught
- **Spell mastery ranks** through use. At mastery, you can become a
  **trainer** and teach that spell to others **[core]** — for a fee you
  set. Academies as player businesses in training halls (§3).
- Teaching is a gameplay session (ritual/lesson), not a menu click —
  and teaching a never-awakened player *is* their awakening: masters
  can initiate, which makes early mages genuinely powerful figures.
- Lost/forbidden spells found only in the world or taught by the last
  living master — if all masters die in the demigod zone, the spell can
  literally go extinct until rediscovered. Knowledge scarcity with real
  teeth.
- Enchanting = mage + crafter collaboration: the smith forges the
  vessel, the mage binds the spell.

## 6. War **[core]**
- Large-scale town-vs-town or faction wars over wedge territory and
  resource rights.
- **Losers lose 1 random equipped piece** **[core]** — dropped as loot
  on the field. Painful, not character-ending; feeds the item sink.
- Declared with lead time (defenders can prepare, mercenaries can sign
  on); war contracts and mercenary companies.
- Mounted combat shines here **[core]**: cavalry charges, mounted
  archery, supply-wagon raids. Also mount careers outside war —
  breeding, racing (bettable, §4), caravans.

## 7. Religious factions & Ascension **[core — the endgame hook]**
- Factions with rep grinds, blessings, exclusive quests; cathedral seats
  in the capitol; choosing one closes doors with the others.
- **Ascension:** at max rep + max level, walk through your faith's gate
  in the capitol → the **demigod realm**: pure PvP, permadeath, monsters
  that can kill even you. Advancement only through kills. **[core]**
- One-way ticket. Your mortal life — property, wealth, name — is
  settled or willed before you go. Ascension day as a public event.

### "When you die you get something" — DECIDED: Sainthood + the Monument
Both happen on every demigod death:
- **The Monument:** kills, deeds, and final death carved on a capitol
  monument forever. Every demigod who ever lived is on it.
- **Sainthood:** your faction canonizes you; you become an NPC statue/
  shrine in the mortal world that grants blessings — your old name,
  permanently in the world other players touch. (Scale of the shrine
  could reflect the scale of the life: a demigod slain on day one gets
  a roadside marker; a legend gets a chapel.)

Rejected: legacy-inheritance perks and relic drops — the reward is
*remembrance*, not power transfer.

### Keeping the mortal and demigod worlds connected
- **Hard rule: no living demigod ever appears in the mortal world.**
  Ascension is one-way and permadeath is absolute.
- **Echoes:** the arena (§4) can summon the *ghost of a dead demigod*
  — an AI echo reconstructed from their Monument record (their build,
  their gear, their recorded fighting patterns) — as an exhibition
  boss. Mortals get to fight the legend; the legend stays dead. Saints'
  echoes could also appear at their own shrines on holy days.
- Faction standing in the demigod realm feeds small buffs to that
  faction's mortal followers → mortals care who's winning upstairs.
- Endgame of the endgame: a demigod who conquers the final area becomes
  a **god of the pantheon** — retires the character permanently, gets a
  server-visible effect (holiday, blessing, weather?) named after them.

## 8. Platform notes (PC / Xbox / PS / Switch)
- Controller-first UI from day one — crafting minigames must feel good
  on a pad (timing/analog interactions port better than cursor-heavy
  ones).
- Crossplay + cross-progression assumed; single shared world per region
  if possible.
- Switch is the constraint ceiling: budget world streaming and crowd
  scenes (arena, wars) for it early or it will hurt later.
- Low-intensity session types (shopkeeping, betting, spectating,
  fishing?) are good handheld-mode loops.

## Open questions
- [ ] Death *below* the demigod realm: what does ordinary death cost?
- [ ] How many players per world/shard? Wars and town councils need a
      real number to design against.
- [ ] Setting/tone: the name **Bloodborn** — gothic? dark fantasy?
      how dark? (Brothels and blood-gods on the page suggest mature
      rating; confirm M-rating comfort.)
- [ ] Classless (skill-based, spells are things you learn) vs classed?
      Notes lean classless; hidden magic (§5.1) almost requires
      classless — a mage class on the character screen would spoil the
      secret.
- [ ] Crafting minigame depth vs accessibility — how much can a casual
      player enjoy without mastering it?
- [ ] BotW-style combat in an MMO: how do we handle latency for
      parry/dodge timing, and does gear-durability à la BotW exist here
      or does repair/wear (§2.6) replace it?
- [ ] How long should the magic secret realistically hold on a fresh
      server, and is there a "season 1 mystery" plan for launch?
