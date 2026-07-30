# Bloodborn — Brainstorm (living document)

Expansions on the founding notes (`design/notes/2026-07-26-handwritten-brainstorm.md`).
Nothing here is locked. Ideas marked **[core]** trace directly to the
original page; everything else is riffing.

Platforms: full 3D, crossplay — PC, Xbox, PlayStation, Switch.

---

## 0. Decisions locked so far (2026-07-26 → 07-28)

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
- **Durability = repair/wear (§2.6), not BotW-style breakage.** Weapons
  never shatter mid-fight; they wear down and need crafter repair.
- **Teaching is capped and rewarded.** Masters have limited disciple
  slots (freed on graduation) and earn spell XP from their disciples'
  progress (see §5.3).
- **Spell tiers exist; teaching unlocks at Master.** Working ladder:
  Novice → Adept → Expert → Master → Grandmaster → Incarnate (§5.4).
- **Incarnates:** one Incarnate per spell per server; one Incarnation
  per character. Offered at Grandmaster; declining grants a permanent
  extra teaching slot in that spell. The slot frees on the holder's
  permadeath in the demigod realm — or lapses after **30 real-world
  days** without the account logging in — with a server-wide
  announcement (§5.4).
- **Succession Trial:** an open seat is claimed via an arena
  **free-for-all among qualified grandmasters — any combat goes**
  (§5.4).
- **Server model:** medium worlds — ~5–10k characters, ~1–2k peak
  concurrent per world. Scarcity and fame stay personal.
- **Ordinary death is zone-scaled.** Towns/spoke roads: durability hit
  only. Wedges: carried goods (materials, coin) also drop where you
  fell, recoverable. **Equipped gear never drops outside war.** The
  death ladder: ordinary death < war loss (1 equipped piece) <
  demigod realm (everything, forever).
- **Progression: classless, skill-by-use.** Every proficiency (swords,
  riding, smithing, each spell) is a skill grown through meaningful
  use. "Level" = total across skills; "max level" (the ascension gate)
  = capping a defined skill set, TBD. Magic skills don't appear on the
  sheet until awakening — the secret is structural.
- **Power curve: moderate vertical.** Veterans usually win clean; a
  skilled newcomer can threaten a careless one and can always escape.

### Added 2026-07-27/28 (the open-questions sweep, L32–L39)

- **Ordinary death numbers (L32):** ~10% durability on all equipped
  per death; wedge cargo owner-locked ~10 min, then open loot,
  despawning ~1 hour; respawn at a **bound blood-shrine**.
- **Teaching numbers (L33):** 3 disciple slots at Master, +1 at
  Grandmaster; 7-day dismissal cooldown (graduation frees the slot
  instantly); lineage XP counts to Grandmaster and stops; daily
  trickle capped at ≈1 hour of own practice.
- **The spell seat is the Incarnate**, not the Ascendant —
  "Ascension" now belongs solely to the demigod gate.
- **Incarnate true forms (L34):** each breaks one rule the base
  spell obeys *and* marks the body with a visible tell. Never a
  numeric tier. Seat = fame + risk; declining = quiet power.
- **Succession Trial (L35):** 3-day lead, midnight, Veiled Ring;
  team-ups legal but one winner; awakened-only crowd, echoes barred.
- **Season 1 mystery (L36):** awakening gated by seeded,
  server-throttled events with a guaranteed slow path for casuals;
  total marketing silence; layered secrets.
- **No transfers (L37):** rebirth instead — fresh start elsewhere,
  an epitaph line left behind.
- **Crafting floor (L38)** and **combat netcode stance (L39)** —
  depth in the ceiling not the floor; favor-the-defender netcode as
  a vertical-slice gate.

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

And inside the fiction, magic is a **myth** (see `lore.md`): the NPC
world believes mages are fireside stories. Public wonder exists but is
institutional — shrine-respawns and church rites are *miracles of the
god*, implying nothing about people wielding power. There is no law
against sorcery because officially it doesn't exist; an exposed mage
faces mobs ("blood-warped!") and the quiet attention of secret
institutions, not a courtroom.

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
  set. Academies as player businesses in training halls (§3) — but
  because magic is publicly a myth, an academy operates **behind a
  front**: a bindery, a bathhouse, a fencing school. The signage says
  one thing; the cellar says another.
