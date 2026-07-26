# Bloodborn — Design Pillars & Decision Queue

Status tracker for the big structural decisions. Detail lives in
`brainstorm.md`; this file is the map. Updated as decisions lock.

---

## Locked foundations (as of 2026-07-26)

| # | Pillar | Decision |
|---|--------|----------|
| L1 | World shape | The Wheel: 6 **large** town regions ringing an **extra-large** capitol hub |
| L2 | Combat feel | BotW-style real-time action combat |
| L3 | Durability | Repair/wear economy; no mid-fight breakage |
| L4 | Crafting | Flagship system: rolled material properties, multi-stage hands-on pipelines, discovered recipes, maker's marks |
| L5 | Property | Buy buildings or rights; player businesses; town councils |
| L6 | Arena | PvP + PvM, player betting, no-stakes sport; echo bouts; Succession Trials |
| L7 | Magic secrecy | Hidden system — discovered in-world, no magic in presentation |
| L8 | Spell tiers | Novice → Adept → Expert → Master → Grandmaster → Ascendant |
| L9 | Teaching | Unlocks at Master; capped disciple slots freed on graduation; lineage XP (big on rank-ups, trickle on use) |
| L10 | Ascendants | One per spell per server; one per character; decline = +1 teaching slot; 30-day lapse; arena free-for-all Succession Trial |
| L11 | War stakes | Losers drop 1 random equipped piece |
| L12 | Endgame | Faction max rep + max level → one-way ascension → permadeath demigod realm; advance only by kills |
| L13 | Death reward | Sainthood + the Monument (remembrance, not power transfer) |
| L14 | Demigod boundary | No living demigod in the mortal world; arena summons AI echoes of dead ones |
| L15 | Platforms | Full 3D, crossplay: PC, Xbox, PlayStation, Switch |

---

## Pillars to figure out

Ordered by how much everything else depends on them.

### P1. Server & population model 🔴 decide first
How many players share a world? One megaserver with tech tricks, or
many smaller shards?
- **Why first:** it sets the value of literally every scarce thing we've
  designed — "one Ascendant per spell *per server*," war sizes, town
  council seats, how long the magic secret holds, economy depth.
- Key questions: target concurrent players per world; sharding/layering
  tech; can characters transfer (transfers would break Ascendant
  uniqueness and lineage meaning)?

### P2. Ordinary death 🔴 decide first
What does dying cost in the mortal world?
- **Why first:** permadeath upstairs only reads as heavy against a
  known baseline; war equipment-loss needs to sit *above* normal death
  severity, not below it.
- Key questions: drop nothing / drop carried loot / gear damage on
  death? respawn where? death in the wedges vs in town? any XP or
  skill cost?

### P3. Progression model 🟠
The notes say "max level" exists — but what is a level here?
- Spells are quested (not leveled), spell tiers are per-spell, crafting
  is skill-based. So what does the *character level* govern — health/
  stamina? weapon proficiencies? Is it classless skill-by-use
  (Runescape/UO-style) with "max level" meaning all-caps, or a
  conventional XP level?
- Hidden magic (L7) already rules out class selection at creation.
- Dependencies: P2 (death costs), L12 (max level gates ascension).

### P4. Setting, tone & lore 🟠
The name **Bloodborn**, how dark, and the world's identity.
- Key questions: M-rating confirmed (brothels, blood-faiths, gambling
  are on the founding page)? What are the six towns — names,
  specialties, cultures? What are the religious factions — how many,
  what do they worship, why do their gates lead to a demigod realm?
  Why is the world a wheel? What *is* the demigod realm,
  cosmologically?
- Dependencies: none — can run in parallel with everything.

### P5. War & territory 🟡
Structure of large-scale wars.
- Who declares war on whom — towns? factions? guilds? What's actually
  won — wedge resource rights? town tax control? How often, what
  scale, how do defenders prepare? Mercenary contracts?
- Dependencies: P1 (population sets war scale), P7 (who the social
  actors are).

### P6. Economy fundamentals 🟡
- One currency or several? Global auction house vs local-only markets
  (local markets + caravan trade fits the Wheel; global AH kills trade
  runs)? Gold sinks (property upkeep, betting rake, repair fees)?
  Bank/storage rules?
- Dependencies: P1, P5; business model (P9) looms over it.

### P7. Social structures 🟡
- Are guilds a formal system, or do player structures emerge from what
  we already have (town councils, academies, mercenary companies,
  religious orders)? Formal guilds might be redundant — or the glue.
- Dependencies: P5 (war needs declared sides).

### P8. PvE & content model 🟢
- What's the moment-to-moment PvE: open-world monsters in the wedges,
  dungeons, world bosses? Quest design philosophy (the awakening
  quests set a high bar — handcrafted mystery vs repeatable content)?
  Monster-capture for the arena?
- Dependencies: P4 (lore drives content).

### P9. Business model 🟢 (but don't sleep on it)
- Buy-to-play / sub / F2P+cosmetics? Constrains economy design hard
  (RMT pressure on a player-driven economy is real). No pay-for-power
  is presumably a given in a game about earned scarcity.
- Dependencies: informs P6; needs deciding before economy tuning.

### P10. Demigod realm structure 🟢
- How many areas past the gate? What "advance to new area by kills"
  means concretely (kill count? trophies?). What's at the end — the
  final area, godhood, pantheon effects? How demigod combat differs.
- Dependencies: P3 (what ascending characters bring with them).

---

## Suggested working order

1. **P1 + P2 together** — population and ordinary death are the two
   numbers every other system is priced in.
2. **P3** — progression, because "max level" gates the endgame.
3. **P4** — lore sprint: name the towns, the faiths, the world.
4. **P5 + P7** — war and social structure as one conversation.
5. **P6 + P9** — economy and business model as one conversation.
6. **P8, P10** — content models once the skeleton stands.
