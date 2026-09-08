# Marrowmark — Live Operations

What a server is after its first year, what the operator actually
turns, and what they must never touch.

---

## 1. The Revelation Arc is an overture, not the game **[core — L77]**

The worry that produced this document: a server finishes the Arc
(Myth → Whispers → Unveiling → Scouring → Wonder), the mystery is
solved, the myth-breaker is named on the Monument — and then what?

**Look at what is actually still running.**

| System | Why it does not end |
|---|---|
| **War** (L25) | Rights are held for a season and then contested again. There is no final map |
| **Economy** (L26, L59) | Every repair costs an item its life, so gear leaves the world forever and crafters refill it forever |
| **Incarnate seats** (L10, L30) | Held by the living, and the Interior's entropy guarantees every holder eventually falls. Seats cycle without any timer |
| **The Interior** (L30) | A permanent frontier. Nobody comes back, so it is never cleared |
| **The Monument** (L13) | Accumulates names for as long as the world runs |

**Everything structural in Marrowmark is cyclical by construction.**
What the Arc spends is one thing only: the surprise that magic exists
at all. That was always a one-time overture, and L36 said so — *"the
information secret is expected to break at internet speed; the
mechanical climb is what's paced."*

So the second year is not an empty world. It is the game, without the
opening.

## 2. What a newcomer in year three actually loses — and does not

**Loses:** the surprise. They are told magic is real instead of finding
out. That is a genuine loss and should not be talked around.

**Does not lose — and this is most of it:**

- **The climb.** They still have to awaken, find a teacher, and work up
  the tiers. L36 paced the *mechanical* road precisely because the
  informational one cannot be protected.
- **Which spells this world has** (L36, layer 2). Per-server facts a
  wiki cannot spoil, because they differ per world.
- **Who holds the seats, and whose lineage they would be joining.**
  Live, contested, and changing.
- **The Interior**, which is untouched by any of it.
- **The secret canon** (`lore.md` §9), answered only at the Heart, and
  the Heart is reached once per server if at all.

**The design already accounted for this.** L36's layered structure was
built so that layer one is sacrificial and layers two through four are
per-server facts. A late joiner arrives after layer one has fallen and
finds the other three intact.

## 3. The answer to "I want to be there at the start" is a new world **[L78]**

Some players want the Myth epoch — the fog, the rumours, nobody knowing
anything. That appetite is real and it cannot be served by an old
server.

**So new worlds open on a cadence, and there is always a young one.**
This is also L16's launch-surge answer, already on file: *more worlds,
never bigger ones*, because the fame logic depends on smallness.

**Rebirth makes moving cheap without breaking anything** (L37). A
player who has seen a world's whole arc starts fresh on a new one
keeping account flair — and, critically, **their P12 marks**. Starting
again is therefore not a loss but a *step*: another life, and possibly
another Incarnate seat, on the road to six.

That closes a loop the design did not obviously have when P12 was
raised. **The second-year problem and the Age of Gods turn out to be
the same mechanism seen from two ends** — the reason to start again and
the reward for having done so.

**Old worlds are not retired for being old.** They run while they hold
a functioning economy. Retirement is a population question, not an age
one, and it uses rebirth when it comes.

## 4. What the operator actually turns

Four dials, and only four.

**1. The awakening valve.** `feasibility-review.md` §3.3 calls this
*"the single most important live-ops dial in the game"* and instructs
that it be built as a dial rather than a constant. It governs the rate
at which awakening events seed. Turn it down and a world stays in Myth
longer; turn it up and the fog lifts.

**2. Epoch arming conditions** (L41). Thresholds *arm* an epoch; a
named player act *fires* it. The operator tunes the arming, never the
firing — see §5.

**3. New world cadence.** How often a fresh server opens, against how
many young worlds the population can actually fill. Opening too many
is worse than opening too few: a thin world has no economy, and
`feasibility-review.md` §3.1 is clear that player-driven economies die
of thin markets rather than exploits.

**4. Coin faucets by epoch** (`economy.md`). §3.2 found early-server
deflation the likelier failure than inflation — generous at the start,
tightening as wealth accumulates.

## 5. What live-ops must never do **[L79]**

- **Never fire an epoch.** L23 promises each server writes its own
  history through *player-advanced* epochs, and L41 puts the trigger in
  a named player's hands. An operator who turns an age by hand has made
  the server's history staff fiction, and every player who was there
  will know.
- **Never inject a world event that overrides player history.** No
  scripted invasions, no "the gods are angry this week." Events in
  Marrowmark come from players and from world state.
- **Never run a season, a battle pass, or a rotating shop.** L27 forbids
  pay-for-power, purchasable goods a crafter could make, and cosmetic
  gear shops. There is no live-service treadmill to attach.
- **Never rebalance in a way that voids crafted goods.** Every item has
  a maker's name on it (L68). Patching a material's properties devalues
  work somebody did, and their reputation is attached to it.
- **Never resurrect a spent secret.** Once a world is past the
  Unveiling it stays past it. Nostalgia is served by a new world (§3),
  not by rewinding an old one.

## 6. Telemetry: what you have to measure to turn anything

A dial nobody can read is a guess. The minimum instrumentation:

- **Awakened count and rate**, per world — the direct feedback on dial 1.
- **Epoch arming progress**, so an operator can see an age approaching
  rather than being surprised by it.
- **Market depth per goods category per town.** §3.1 names thin markets
  as the likeliest economic failure; this is the early warning, and it
  is also the retirement signal (§3).
- **Time-to-first-awakening** for new accounts, against L36's guard
  rail that at least one slow reliable path must arrive in months,
  never never.
- **Contested-delve pressure** (§4.3) — the design's flagged
  highest-stakes unknown, and unanswerable without measurement.
- **Onboarding gate completion** (`onboarding.md` §7), especially item
  five: whether new players name someone they intend to return to.

**Instrument before launch, not after.** Every one of these is
retrofittable in principle and miserable in practice, and the awakening
valve is useless without the first two.

---

## Open questions

- [ ] New world cadence: how often, and what population threshold
      justifies opening one?
- [ ] What population floor triggers retirement, and how much warning
      do inhabitants get?
- [ ] Does a retired world's history survive publicly — a readable
      Monument after the world is gone? (Leaning: yes. It costs almost
      nothing and it is the whole point of L23.)
- [ ] Can a player hold characters on several worlds at once, or does
      rebirth imply leaving? L37 says rebirth is a fresh start, but not
      whether the old character is deleted or merely left behind.
- [ ] Who operates the dials on a solo project, and how much of it can
      be automated against telemetry rather than watched?
- [ ] Do the Age of Gods worlds (P12) run on the same cadence and
      lifecycle as ordinary ones, or are they a different kind of
      server entirely? Still open from `brainstorm.md` §10.
