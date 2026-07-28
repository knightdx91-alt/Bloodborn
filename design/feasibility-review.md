# Bloodborn — Feasibility & Simulation Pass (v1)

STATUS: review artifact, 2026-07-28. Run against L1–L39 and the five
working-canon docs. Two lenses: **can it be built** (developer) and
**does it hold up when real people play it** (player simulation +
red team). Nothing here unlocks a decision; it flags where a lock
needs a guard rail or a prototype proof.

---

## 1. Developer feasibility

### 1.1 The honest scope statement

This design is a **AAA-scale MMO**: full-3D open world (7 large
regions), crossplay across 4 platforms including Switch, action
combat with rollback-adjacent netcode, a fully player-driven economy,
a systemic monster ecology, a hidden second game (magic), a
permadeath endgame realm, and a companion app. Comparable projects
(New World, Ashes of Creation, Camelot Unchained) ran 100–300+
people and 5–8 years, at $100M+. **The design is coherent; the
feasibility question is almost entirely budget and team, not
mechanics.** Everything below assumes that's understood and the
answer is either funding at that scale or a ruthless staged scope
(see §5).

### 1.2 Technical risk register (ranked)

| # | Risk | Severity | Notes |
|---|------|----------|-------|
| T1 | **BotW-feel combat at MMO latency** | Critical | L39's stance (favor-the-defender + animation commitment) is the right one and has partial precedent (ESO, New World). But "feels BotW-good at 100ms" is unproven at 150v150. Vertical-slice gate is correctly placed. |
| T2 | **Switch as crossplay floor** | Critical | 150v150 battles + capitol crowds on Switch-class hardware is the single most likely promise to break. Options: cap war battles lower (60v60), aggressive crowd imposters, or accept Switch ships later / next-gen Switch only. Decide before the slice, because it caps battle design. |
| T3 | **Cheat pressure vs. client-favored netcode** | High | Favor-the-defender + real item loss (war drops, open loot) = strong incentive to cheat on PC, and client-authoritative windows widen the attack surface. Needs server-side sanity bounds (max i-frame budget/minute) and a stats-anomaly pipeline from day one, not post-launch. |
| T4 | **One shared world per region at 5–10k chars** | Medium | Small worlds are *cheaper* than megaservers — this is a feasibility positive. But 6 towns × economy needs a minimum viable population per world (see §3.1). Many small worlds also multiplies live-ops (epoch states, Incarnate rosters per server) — all database-driven, so tractable. |
| T5 | **Systemic content stack** (ecology, rumor, contracts, named horrors) | Medium | Each is individually simple (world-state → generated text/contracts), but they compound into a QA surface where bugs are *lore* ("the board lied about the world"). Needs a world-state simulator running in CI. |
| T6 | **Companion app** | Low-Medium | Read-and-manage only (L31) keeps it thin, but it's still a second client, second release cadence, second security surface. Cut-safe: ship post-launch without breaking any promise. |
| T7 | **The Interior** | Low | Four rings for <1% of players is a classic content-cost trap, but the doc already contains the mitigations (echoes, Monument, scrying question) and the rings are small by design. Build it late; the gate can stay closed at launch week. |

### 1.3 Production positives worth naming

- **War is scope-sane by construction** — rights are database rows,
  battles are field events on existing terrain, no sieges or
  destructible towns (war-society §4). This is the cheapest possible
  version of meaningful territory war.
- **Epochs are cheap** by design (L23: dialogue, laws, posture —
  not rebuilt maps).
- **Classless skill-by-use** (L18) deletes an entire class-balance
  department.
- **No instancing** (L29) removes a whole server-tech layer (at the
  cost of contested-space social risk, see §4.3).
- **Marketing silence** (L36) is a commercial risk (a B2P MMO hiding
  a third of its systems from its own store page) — but the "grounded
  crafting/war MMO" that's *visible* is already a sellable game. The
  visible game must be able to justify the box price alone. It can.

---

## 2. Player simulations (archetypes vs. the locks)

### 2.1 Casual Chris — 6 hrs/week, one town, one trade
- **Works:** starts with a trade and a town (content.md §4); crafting
  floor never hard-fails him (L38); shop runs offline via NPC staff +
  app; death costs ~10% durability, no gear loss outside wedges;
  coach/barge travel is his session-friction answer.
- **Strain:** under L36's throttled awakening, Chris probably *never*
  awakens in year one — and after the server-wide Unveiling, "magic is
  real and I still can't have any" can curdle. **Guard rail needed:**
  awakening seeds must not be pure playtime-lottery; at least one
  slow, reliable path (faith questline depth, rumor chains) should be
  completable at casual pace, arriving in months, not never.
