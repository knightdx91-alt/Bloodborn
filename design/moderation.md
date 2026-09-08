# Marrowmark — Moderation & Trust and Safety

**The largest uncovered risk in the project**, and unusual enough that
generic MMO practice does not cover it. Several locks deliberately
removed the tools most games moderate with.

---

## 1. What makes this game's exposure unusual

| Lock | What it removed or added |
|---|---|
| **L46** | Proximity voice is **always audible with no in-game mute**. The standard first tool is gone by design |
| **P11** | An LLM behind every named NPC — **output** moderation, which is far harder than input |
| **L26** | A player-driven economy with real value to defraud people of |
| **L73** | Knowledge as property, so there is now something to steal that is not an object |
| **L29/L26** | **No global chat and no global auction house** — so there is very little text to moderate, which is the medium moderation is built for |
| **L16** | Small worlds, ~5–10k characters |

The first five are liabilities. **The sixth is the most valuable
moderation asset in the design, and it is free.**

## 2. The line: fiction, not friction **[core — L74]**

The single most important rule, because getting it wrong destroys the
game faster than any griefer.

**Marrowmark is an adversarial world on purpose.** It *wants*:

- Banditry and cargo looting — `feasibility-review.md` §2.5 calls this
  "intended gameplay (salvage/banditry), not grief"
- Betrayal — L35 says Succession Trial alliances "end in betrayal by
  design"
- Hard bargains, cornered markets, price gouging, ruinous rents
- Wars declared on people who did not want one
- Circles funding both sides of a conflict (L25)
- Lying. NPCs lie, rumours are wrong (L48), and players may too

**None of that is a moderation matter.** A player who robs your caravan,
breaks their word, or bankrupts your shop has played the game
correctly, and any policy that treats it as abuse is a policy that
deletes the game.

**The line is harm to a person, not harm to a character.** Slurs,
sexual harassment, threats, targeting someone's real identity, stalking
across sessions, and organised brigading are the actual surface — and
none of them require any in-fiction pretext to recognise.

> **Test for any report:** would this still be wrong if the game had no
> rules at all? Robbery would not. What was said while doing it might
> be.

## 3. Layer one: the world punishes you **[the cheap layer]**

The design's own properties do more moderation work than any tooling,
and they cost nothing extra because they already exist:

- **Small worlds with permanent names** (L16). Reputation is real and
  local. There is no crowd to disappear into.
- **Maker's marks on everything** (L68). Sell rubbish under your own
  name and the name is what suffers.
- **NPCs may dislike you and walk off** (L47). `brainstorm.md` §9.6
  already calls this "the best moderation tool on this list" — an NPC
  who stops talking to someone abusive is a consequence delivered
  entirely in fiction.
- **Conversation ownership** (§9.6): the initiator holds the floor, and
  disposition drops toward an interloper rather than the person they
  are pestering.
- **Charters carry reputations** (L24). A Company known for harbouring
  a griefer pays for it in recruitment and contracts.
- **The Monument never forgets** (L13).

**Design principle: prefer a consequence to a punishment.** A player
whose reputation collapses, whose NPCs will not deal with them, and
whose charter drops them has been dealt with more thoroughly than a
three-day suspension achieves — and the story is better.

This layer handles the ordinary jerk. **It does not handle malice, and
pretending otherwise is how games get this wrong.**

## 4. Layer two: the player's own tools

