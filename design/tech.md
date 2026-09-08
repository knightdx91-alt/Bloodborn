# Marrowmark — Technical Design & Solo Production Strategy

Written 2026-09-08 against a specific reality: **one developer, AAA
feature ambition, a multi-year horizon.** Every recommendation here
is shaped by that constraint. A funded studio would make different
calls in several places, and those are flagged where they occur.

---

## 1. The substitution this whole plan rests on **[core]**

A solo developer cannot match a studio on **content volume**. Six
large regions plus a capitol, hundreds of crafted items, a monster
ecology, and 40–80 bespoke conversational NPCs is thousands of
person-years of art and authoring. No work ethic closes that gap.

A solo developer *can* match a studio on **systems depth** — and
systems depth is exactly what makes this design distinctive. Nobody
will play this for the polygon count. They will play it for the
economy, the wars, the crafting, and the secret.

**So: build systems to full ambition. Buy, modularize, or generate
content volume.** Concretely —

- **Buy the art bar.** Marketplace assets, scanned material libraries,
  and animation sets, unified by a single consistent lighting and
  post treatment. A coherent bought look beats an inconsistent
  handmade one, and L20 (grounded medieval) is the single
  best-served genre in every asset marketplace that exists.
- **Modular kits over bespoke geometry.** One town kit with real
  variation beats six hand-built towns. The Wheel's six towns differ
  by *palette, layout, faith, and trade*, not by unique architecture.
- **Procedural wedges, handcrafted landmarks.** Generate the country
  between towns; hand-place only what players will remember — a
  delve mouth, a shrine, a wreck, a crossroads inn.
- **Generate the text volume.** This design already runs an LLM
  layer for NPCs (P11). The same pipeline drafts barks, item
  descriptions, rumor phrasings, and epitaphs. Author the *systems*
  and the *voice cards*; generate the words.
- **Cut what is purely headcount.** Hand-authored quest chains at
  scale are studio work. L29 already prefers contract boards, rumor,
  and mystery over authored quest volume — that lock was written for
  design reasons and pays off enormously here.

## 2. Engine: Unreal 5 **[recommendation]**

For this project, by these constraints:

- **Source access.** §7 of `combat.md` needs custom netcode. Engines
  you cannot modify cannot implement favor-the-defender honestly.
- **Fidelity without an art team.** Nanite and Lumen mean acceptable
  AAA-adjacent visuals without manual LOD chains and lightmap bakes —
  which is a *solo-developer lever* more than a graphics feature. It
  removes weeks of optimization labour per environment.
- **The marketplace is the content plan.** §1 depends on a deep asset
  ecosystem; Unreal's is the deepest for grounded medieval.
- **Console path is well-trodden**, including Switch 2.
- **Animation tooling** is the best available, and §6 of `combat.md`
  makes animation readability a hard requirement rather than polish.

**The honest caveat: Unreal's replication is not MMO-scale.** It is
built for tens of players, not thousands. This is true of every
general-purpose engine, so it is not a reason to pick differently —
but it does mean the server architecture in §3 is *custom work you
will write*, not a feature you will configure. Budget for that
honestly.

*A funded studio might reasonably choose a custom or heavily forked
engine here. A solo developer should not.*

## 3. Server architecture

**Zone-server model with a persistent backend.**

- **Zone servers** — one authoritative simulation process per region
  (7 total: six wedges plus the capitol), each an Unreal dedicated
  server instance. L16's medium worlds (~1–2k concurrent) put roughly
  150–300 players in a region, which is within reach of a single
  well-tuned process.
- **Seamless handoff at region borders.** L28 forbids fast travel, so
  players cross borders constantly on horseback — handoff must be
  invisible. This is the hardest engineering problem in the project
  after combat netcode.
- **A backend of record** — a normal database holding characters,
  skills, inventory, shops, ledgers, charters, rights, rumors,
  lineages, epochs, and the Monument. Zone servers are simulation;
  the database is truth.
- **Stateless service layer** for anything not tied to a place:
  market boards, the companion app (L31), the Monument, war escrow.
  The companion app talks only to this layer and never to a zone
  server, which is what keeps L31 safely non-gameplay-critical.
- **The LLM layer (P11) is a separate service** behind its own
  budget and rate limits, reachable from zone servers, never
  authoritative over game state (L49 guarantees this in design; the
  architecture should guarantee it structurally too).

**War is already scope-sane by construction** (`war-society.md`):
rights are database rows, battles are scheduled instances of ordinary
combat. Nothing about wars requires new simulation technology.

## 4. Data model — the entities that must exist early

Getting these wrong is expensive later, so define them before the
world exists:

- **Character** — skills (per-skill XP, L18/L40), not a class.
- **Item instance** — rolled material properties (L4), durability
  state (L3), and a **maker's mark** referencing a character who may
  no longer exist. Marks are permanent even when the maker is gone.
