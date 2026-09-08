# Marrowmark — Design Pillars & Decision Queue

Status tracker for the big structural decisions. Detail lives in
`brainstorm.md`; this file is the map. Updated as decisions lock.

---

## Locked foundations (as of 2026-07-26)

| # | Pillar | Decision |
|---|--------|----------|
| L1 | World shape | The Wheel: 6 **large** town regions ringing an **extra-large** capitol hub |
| L2 | Combat feel | BotW-style real-time action combat |
| L3 | Durability | Repair/wear economy. ~~No mid-fight breakage~~ — **amended by L62/L63 (2026-09-08)**: things do break, but only as the earned end of a long visible decline, never at random |
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
| L21 | Lore | Godsgrave cosmology adopted as working canon (`lore.md`): the god's blood explains respawn, regional materials, monsters, awakening, and permadeath; four faiths; six named towns; the Quickened = the awakened (L52); anyone is awakenable; secret canon in §9 |
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
| L40 | Max level (the ascension gate) | Extends L18/L12. "Max level" = your **top 8 skills, summed against a threshold**. Breadth past 8 contributes nothing, so the gate demands real depth — but *which* eight is entirely the player's, and two ascended characters need share no skill. Magic skills are **eligible but never required**: there are far more than 8 mundane skills, so no one is gated on awakening and the visible game still reaches the endgame on its own (`feasibility-review.md` §3.4). Threshold number is tuning |
| L41 | Epoch advancement | Extends L23. **Thresholds arm; a named act fires.** Server-side conditions (awakened count, witnessed public castings, institutional pressure) arm the next epoch and are live-tunable — this is §3.3's dial. Once armed, the age turns only when a player commits the qualifying public act, and that player is named on the Monument (L23). Before arming, the same act does not turn the age — it just gets you hunted. An early hero fails dangerously rather than being told no |
| L42 | Earning an Incarnate mark | Extends L10/P12. **Winning the seat marks you.** Claim an Incarnate seat, then end that life, and the account keeps that spell's sigil on every character after — unexplained, forever. Holding or losing a seat leaves nothing. The road is deliberately brutal: one seat per character (L10) means each mark is a full character lifetime ending in a claimed seat |
| L43 | Arrival in the Age of Gods | Extends P12. **Knowledge, not power.** A marked account arrives already awakened, knowing its marked spells by name and effect — and casting them at Novice. The climb is real and must be walked again. This is vision.md's third promise ("knowing isn't having") restated at account scale, and it keeps L19's power curve intact in a world you would otherwise enter pre-solved |
| L44 | Marks required; two doors | Extends P12/L42. **Six marks** opens the Age of Gods — a genuine lifetime road, kept as raised. Because six claimed seats is close to a decade, the prequel has a **second entrance** (L45): refusing godhood at the Heart. Marks are the long road walked by the living; the Heart's refusal is the short road paid for with everything. Neither is required for the other, and the expansion's audience is the union of both |
| L45 | The Age of Gods **is** the sealed arc | Extends L30/P12. The "other option" at the Heart (`demigod-realm.md` §4) and the seal-weakening expansion hook (`lore.md` §9) are **the same door as P12's** — refusing pantheon godhood is what cracks time open. Three dangling threads become one. Launch data still contains nothing about what refusal does; the answer now exists internally, sealed, instead of being a promise with no payload |
| L46 | Proximity speech is always audible | Extends P11 §9.4/§9.6. **No in-fiction mute, no whisper channel, no private mode.** Speech in public is public, always — the strongest version of the tavern-as-information-market bet. Secrets therefore leak from careless *placement*, by design. Stakes-bearing NPCs (Circle contacts, the Lamp, anything touching L22) are protected diegetically instead: **they simply refuse to speak while anyone is in earshot**, which is better fiction than a muted channel and the same protection. Platform-level personal block/mute exists as a safety and certification layer (required by all three console platforms for player-to-player voice) — never as a gameplay toggle |
| L47 | Disposition is never numeric | Extends P11 §9.3. No bar, no number, no named tier. An NPC's regard reads entirely through behavior: greeting warmth, whether they use your name, body language (head turns, lean-ins, the eyes going to an eavesdropper), how much they volunteer, and whether they end the conversation and walk off. The budget goes to animation and voice direction, not UI — §9.3's own position, that cheap animation sells *alive* better than model quality |
| L48 | Gossip distortion is generated | Extends P11 §9.3. Distortion is **fully generated** — the model decides how a rumor curdles and says it in the NPC's own voice. Alive, never a pattern players can memorize. One hard constraint: **the noun space is fixed.** Retrieval supplies every proper noun (real people, towns, goods, events on this server); the model may invent causes, motives, exaggerations and interpretations freely, but never a new name — and above all never a spell name. A generated false spell sends a whole server hunting something that does not exist. Invented *meaning* is the feature; invented *nouns* are the bug |
| L49 | The intent ceiling | Extends P11 §9.2. **No ceiling on what the model may propose; a hard gate on what executes.** The model can reach for any intent, including war declarations and escrow — but every binding intent (coin, gear, enrollment, escrow, contract, charter, war) requires explicit player confirmation before it takes effect. The panel is the gate, never a receipt for something already done. This keeps §9.2's rule intact — the model still never mutates state — while removing the whitelist's expressive ceiling. A misheard sentence can raise a panel; it can never sign one |
| L50 | The enemy at launch | Extends L21/`lore.md` §9. **Rare, deniable traces only.** A handful of things across the whole world that the Godsgrave cosmology does not explain — wrong-shaped wounds, a deep-delve chamber older than the god, ruins in the Interior nobody built — each always explicable as something ordinary. Nothing names it, nothing confirms it, and no NPC knows. Rewards obsessives, spoils nothing, and gives the Heart's revelation the foreshadowing it needs to land as a payoff rather than an asspull |
| L51 | Switch target is Switch 2 only | Amends L15. The Nintendo target is **Switch 2 exclusively** — original Switch is not supported. This materially downgrades **T2** (the Switch battle ceiling, `feasibility-review.md`), which was the constraint holding war enrollment caps toward 60v60; L25's 150v150 aspiration becomes plausible rather than fantasy. Crossplay across PC/Xbox/PlayStation/Switch 2 is unchanged |
| L52 | Title: **Marrowmark** | The working title "Bloodborn" could not ship — *Bloodborne* is a live trademark in the same goods class, phonetically identical, and the name argued against L36's marketing silence by promising the supernatural on the box. **Marrowmark** is a coined compound: grounded, registrable, and quiet about magic. The in-world term for the awakened moves with it — **the Quickened**, which grows out of `lore.md`'s own language (the blood *quickens*) and is truer to L21, since anyone is awakenable rather than born to it. Professional clearance (`naming.md` §5) is still outstanding and blocks anything public |
| L53 | PC first; consoles follow | Sequencing under L15, not a reduction of it. All four platforms and full crossplay remain the commitment; PC ships first because console certification costs money and months while teaching nothing about whether the game is good, and every design risk in the project is answerable on PC. **Crossplay is designed for from day one** — controller-first input, no keyboard-dependent systems, no PC-only UI affordances — so consoles are a port, never a retrofit |
| L54 | Engine: **Unity**, URP, Unity 6 LTS | `tech.md` §2. Chosen over Unreal 5, which that document previously recommended, once two constraints entered the reasoning: the developer is new to gamedev, and an AI collaborator is a major share of the labour. Unity is **all text** (C#, YAML scenes/prefabs, C# editor tooling) so the whole codebase is legible to both; it puts client, headless server and tools in **one language**, which matters enormously for one person; and it has the gentlest learning curve of the serious engines. The cost is real — Unreal's Nanite/Lumen art leverage is given up for more hand-optimization and a lower out-of-box ceiling — and is the right trade here because Marrowmark's distinctiveness is systems, not fidelity. **No engine's built-in networking is MMO-scale**, Unity's included: the zone-server layer is code to be written, not a package to install |
| L55 | Stamina is exertion, not just combat | Extends L2/`combat.md` §2, and reverses that document's original "does not govern walking, riding, or crafting" line. **One bar covers fighting and the physical cost of crossing the world.** Combat actions, sprinting, climbing, swimming and jumping all draw on it, and **encumbrance shrinks it** — what you carry reduces what you have to spend, so hauling cargo (L17/L32) is felt before any bandit appears. This is what stops L28's "distance is real" promise from being free: a stamina bar that ends at the edge of combat makes travel costless and quietly contradicts the pillar. Deliberately exempt: **walking** (a cost there is misery, not tension), **riding** (L28 makes mounts the speed system; the horse has its own limits, not yours) and **crafting** (L38's floor rule forbids gating the flagship system). The exemption list is an interpretation pending confirmation — see the flag in `combat.md` §2 |
| L56 | Combat is athletic, not supernatural | Extends L2/`combat.md` §0–§1, §3. Fights are **kinetic — you move while you fight**: dodges reposition rather than merely evade (so exchanges circle instead of shuffling on a line), momentum feeds attacks, and terrain is fighting space. **Techniques are primarily how you move** — a dash-thrust, a spinning step-through, a leaping overhead — so learning a weapon expands where your body can go, and progression is felt as mobility rather than numbers. This is Marrowmark's Sword Skill: still a commitment, still stamina-priced, still readable, so §6's grammar is untouched. **Mobility is afforded, never required** (amended 2026-09-08): standing your ground behind a shield and winning a stamina war is a legitimate build, not a failure to play correctly — L18 is classless, and a game that only rewards footwork has one build wearing different hats. Both ends spend the same bar differently: the mobile fighter spends it on movement and avoids damage; the grounded fighter spends it on absorption, since blocking bleeds stamina instead of health. Armour weight rides the same encumbrance channel as cargo (L55), so plate means a smaller bar — the cost that keeps heavy builds honest. **Ceiling: anything a trained human body could do, nothing it could not** — no double jumps, air dashes, midair multi-hits or wall-running. That ceiling is a deliberate saving: the mortal world stays bound by human bodies so that an Incarnate's true form breaking its one rule (L34) lands like a thunderclap. A world where everyone already defies gravity has nothing left to spend when magic arrives |
| L57 | One encumbrance budget: armour competes with cargo | Extends L55/L56. Armour weight and carried goods draw on the **same** stamina budget, so a fighter in plate hauls almost nothing and a loaded hauler fights badly. **You cannot be both the cargo and the muscle.** This is deliberate and its real payoff is economic rather than tactical: escort work becomes a profession instead of a favour, caravans (L26/L28) have a reason to hire that no rule had to invent, and a merchant is genuinely vulnerable in a way that makes the roads matter. Guards who armour up are guards who are not carrying, which is exactly the division of labour a physical-goods economy wants |
| L58 | Armour changes on the road; the armour sets the cost | Extends L57. Armour can be changed **anywhere** — no camps, no towns, no menus — but the class decides how long you are helpless doing it: seconds for light, a minute and more for plate, faster with help (historically plate needed a second pair of hands, and here that gives a caravan crew a reason to stop together). Mid-change you are still wearing what you started in, and **interruption loses all progress**, so armouring up is a gamble on having enough time rather than a free action. This is what turns L57 from a loadout constraint into a live decision on the road: a guard is either armoured and carrying nothing, or carrying goods and a minute away from ready — and an ambusher can read which, at a distance, before choosing the moment |
| L59 | Repairs shrink the ceiling; gear dies | Extends L3. **Every repair restores condition but permanently lowers the item's maximum.** Once that ceiling falls past roughly a quarter of the original, the item is scrap — materials, not equipment. This is the sink that makes `brainstorm.md` §2.6 true: war losses and Interior deletion touch some players, but **wear touches everyone every day**, and it is the only demand engine that never stops. Without it a masterwork blade forged in year one is still circulating in year five and crafting collapses into a checklist |
| L60 | Wear bites only past a threshold | Extends L3/L59. An item performs **perfectly down to about half condition**, then declines. Casual wear costs nothing; neglect costs real damage. This is L38's floor philosophy applied to upkeep — maintenance is never a tax on ordinary play, only on ignoring it. And **nothing ever breaks in your hands**: a fully spent item is bad, not useless, because L3 forbids mid-fight breakage absolutely. There is no state in which a player's weapon stops working |
| L61 | Anyone repairs; skill sets the price | Extends L59. **Any player can repair with materials, anywhere** — but the smith's skill decides how much ceiling the repair costs. A field patch by an untrained hand gets you home and shortens the blade's life badly; a master's bench repair costs it almost nothing. Measured on the current tuning: an amateur-patched item survives ~19 repairs, a master-maintained one ~76 — a fourfold difference in working life. That spread is what makes master smiths worth travelling to and turns **repair into a profession**, not a chore, without ever stranding a player whose kit fails deep in a wedge |
| L62 | Weapons break — earned, never random | **Amends L3.** A weapon breaks only when it reaches zero condition **and is used again**, after the whole visible decline of L60. There is no randomness at any point: a player who repairs before the danger zone will never once see an item fail, and one who fights on with a ruined blade chose to. That distinction is everything — L2 names BotW as a reference, and BotW's breakage is its most resented mechanic precisely because it is fast and arbitrary. A broken item is scrap and cannot be repaired, which gives the moment weight and keeps the item sink (L59) honest. Consequences the design gets for free: **backup weapons become real** (and cost encumbrance under L57, so "second blade or more cargo?" is a genuine decision), and visible weapon damage lets a duellist **read that an opponent is one parry from disaster** — exactly the no-UI information L20 wants |
| L63 | Armour is per slot; pieces break off | Extends L62. Armour is tracked across **head, torso, arms and legs**, each with its own condition. A piece that breaks does not merely stop protecting — **it comes off**, and that slot is bare for the rest of the fight. Armour therefore degrades in visible steps rather than vanishing: the vambrace goes, then the helm, and a fighter who started the day in plate finishes it half bare and increasingly desperate. That progression is legible to everyone watching, and with unarmoured damage sitting well above every armoured class, losing a piece is felt immediately. Also allows piecemeal kit, which is what a poor fighter actually wears |
| L64 | Directional combat, Kingdom Come-style | **Five cutting arcs plus the thrust, chosen by free aim** rather than a menu — right stick, snapped to the nearest zone on a controller (KCD shipped this on consoles; precision is the cost, not feasibility). Direction is **not a second system stacked on** `combat.md` §6's attack shapes — it is the other half of the same telegraph: the weight shift says quick or heavy, the wind-up says where. One read, two pieces of information. **Direction decides which armour slot takes the blow** (overhead→head, high cuts and thrusts→torso, low arcs→legs), which is what makes L63 mean something: which piece of a harness fails is now a record of how its owner was fought. Guards must match the arc — an adjacent guard glances, anything else lands clean, and **only a thrust guard stops a thrust**, which is why the point is dangerous against someone reading edges. Nothing is aimed at the arms, because arms are what you raise to defend: **vambraces wear from blocking**, so a sword-arm that gives out after a day of parrying is the most grounded failure the system can produce |
| L65 | The guard is read from the body | Extends L64 and `combat.md` §6's no-UI rule. **No guard indicator of any kind.** You read an opponent's guard from how they hold the weapon, the same way you read whether a blow is quick or heavy. This is the most demanding readability requirement in the design and it makes **animation quality load-bearing rather than decorative** — if a guard pose does not read at a glance, the combat does not work and no interface element may be added to rescue it. Consequence recorded plainly: combined with L64, this is the steepest learning curve in the genre, and it makes the still-unwritten onboarding document the most important gap in the project |
| L66 | Materials have properties, not quality | Extends L4. Four continuous axes — **hardness, toughness, density, purity** — rolled per source, each with a real cost, so no configuration is simply best. Hardness buys the edge and fights toughness; toughness buys the item's life (L59's ceiling); **density buys blunt force and charges weight**, which eats stamina headroom under L55/L57, so one number has three consequences and no right answer. **Purity is a multiplier on skill's reach**, not a bonus of its own: clean stock rewards a good hand and does little for a poor one, which is why masters bid for good ore and beginners should not. Detail in `crafting.md` |
| L67 | Stages are trades; skill decides your share | Extends L4/L38. A pipeline is hands-on operations — smelt, fold, quench, temper, grind — and **every stage offers something and charges something**. The asymmetry that matters: **skill scales what you collect, the charge is the same for everyone.** A master and a beginner quenching one billet lose the same toughness; the master takes far more hardness for it. This is L38 made mechanical — no stage can hard-fail a patient beginner (a floor on realisation guarantees an unskilled hand still improves the work), while the ceiling stays enormous. Gains meet diminishing returns and costs scale with what is there to lose, so **each stage acts on what the last one left and order is part of the craft** — tempering an unquenched billet is a wasted heat, and no wiki can hand that understanding over as a number |
| L68 | Everything is signed | Extends L4. **Every finished item carries its maker's name, good work and bad.** No anonymous path exists — the code has no overload permitting one. Reputation becomes earned and losable, so flooding a board with rubbish costs a smith their name; second-hand gear becomes legible, which matters in an economy where goods physically travel and wear out; and marks are permanent, outliving their makers (`tech.md` §4), so a blade signed by someone long dead is a real object with a history |
| L69 | Onboarding is an apprenticeship, not a tutorial | `onboarding.md`. **No tutorial zone, no tooltips, no training room** — all three break L20 before the player has seen anything. You begin as somebody's **hired hand**: a smith, a carter, a drover with a trade, work that needs doing, and opinions about how it is done. They teach you because that is what employers do. This is already paid for — P11's conversational NPCs exist to be the display layer for world state, and teaching is the same job. The master replaces the quest marker (spoken directions in landmarks), the tutorial popup (someone watching you work), the class choice (a trade you can leave), and the recipe list ("watch; now you do it") |
| L70 | Directional combat is taught by a person who stops talking | Extends L65/L69. L65 forbids a guard indicator, so it is replaced by a **sparring partner who calls the arc aloud and then gradually stops** — announced and slow, announced at speed, unannounced with one arc, then two, then everything. This is the fading-indicator idea made **diegetic**, so L65 survives intact: the information comes from a person's voice rather than an interface, and it stops because *they* stop. A player who wants it back asks for it back, out loud. The drill yard is never exited — veterans learning a new weapon family return to it, and so do Companies drilling before a declared war (L25) |
| L71 | You learn from difficulty, not repetition | Closes P3's long-open anti-grind question. **A task well below your skill teaches nothing** — past a window beneath your current level, gain is zero. This is the whole anti-macro design, and it is a rule about *learning* rather than a rule about *players*: a bot hammering an easy action is not cheating, it is wasting its own time, and nobody genuinely playing is ever punished by it. Two supports: a **daily soft cap** (L33's precedent — past it learning slows sharply but never stops, per L38's spirit), so no marathon replaces months; and **no decay ever**, because a trade you learned is a trade you know. Measured on current tuning: casual play (~20 uses/day) masters one skill in ~88 days, heavy play (~200/day) in ~15 — a tenfold playtime difference buying a sixfold time difference, and L40's gate needs eight of them |

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
Classless skill-by-use, moderate vertical power curve. The ascension
gate is **L40** (top 8 skills against a threshold; magic eligible,
never required), and anti-grind is **L71** (you learn from difficulty,
not repetition) — which closes the last structural piece here. Both are
built and tested in `sim/Marrowmark.Sim/Progression/`. Remaining: the
threshold number and per-skill caps, which are tuning.

### ~~P4. Setting, tone & lore~~ ✅ LOCKED → L20, L21
Working canon in `lore.md`. Epoch advancement is now **L41**
(thresholds arm, a named act fires). Remaining sub-questions: final
naming pass; the enemy's nature (§9); how much each faith questline
glimpses of the secret canon.

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

Four of its questions are now locked: **L46** (always audible),
**L47** (disposition never numeric), **L48** (generated distortion over
a fixed noun space) and **L49** (no proposal ceiling, hard execution
gate). Still open: multi-party scope (needs the prototype), and —
escalated — **the cost ceiling, which now reaches the business model.**

⚠️ **P11 vs L27 — the open commercial question.** §9.1's arithmetic
(~33 inferences/sec at 3k concurrent, forever) is a permanent
per-player operating cost on a game with no recurring revenue. That is
a genuine collision with L27's buy-to-play lock, and it is not settled.
Subscription is explicitly on the table. Note that a sub breaks L27's
*letter* while keeping its *spirit* intact — no pay-for-power, no
cosmetic shop, no crafter-competing goods — which makes it a far
cleaner fit than any monetization that sells advantage. Alternatives
still live: per-account daily story-tier budget degrading in-fiction,
per-NPC rate limits, or shipping story-tier NPCs only with expansions
that fund their own inference. **Decide after the slice measures real
cost per turn** — this is the one question where paper numbers are
worth less than a week of telemetry. Full list at the bottom of
`brainstorm.md`.

Slice gate (§9.8): one town, six voice NPCs, one rumor that provably
arrives *wrong* in the next town, one epoch flip that visibly changes
what all six say.

### P12. The Incarnate marks & the Age of Gods 🔶 OPEN (2026-09-08)
`brainstorm.md` §10. Hold an Incarnate seat (L10), end that life,
and the *account* keeps a **mark** — the sigil of the spell you
embodied — on every character after. Nothing explains it. Six
distinct marks open passage to an **Age of Gods** world: the same
Wheel, centuries before the god's death, when the gods still walked
and magic was not yet a secret. You relive history knowing how it
ends.

Shape that already feels settled: the mark is **account flair, not a
transfer** — L37 holds intact, nothing of the character moves; the
tone inversion is **social, not visual** (magic as a licensed trade,
gods as landlords — same medieval bar, opposite feeling, §10.3);
**nothing flows back** from the prequel (§10.6); and the hook ships
at launch as an icon and a counter while the expansion waits on
whether players catch fire over it (§10.9).

This is the first answer in the design to *what a veteran chases
after the seats are taken* — but it does not answer the year-two
newcomer joining a world whose mystery is already solved (§10.8).
That gap stays open.

Two of its questions are now locked: **L42** (winning the seat is what
marks you) and **L43** (you arrive knowing, not powerful). Still open:
how many marks, whether this **is** the sealed expansion arc
(`demigod-realm.md` §4 / `lore.md` §9) rather than a third thread, how
it relates to the Interior, how much secret canon a playable prequel
spends, and whether the Age of Gods writes per-server history (L23).
Full list at the bottom of `brainstorm.md`.

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
10. **Incarnate marks raised as P12** (2026-09-08) — `brainstorm.md`
    §10; open, seven questions to settle, launch hook separable from
    the expansion.
11. **Open-questions pass, session 1** (2026-09-08) — L40–L50 locked:
    the ascension gate (L40), epoch advancement (L41), P12's marks and
    arrival (L42–L45), and four of P11's six calls (L46–L49), plus the
    enemy's launch presence (L50). P11's cost ceiling escalated to a
    business-model question rather than forced. **Resume here:** P12's
    two remaining questions (secret-canon spend, per-server history),
    then the content structures that unblock the slice (rumor data
    model, the casual awakening chain), then economy and war numbers,
    then the naming pass.

**The original ten structural pillars are locked (71 decisions).** P11
(living NPCs) and P12 (the Incarnate marks) are new and open — both
added since the sweep. The one-page
distillation is `vision.md`; the build-and-play sanity check is
`feasibility-review.md` (design PASS; production PASS at AAA scale
or via the staged path in §5).

### Next phase

0. ⚠️ **Trademark clearance on "Marrowmark"** — `naming.md` §5. The
   title is chosen (L52); clearance is not done. Class 9 and 41
   searches plus a common-law sweep, and an attorney. This blocks any
   public material, store page, domain, or social account.
1. **Naming polish** — currency ("marks" is placeholder), the six
   town names, "the Interior," spell naming conventions. **The "mark"
   collision is now four-way** and effectively settled by L52: the
   *title* contains it, which makes maker's marks (L4) the canonical
   in-world "mark" and forces the currency to be renamed outright.
   P12's Incarnate sigil needs its own word too (`naming.md` §4).
2. **Build Stage 1 of `tech.md` §6** — single-player combat, in six
   steps from a character controller to a working parry. `combat.md`
   §9's prototype is the target, but its networked half (Stage 2) is
   what actually settles the L39 gate and cannot be attempted until
   Stage 1 exists. For someone learning Unity, Stage 1 *is* the
   learning, and it ends in something a person can hold a controller
   and play. The full vertical slice is Stage 3 onward.
3. **Two prototype-shaped risks to answer inside the slice**:
   the Switch battle ceiling (`feasibility-review.md` T2) and
   contested-delve pressure (§4.3).
4. **Settle P11's six open questions**, then prototype the living-NPC
   gate (`brainstorm.md` §9.8) alongside the slice — latency, cost per
   turn, and STT across accents are all things paper won't answer.
5. **Decide P12's cheap half now** — the mark is an icon and a
   counter and belongs in the launch data model whether or not the
   Age of Gods is ever built. The expensive half can wait a year for
   evidence.

### Gaps with no doc yet

Raised 2026-09-08. Not open *questions* — open *documents*.

**Now written:** ~~combat design~~ → `combat.md` (the L39 gate, the
skill-vs-gear resolution, enemy vocabulary, the latency contract).
~~Technical design~~ → `tech.md` (engine, server architecture, data
model, solo production strategy, build order). ~~The title problem~~ →
`naming.md`.

~~Onboarding~~ → `onboarding.md` (L69/L70): the tutorial is a person who
employs you, and directional combat is taught by a sparring partner who
calls the arc aloud and gradually stops.

**Still uncovered**, each load-bearing: live-ops and the
server's second year; moderation and trust & safety (which P11 aims a
live microphone at, and which L46 makes sharper); UI and information
design, including the companion app (L31); art and audio direction —
note that `combat.md` §6 makes animation and sound readability a
**hard requirement**, not polish; and telemetry for the awakening
throttle that §3.3 calls the most important live-ops dial in the game.