- **Verdict: holds, with the guard rail.**

### 2.2 Marta the Market Baron — shopkeeper/caravaner
- **Works:** the whole economy chapter is her game: local price
  spreads as a profession, commissions, ledgers, app management.
  Item sinks guarantee perpetual demand.
- **Strain:** thin-market risk (see §3.1); and offline shops + NPC
  staff invite undercut-sniping wars fought via the companion app at
  3am. That's arguably *gameplay*, but standing-order tools must be
  good enough that sleep isn't a competitive disadvantage.
- **Verdict: holds; strongest archetype in the design.**

### 2.3 Ban the Banner — war player
- **Works:** declared, staked, scheduled wars with real gear loss and
  bystander protection is a proven fun shape (structured GvG).
  Mercenary Companies mean war access without politics.
- **Strain:** scheduled battles across time zones on worlds that are
  region-sharded needs battle scheduling to be *negotiated at
  declaration* (it's listed open in war-society; flag it as required
  for the slice). Also, 30v30–150v150 with T2 unresolved may land at
  the low end.
- **Verdict: holds; scheduling is the open sore.**

### 2.4 Quill the Aspirant — wants magic
- **Works:** the discovery→teacher→lineage climb is the game's best
  story. Teaching math checks out: with 3 slots/master and
  graduation freeing slots, spread is exponential but socially
  gated — a server goes from 1 knower to ~hundreds over months,
  which matches the L36 pacing target.
- **Strain:** the 30-day Incarnate lapse (L10) fires on *account
  inactivity* — a hospital stay or a deployment costs a seat with a
  server-wide announcement attached. **Guard rail suggested:** a
  one-time per-holder "regency" declaration (pre-announced absence,
  seat held, say 60 days, usable once) keeps the pressure while
  removing the cruelest case.
- **Verdict: holds, one cruelty to sand off.**

### 2.5 Grim the Griefer — plays to ruin days
- Open-world ganking: wedge deaths cost the *victim* cargo but the
  ganker gains little (equipped gear never drops, L17), and towns/
  spokes are safe. Payoff-to-grief ratio is deliberately poor. ✔
- Corpse/shrine camping: shrine respawn is involuntary and tithed;
  binding choice lets victims relocate. Add standard grace-on-respawn
  and this is contained. ✔
- War griefing: escrow prices out fake declarations (war-society §3.1). ✔
- Loot-vulture careers (waiting out the 10-min grace at wreck sites):
  this is *intended* gameplay (salvage/banditry), not grief. ✔
- **Verdict: the design is unusually grief-resistant for a
  full-physicality MMO; the dangerous surface is chat/social, which
  is a moderation problem, not a design problem.**

### 2.6 Vex the Exploiter — plays the systems, not the game
- **Trickle farming:** capped at ~1hr-equivalent/day (L33). ✔
- **Kill-trading for ichor** in the Skin (two demigods farming each
  other's respawns — except there are no respawns; permadeath makes
  kill-trading self-terminating). ✔ Elegant.
- **Trial match-fixing / betting manipulation:** team-ups are legal
  (L35) and the book is a shadow book — collusion is *lore*. But
  shadow betting + RMT is a real-money laundering vector; the RMT
  enforcement plan (L27) must explicitly cover the Veiled Ring's book.
- **Seat-lapse sniping:** a Circle could social-engineer an
  Incarnate into quitting, then farm the announcement. Honestly?
  That's a story. Keep it.
- **Cargo insurance fraud** (House insurance product, economy §3 —
  insure a caravan, "lose" it to a friendly bandit, split): needs
  claims tied to verifiable world events (the death, the looters'
  identities are all server-known). Design the insurance product
  around what the server can prove.
- **Verdict: mostly pre-answered; two named follow-ups (RMT-in-
  shadow-book, insurance fraud).**

---

## 3. Systemic stress tests

### 3.1 Population math (the one real design-side worry)
1–2k peak concurrent across 7 large regions ≈ 150–300 concurrent per
region before capitol weighting. Split those across delving, war,
roads, and shops, and a town's market board might have **a handful of
active sellers per goods category**. Player-driven economies die of
thin markets, not exploits.
- Mitigations already in-design: local-only boards concentrate
  liquidity per town; NPC staff keep shops open while owners play
  elsewhere; the capitol Concourse is the deep market.
- **Recommendation:** treat 1–2k concurrent as the *floor*, tune the
  Wheel's size to feel full at floor population, and hold a
  launch-surge plan (more worlds, never bigger ones — L16's fame
  logic depends on smallness).

