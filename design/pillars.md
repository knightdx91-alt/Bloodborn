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
| L10 | Incarnates | One per spell per server; one per character; decline = +1 teaching slot; 30-day lapse, softened by **regency** (one pre-declared absence per holder holds the seat up to 60 days, usable once); arena free-for-all Succession Trial. Seat announcements are **epoch-gated in surface form**: pre-Unveiling they reach only the awakened (dreams, marked coins, Circle word); the public version ("a famous duelist has died") exists only post-Unveiling |
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
| L34 | Incarnate true forms | The true form breaks one rule the base spell obeys (true Fireball needs no line of sight; true Mending works on the recently dead) AND marks the body with a visible tell readable by folklore-literate observers. Never a numeric tier — a Grandmaster's cast stays equal in raw power. Seat = fame + risk (announced, Monument-tracked, huntable, marked, locked out of other seats); decline = quiet power (anonymity, all seats stay open, +1 teaching slot) |
| L35 | Succession Trial rules | Extends L10/L22. 3 real days from seat-open announcement to Trial, fired at midnight server time in the Veiled Ring. Team-ups fully legal, but the seat lands on exactly one head — alliances end in betrayal by design. Audience: any awakened may spectate and bet (shadow book only); living Incarnates may watch, never intervene; echoes barred — the Trial belongs to the living |
| L36 | Season 1 mystery plan | Extends L7/L23. Awakening is gated by seeded in-world events (blood poolings, survived deaths, relic contact), server-throttled early and loosening as epochs advance — wikis tell you where to look, never how to skip the line; target weeks of Myth, months to Unveiling. Guard rail: seeding is never a pure playtime lottery — at least one slow, reliable awakening path (deep faith questlines, long rumor chains) is completable at casual pace, arriving in months, never never. Marketing: total silence on magic; the game ships as a grounded crafting/war MMO and the leak is the marketing. Secrets are layered: magic's existence (breaks fast, fine) → which spells exist (each individually discovered) → the three institutions' agendas → the secret canon of the god's death (answered only at the Heart) |
| L37 | No transfers; rebirth | Characters are citizens of one history — no transfers between worlds, ever. For dying servers or friend-chasing: rebirth — start fresh on the new world keeping only account flair; the old world records an epitaph line ("departed the world"). Skills, gear, titles, seats, lineage all stay behind. Server retirement uses rebirth too |
| L38 | Crafting floor | Extends L4. Depth lives in the ceiling, not the floor: every stage is playable naively with acceptable results; skill raises quality ceilings, never gates the floor. No stage may hard-fail a patient beginner. Casuals buy intermediates and do only the stages they enjoy; masters make the legends |
| L39 | Combat netcode stance | Extends L2. Favor-the-defender: client-authoritative dodge/parry windows with server reconciliation, tuned to feel fair at ~100ms; enemy readability comes from committed telegraph animations, not frame-perfect timing. Vertical-slice gate: parry/dodge must feel BotW-good at real MMO latency before anything else ships |

---

## Pillars to figure out

Ordered by how much everything else depends on them.

### ~~P1. Server & population model~~ ✅ LOCKED → L16, L37
Medium worlds; transfers forbidden, rebirth instead. Remaining:
launch-surge plan (more worlds, never bigger — see
`feasibility-review.md` §3.1).

### ~~P2. Ordinary death~~ ✅ LOCKED → L17, L32
Zone-scaled; ~10% durability, cargo grace→open loot→despawn, bound
shrine respawn. Remaining: tithe scaling by distance (closes the
bind-and-die slow-teleport edge case, `feasibility-review.md` §4.1).

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
rumor data model, and — flagged highest-stakes open question in the
design (`feasibility-review.md` §4.3) — contested-delve pressure at
floor population. Prototype alongside the slice; paper won't answer it.

### ~~P9. Business model~~ ✅ LOCKED → L27
`economy.md` §7. Remaining: expansion cadence/pricing after the
vertical slice.

### ~~P10. Demigod realm structure~~ ✅ LOCKED → L30
`demigod-realm.md`. Remaining: ring/offering tuning, whether L34
true-forms escalate inside, low-population feel, mortal scrying.

### P11. Living NPCs — free-form voice dialogue 🔶 OPEN (2026-07-30)
`brainstorm.md` §9. No dialogue trees: you hold a button and talk out
loud; NPCs answer in their own voice. Treated as the **display layer
for world state** — the cheapest way to make epochs (L23) and player
choices legible, and the delivery mechanism for the magic secret's
epoch gating (L22).

Shape that already feels settled: **speech is free, action is typed**
(the model emits whitelisted intents, never mutates state; binding
deals route to a confirm panel); three model tiers with ~40–80 truly
conversational NPCs; small lossy per-NPC memory; gossip diffusion at
caravan speed (L28); push-to-talk on a dedicated bind, never open mic;
proximity conversation where bystanders — players *and NPCs* — overhear;
voice-first with full-fidelity text parity.

Open before it can lock: proximity audibility default, multi-party
scope, model tiering + per-turn cost ceiling against L27, authored vs.
generated gossip distortion, whether disposition is visible, and where
the intent whitelist ends. Full list at the bottom of `brainstorm.md`.

Slice gate (§9.8): one town, six voice NPCs, one rumor that provably
arrives *wrong* in the next town, one epoch flip that visibly changes
what all six say.

---

## Suggested working order

1. ~~P1 + P2~~ ✅ done (2026-07-26)
2. ~~P3~~ ✅ done (2026-07-26)
3. ~~P4~~ ✅ done (2026-07-26) — working canon in `lore.md`
4. ~~P5 + P7~~ ✅ done (2026-07-26) — `war-society.md`
5. ~~P6 + P9~~ ✅ done (2026-07-26) — `economy.md`
6. ~~P8, P10~~ ✅ done (2026-07-26) — `content.md`, `demigod-realm.md`
7. ~~Open-questions sweep~~ ✅ done (2026-07-27/28) — L32–L39 closed
   every remaining question in `brainstorm.md`
8. ~~Feasibility & simulation pass~~ ✅ done (2026-07-28) —
   `feasibility-review.md`; guard rails folded back into L10 and L36

9. **Living NPCs raised as P11** (2026-07-30) — `brainstorm.md` §9;
   open, six questions to settle, slice gate defined.

**The original ten structural pillars are locked (39 decisions).** P11
(living NPCs) is new and open — the first addition since the sweep. The one-page
distillation is `vision.md`; the build-and-play sanity check is
`feasibility-review.md` (design PASS; production PASS at AAA scale
or via the staged path in §5).

### Next phase

1. **Naming polish** — currency ("marks" is placeholder), the six
   town names, "the Interior," spell naming conventions.
2. **Vertical slice** — the smallest playable proof of the loop: one
   town + its wedge, one crafting pipeline to mastery, combat vs. a
   few monster types at real MMO latency (the L39 gate), one hidden
   awakening end-to-end.
3. **Two prototype-shaped risks to answer inside the slice**:
   the Switch battle ceiling (`feasibility-review.md` T2) and
   contested-delve pressure (§4.3).
4. **Settle P11's six open questions**, then prototype the living-NPC
   gate (`brainstorm.md` §9.8) alongside the slice — latency, cost per
   turn, and STT across accents are all things paper won't answer.
