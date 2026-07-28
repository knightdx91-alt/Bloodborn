# Bloodborn — Economy & Business Model (working canon v1)

STATUS: **WORKING CANON** (adopted 2026-07-26; player-driven economy
per direct instruction, remainder delegated best-call). Covers P6
(economy) and P9 (business model).

---

## 1. First principle: players make the market

**The economy is player-driven.** NPCs sell raw services and staples
only — never finished goods that compete with player crafters. If a
sword, a saddle, a coat, or a meal worth having exists, a player made
it, priced it, and put their mark on it.

## 2. Retail — the shop is the interface **[core: player shops]**

Players rent or buy buildings (L5) and **run shops in them**. Shops
are the primary way goods reach buyers:

- **Stock & pricing:** the owner stocks the shelves, sets prices,
  arranges the display. NPC staff (wages = coin sink) sell while the
  owner is offline; the owner sets standing orders ("buy iron under
  X, never sell the masterwork blade").
- **Shopfront identity:** signage, layout, livery — crafted, of
  course. A famous shop is a destination; maker's-mark reputation
  (L4) turns into foot traffic.
- **Ledgers:** every shop keeps books — what sold, to whom, at what
  price. Good data is part of the shopkeeper game (and a smuggler's
  liability, §6).
- **Commissions:** buyers post commission orders (a winter coat,
  wolf-lined, before the war window opens); crafters bid. The order
  book is where crafting careers start.
- **Companion app (L31):** shop ledgers, restock orders, price
  changes, and commission bids are manageable from the mobile
  companion — the asynchronous half of shopkeeping. Read-and-manage
  only; nothing gameplay-critical lives there.

## 3. Markets are local — goods must travel

**No global auction house.** Each town has a **market board** listing
only goods physically warehoused in that town. Coin is bankable and
abstract; **items are physical** — no mail, no teleporting goods.

- Price discovery is local: iron is cheap in Hammarsted and dear in
  Greywater, and *that spread is a profession*. Caravans (mounted!)
  arbitrage between towns along the rim and spokes.
- Moving goods = risk (wedge death drops carried goods, L17) =
  escorts, insurance (a House product), convoys, banditry, and the
  road-rights wars (L25) all feed each other.
- The capitol's Concourse is the deep market — highest volume, highest
  stall fees — but still local: goods must get there.

### 3.5 No fast travel, no teleportation (DECIDED 2026-07-26)
People are as physical as goods — player teleportation with inventory
would *be* item mail, so it doesn't exist. The rules:

- **No instant travel of any kind.** No waypoints, no recall/
  hearthstone (an escape teleport would gut caravan raids and war
  retreats), no summon-to-friend.
- **Mounts are the fast travel** — speed is bred, bought, and losable,
  not a menu option. Stables, way-inns, and coaching are player
  businesses.
- **Hands-free travel is the convenience layer:** coaches and river
  barges (player- or NPC-run) carry you in real time while semi-AFK —
  manage shop ledgers, plan commissions, chat while the wagon rolls.
  Not instant; just not hands-on. This is the session-friction answer
  for console/handheld play.
- **Tuning target:** a spoke ride on a decent horse is minutes, not
  tens of minutes. The Wheel is compact by design; distance should be
  felt, never dreaded.
- **Sanctioned exceptions:** shrine knitting-back on death
  (involuntary, tithed, lore-sanctioned) and the one-way ascension
  gate. If magic ever touches travel, it's a near-mythical late-epoch
  rarity — flesh only, no cargo — making a portal-caster a famous
  institution, not a UI feature. Default: doesn't exist.

## 4. Coin — one currency, real sinks

- Single currency: **marks** (placeholder name). Letters of credit at
  the capitol bank for large sums; local strongboxes elsewhere.
- **Coin sinks** (NPC-facing, non-negotiable for a player economy):
  shrine tithes on knitting-back (respawn), property rent/upkeep and
  council taxes, NPC staff wages, charter registration, war escrow
  fees, stall fees, betting rake at the Ring.
- **Coin faucets** kept modest: monster bounties, quest rewards, NPC
  staple purchases. Faucets < sinks at maturity; wealth should come
  from *other players*, not the tap.
- **Item sinks** already locked: durability decay consuming repair
  materials (L3), war-field drops recirculating gear (L25), demigod
  permadeath deleting entire kits (L12). The crafting demand engine.

## 5. Banking & storage
- Town warehouses (local goods = local listings), capitol vault for
  coin and small precious items. No remote access to stored *goods* —
  wealth in things is wealth that sits somewhere, guardable, robbable
  (war objective potential).

## 6. The shadow economy
Circles (L24) get the black layer: smuggling past toll rights,
fencing war loot, unlicensed betting books, covert war finance
(L25-addendum), and — in Myth/Whispers epochs — the quiet trade in
awakening rumors, schematics, and spell lessons. Two ledgers, one
shop: the bindery upstairs, the cellar below (L22). Shadow money
leaves trails; exposure is the price of losing.

## 7. Business model (P9 — best call)

- **Buy-to-play** base game + paid expansions (the seal-weakening arc,
  L23/§9, is literally built for expansions).
- **No pay-for-power. No tradeable purchased goods. Nothing sold that
  a crafter could make.** In a maker's-mark economy, gear appearance
  IS crafter prestige — a cosmetic gear shop would gut the game's
  status economy. Hard line.
- Monetizable without damage: account flair (portrait frames, Monument
  etching styles), extra character slots, name reservations. Sparingly.
- **No RMT tolerance**: a player-driven economy with real scarcity is
  an RMT magnet; buy-to-play (no free accounts) + physical-goods
  friction + no mail already blunt it. Enforcement budget planned from
  day one, not bolted on.
- Optional cosmetic-only subscription: **rejected for now** — revisit
  only if server economics demand it, and never with economy-touching
  perks.

## Open tuning questions
- [ ] Currency name; denominations; starting coin.
- [ ] Rent/tax/wage numbers per town tier; council tax-setting bounds.
- [ ] Commission escrow rules; dispute handling.
- [ ] Warehouse robbery: full system (war objective? Circle heist?) or
      flavor-only at launch?
- [ ] Insurance as a House product: moral hazard tuning. **Constraint
      from `feasibility-review.md` §2.6:** claims must key off what
      the server can prove (the death event, the looters' identities
      are all recorded) — otherwise insure-and-"lose"-it fraud with a
      friendly bandit is trivial.
- [ ] Expansion cadence and price points (post-vertical-slice call).
- [ ] **RMT enforcement must explicitly cover the Veiled Ring's
      shadow book** (`feasibility-review.md` §2.6) — unlicensed
      betting on Succession Trials is a real-money laundering vector.
- [ ] Shrine tithe scaling by distance from the death site — closes
      the bind-far-and-die slow-teleport edge case (§4.1).
- [ ] Coin faucet curve by epoch: early-server deflation is the
      likelier failure than inflation (§3.2) — start generous,
      tighten as wealth accumulates.
