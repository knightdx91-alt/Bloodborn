# Thornfield — the town prototype

The second of the two prototypes. `launcher.tscn` boots first and
offers **Drill Yard** (combat, `main.tscn`, documented in `README.md`)
or **Thornfield** (`town.tscn`). The two share the repository and
nothing else — the town build left every combat file untouched.

Written after the fact, by reading the code: the town arrived across
five commits with no documentation of any kind, and this file is the
record that should have come with it.

## Running it

```
godot --path prototype                  # launcher, then pick
godot --path prototype town.tscn        # straight to Thornfield
```

Verified to instantiate at 439 nodes against Godot 4.3, alongside the
yard's 91.

## What is actually there

| Piece | Where | What it is |
|---|---|---|
| Town geometry and dressing | `town.gd` | Harvest-town layout from CC0 Quaternius kits. Licence evidence is recorded in `assets/town/LICENSE-QUATERNIUS-CC0.txt` |
| Walking around | `town_player.gd` | A town-speed player, separate from the yard's fighter |
| People | `npc/roster.gd`, `npc/npc.gd` | 9 conversational townsfolk and ~25 for crowd barks, standing where their work is (`onboarding.md` §5) |
| Ambient talk | `npc/bark_bank.gd` | Epoch-filtered lines, so what you overhear changes as the world does |
| Conversation | `npc/conversation.gd` | Walk up, hold to talk, pick a topic. See the gate below |
| Contract & market boards | `town_systems/boards.gd` | Generated from world state, never authored |
| Rumour | `town_systems/rumors.gd` | Source, age and distortion; buying a drink is the search |
| Shrine | `town_systems/shrine.gd` | Respawn and its toll (`lore.md` §3, `onboarding.md` §3) |
| Apprenticeship | `town_systems/apprenticeship.gd` | `onboarding.md` §1 — you begin as somebody's hired hand |
| The state it all reads | `town_systems/world_state.gd` | One seeded object. Boars, caravans, harvest demand, warehoused goods, rumours, coin, hire flags |

**The best thing in it is that the boards do not lie.** `content.md` §3
asks for "systemic work generated from *actual world state*", and
`boards.gd` does exactly that: cull contracts exist because boar
pressure is non-zero and pay scales with it, escort contracts exist
because a caravan is actually mustering and pay scales with the guards
it wants, the harvest contract exists because `harvest_demand > 0`. Set
the pressure to zero and the contract is simply not on the board.

It also answers, in part, an open question `content.md` still lists:
**"Rumor system data model (epoch + history + noise mixing)."** Rumours
carry source, age and distortion; `search()` ranks freshest-first and
penalises distortion; `age_all()` creeps distortion upward with time,
and anything past 0.5 comes back hedged — "Or that's how it came to me.
Drink bends stories."

## The conversation gate, and where it diverges from L49

**No LLM runs in the prototype.** The voice is carried by authored
lines. What the code builds is the *shape* a model would later slot
into, and that shape is two gates:

1. Each topic declares an **intent**. Anything binding — hiring, taking
   a contract, spending coin on a drink — is marked binding and stops
   at an explicit confirm panel before anything happens.
2. Execution goes through a closed **effect table**. An effect with no
   entry is refused rather than attempted.

Gate 1 is `L49` working as written: *"The panel is the gate, never a
receipt for something already done."* A jailbroken NPC could not sign
anything here, which `moderation.md` §5 calls the difference between an
embarrassing clip and an incident. Gate 2 is right too — L49 constrains
what the model may *propose*, and says nothing that requires the game
to own an executor for every proposal.

> ### ⚠️ The INTENT list is a whitelist, and L49 removed that ceiling
>
> `conversation.gd` holds `INTENTS` — five values, with "Anything else
> is refused, never executed." **L49 exists specifically to delete that
> ceiling:** *"No ceiling on what the model may propose; a hard gate on
> what executes... while removing the whitelist's expressive ceiling. A
> misheard sentence can raise a panel; it can never sign one."*
>
> **This is not carelessness, and the fix is not in this file.** The
> five intents are carried *verbatim* from `brainstorm.md` §9.2, which
> named exactly `offer_contract(id)`, `share_rumor(topic)`, `refuse`,
> `set_disposition(-1)`, `none` — and which said nothing about having
> been amended. The town was implemented faithfully against the document
> it was pointed at. **§9.2 has now been annotated**, because a
> superseded passage that does not say so will be implemented again by
> the next person who reads it.
>
> **It breaks nothing today**, since the only things producing intents
> are authored topic cards, and a closed set of authored cards is just
> content. It matters the moment a model goes behind it: a whitelist
> then caps what an NPC can *reach for*, which is the expressiveness
> L49 decided to buy, having already paid for the safety with the panel.
>
> **The "plan §4" both files cited does not exist in `design/`.** The
> real authorities are `brainstorm.md` §9.1 (barks get no model at all)
> and §9.2 (speech is free, action is typed), as amended by **L49** and
> **L75**, with `moderation.md` §5 on why it is a security property and
> not only a design one. Both citations have been corrected.
>
> A second, smaller thing: `offer_contract` is doing double duty as
> "binding", which is why buying a two-penny ale is tagged a contract
> offer. It is gated correctly — coin never moves without the panel —
> but the taxonomy conflates *what was meant* with *whether it binds*,
> and those want separating before a model generates the first one.

