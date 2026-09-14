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

## 2. Engine: Godot 4 **[DECIDED — L54, revised 2026-09-14]**

**Godot 4, GL Compatibility renderer, current stable.** Revised from
Unity on 2026-09-14, after the two questions holding the review were
researched — §2a has the evidence and the sources, and this section
states the decision.

**Why Godot here:**

- **The whole build-and-play loop runs without the developer's
  machine.** The project is authored as text, built headless against a
  software rasteriser with no GPU, exported to the web, driven with
  simulated input and *looked at* — then published, so it can be played
  on a phone. Stage 1 steps 1–3 exist because of this. **Unity cannot
  be operated this way**, and on a solo project where an AI
  collaborator is a large share of the labour, that is not a
  convenience — it is the difference between the engine work happening
  and not happening.
- **Everything is text, more so than Unity.** Scenes, scripts and
  config are all plain text. Unity's YAML is text too; Unreal's
  Blueprints are binary `.uasset`, which is why this document stopped
  recommending Unreal long before it stopped recommending Unity.
- **It runs on the hardware that exists.** A 2017 MacBook Air runs the
  Godot editor comfortably. This removes what `pillars.md` listed as
  the project's first hardware blocker.
- **Cheaper to ship on console**, which was assumed to be the reverse:
  W4 Consoles is $2,000/yr for all three platforms with no revenue
  share, against Unity Pro at $2,310 per seat per year, which Unity
  *requires* to publish on console at all. §2a.
- **No licence, no runtime fee, no revenue share**, and the engine
  cannot be relicensed out from under the project — which on a
  multi-year solo build is worth more than it looks.

**The honest cost — four things, all real:**

- **A thinner tooling ecosystem.** Godot's Asset Library is around
  three thousand items against Unity's tens of thousands. Bought
  *content* is unaffected (§2a: Unity's own store permits cross-engine
  use), but editor extensions, inventory and dialogue systems, shader
  editors and inspector tooling are written here or done without.
  **This project is unusually insulated** — §1 buys content and
  hand-writes systems — but it is not free.
- **C# does not reach the web export**, so rules the prototype
  exercises are written twice. **L88** governs this, including the exit
  condition, because it must not become permanent by drift. Detail
  below.
- **Console ports run through one small vendor.** W4 Consoles is built
  by the people who built Godot, which is reassuring, but it is a
  concentration risk Unity does not carry. **Switch 2 is in early beta
  there** and L53 targets Switch 2 only — a schedule risk to watch,
  not a blocker at this distance.
- **Unreal's art leverage is still given up**, exactly as the Unity
  lock gave it up. Nanite and Lumen remove weeks of manual
  optimisation per environment. **This remains the right trade for
  Marrowmark specifically**, because the game's distinctiveness is its
  systems rather than its fidelity — and it is a trade this project
  made two engine decisions ago.

**Renderer: GL Compatibility.** It runs on everything in L15/L51
including Switch 2 and the developer's own hardware, and it is what the
headless build loop rasterises in software. Forward+ is available later
if the art direction demands it; nothing yet does.

**Version:** take current stable and pin it. Engine upgrades are a cost
with no gameplay upside — though note W4 Consoles tracks 4.4–4.6, so
the pin should stay inside what it supports.

*A funded studio with an art team would still choose Unreal, and a
studio with staff to spare would reasonably still choose Unity. This
decision is correct for these constraints — one person, no PC, an AI
collaborator doing a large share of the work — not universally.*

### The record: how this got here

Kept because the reasoning matters more than the conclusion, and
because a lock that flips should show its working.

**2026-09-08 — Unreal 5 → Unity (original L54).** Two facts changed the
recommendation: the developer is new to gamedev, and an AI collaborator
is a major part of the labour. Unreal's Blueprints are binary and
opaque to a collaborator; Unity is all text, puts client, server and
tools in one language, and has the gentlest learning curve of the
serious engines.

**2026-09-13 — the Godot challenge.** A full build-and-play loop was
demonstrated inside the assistant's environment with nothing on the
developer's machine. That undermined "everything is text" as a Unity
advantage outright — Godot wins it — and revealed that the assumption
underneath *both* original arguments, that the developer would do all
engine work, was false.

**2026-09-14 — the research, and the flip.** §2a. The marketplace
argument mostly dissolved and the console argument inverted. Neither
remaining question favoured Unity once looked at.

