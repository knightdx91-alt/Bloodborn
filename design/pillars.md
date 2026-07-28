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
| L8 | Spell tiers | Novice → Adept → Expert → Master → Grandmaster → Incarnate |
| L9 | Teaching | Unlocks at Master; capped disciple slots freed on graduation; lineage XP (big on rank-ups, trickle on use) |
| L10 | Incarnates | One per spell per server; one per character; decline = +1 teaching slot; 30-day lapse; arena free-for-all Succession Trial |
| L11 | War stakes | Losers drop 1 random equipped piece |
| L12 | Endgame | Faction max rep + max level → one-way ascension → permadeath demigod realm; advance only by kills |
| L13 | Death reward | Sainthood + the Monument (remembrance, not power transfer) |
| L14 | Demigod boundary | No living demigod in the mortal world; arena summons AI echoes of dead ones |
| L15 | Platforms | Full 3D, crossplay: PC, Xbox, PlayStation, Switch |
| L16 | Server model | Medium worlds: ~5–10k characters, ~1–2k peak concurrent. Big enough for a real economy; small enough that Incarnates and master crafters are known names |
| L17 | Ordinary death | Zone-scaled. Towns/spoke roads: durability hit only. Wedges: carried goods (materials, coin) also drop where you fell, recoverable. Equipped gear never drops outside war. Death ladder: ordinary < war (1 equipped piece) < demigod realm (everything) |
| L18 | Progression | Classless, skill-by-use. Every proficiency is a skill grown through use; "level" = total across skills; magic skills invisible until awakening. "Max level" = capping a defined skill set (definition TBD) |
| L19 | Power curve | Moderate vertical: veterans usually win clean, but a skilled newcomer threatens a careless one and can always escape |
| L20 | Tone | M-rated grounded dark, low-magic medieval |
| L21 | Lore | Godsgrave cosmology adopted as working canon (`lore.md`): the god's blood explains respawn, regional materials, monsters, awakening, and permadeath; four faiths; six named towns; Bloodborn = the awakened; anyone is awakenable; secret canon in §9 |
| L22 | Magic is myth | The NPC world believes mages are folklore. Public wonder is institutional miracle only. No anti-sorcery law — officially sorcery doesn't exist; exposure means mobs and secret institutions (Office of the Lamp / Vigil high circle / Open Vein inner circle), not trials. Succession Trials convene in the Veiled Ring (hidden night circuit); academies operate behind fronts |
| L23 | Living history | Each server writes its own permanent history through player-advanced epochs. The Revelation Arc (`lore.md` §10): Myth → Whispers → Unveiling (the myth-breaker is named on the Monument, once per server) → Scouring → Wonder. Epochs are cheap to represent: dialogue, laws, faction posture, set-piece transitions — not rebuilt maps |
| L24 | Social structures | Charters, not guilds (`war-society.md`): Companies (war), Houses (economy), Orders (faith), Circles (secret, unregistered); fellowships for casual groups; town councils remain place-based |
| L25 | War | Wars are staked contracts over seasonal *rights* (resources, roads, town grants), never town conquest. Declared with lead time, escrowed stakes, enrollment-only war rules, scheduled battles; enrolled war dead drop 1 equipped piece on the field (L11). Bystanders untouched. Circles can covertly fund wars, at exposure risk |
| L26 | Economy | Player-driven (`economy.md`): NPCs never sell finished goods; player shops in rented/owned buildings are the retail layer (NPC staff, ledgers, commissions); local market boards only — no global AH, no item mail, goods physically travel (caravans/arbitrage); single currency with hard NPC sinks; shadow economy through Circles |
| L27 | Business model | Buy-to-play + paid expansions. No pay-for-power, no purchasable goods a crafter could make, no cosmetic gear shop (gear appearance = crafter prestige). Sparse account flair only; RMT enforcement planned from day one |
| L28 | Travel | No fast travel, no teleportation, no recall/summon. Mounts are the speed system; hands-free coaches/barges are the convenience layer; compact Wheel keeps distances felt-not-dreaded. Exceptions: shrine respawn, the ascension gate (`economy.md` §3.5) |
| L29 | PvE & content | No instanced PvE (`content.md`): shared contested delves around blood poolings; monster ecology with cull pressure and named horrors; quests = handcrafted mystery chains + world-state contract boards + rumor as discovery. No quest markers |
| L30 | The Interior | Demigod realm (`demigod-realm.md`): four descending rings (Skin/Veins/Marrow/Heart); kills yield carried ichor, descent costs ichor offerings; no crafting or repair inside — entropy guarantees every demigod's final fight; the Heart grants the truth and pantheon godhood with a named server-visible mark |
| L31 | Companion app | Optional mobile companion for the asynchronous life: shop ledgers/restock/prices, commission bids, rumor mill, Monument feed, war declarations, arena odds. Never gameplay-critical — the shopkeeper's evening glance, not a second job |
| L32 | Ordinary death details | Extends L17. Durability hit: ~10% on all equipped gear, every death. Wedge cargo drop: owner-only grace ~10 min, then open loot; despawns ~1 hour untouched. Respawn: bound blood-shrine (bind at any shrine; the god's blood knits you back at the one you chose) |
| L33 | Teaching numbers | Extends L9. Disciple slots: 3 per spell at Master, +1 at Grandmaster (stacks with the decline-the-seat +1). Dismissal cooldown: 7 real days (graduation frees the slot instantly). Lineage XP counts fully up to Grandmaster and stops there — the Incarnate seat is never XP, only the Trial. Daily trickle cap: a full roster's passive XP ≈ 1 hour of own practice; rank-up windfalls are the real prize |

---

## Pillars to figure out

Ordered by how much everything else depends on them.

### ~~P1. Server & population model~~ ✅ LOCKED → L16
Medium worlds. Remaining sub-questions: character transfer policy
(transfers threaten Incarnate uniqueness and lineage — likely
forbidden, or titles/lineage stripped on transfer); respawn points.

### ~~P2. Ordinary death~~ ✅ LOCKED → L17
Zone-scaled. Remaining sub-questions: exact durability hit size;
recovery timer on dropped goods before they despawn/become lootable.

### ~~P3. Progression model~~ ✅ LOCKED → L18, L19
Classless skill-by-use, moderate vertical power curve. Remaining
sub-questions: which skills count toward the "max level" ascension
gate; per-skill caps and total-cap structure; anti-AFK-grind design
(meaningful-use XP rules, as with spell trickle).

### ~~P4. Setting, tone & lore~~ ✅ LOCKED → L20, L21
Working canon in `lore.md`. Remaining sub-questions: final naming
pass; the enemy's nature (§9); how much each faith questline glimpses
of the secret canon.

### ~~P5. War & territory~~ ✅ LOCKED → L25
`war-society.md`. Remaining: tuning numbers, battle formats, epoch
interactions.

### ~~P6. Economy fundamentals~~ ✅ LOCKED → L26
`economy.md`. Remaining: currency naming, rent/tax/wage numbers,
commission escrow, warehouse robbery scope.

### ~~P7. Social structures~~ ✅ LOCKED → L24
`war-society.md`. Charters (Company/House/Order/Circle) +
fellowships + councils. Remaining: charter creation costs, roster
caps, Circle exposure mechanics.

### ~~P8. PvE & content model~~ ✅ LOCKED → L29
`content.md`. Remaining: delve counts, named-horror generation,
rumor data model, group scaling without instancing.

### ~~P9. Business model~~ ✅ LOCKED → L27
`economy.md` §7. Remaining: expansion cadence/pricing after the
vertical slice.

### ~~P10. Demigod realm structure~~ ✅ LOCKED → L30
`demigod-realm.md`. Remaining: ring/offering tuning, Incarnate
true-forms inside, low-population feel, mortal scrying.

---

## Suggested working order

1. ~~P1 + P2~~ ✅ done (2026-07-26)
2. ~~P3~~ ✅ done (2026-07-26)
3. ~~P4~~ ✅ done (2026-07-26) — working canon in `lore.md`
4. ~~P5 + P7~~ ✅ done (2026-07-26) — `war-society.md`
5. ~~P6 + P9~~ ✅ done (2026-07-26) — `economy.md`
6. ~~P8, P10~~ ✅ done (2026-07-26) — `content.md`, `demigod-realm.md`

**All ten structural pillars are locked (31 decisions).** The
one-page distillation is `vision.md`. What remains is tuning (numbers
marked TBD throughout), a naming polish pass, and the next phase:
defining a vertical slice — the smallest playable proof of the loop
(one town + its wedge + capitol district, crafting pipeline, a delve,
a war, an awakening).