**Disposition is flags, not numbers** — warm, uses-your-name, stays to
talk. That is the right call and worth keeping: `L76` explicitly
rejects reputation scores, which "become weapons within a week and turn
an adversarial world into a popularity contest".

## What is placeholder

- **NPC bodies** are the blocky humanoid with a tinted tunic. Real
  civilian bodies are an art pass that has not happened.
- **The world state is seeded once and never persists.** Nothing
  survives leaving the scene.
- **The rules live only here.** See below — this is the open question.

## L88, settled — the rules moved

**The town's rules now live in `sim/Marrowmark.Sim/Town/`, in C#, with
tests.** What stayed in GDScript is the prose and the presentation,
which is where the line belongs.

| Rule | Authority | Mirror |
|---|---|---|
| World state shape | `Town/TownState.cs` | `town_systems/world_state.gd` |
| What work exists, what it pays, taking it | `Town/ContractBoard.cs` | `rules/contract_board.gd` |
| Rumour ranking, ageing, the drink | `Town/RumourMill.cs` | `rules/rumour_mill.gd` |
| One master, binding | `Town/Apprenticeship.cs` | `rules/town_rules.gd` |
| The shrine's toll | `Town/Shrine.cs` | `rules/town_rules.gd` |
| The numbers | `shared/tuning/town.json` | `rules/town.json` |

`town_systems/boards.gd`, `rumors.gd`, `apprenticeship.gd` and
`shrine.gd` are now **thin prose layers** over those mirrors. The board
still says "Blood-warped boars press at the Hedges west (pressure 3 of
5)"; it no longer decides that the contract exists or that it pays 13.

**Where the line is drawn, and why there.** `Contract` carries the
facts — kind, subject, magnitude, pay, taken — and no title or detail.
A test asserts that, because prose creeping back into the rules is the
failure that would make a second town unable to reuse any of this. A
different town phrases the same cull differently; it should not have to
re-derive which culls there are.

**What the port added that the GDScript did not have:**

- **27 tests**, where there were none.
- **`Take` now refuses work that is not posted.** It previously appended
  any string handed to it, so a mistyped id — or a model reaching for a
  contract that had been withdrawn — booked a job nobody was offering.
  This matters precisely because L49 lets the model reach for anything;
  the gate has to be here.
- **`Hire` now refuses a master who does not hire**, for the same reason.
- **The market hides goods at zero quantity.** It previously listed
  anything in the dictionary, including an empty cask rack, which is
  the same lie about the world that `content.md` §3 forbids the contract
  board from telling.

**What it deliberately did not take:** the authored rumour text, the
errand lines, Sarella's words over the shrine stone, and the seed of
Thornfield's own boars and caravans. Those are content. `sim/` stays
engine-free and town-free — it knows what a town is, not which one.

## ⚠️ The QA pass, 2026-09-15 — five things that did not work

Found by checking the thing you actually boot into, rather than the
rules underneath it.

1. **Thornfield had no floor.** `_terrain()` built a 500×500
   `PlaneMesh` — a `MeshInstance3D`, purely visual. The town had **153
   static bodies and not one of them was ground**: 71 of 81 probe
   points across the map were open sky, and the walker fell through the
   world on arrival, reaching y = −43 within two seconds of the scene
   loading. The file header claimed "walkable collision is included";
   that was true of the buildings and of nothing else. Now a thin
   collision box under the visible plane, matched to its extent, same
   shape as the yard's.
2. **The shrine respawned you underground.** With no floor, the only
   thing under the respawn point was a building at y = 2. Fixed by the
   floor.
3. **The pad did nothing in town.** WASD and the on-screen stick only,
   so on the APK — which is how this is actually played — a plugged-in
   controller worked in the yard and was dead here. Left stick walks
   and **A** talks, matching `world.gd` so the two scenes do not want
   different hands.
4. **Picking a scene was a one-way door**, in both directions: no way
   back to the launcher short of killing the app, which on a phone
   means the task switcher. **Start**, or Escape, now returns. In town
   it closes an open conversation first, so it never throws away a
   dialogue you were reading.
5. **The menu clipped.** 72px of title and two 110px buttons came to
   more than 450px of content, and "Thornfield" was cut off the bottom
   of a short window. The launcher now scales to the viewport on **both
   axes** — scaling on height alone blew the title out to 858px inside
   a 720px-wide phone and dragged the buttons off both edges — and is
   checked at ten screen shapes from 360×640 to 1600×2560.

## ⚠️ Reported from play, 2026-09-15 — waist deep in the road

The walker spawned buried to the waist. `_build_body()` offset the model
`Vector3(0, -1.0, 0)`, copied from `world.gd` — where it is correct,
because the yard's capsule is **2m centred on the node origin** and the
model genuinely does have to hang a metre below it to stand on its feet.

The town's capsule is different: 1.8 tall and offset *up* by 0.9, so its
bottom sits on the node origin. The paladin's own feet are also on its
origin — measured, y 0.000 to 1.725 — so the correct offset here is
**zero**, and the inherited −1.0 sank the visible body exactly one metre
into a 1.725m character.

It went unnoticed because the town had no floor until the same day: the
walker fell straight past the problem. **Fixing one bug is what exposed
the other**, which is the usual shape of it.

## Still open

- **The world state is seeded once and never persists.** Nothing
  survives leaving the scene.
- **`offer_contract` is doing double duty as "binding"**, so a two-penny
  ale is tagged a contract offer. Gated correctly; the taxonomy wants
  separating before a model generates the first one.
- **NPC bodies** are still the blocky placeholder.
