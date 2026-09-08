# MARROWMARK

A large-scale, cross-platform 3D MMORPG (PC, Xbox, PlayStation,
Switch 2 — one shared world, full crossplay) where the world keeps the
score. Buy-to-play. M-rated grounded dark fantasy.

>  **Title set 2026-09-08 (L52):** *Marrowmark*, replacing the
> working title "Bloodborn" — which could not ship against the
> *Bloodborne* trademark. Professional clearance is still outstanding
> and is a blocker on anything public: see
> [`design/naming.md`](design/naming.md).

**Status:** 87 locked decisions, the original ten structural pillars
closed, feasibility reviewed. Two newer pillars are partly locked and
still open: **P11, living NPCs** (free-form voice dialogue,
`brainstorm.md` §9) and **P12, the Incarnate marks** (an unexplained
sigil that outlives the character, and the Age of Gods it eventually
opens, `brainstorm.md` §10).

**The design side is complete** — every structural question is locked
and every document that was missing has been written. What remains is
not design.

**Stage 1 has started.** [`design/tech.md`](design/tech.md) §6 walks
from a character controller to a working parry in six steps; step one
is written and waiting in [`unity/`](unity/). That is the road to the
L39 gate ([`design/combat.md`](design/combat.md) §9) — the one result
that can kill or confirm the whole project.

⚠️ **One open question now reaches the business model:** P11's
per-turn inference cost against L27's buy-to-play lock. Subscription
is on the table. Deferred until the vertical slice measures real cost
— see `design/pillars.md`, P11.

---

**Picking this up again?** Start with [`STATUS.md`](STATUS.md) — where
things stand, what's next, and what can be done without a laptop.

## Read in this order

| Doc | What it is |
|-----|-----------|
| [`design/vision.md`](design/vision.md) | **Start here.** The one-page pitch and the five promises. |
| [`design/pillars.md`](design/pillars.md) | The decision log — all 87 locks (L1–L87), pillar status, and the next-phase plan. The map to everything else. |
| [`design/feasibility-review.md`](design/feasibility-review.md) | Build-and-play sanity check: developer risk register, six player-archetype simulations, systemic stress tests, verdict and staged production path. |
| [`unity/`](unity/) | Unity scripts staged before they can be verified in the editor, with setup instructions. Step 1 of the Stage 1 prototype lives here. |
| [`sim/`](sim/) | The rules of the game as engine-free C#, with tests. Runs anywhere; the zone servers will run this same code. |
| [`design/art-audio.md`](design/art-audio.md) | Art as the interface: what must read at a glance, why the look lives in the treatment rather than the assets, and what audio carries that the eye cannot. |
| [`design/interface.md`](design/interface.md) | Minimalist by rule: nothing permanently on screen, legibility as a skill, maps as player-made goods, and the companion app as the pressure valve. |
| [`design/liveops.md`](design/liveops.md) | What a server is after its first year, the four dials an operator turns, what they must never touch, and the telemetry to read them by. |
| [`design/moderation.md`](design/moderation.md) | Minimal intervention: what the law and the consoles actually require, why the fiction is never policed, and how the world's own consequences do the rest. |
| [`design/onboarding.md`](design/onboarding.md) | The hardest problem in the design: teaching a game with no markers, no class, and no guard indicator — by making the tutorial a person. |
| [`design/crafting.md`](design/crafting.md) | The flagship system: material properties as tradeoffs, pipelines as trades, why skill raises the ceiling without gating the floor, and maker's marks. |
| [`design/combat.md`](design/combat.md) | The combat specification: core loop, stamina, where skill lives vs. gear, the damage triangle, enemy telegraph vocabulary, the latency contract, and the prototype gate that must pass first. |
| [`design/tech.md`](design/tech.md) | Engine (Unity), server architecture, data model, platform sequencing, the solo production strategy the whole plan rests on, the staged build order, and how the work actually gets divided. |
| [`design/naming.md`](design/naming.md) | How the title was chosen, why the old one could not ship, and what real trademark clearance still requires. |
| [`design/lore.md`](design/lore.md) | Working canon: the Godsgrave cosmology, four faiths, six towns, the Revelation Arc, and the secret canon (§9 — spoilers). |
| [`design/economy.md`](design/economy.md) | Player-driven economy, shops, local markets, travel, coin sinks, the shadow economy, business model. |
| [`design/war-society.md`](design/war-society.md) | Charters (Companies, Houses, Orders, Circles), rights-based territory, and declared wars. |
| [`design/content.md`](design/content.md) | PvE: shared delves, monster ecology, quests as mystery/contracts/rumor. |
| [`design/demigod-realm.md`](design/demigod-realm.md) | The Interior — the permadeath endgame realm and its four rings. |
| [`design/brainstorm.md`](design/brainstorm.md) | The living working document. Everything above was distilled from here; the full decision trail lives at the bottom. |
| [`design/notes/`](design/notes/) | The original handwritten brainstorm the whole project grew from. |

## The shape of it, in six lines

- A god died at the center of the world; six towns ring its grave.
- Every finished good is player-made and carries its maker's mark.
- Nothing teleports — not goods, not people. Distance is the game.
- Wars are staked contracts over seasonal rights, fought by the enrolled.
- Magic is a secret the players discover, spread, and eventually break.
- The longest climb ends in permadeath, and one player becomes a god
  the whole server lives under, by name.

## Working agreement

See [`CLAUDE.md`](CLAUDE.md) — single branch (`main`), no PRs.