### 3.2 Death-ladder economics
~10% durability per death (L32) × repair-material consumption (L3) +
war drops (L11) + Interior deletion (L12): three sinks at three
scales. The loop closes: casual deaths feed repair trade, wars feed
replacement trade, ascensions delete top-end kits so the best gear
never saturates. **No inflation hole found** — the watch item is coin
(faucets are modest, sinks are everywhere; early-economy deflation is
the likelier failure — tune faucets generous at server-start epoch,
tighten as wealth accumulates).

### 3.3 Secret-erosion pacing
L36's layered structure survives its own spoiling: layer 1 (magic
exists) is sacrificial; layers 2–4 are per-server facts (which spells,
who holds seats, whose lineage) that a wiki *cannot* spoil because
they differ per world. The throttle valve (awakening seeding) is
server-side and tunable live — the single most important live-ops
dial in the game. Build it as a dial, not a constant.

### 3.4 The visible game must carry the box
Restated as a test: strip every hidden system out of Bloodborn and
ask if the remainder — crafting, shops, caravans, wars, delves,
arena, councils — is a game worth $60 with zero knowledge of magic.
Reading economy.md and war-society.md: **yes, narrowly** — it's
"medieval EVE-lite with BotW combat," which has an audience. But it
means crafting and war polish cannot be traded away to fund the
secret layers; they ARE the product on the shelf.

---

## 4. Contradictions & friction found (small, fixable)

1. **L28 vs shrine binding (L32):** binding at a far shrine then
   dying deliberately is a slow one-way teleport (naked, cargo
   dropped). Mostly self-punishing — but pair it with the tithe
   scaling by distance-from-death to kill the last edge case.
2. **Trial secrecy vs. server-wide announcements (L10 vs L22):** a
   *server-wide* "the Incarnate of Fireball has fallen" broadcast in
   the Myth epoch contradicts magic being unknown. Fix: the
   announcement's *surface form is epoch-gated* — in Myth/Whispers it
   reaches only the awakened (dreams, marked coins, Circle word); the
   public version ("a famous duelist has died") appears post-
   Unveiling. Same trigger, epoch-dressed.
3. **Echo tech vs. institution secrecy (L14 vs L22):** public arena
   echoes of dead demigods are fine (ascension/faith is public), but
   confirm echoes never *cast* publicly pre-Unveiling, or the arena
   itself breaks the myth. One sentence in content canon fixes it.
4. **vision.md drift:** says "31 decisions," predates the Incarnate
   rename in one line, and doesn't reflect L32–L39. Needs a sync
   pass (known).

## 4.3 One structural risk to watch (no fix locked)
No-instancing (L29) + small worlds means **prime-time delve
contention is the whole PvE experience**. Contested-shared PvE is
the design's boldest bet after permadeath: it produced both EVE's
best stories and Archeage's worst days. The open tuning question in
content.md (group scaling, chokepoints) is quietly one of the
highest-stakes unanswered questions in the design. Prototype early —
paper answers won't hold.

---

## 5. Verdict

**Design feasibility: PASS.** The systems close their loops, feed
each other (destruction→crafting, distance→war, secrecy→politics),
and the exploit surface is unusually well pre-answered because
physicality and permadeath self-limit most degenerate strategies.
No lock contradicts another beyond the four small items in §4.

**Production feasibility: PASS ONLY AT AAA SCALE, or with staging.**
If the funding reality is smaller, the honest staged path is:
1. **Vertical slice** (the L39 gate): one town + its wedge, one
   crafting pipeline to mastery, combat vs. 5 monster types at real
   latency, one hidden awakening event end-to-end.
2. **"Visible game" launch scope:** the Wheel, economy, wars, delves,
   arena — with magic systems built but the awakening valve nearly
   closed. The secret layers are content-complete for *hundreds* of
   players, not thousands, at launch — which is exactly what the
   Myth epoch means anyway. The design's own pacing is its de-scoping
   plan; that's rare, and it's the strongest thing in here.
3. **The Interior ships when the first servers near the gate** — the
   design guarantees months of runway.

**Top five actions coming out of this pass:**
1. Resolve T2 (Switch battle ceiling) before slice combat design.
2. ~~Add the casual awakening guard rail (§2.1) to L36's detail.~~ DONE 2026-07-28.
3. ~~Add Incarnate regency (§2.4) to L10's detail.~~ DONE 2026-07-28.
4. ~~Epoch-gate the Trial announcement surface (§4.2).~~ DONE 2026-07-28 (L10).
5. Prototype contested-delve pressure (§4.3) alongside the slice.