- Teaching is a gameplay session (ritual/lesson), not a menu click —
  and teaching a never-awakened player *is* their awakening: masters
  can initiate, which makes early mages genuinely powerful figures.

**Disciple slots (DECIDED — cap exists; numbers TBD)**
- A master has a limited number of **active disciple slots** per spell
  (working number: 3–5).
- A slot frees when the disciple **graduates** — reaches mastery in
  that spell themselves. A master's throughput is gated by student
  diligence, so masters select students carefully: tryouts, trial
  periods, waiting lists. Academies get real hierarchy for free.
- A disciple learns a given spell from **one** master — that master is
  their lineage for that spell. (Different spells from different
  masters is fine.)
- Dismissing a disciple is possible but the slot stays locked for a
  cooldown — prevents churn-teaching through bodies.
- Caps also throttle how fast magic spreads on a fresh server, which
  protects the secret (§5.1).

**Lineage XP (DECIDED — masters earn from disciples; tuning TBD)**
- Masters gain spell XP from their disciples' progress with the taught
  spell. Weighting designed against alt/AFK farming:
  - **Rank-ups pay big.** A chunky XP award each time a disciple ranks
    the spell up. Un-farmable — ranks per disciple are finite. Fires as
    a felt moment: *"somewhere, your disciple grew stronger."*
  - **Use pays a trickle.** Small XP per meaningful cast (combat,
    quests — not casting at a rock), with diminishing returns per
    disciple per day.
- Aligned incentives: scarce slots + XP-paying students = masters
  recruit talented, active players, not warm bodies.
- Open tuning question: can tithe XP alone carry a master to the top
  rank, or is personal casting required for the final rank?

### 5.4 Tiers and Incarnates (DECIDED — structure; tuning TBD)

**The ladder:** Novice → Adept → Expert → Master → Grandmaster →
**Incarnate**, per spell.

- **Master** is where teaching unlocks — you can only teach a spell
  you have mastered. A disciple *graduates* (freeing their slot, §5.3)
  when they reach Master themselves.
- **Grandmaster** sits above Master. Proposed requirement: deep
  personal use **plus** graduated disciples — a grandmaster has proven
  both power and lineage. (Numbers TBD.)

**The Incarnate**
- On reaching Grandmaster of a spell, the character is **offered
  Incarnation** of that spell.
- **One Incarnate per spell per server. One Incarnation per character**
  — accepting Fireball forecloses ever being Incarnate of anything
  else.
- **Declining grants a permanent extra teaching slot** in that spell.
  Declining one spell's offer does not block later offers from other
  spells. The fork is power vs. legacy: become the spell's singular
  embodiment, or become its greatest teacher.
- **Succession:** the Incarnation frees when the holder dies their
  permadeath in the demigod realm, **or lapses after 30 real-world
  days without the account logging in** (DECIDED — prevents dead
  accounts locking seats forever). **Regency (DECIDED, L10):** each
  holder may once pre-declare an absence, holding the seat up to 60
  days — the pressure stays, the hospital-stay cruelty goes. Either
  way a **server-wide announcement** fires — *"The Incarnate of
  Fireball has fallen"* / *"...has forsaken the flame"* — and the
  seat opens. **The announcement's surface form is epoch-gated
  (L10):** pre-Unveiling it reaches only the awakened (dreams,
  marked coins, word through the Circles); the public merely hears
  a famous duelist has died. Post-Unveiling, it's news.
- **The Succession Trial (DECIDED):** an open seat is claimed through
  an **open trial in the arena — a free-for-all among all qualified
  grandmasters who enter, any combat goes.** Weapons, spells, gear,
  mounts, dirty tricks — anything the arena walls can hold. Last one
  standing takes the seat.
  - Scheduled with lead time after the announcement so claimants can
    travel, prepare, and those who know can gather to watch.
  - **Venue: the Veiled Ring** — the arena after dark, off the books
    (`lore.md` §6). Magic being publicly a myth, the Trial can't be a
    daytime spectacle; it's the biggest night of the hidden circuit.
    Mechanics unchanged.
  - Arena rules still apply on stakes: it's sport — no equipment loss,
    no death. The prize is the seat itself.
  - Betting runs through underground books (§4): odds on every
    claimant, wagers taken from those in the know.
  - If exactly one grandmaster enters, they claim by walkover — but
    the ceremony still happens in the arena, witnessed.
  - If no one qualifies or enters, the seat stays open and the trial
    re-fires when a new grandmaster emerges.