- **Platform block and mute.** Mandatory — every console requires it
  for player-to-player voice (`combat.md`-adjacent, L46's note). It is
  account-level and per-player, and it is **not a gameplay toggle**: a
  blocked player is silenced for you, and nothing about the world
  changes.
- **Blocking is symmetric and quiet.** No notification, no in-world
  tell. A block that announces itself invites retaliation.
- **Report with a rolling buffer.** In a voice game there is no chat
  log, so the reporter's client keeps a short rolling local audio
  buffer and submits it *with* the report — never continuously, never
  server-side by default. This is the only workable way to evidence
  voice abuse, and its privacy shape must be stated plainly in-product.

**Deliberately absent from this layer:** a karma system, a community
reputation score, or any mechanism that lets players formally judge
each other. Those become weapons within a week, and they turn an
adversarial world into a popularity contest. Reputation in Marrowmark
is what people *say about you*, not a number the game keeps.

## 5. Layer three: the LLM problem **[L75]**

Players will jailbreak the NPCs. This is certain, not a risk.

**What they will try:** make an NPC say something vile and clip it;
extract the system prompt; use the NPC as a laundering channel for
things the player cannot say themselves; talk an NPC into promising
something the game cannot deliver.

**What actually protects the project:**

- **The model never mutates state (L49).** It emits intents; every
  binding one stops at explicit confirmation. This was written as a
  design rule, but it is equally a **security property**: a fully
  jailbroken NPC still cannot move coin, gear, escrow or enrollment.
  It is the difference between an embarrassing clip and an incident.
- **Secret canon is absent from the corpus, not forbidden within it**
  (§9.6). Per epoch, the retrievable set simply does not contain what
  the player is fishing for. **You cannot extract what is not there** —
  this is the strongest protection in the design and it is worth
  restating as security rather than only as fiction.
- **Output moderation on every generated line**, not just input.
  Input-only filtering fails against jailbreaks by construction.
- **The in-fiction failure mode** (§9.6): a refusing NPC gets confused,
  loses the thread, and turns away. Never "I can't help with that,"
  which both breaks L20 and tells a jailbreaker exactly where the wall
  is.
- **Generated gossip has a fixed noun space (L48).** The model can
  invent meaning but never new proper nouns, so it cannot mint content
  that propagates through the rumour system as fact.

**Accept that clips will exist.** The goal is not zero — it is that the
output of a successful jailbreak is *boring*: a confused peasant who
wanders off, not a quotable atrocity. Design the failure to be
unrewarding rather than impossible.

## 6. The economy: crime versus fraud

Hardest judgement calls live here, because the economy is adversarial
by design.

**Play, not abuse:** cornering a market, undercutting to ruin a rival,
overcharging a desperate buyer, hiring bandits, insuring a caravan and
losing it honestly, copying a schematic you legitimately obtained.

**Abuse:** real-money trading, account theft, exploiting a bug in
escrow or commissions, and any scam whose mechanism is a *lie about how
the game works* rather than a lie about the world. Convincing someone a
mine is rich when it is not is play; convincing them a UI button does
something it does not is fraud.

Two named follow-ups already on file from `feasibility-review.md` §2.6
and `economy.md`:

- **RMT enforcement must cover the Veiled Ring's shadow book.**
  Unlicensed betting on Succession Trials is a real-money laundering
  vector, and it is the one place where in-fiction crime and actual
  crime touch.
- **Insurance claims must key off what the server can prove.** The
  death, the looters and their identities are all recorded — design the
  product around that, not around trust.

## 7. What this will cost, honestly

- **Always-audible voice (L46) will produce more harassment than a
  private-by-default design would.** That is an accepted cost of a
  deliberate choice. Under the minimal-intervention posture (§0) most
  of it is answered by blocking and by the world's own consequences
  rather than by staff.
- **Even the mandatory floor is not free.** Voice reports need a human
  to listen, and that does not scale like text. A solo or small team
  cannot staff much of it — a real argument for **a small first world
  and slow growth** rather than a wide launch, and for keeping the
  actionable list as short as §0 makes it.
- **Per-turn LLM output moderation is a cost on every conversation**,
  and it lands on the same budget as P11's open collision with L27.

## 8. Non-negotiables

1. **Never moderate the fiction.** Robbery, betrayal and ruin stay —
   nor anything above the legal floor (§0). Rudeness is not an offence,
   and unpleasantness is not enforcement's problem.
2. **Never let an LLM be the authority on state** (L49). No exceptions,
   no "trusted" NPC class.
3. **Never announce a block or a report** to its subject.
4. **Never record audio continuously**, server-side or otherwise.
5. **Never ship an "I can't help with that" NPC.** The failure is
   always in fiction.
6. **Never let a moderation tool become a gameplay tool.** Blocking is
   safety; it must confer no advantage and impose no in-world effect.

---

## Open questions

- [ ] What exactly sits on the actionable list, written as a short
      explicit set rather than a principle. §0 says "the legal floor";
      that has to become a list somebody can apply at 2am without
      making judgement calls.
- [ ] Who listens to a voice report at launch scale, and what does one
      incident cost in time? Small under §0, but not zero.
- [ ] Rolling buffer length, retention, and how its privacy shape is
      communicated in-product.
- [ ] Does a charter (L24) bear formal responsibility for its members,
      or only informal reputational cost?
- [ ] Is there any in-fiction expression of a ban — an epitaph line, a
      name struck from the Monument — or is enforcement kept entirely
      out of the world? (Leaning: entirely out. Punishment dressed as
      lore invites players to treat it as content.)
- [ ] Appeals, and who hears them.
- [ ] How the companion app (L31) handles reports, given it is the one
      surface a player can reach when not in the world.
