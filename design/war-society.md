# Bloodborn — War & Society (working canon v1)

STATUS: **WORKING CANON** (adopted 2026-07-26, delegated best-call).
Covers pillars P5 (war & territory) and P7 (social structures).
Numbers are working values; structures are the decision.

---

## 1. Social structures — charters, not guilds

**Call: there is no generic "guild" system.** Player organizations are
**charters** — formal institution types with distinct mechanical
identities, built on systems we already have (property L5, faiths,
academies, the hidden circuit). A generic guild would flatten all of
these into one button.

| Charter | What it is | Mechanical identity |
|---------|-----------|---------------------|
| **Company** | Mercenary / free company | The war actor: signs war contracts, fields banners, negotiates enrollment. Public roster. |
| **House** | Merchant or craft house | The economic actor: joint property, shared workshops, caravan routes, apprentice rosters, market stalls. |
| **Order** | Faith-licensed organization | Licensed by one of the four faiths; carries faith rep benefits and obligations; can be called to holy work (monster culls, shrine defense). |
| **Circle** | Secret society | The **only unregistered charter**. Hidden roster, hidden property (fronts). Mage academies, smuggling rings, the Vein's cells. Exists to make secrecy (L22) organizational, not just personal. |

- Charters register at the capitol (Circles conspicuously don't).
- Charters can jointly own property, fly crafted liveries/banners
  (crafters again), and hold **rights** (see §2).
- A character can belong to one Company OR Order (your banner), plus
  one House (your livelihood), plus any Circles (nobody knows).
- **Fellowships**: a lightweight social group (shared chat, party
  persistence) with zero mechanical power — so friend groups don't
  need a charter, and charters stay meaningful.
- **Town councils** (L5) are not charters — they're place-based bodies
  of building owners. Councils govern towns; charters act across them.

## 2. Territory — rights, not conquest

**Call: war never conquers or razes a town.** Towns are permanent
home infrastructure; council seats change hands through the property
market, not the battlefield. What war fights over is **rights**:

- Wedge resource rights: a named mine, quarry, hunting range, herb
  fen, blood-touched vein.
- Road rights: toll collection on a rim-road segment; caravan
  protection monopolies.
- Town-granted rights: market-day priority, arena bout scheduling,
  militia contracts — granted by councils, challengeable by war.

Rights are **held for a season** (working: 3 months), generate
income/materials while held, and become re-challengeable when the
season turns. Nothing is owned forever; the map's wealth keeps
circulating without the map itself changing hands.

## 3. War — declared, staked, bounded

**The shape: a war is a contract between two sides over a named
right, fought in scheduled battles, with stakes posted up front.**

1. **Declaration.** A Company (or Order, or a council for town-granted
   rights) files a challenge on a specific right. Requires a stake
   escrowed at the capitol (coin/materials) — walking away forfeits
   it. No stake, no war: this prices out griefing declarations.
2. **Lead time.** Working: 3 real days. Both sides recruit — mercenary
   Companies can be contracted by either side; individuals can enlist
   under a banner. Betting books open (of course they do).
3. **Enrollment.** War rules apply **only to enrolled combatants**.
   Bystanders and non-combatants keep ordinary death rules (L17) and
   cannot be dragged into war stakes. Enrollment caps negotiated at
   declaration (working range: 30v30 to 150v150 on a 1–2k-concurrent
   world).
4. **Battles.** The war window (working: 7 days) contains scheduled
   field battles and objective play over the contested right (hold
   the mine, run/raid the caravan, control the tollhouse). Mounted
   combat (founding note) is the war-fighting backbone: cavalry,
   supply wagons, outriders.
5. **The equipment stake (L11, interpreted).** An enrolled combatant
   who **dies in a war battle drops 1 random equipped piece where
   they fall** — battlefield loot, scavengeable while the fight runs.
   Losing sides bleed gear battle by battle; won gear carries the
   fallen's maker's marks home as trophies. (Interpretation of the
   founding note chosen for immediacy: loss happens on the field, not
   in a settlement screen.)
6. **Resolution.** Best-of over the window's battles/objectives.
   Winner takes the right for the season + the escrowed stake.
   Treaties allowed mid-war (tribute to withdraw). Every war is
   recorded — named battles enter the server's living history (L23),
   and war dead feed the crafting economy's demand (§2.6 brainstorm).

## 4. Why this shape

- **Consent + stakes coexist.** The founding page demands real loss
  (1 equipped piece); enrollment-only war rules deliver it without
  making the open world a gank field — that job stays with the
  wedges' zone-scaled risk (L17).
- **Wars are stories.** Declared, named, scheduled, betted-on, and
  recorded — every war is legible server history, not a blur of
  skirmishes.
- **Everything feeds crafting.** Battlefield gear loss is the item
  sink; banners, barding, siege-less field kit are crafting demand;
  won trophies carry maker's marks.
- **Scope-sane.** No siege engines, no destructible towns, no
  territory repaint at launch. Rights are database rows; battles are
  instanced-ish field events on existing terrain.

## Open tuning questions
- [ ] Season length; war-window length; lead time; enrollment caps.
- [ ] Stake sizing: flat, or scaled to the right's income?
- [x] **Circles CAN covertly fund wars (DECIDED 2026-07-26).** A war's
      escrow can be staked through intermediaries, hiding the true
      buyer. The risk: shadow money leaves trails — a badly lost war,
      a captured paymaster, or a bought informant can **expose the
      Circle**, converting its hidden assets and roster into public
      knowledge (catastrophic in Myth/Whispers epochs; merely
      dangerous later). Exposure mechanics TBD.
- [ ] Battle format details: objective types per right type.
      **Time-of-day scheduling across time zones is required for the
      vertical slice** (`feasibility-review.md` §2.3) — negotiate the
      battle window at declaration, alongside enrollment caps.
- [ ] **Enrollment cap ceiling depends on the Switch crowd budget**
      (`feasibility-review.md` T2). 150v150 is aspirational; design
      battle objectives so they still read at 60v60.
- [ ] Epoch interactions: do Scouring-age wars gain new casus types
      (mage-hunts, sanctuary defense)?