- Emergent drama: since permadeath exists only upstairs, grandmasters
  who covet a held Incarnation cannot take it in the mortal world. They
  can wait — or ascend themselves and hunt the Incarnate in the
  demigod realm. Incarnate-hunting becomes a career.
- What Incarnation *grants* (proposals, TBD): an empowered or unique
  "true form" of the spell, distinct visuals every witness recognizes,
  their name attached to the spell in-world, a seat/shrine in the mage
  quarter. Should be meaningful but not so strong that declining is
  irrational — the extra teaching slot must be a real alternative.

**Lineage as world history**
- Every spell has a **genealogy**: discoverer → their disciples → the
  whole tree. Spell founders are recorded on the Monument (§7).
- When a master ascends and dies in the demigod realm, their lineage
  is what survives them — remembrance, not power, same as Sainthood.
- Extinction risk (§5.2) becomes visible: a spell with three living
  casters and no active masters is a spell the server can lose.
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
- **Companion mobile app (L31):** the asynchronous layer — shop
  ledgers and pricing, commission bids, rumor mill, Monument feed,
  war declarations, arena odds. Never gameplay-critical.

## 9. Living NPCs — free-form voice dialogue **[new pillar, 2026-07-30]**

The pitch: **no dialogue trees.** You walk up to an NPC, hold a
button, and *talk* — out loud, in your own words — and they answer in
their own voice. No wheel, no numbered options, no "1. Tell me about
the war."

This is not a separate feature from "choices change the world." It is
the cheapest possible **display layer** for world state, which is
exactly the bet `lore.md` §11 already makes: *epochs must be cheap to
represent — dialogue, laws, faction posture, not rebuilt maps.* Voice
NPCs are how the world tells you what you did, out loud, in its own
words.

### 9.1 The pipeline and its budget

Mic → speech-to-text → retrieval → model → text-to-speech → audio.

- **Latency is the whole game.** Alive under ~800ms to first audio;
  broken past ~1.5s. Budget it like netcode (L39), not like a
  chatbot: streaming STT, streaming TTS, no retrieval round-trip per
  turn.
- **Cost at MMO scale is the real gate**, not quality. 3,000
  concurrent players at one NPC turn per ~90s is ~33 inferences/sec,
  forever, on a buy-to-play game with no sub (L27). Survive it by
  tiering:
  - **Barks / crowd** — no model at all. Authored lines, epoch-
    filtered. ~95% of NPC speech volume.
  - **Ambient named NPCs** (the innkeeper, the dock foreman, the
    woman who always sits by the shrine) — small model, tight
    prompt, heavy caching.
  - **Story-bearing NPCs** (quest chains, faction seats, the Office
    of the Lamp contact) — the good model, rate-limited, rare.
- **Scope: ~40–80 truly conversational NPCs across six towns**, not
  thousands. Rarity is a feature. If everyone talks, nobody is
  memorable.

### 9.2 Speech is free; action is typed **[the load-bearing rule]**

The failure mode that kills projects like this: the model happily
promises things the game cannot do.

**The model never mutates world state.** It emits an intent from a
whitelist — `offer_contract(id)`, `share_rumor(topic)`, `refuse`,
`set_disposition(-1)`, `none` — and the game validates that intent
against what that NPC is actually authorized to do right now.

Anything binding (coin, commission, contract, enrollment, war escrow)
routes into a normal confirm panel. **You talk your way into the
deal; you still click to sign it.** This also gives console/text
parity, an audit trail, and softlock immunity on required quest
beats.

### 9.3 What actually makes them feel alive

Not fluency — fluency is table stakes, and every LLM NPC in the
industry sounds like the same eager assistant.

- **Knowledge boundaries.** Each NPC has a *what I could plausibly
  know* set: their town, trade, faith, the current epoch, and rumors
  that have physically reached them. Nothing teleports (L28) — and
  neither does information. An NPC who doesn't know is more
  convincing than one who knows everything.
- **Memory that is small and lossy.** 3–5 remembered facts per player
  per NPC, decaying. *"You're the one who bought the bad steel off
  Corran."* Not a transcript.
- **Gossip diffusion.** What you say becomes a rumor object with a
  source, a decay timer, and **distortion**. It travels at caravan
  speed. Three towns over it is wrong in an interesting way. Plugs
  straight into the rumor layer in `content.md` §3.