**What did not change at any point:** no engine's built-in networking
is MMO-scale, Godot's included. The zone-server layer in §3 is code to
be written, not a package to install. That was true of Unreal, true of
Unity, and is true now.

### The 2026-09-13 evidence, in full

**Recorded when it was still a challenge to a locked decision**, and
kept as written.

**What was demonstrated.** A Godot 4.3 project was built, exported and
**play-tested end to end inside the assistant's own environment**, with
no editor, no GPU and nothing done on the developer's machine:

1. Project authored as text — scenes, scripts, config.
2. Built headless against a software rasteriser.
3. Exported to web.
4. Loaded in a browser, **driven with simulated keypresses**.
5. Screenshotted and visually verified — the character moved, the
   camera followed, the world was correct.

That is the full development loop. It is not possible with Unity, whose
editor cannot be operated this way and whose Blueprint-equivalent
workflows are opaque to an assistant regardless.

**What this changes about §2's reasoning.** Two arguments were made for
Unity. "Everything is text" was already a tie at best — Godot wins it.
The assumption underneath both was that **the developer would do all
engine work**, and that assumption is now false.

| | Unity | Godot |
|---|---|---|
| Assistant can build end to end | No | **Yes, demonstrated** |
| Runs on the current hardware | Poorly | Yes |
| Developer can play builds today | No | **Yes, in a browser** |
| Asset marketplace depth | Much deeper | Thinner — **but Unity's store is usable from Godot, see §2a** |
| Console path (L53) | Direct | Third-party porting house — **and cheaper, see §2a** |
| One language client/server/tools | Yes (C#) | Yes when shipping, **no for the web build** — see below |

**The honest shape of the trade is a question of *when*.** Unity's
advantages — marketplace depth for §1's buy-the-content strategy, and
the console path — land at **Stage 3 and beyond**, a year or more out.
Godot's advantage lands **today**, and compounds every week: it is the
difference between the engine work happening and not happening.

**What would settle it** — both since answered, in §2a:

- ~~Whether Godot's asset ecosystem can actually carry §1's strategy,
  or whether Unity Asset Store purchases can be converted at
  acceptable cost.~~ **Answered 2026-09-14 — see §2a below.**
- ~~What third-party console porting actually costs against L53.~~
  **Answered 2026-09-14 — see §2a below, and it inverts.**
- ~~Whether the demonstrated loop holds up past grey boxes — it has
  been proven on capsules, not on an animated character with combat.~~
  **Answered as far as it can be here (2026-09-13.)** The loop has now
  carried a rigged skinned character, blended locomotion, a dodge with
  invulnerability frames, a weapon placed on a bone, a hitbox, and a
  target that reacts — all authored, built, exported and verified
  without an editor. It also *diagnosed* three broken asset deliveries
  and four input bugs by measurement rather than inspection.

  **What it cannot do is judge feel**, and the limit is concrete rather
  than theoretical: the verification browser renders at three to four
  frames a second. That is not merely too slow to assess timing — at
  that rate input timing itself misreports, which had to be designed
  around. This is the same answer `combat.md` §9 gives for every
  engine: a human holds the controller or the question stays open. **It
  is not a point of difference between Unity and Godot**, so it should
  not weigh on L54 either way.

## 2a. L54 — the research, and a recommendation (2026-09-14)

Both remaining questions are answered. **Neither landed where §2
assumed.** The recommendation was to flip L54 to Godot; **that decision
was taken on 2026-09-14** and §2 now states it. This section is the
evidence it rested on.

### Question 1: can Godot's ecosystem carry §1's buy-the-content strategy?

**Yes — and the Unity Asset Store is available from Godot anyway.**

Unity's own support documentation says Asset Store assets **may be used
with other engines**, Godot and Unreal named explicitly, provided the
Asset Store EULA is followed. The binding conditions:

- **No redistribution** — assets cannot ship as standalone items, or in
  a way that lets others extract them from the build.
- **No cost-sharing** — you cannot split a purchase and share access.
- **The asset cannot be the project's primary purpose**, and
  user-generated-content monetisation needs the creator's permission.
- **Per-asset licences override this**, as do open-source components
  inside a pack. Each purchase has to be read.

That substantially dissolves the "marketplace depth" argument, because
the marketplace is not Unity-only. **But the question has two halves
and they answer differently:**

| | Transfers to Godot? |
|---|---|
| Models, textures, animation, audio | **Yes.** These are FBX/glTF/WAV, not Unity objects |
| Materials, prefabs, shaders, scene setup | **No.** Rebuilt per pack — real work, not free |
| Editor extensions, systems, C# plugins | **No, and not at any price.** They are Unity software |

**The genuine gap is tooling, not content.** Unity's store runs to tens
of thousands of items; Godot's Asset Library is around three thousand,
mostly free and community-maintained. Behaviour trees, inventory and
dialogue systems, shader editors, inspector tooling — on Godot these
are written or done without.

**And that is the half this project is least exposed to.** §1's
strategy is *build systems to full ambition, buy content volume*. The
systems are being hand-written regardless — `sim/` is over two hundred
tests of rules nobody sells. What gets bought is content, and content
is the portable half.

Two practical notes: **Godot prefers glTF/GLB**, and FBX, while
improved in 4.3, still lags on complex rigs — so prefer GLB where a
seller offers both. And conversion is not free: budget rework per pack
for materials and prefab structure.

> ⚠️ **A content risk that is NOT about the engine, and is the more
> urgent finding.** §1 names animation volume as the project's largest
> content risk (~300–400 clips), and the plan rests on **Mixamo**. As
> of mid-2026 Mixamo is still up, but showing signs of being left
> alone: repeated multi-day outages through 2025, Adobe having already
> discontinued its companion product Fuse, and at least one Adobe
> support contact telling a user during an outage that "Mixamo is not
> supported anymore." **That last is a forum anecdote, not an
> announcement** — but there is no roadmap and no commitment either.
>
> This costs the same under Unity and Godot, so **it does not bear on
> L54 at all.** It bears on doing something now: **download and commit
> the clips this project needs while the service is up**, rather than
> assuming it will be there at Stage 3. Alternatives exist (ActorCore,
> Rokoko, Cascadeur, hand-authored) but all of them cost more than
> free.

### Question 2: what does console porting cost against L53?

**Less on Godot than on Unity.** This is the finding that inverts §2's
comparison table, which listed the console path as a Unity advantage.

**Godot — W4 Consoles**, built by the company the Godot founders
started. Published subscription pricing, no quote required:

- **Starter: $800/year for one platform, $2,000/year for all three** —
  the tier for companies under $300k revenue and 30 employees, which is
  this project by a wide margin.
- **No revenue share and no runtime fee.** Full source access.
- Switch, PS5 and Xbox Series in production; **Switch 2 in early beta**
  and billed as a separate platform from Switch 1 — which matters,
  because L53 targets **Switch 2 only**. Full commercial release is
  "coming soon", which is a real schedule risk to watch rather than a
  blocker at this distance.
- Godot 4.4–4.6 supported. **C# is in beta on Switch and Xbox**, which
  partially softens the §2 C# concern below — though not for the web.

**Unity — a licence requirement, not a porting fee.** Console
development on PlayStation, Xbox or Switch **requires an active Unity
Pro subscription**, or a Preferred Platform License key from the
platform holder. Unity Pro went to **$2,310 per seat per year on 12
January 2026**. Sony and Nintendo issue platform keys; **Microsoft does
not**, so shipping on Xbox means paying Unity directly regardless.

**So: $2,000/year for three platforms on Godot, against $2,310/year per
seat on Unity before any porting work at all.** Platform-holder devkits
and approval are required either way and are not in either number.

**The honest counterweight:** W4 is one small company, and taking all
three console ports through a single vendor is a concentration risk
Unity does not carry. That is a real difference — it is just not a
*cost* difference, which is what §2 assumed.

### Where this leaves L54

The original case for Unity was two arguments. Here is what was left
of them, with the two later findings — the state of play at the moment
the decision was taken:

| Argument | Status |
|---|---|
| Everything is text | **Lost.** Godot wins outright, and by more than a tie |
| Asset marketplace depth | **Mostly dissolved.** The store is usable from Godot; the residue is tooling, where this project is least exposed |
| Console path (L53) | **Inverted.** Godot is cheaper; the counterweight is vendor concentration, not money |
| Assistant can build end to end | **Godot, decisively.** Stage 1 steps 1–3 exist because of it |
| C# does not reach the web | **Against Godot.** Rules written twice while the web build is the play surface — see below |

**Decided 2026-09-14: L54 is Godot.** The mirroring cost is accepted
with a named exit, which is **L88** — when the developer can routinely
run native builds, the prototype moves to Godot's .NET build and
`prototype/rules/` is deleted the same day. Naming the exit is the
point: this is the kind of cost that becomes permanent by drift.

### A fourth consideration: C# does not reach the web (2026-09-13)

**Godot's web export cannot run C#.** Godot 4 lost C# on every platform
except Windows, macOS and Linux when it moved from Mono to .NET, and
the web is one of the platforms it lost. There are community builds
that restore it; there is nothing official.

This is narrower than it first looks, and worth stating precisely:

- **It does not affect shipping.** Marrowmark ships to PC first (L53)
  and consoles later. Godot runs C# on all of those, so `sim/` would be
  the client and the server exactly as written.
- **It does affect the development loop**, and the loop is the entire
  reason Godot is under consideration. The web build is how the
  developer plays anything at all without a PC. So for as long as that
  is true, anything the prototype needs to *do* has to exist in
  GDScript as well as C#.

**How it is handled now.** `sim/` stays the authority: it is what the
server will run and what the tests cover. `prototype/rules/` mirrors
the parts the prototype needs in GDScript, and the mirroring is
deliberate duplication, accepted with open eyes.

**The tuning is not duplicated**, because that is the part that would
actually hurt. Every number lives once, in `shared/tuning/combat.json`,
which both sides read, and `TuningFileTests.cs` fails the build if the
prototype's copy drifts from it. Logic diverging is a bug someone will
eventually notice; numbers diverging is a month of tuning against the
wrong game.

**What it costs:** every rule the prototype exercises is written twice.
That is affordable at the size of a dodge and it is not affordable at
the size of the whole game. If Godot wins L54, this is a real bill —
either the web loop is dropped once there is better hardware, or the
simulation is written in GDScript and C# stops being the authority.
**Either is a decision, and neither should happen by drift.**

**Interim position at the time:** the prototype is Godot because that
is what can be built now, and is explicitly not a commitment.
*Superseded 2026-09-14 — it is the commitment now.*

## 3. Server architecture

**Zone-server model with a persistent backend.**

- **Zone servers** — one authoritative simulation process per region
  (7 total: six wedges plus the capitol), each a headless Unity
  server build. L16's medium worlds (~1–2k concurrent) put roughly
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

**No engine's built-in networking is MMO-scale**, Unity's included.
Netcode for GameObjects is built for tens of players, not thousands —
it is fine for the Stage 2 latency prototype (§6) and wrong for the
shipped game. The zone-server layer above is **code you write**, not a
package you install. Budget for it honestly; it is the second hardest
engineering problem here after combat netcode, and it does not need to
exist until Stage 3.

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
**It is abandonment** — caused by long stretches with nothing playable.
Every stage below ends in something you can put in front of a person.

**`combat.md` §9's prototype is the first target, but it is not the
first step.** As specified it combines animation-driven combat,
custom netcode, and latency reconciliation — a wall for a first
project. It stages cleanly, and each stage is independently playable:

### Stage 1 — learning the engine by building the real thing

*Stage 1 is built and playable in a browser — every step except step 4's
tuning pass, which needs a controller. Built in Godot, which as of
2026-09-14 is the engine (L54) rather than an experiment.*

1. ✅ **Move and look.** A character controller, a camera, a flat test
   room. Nothing from the design yet — this is the tutorial.
2. ✅ **Dodge.** A roll with invulnerability frames and a recovery
   window. This is the first real piece of `combat.md` §1.
3. ✅ **Attack and hit.** One weapon, committed animation, a hitbox, a
   training dummy that reacts.
4. **Stamina — wired, not tuned.** The §2 economy: attacks, dodges,
   sprint. All three draw on the bar, and the enemy pays for its swings
   out of the same one. **What is left is the tuning**, and it is the
   first step that needs a controller rather than a screenshot.
   `prototype/spar.gd` can now answer the half that is not about feel —
   whether any one answer is strictly better — and as of 2026-09-14 it
   says no: see the box below.
5. ✅ **One enemy, three attack shapes.** §6's vocabulary — quick,
   heavy, committed — with distinct wind-ups, reach, arc and damage,
   and the committed attack unparryable by rule. *The dodge is no
   longer a trick: standing still for 30 seconds costs 342 damage and
   two deaths; dodging the wind-ups costs none of it.*
   **Caveat on §6's actual requirement:** the heavy and the committed
   currently share one clip at different speeds, so they are told apart
   by timing rather than by shape. §6 calls animation readability a
   hard requirement, so this is a real gap —
   `assets/SPEC-attack-clips.md` asks for the three distinct clips that
   close it.
6. ✅ **Parry.** The hardest single-player piece, and the heart of the
   game's combat. A tight window that survives §7's latency envelope, a
   refund on success and none on failure, an unparryable committed
   attack, and a 0.9s stagger that is genuinely a free punish —
   measured: parry, free again in 0.12s, punish lands.
   **What it also surfaced, which is more important than the feature:**
   see below.

**Stage 1 is the honest test of whether this project happens.** It is
months of work for someone learning, it is entirely single-player, and
at the end you can hand someone a controller and watch their face.
**Judge it on feel, not completeness** — and on whether you still want
to keep going.

### Stage 2 — the L39 gate proper
7. **Two clients, one server.** Networked combat, server-authoritative
   damage, client-authoritative defensive windows.
8. **The latency slider.** 0–150ms injection, then tune until 100ms is
   indistinguishable from 0 (`combat.md` §7 and §9).

*This is where L39 is actually passed or failed. It cannot be
attempted before Stage 1 exists.*

> ### ✅ What Stage 1 found: the vocabulary works, and L56 is measurably right
>
> `prototype/spar.gd` fights the same seeded enemy several ways and
> reports what each is worth. Four seeds, forty seconds each, striking
> into openings only:
>
> | Strategy | Kills | Dealt | Taken | Openings made |
> |---|---|---|---|---|
> | Dodge everything, **away** | **0** | 56 | 26 | 2 |
> | Dodge everything, **around** | 4 | 524 | 59 | 21 |
> | §6's answers, dodging away | 4 | 826 | 176 | 31 |
> | §6's answers, dodging **around** | 8 | 1020 | 176 | 40 |
> | Parry everything you can | 10 | 1376 | 66 | 51 |
>
> **L56 is vindicated by the numbers.** "A dodge repositions, it does
> not merely evade. Dodging *toward*, *around* and *through* are all
> real options, so exchanges circle rather than shuffling back and
> forth on a line." Dodging *away* produces two openings in a hundred
> and sixty seconds and kills nothing. Dodging *around* — the identical
> mechanic, aimed differently — produces twenty-one and kills four.
>
> **And parry is the high-reward answer §2 says it is**, on every axis
> at once: most kills, most damage dealt, least damage taken. That last
> is bot-flattered, because it parries 0.22s quick wind-ups no human
> could read — which is exactly why §6 gives the quick attack to the
> dodge. The realistic line is "§6's answers, dodging around", and it
> is second.
>
> ### ⚠️ And a correction, because this was recorded wrong first
>
> **This section previously said the dodge was strictly dominant and
> that §6's three answers collapsed into one.** That was measured with
> a bot that only counted damage *taken* and never tried to win —
> under which metric refusing to fight is optimal, and the boxer who
> runs away is champion. Counting kills reverses the finding
> completely.
>
> The lesson is not about dodging. **A metric that does not include
> the goal will confidently rank the strategies that ignore it first**,
> and it took a deliberately disciplined bot to see it.

### Stage 3 onward — the game
9. **One crafting pipeline, end to end.** Ore to sword, every stage
   playable, rolled properties, a maker's mark, durability, repair.
   Proves the flagship system (L4/L38) and the item data model.
10. **One town, one wedge.** Streaming, mounts, a shop, an NPC
    shopkeeper, a delve mouth, monsters using §6's vocabulary. The
    first thing that feels like Marrowmark.
11. **Persistence and accounts.** Characters, the account/character
    split (§4), death and durability, shrine respawn.
12. **The prototype-only risks**, now answerable: contested-delve
    pressure (`feasibility-review.md` §4.3) and crowd budgets.
13. **P11's slice gate** (`brainstorm.md` §9.8) — six voice NPCs, one
    rumor that arrives wrong, one epoch flip. Also where real per-turn
    cost gets measured, which settles the open L27 collision.
14. **Everything else**, in whatever order the game demands by then.

## 7. What to deliberately not build

- **Custom engine.** Ever.
- **Custom asset pipeline** beyond what Unity gives you.
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

## 8. How this actually gets built **[the working method]**

One developer, new to gamedev, working with an AI collaborator. The
division of labour is not negotiable — it follows from what each side
can physically do.

> ⚠️ **Rewritten 2026-09-13, updated 2026-09-14.** This section
> previously said the collaborator could not see a viewport, press
> Play, or look at the game. **That is no longer true**, and the
> difference is a large part of why L54 is now Godot.

### What actually happens

The collaborator authors the project as text, builds it headless
against a software rasteriser with no GPU, exports it to the web, loads
the real build in a browser at phone size, drives it with simulated
touch, and **looks at the result**. Stage 1 steps 1 to 3 were built
this way without the developer's machine being involved at any point.

That loop has caught things no amount of reading would have: a
character walking off the edge of the world, a camera fine on a laptop
and showing nothing but sky on a phone, a walking speed no thumb could
reach, three broken character deliveries that passed every structural
check, an input that fired on press instead of release, and taps being
silently eaten below ten frames a second.

**It has limits, and they are sharp.** The verification browser renders
at three to four frames a second, so anything about *timing felt in the
hand* is unmeasurable there — and at that frame rate, input timing
itself misreports, which has to be designed around rather than assumed
away. Screenshots are stills. Nothing here judges feel.

**What is still yours by necessity.** Nothing about the loop above
removes the need for a human to open the editor when something is
genuinely visual — laying out a level by eye, judging a material, or
any moment where "does this look right" is the question. The loop
reduces that surface; it does not erase it.

> **For the record, because it is why L54 moved:** on Unity this
> division would be far worse. The collaborator could write every C#
> script, scene and prefab file and explain all of it, but could not
> open the editor, press Play, or look at the result — so nothing would
> be known to work until the developer pulled it. That asymmetry, more
> than any feature comparison, is what settled the engine.

**And one thing is permanently yours: judging feel.** `combat.md` §9's
gate is *"does this feel BotW-good at 100ms."* No one who cannot hold
the controller can answer that. The collaborator builds it; you decide
whether it is right. Treat its combat numbers as first guesses to be
overwritten, never as tuning.

**The loop:**
1. You describe what should happen, or point at what feels wrong.
2. The collaborator writes it, builds it, verifies it by rendering and
   by driving the real build, and publishes it.
3. You open a URL on any device and report back — usually "the
   recovery is too long", which is the half of this it cannot do.
4. Repeat.

> **Hardware note (revised 2026-09-14).** The hardware question has
> stopped being interesting, which is itself part of why L54 moved.
> **Godot 4 runs comfortably on the 2017 MacBook Air** — a ~100MB
> download, no compile cycle, no domain reload — and more to the point,
> Stage 1 steps 1–3 were built without that machine being switched on.
>
> A better machine is still wanted eventually, and a **Windows PC** is
> the right buy when it happens: PC is the first ship target (L53) and
> console SDKs are Windows-only later. It blocks nothing now.
>
> *Superseded: this note previously argued about Unity 6.6 on Intel
> Macs, and about Built-In versus URP. Neither applies.*

**Getting started, concretely:**
- **The project already exists.** `prototype/` is it. Download **Godot
  4** (about 100MB, runs fine on the 2017 Air), open that folder as a
  project, press Play. Nothing needs creating.
- Pin the version, and keep the pin inside what **W4 Consoles**
  supports (currently 4.4–4.6) so the console path stays open.
- Set up **Git LFS** before committing any large binary assets —
  retrofitting LFS after the fact means rewriting history. Note
  `.gitattributes` already unsets LFS under `docs/`, because GitHub
  Pages serves LFS pointers rather than files.
- The design docs stay in `design/`. They are the specification the
  code is written against, and they stay authoritative: when code and
  a lock disagree, the lock wins or the lock changes on purpose.

---

## Open questions

- [x] **PC-first sequencing** → **L53**. All four platforms and full
      crossplay remain committed; consoles are sequenced after PC, and
      designed for from day one so they stay a port, not a retrofit.
- [ ] Database choice and hosting model (backend language is settled
      by L54 — C#, shared with the client).
- [ ] Region border handoff design — the hardest problem after combat
      netcode (§3).
- [ ] Whether zone servers are one process per region or further
      subdivided under load.
- [ ] Asset strategy specifics: which marketplace ecosystems, and the
      unifying art treatment that makes bought content cohere (§1).
- [ ] Git LFS setup before the first binary asset lands (§8), and
      build infrastructure later.
- [ ] Legal entity, and **trademark clearance on Marrowmark** (see
      `naming.md` §5) — both needed before any public-facing material.
