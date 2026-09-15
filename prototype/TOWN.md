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

## ⚠️ The open question: L88

`world_state.gd`, `boards.gd`, `rumors.gd`, `apprenticeship.gd` and the
toll arithmetic in `shrine.gd` are **real game rules with no C#
counterpart and no tests.** `sim/` has no town, npc or rumour code at
all.

**L88 is explicit that `sim/` stays authoritative and the prototype
mirrors it**, and the reason is written into the lock: rules in two
places drift, and rules in the engine-facing copy cannot be tested or
reused by the server Stage 2 is about to build. Contract generation
from world state is precisely the kind of thing that will need to run
server-side.

Either Thornfield is understood to be a throwaway UX sketch, or these
move. It is a fork worth choosing rather than drifting into.
