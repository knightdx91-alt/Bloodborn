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

## 2. Engine: Unity **[DECIDED — L54]**

**Unity, URP, current LTS.** Chosen 2026-09-08 over Unreal 5, which
this document previously recommended. The reasoning changed when two
facts entered it: the developer is **new to gamedev**, and an **AI
collaborator is a major part of the labour**. Both point the same way.

**Why Unity here:**

- **Everything is text.** C# scripts, scenes and prefabs (YAML), and
  editor tooling are all readable and writable by an AI collaborator.
  Unreal's Blueprints are binary `.uasset` files — opaque, and also
  the way most solo Unreal developers actually work. Choosing Unreal
  would mean a collaborator blind to a large share of the project.
- **One language everywhere.** §3 makes clear the MMO server is custom
  work regardless of engine. In Unity that server is C# — the same
  language as the client, sharing the same data structures and
  potentially the same simulation code. For one person, a single
  language across client, server, and tools is worth more than any
  rendering feature.
- **The gentlest learning curve of the serious engines**, with the
  deepest tutorial ecosystem — which matters when the developer is
  learning the craft and the project simultaneously.
- **Faster iteration.** No C++ compile cycle between having an idea
  and seeing it.

**The honest cost.** Unreal's Nanite and Lumen remove weeks of manual
optimization per environment, and that solo-art-leverage argument —
the original reason this document said Unreal — remains true. Unity
will mean more hand-optimization and a lower out-of-box visual
ceiling. **This is the right trade for Marrowmark specifically**,
because the game's distinctiveness is its systems (economy, crafting,
war, secrecy) rather than its fidelity, and systems are exactly what
the collaboration is good at.

**Render pipeline: URP**, not HDRP. URP scales across every target in
L15/L51 including Switch 2, is far lighter to learn, and its ceiling
with good art direction is well above what this project needs. HDRP
would look better on PC and hurt everywhere else.

**Version:** take the current **Unity 6 LTS** from Unity Hub. Pin it
and do not chase releases mid-project — engine upgrades are a cost
with no gameplay upside.

*A funded studio with an art team would likely still choose Unreal.
This decision is correct for these constraints, not universally.*

### ⚠️ L54 under review — the Godot challenge (2026-09-13)

**New evidence has undermined one of the two reasons Unity was
chosen.** Recorded here rather than acted on, because a locked engine
should not change by drift.

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
| Asset marketplace depth | Much deeper | Thinner |
| Console path (L53) | Direct | Third-party porting house |
| One language client/server/tools | Yes (C#) | Yes when shipping, **no for the web build** — see below |

**The honest shape of the trade is a question of *when*.** Unity's
advantages — marketplace depth for §1's buy-the-content strategy, and
the console path — land at **Stage 3 and beyond**, a year or more out.
Godot's advantage lands **today**, and compounds every week: it is the
difference between the engine work happening and not happening.

**Not yet decided.** What would settle it:

- Whether Godot's asset ecosystem can actually carry §1's strategy, or
  whether Unity Asset Store purchases can be converted at acceptable
  cost (many formats are engine-neutral; many are not).
- What third-party console porting actually costs against L53.
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

**Interim position:** the prototype in `prototype/` is Godot, because
that is what can be built now. L54 stands until the questions above are
answered, and the prototype is explicitly not a commitment.

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

*Steps 1 to 3 are done and playable in a browser (2026-09-13), built in
Godot because that is what could be built without a PC. See the L54
review in §2 — the prototype is not a commitment.*

1. ✅ **Move and look.** A character controller, a camera, a flat test
   room. Nothing from the design yet — this is the tutorial.
2. ✅ **Dodge.** A roll with invulnerability frames and a recovery
   window. This is the first real piece of `combat.md` §1.
3. ✅ **Attack and hit.** One weapon, committed animation, a hitbox, a
   training dummy that reacts.
4. **Stamina.** The §2 economy: attacks, dodges, sprint. Tune it until
   panic-rolling actually punishes. *All three already draw on the bar,
   so this is a tuning pass rather than construction — and the first
   step that would rather have a controller than a screenshot.*
5. **One enemy, three attack shapes.** §6's vocabulary — quick, heavy,
   committed — readable by animation and sound alone. *The step that
   makes the dodge mean anything: so far nothing has ever swung back.*
6. **Parry.** The hardest single-player piece, and the heart of the
   game's combat.

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

> ⚠️ **Rewritten 2026-09-13.** This section previously said the
> collaborator could not see a viewport, press Play, or look at the
> game. **That is no longer true**, and the difference is the whole
> reason L54 is under review. What follows describes both paths,
> because which one applies depends on an engine choice that is not
> settled.

### On the Godot path — what has actually been happening

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

### On the Unity path — what the division would be

**The collaborator can:** write and read every C# script, scene and
prefab file (all text in Unity), the server backend, editor tooling
that automates repetitive setup, and tests. It can explain any of it,
which is the part that matters most while learning.

**The collaborator cannot:** open the editor, drag anything, press
Play, or look at the result. Anything that must happen in the Unity GUI
— importing assets, wiring a scene, configuring an animator, tuning a
material — is yours, though editor scripts can shrink that surface a
lot. **This is the asymmetry that put L54 under review:** the same work
on the Godot side happens end to end without you.

**And one thing is permanently yours: judging feel.** `combat.md` §9's
gate is *"does this feel BotW-good at 100ms."* No one who cannot hold
the controller can answer that. The collaborator builds it; you decide
whether it is right. Treat its combat numbers as first guesses to be
overwritten, never as tuning.

**The loop, on the Godot path:**
1. You describe what should happen, or point at what feels wrong.
2. The collaborator writes it, builds it, verifies it by rendering and
   by driving the real build, and publishes it.
3. You open a URL on any device and report back — usually "the
   recovery is too long", which is the half of this it cannot do.
4. Repeat.

**The loop, on the Unity path:** as above, but step 2 stops at
"writes it", and you pull and press Play before anything is known to
work at all.

> **Hardware note (2026-09-08).** An earlier draft said the
> development Mac could not run Unity. That was an overstatement. A
> 2017 MacBook Air on Unity 6.6 handles Stage 1 — grey rooms, a
> capsule, a few dummies — perfectly adequately. Iteration is slow
> (recompile and domain reload on a dual-core) and 8GB is the pinch
> point, but it is not a blocker. It becomes one around Stage 3, when
> towns stream and bought assets accumulate. Intel Mac support is
> deprecated at 6.6 and **removed at 6.8**, so pin the version.
>
> **For the Stage 1 prototype specifically, use the Built-In Render
> Pipeline rather than URP** (L54). URP compiles a large shader library
> up front, which is the single slowest thing this hardware will do,
> and nothing in Stage 1 needs it. Switching later costs nothing when
> there is no art to convert.

**Getting started on Unity, concretely** — if L54 is confirmed:
- Install **Unity Hub**, then the current **Unity 6 LTS**.
- Create a **3D (Built-In Render Pipeline)** project — see the hardware
  note above, which is the reason, and which overrides L54's original
  URP line for Stage 1. Pin the version; do not upgrade mid-project.
- Put it in this repository under `game/`, and set up **Git LFS**
  before committing any binary assets — retrofitting LFS after the
  fact means rewriting history.
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