- **They don't have to like you.** Disposition, refusal, boredom,
  contempt. An NPC allowed to end the conversation and walk off is
  worth ten that aren't — and is also the best moderation tool on
  this list (§9.6).
- **Voice cards, not one house style.** Per-NPC diction, cadence,
  verbal tics, an anti-pattern budget (no "Ah, traveler!", no
  restating your own question back at you). Accent families by town.
- **Sell it with the body.** Head turns toward whoever is speaking,
  eyes flicking to an eavesdropper, a shopkeeper leaning in to lower
  their voice. Cheap animation does more for *alive* than model
  quality does.

### 9.4 Proximity conversation **[the MMO-only prize]**

Console headset attach rate is high — players already own mics
because they already talk to each other. So assume most players can
speak, and design **voice-first, with full-fidelity text as the
fallback** (§9.7).

That makes it realistic to ask the real question: **nearby players
hear your side of an NPC conversation.**

- **Overheard speech is a rumor source.** Someone standing nearby now
  knows what you asked the drover, and carries it at caravan speed
  like everything else. Taverns become genuine information markets —
  not because we built a rumor UI, but because that is where people
  are standing when they talk. The no-global-AH stance (L26) gets a
  sibling: no global channel for the things that matter.
- **NPCs are bystanders too — this is the big one.** Say the wrong
  thing loudly in a crowded square during **Myth** and it is not a
  flag check: someone *heard* you. The Office of the Lamp doesn't try
  you — officially sorcery doesn't exist (L22) — it just starts
  paying attention. Exposure stops being a stat and becomes a place
  you were careless in. Speak quietly, in the right room, to the
  right person: taught with no tutorial.
- **Public speech is a commitment.** An NPC weighs what you said in
  front of forty people differently from what you whispered. Promise
  a town seat something in the open, break it, and they remember the
  audience as well as the promise.
- **Multi-party is the prize and the hard part.** A Company's
  officers negotiating war stakes with a town seat — three players,
  one NPC, everyone talking. No MMO has that scene. Needs speaker
  diarization, turn-taking, and an NPC that addresses people by name
  and tracks who said what. Cap it (3–4 speakers) and scope it to a
  specific NPC class (faction seats, contract-givers); everything
  else is one-on-one with an audience.

### 9.5 Audio routing **[unglamorous, non-negotiable]**

The friction on console is not hardware — it is that the player's mic
is already committed to a party or Discord.

- **Push-to-talk on a dedicated NPC bind. Never open mic.** Hold to
  speak, local capture only.
- While transmitting to an NPC you are **not** transmitting to
  proximity or party, and vice versa. Visible on-screen channel state
  at all times.
- Open-mic VAD would feed party chatter, background TV and roommates
  into the model as player input — which makes NPCs look *stupid*,
  which is worse than mute.
- Console bind: held bumper, or stick-click while in conversation
  range.

### 9.6 Risks

- **The L22 landmine.** Free-form voice is genuinely dangerous to the
  best secret in the game — day one someone asks a priest "are mages
  real, is the god actually dead." **Hard rule: secret canon lives
  outside the retrievable corpus entirely, per epoch.** Not
  "instructed not to say" — *not present*. During **Myth**, a working
  mage is not in any NPC's knowledge set; they have only folklore,
  discomfort, superstition. During **Whispers**, a few go quiet and
  change the subject. After the **Unveiling**, they name the
  myth-breaker. Players will detect the epoch turning *by how people
  talk*, before any patch note says so. That is L23 living history
  delivered for pennies.
- **Abuse.** Players will jailbreak, harass, and farm clips.
  Moderation on input *and* output, plus an **in-fiction failure
  mode** — the NPC gets confused and turns away, never "I can't help
  with that."
- **Griefing proximity.** Someone will stand beside your quest-giver
  shouting nonsense. In-fiction mitigations: conversation ownership
  (initiator holds the floor), disposition drops toward the
  interloper and *not* toward you, NPCs that turn away and stop
  talking. Hard-mute proximity during anything with stakes (Circle
  contacts, the Lamp, anything touching L22) — secrets leaking
  because a stranger stood nearby is fantastic fiction right up until
  it is a grief tool.
- **STT fairness is first-class, not polish.** If voice is the
  primary path, an NPC that understands one accent and not another is
  a broken game for a chunk of the players. Budget real evaluation
  against accent-diverse audio, early.