- **Recipe knowledge** — per-character discovered state (L4), never a
  global unlock table.
- **Spell knowledge** — per-character, with a **lineage edge** to the
  teacher (L9). The lineage graph is a first-class structure; it is
  queried for L33's trickle and displayed for Incarnate ancestry.
- **Rumor** — content, source, decay timer, distortion history,
  physical location (L48, `content.md` §3). Rumors *travel*, so they
  need position and velocity, not just text.
- **Epoch state** — per-server, with the arming counters L41 requires
  and a live-tunable throttle (`feasibility-review.md` §3.3).
- **Account** — distinct from character. Holds the P12 marks (L42),
  flair, and rebirth history (L37). **Build this separation on day
  one**; retrofitting an account layer under a live character
  database is the kind of migration that eats a month.
- **Monument entry** — append-only, immutable, per-server.

## 5. Platform sequencing **[DECIDED — L53]**

**PC first. Consoles later. Switch 2 as the only Nintendo target
(L51).**

L15 promises four platforms with crossplay, and nothing here breaks
that promise — this is *sequencing*, not scope reduction. The reasons:

- Console certification requires a registered developer entity, dev
  kits, and per-platform compliance passes. That is real money and
  real months, and none of it teaches you anything about whether the
  game is good.
- Every design risk in this repository — combat feel, delve pressure,
  economy liquidity, the awakening throttle — is answerable on PC.
- Crossplay is far easier to add to an architecture that assumed it
  than to retrofit, so **build for it from the start**: controller-
  first input (already L15/§8), no keyboard-dependent systems, no
  PC-only UI affordances. Ship it later; design for it now.

**Switch 2 only materially improves the design.** T2 (the Switch
battle ceiling, `feasibility-review.md`) was the constraint holding
enrollment caps toward 60v60. On Switch 2 the 150v150 aspiration in
L25 stops being fantasy. This should be logged as an amendment to
L15 and a downgrade of T2.

## 6. Build order — every step ends in something playable

The single largest risk to a solo multi-year project is not technical.
**It is abandonment** — and abandonment is caused by long stretches
with nothing playable. Every stage below produces something you can
put in front of a person.

1. **Combat prototype** (`combat.md` §9). One room, three enemies, six
   weapon families, a latency slider. Weeks to months. *This is the
   L39 gate and it can kill the project — build it first.*
2. **Networked combat.** The same prototype, two real clients, real
   server authority, real reconciliation. Proves §7 of `combat.md`
   against reality rather than a slider.
3. **One crafting pipeline, end to end.** Ore to sword, every stage
   playable, rolled properties, a maker's mark, durability, repair.
   Proves the flagship system (L4/L38) and the item data model.
4. **One town, one wedge.** Streaming, mounts, a shop, an NPC
   shopkeeper, a delve mouth, monsters using §6's vocabulary. This is
   the first thing that feels like the game.
5. **Persistence and accounts.** Characters, the account/character
   split, death and durability, shrine respawn.
6. **The prototype-only risks**, now answerable: contested-delve
   pressure (§4.3) and multiplayer crowd budgets.
7. **P11's slice gate** (`brainstorm.md` §9.8) — six voice NPCs, one
   rumor that arrives wrong, one epoch flip. This is also where the
   real per-turn cost gets measured, which is what settles the open
   L27 collision.
8. **Everything else**, in whatever order the game demands by then.

**Stages 1–4 are the honest test of whether this project happens.**
They are achievable solo. If they take two years, that is normal and
not a failure signal.

## 7. What to deliberately not build

- **Custom engine.** Ever.
- **Custom asset pipeline** beyond what Unreal gives you.
- **Anti-cheat from scratch.** Use a platform solution; the design's
  statistical posture (`combat.md` §7) is the part you write.
- **Voice/STT/TTS from scratch.** Vendor everything in P11's pipeline.
- **The Interior**, until the first servers approach the gate — the
  design already guarantees months of runway (`feasibility-review.md`
  §5.3).
- **The Age of Gods** (P12), until the marks prove players care
  (`brainstorm.md` §10.9).
- **A launcher, an anti-RMT team, a support org** — all real, all
  later, none of them design problems now.

---

## Open questions

- [x] **PC-first sequencing** → **L53**. All four platforms and full
      crossplay remain committed; consoles are sequenced after PC, and
      designed for from day one so they stay a port, not a retrofit.
- [ ] Backend language and database choice; hosting model.
- [ ] Region border handoff design — the hardest problem after combat
      netcode (§3).
- [ ] Whether zone servers are one process per region or further
      subdivided under load.
- [ ] Asset strategy specifics: which marketplace ecosystems, and the
      unifying art treatment that makes bought content cohere (§1).
- [ ] Source control and build infrastructure for large binary assets.
- [ ] Legal entity, and **trademark clearance on Marrowmark** (see
      `naming.md` §5) — both needed before any public-facing material.