- **Uncanny sameness** is the quiet killer — and it is a writing
  problem, not a model problem (§9.3, voice cards).

### 9.7 Accessibility & parity

Text input is mandatory and full-fidelity through the same pipeline —
but it is the fallback, not co-equal billing. The genuine can't-speak
population is sharper than "console vs PC": Switch handheld and
anyone playing in a shared or public space, speech-impaired players,
and non-native speakers who read the language comfortably but won't
speak it to a machine that may not parse them.

Designing voice-first changes the tuning: lean into interruption,
hesitation, and NPCs reacting to *how* you said something.

### 9.8 Vertical-slice gate

One town. Six voice NPCs. One rumor that provably travels to the next
town **wrong**. One epoch flip that visibly changes what all six of
them say. If that demo gives people chills, the pillar is real —
if it doesn't, cut to authored barks and lose nothing else.

## Open questions

**Reopened 2026-07-30 by §9 (living NPCs).** The pillar itself is not
locked; these are the calls to settle before the slice.
- [ ] **Proximity audibility default.** Leaning: audible at short
      range, per-player mutable, hard-muted during stakes
      conversations. Alternative: private by default (everyone uses
      it, but the best MMO-only scenes never happen).
- [ ] **Multi-party scope.** Which NPC classes accept 3–4 speakers,
      and does diarization survive console mic quality?
- [ ] **Model tiering boundaries.** Where exactly the bark / ambient
      / story-bearing lines fall, and the per-turn cost ceiling a
      buy-to-play game can carry in perpetuity (L27).
- [ ] **Gossip distortion: authored or generated?** Authored
      distortion tables are safe and repetitive; generated
      distortion is alive and can invent canon it shouldn't.
- [ ] **Is disposition visible to the player?** A number kills the
      illusion; nothing at all makes NPC coldness feel like a bug.
- [ ] **Where the intent whitelist ends** — how much can be
      negotiated by voice before it must become a confirm panel
      (§9.2).

---

**Everything below closed as of 2026-07-28.** Kept as the decision trail.
New questions raised by the feasibility pass live in
`feasibility-review.md` §5 and the per-doc "open tuning questions".
- [x] Ordinary death details → **L32**: ~10% durability on all
      equipped; wedge cargo owner-locked ~10 min, then open loot,
      despawn ~1 hour; respawn at bound blood-shrine.
- [x] Character transfers → **L37**: forbidden. Rebirth instead —
      fresh start elsewhere keeping only account flair; the old world
      keeps an epitaph line. Covers dying servers and friend-chasing
      without breaking lineage or the Monument.
- [x] Setting/tone → resolved by **L20** (M-rated grounded dark,
      low-magic medieval).
- [x] Classless vs classed → resolved by **L18** (classless,
      skill-by-use; magic skills hidden until awakening).
- [x] Crafting depth vs accessibility → **L38**: depth in the
      ceiling, not the floor; no stage hard-fails a patient beginner.
- [x] Combat latency → **L39**: favor-the-defender netcode +
      animation-commitment readability; vertical-slice gate.
- [x] Teaching numbers → **L33**: 3 slots at Master, +1 at
      Grandmaster; 7-day dismissal cooldown (graduation frees
      instantly); lineage XP counts fully up to Grandmaster and stops
      there; daily trickle capped at ≈1 hour of own practice.
- [x] Incarnate powers → **L34**: true form = one broken rule per
      spell + a visible bodily tell; never a numeric tier. Seat is
      fame + risk; declining is quiet power. (Per-spell rule-break
      list is content work, not design.)
- [x] Succession Trial details → **L35**: 3-day lead, midnight
      Trial in the Veiled Ring; team-ups legal, one winner (betrayal
      by design); awakened-only crowd with shadow-book betting;
      living Incarnates spectate only; echoes barred.
- [x] Naming collision → **RESOLVED**: the spell seat is the
      **Incarnate** (the spell made flesh); "Ascension"/"Ascendant"
      now refers only to the demigod gate. Renamed throughout the
      docs. In-world line: *"Incarnates embody the god's blood;
      the Ascended leave the world."*
- [x] Magic secret / season 1 → **L36**: the *information* secret is
      expected to break at internet speed; the *mechanical* climb is
      what's paced. Awakening gated by seeded, server-throttled
      events; total marketing silence; layered secrets so wikis go
      stale against each server's own history.
