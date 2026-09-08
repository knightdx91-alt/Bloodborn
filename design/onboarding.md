# Marrowmark — Onboarding

**The hardest problem in the design.** Every lock in this project is
hostile to a new player: no quest markers (L29), no fast travel (L28),
no class to pick (L18), no recipe list (L4), the best system invisible
(L7), and free-aim directional combat read entirely off the body
(L64/L65) — the steepest learning curve in the genre.

A player logs in with no goal, no marker, no class, and combat they
cannot do. This document exists because that is a real problem and the
answer is not a tutorial.

---

## 1. The core move: you are taught by a person **[core]**

**No tutorial zone. No tooltips. No training dummies in a white room.**
All three would break L20 before the player has seen anything.

Instead: **you begin as somebody's hired hand.** A smith, a carter, a
drover — a working adult with a trade who needs help and has opinions
about how the work is done. They teach you because that is what
employers do, not because a quest system routed you to them.

This is not a framing device. It is the cheapest available answer to
every problem in the paragraph above, and it is **already paid for**:
P11's conversational NPCs (`brainstorm.md` §9) exist to be the display
layer for world state. Teaching is the same job. A master who says
*"mind your left"* is doing what the system was built to do anyway.

**What the master replaces:**

| Instead of | You get |
|---|---|
| A quest marker | "Take this to the Vance farm, it's up the north road" |
| A tutorial popup | Someone watching you work and correcting you |
| A class choice | A trade you were already hired for — and can leave |
| A recipe list | "Watch. Now you do it." |
| A skill tree | An employer who notices you got better |

## 2. Teaching directional combat **[the hard part — L64, L65]**

L65 forbids a guard indicator. Fine — **replace it with a person who
tells you, and let that fade.**

Combat is learned in a **drill yard**, sparring, with blunted steel. No
stakes, no death, endlessly repeatable, and entirely diegetic: this is
how people actually learned. A monster in a field cannot teach you; a
partner who slows down and repeats can.

**The ladder, over the first hours:**

1. **Announced and slow.** Your partner calls the arc before they throw
   it — *"high left"* — and telegraphs at half speed. You are learning
   that direction exists and that your guard must match it.
2. **Announced, real speed.** Same call, no mercy on timing. Now you
   are learning to move the guard fast enough.
3. **Unannounced, one arc.** They stop calling but only use one arc.
   You are learning to *read the body* — L65's actual skill.
4. **Unannounced, two arcs.** Then three. Then everything, including
   the thrust.
5. **They start winning again**, and you go find someone better.

This is the "indicator that fades with skill" idea — but **diegetic, so
L65 survives intact.** The information comes from a person's voice, not
an interface, and it stops because *they* stop, not because a setting
changed. A player who wants it back can ask for it back, out loud,
which is the most Marrowmark sentence in this document.

**Sparring is not a tutorial you exit.** The drill yard stays useful
forever: a veteran learning a new weapon family goes back, and so does
a Company drilling before a declared war (L25).

## 3. The first three hours, concretely

Not a script — a shape. What must be *true* by the end, and roughly
when.

**Hour one — the working day.**
You are hired. You do a piece of ordinary work badly and are corrected.
You are sent somewhere on foot or by horse and it takes long enough
that distance registers as real (L28). You come back. Somebody thanks
you by name.

**Hour two — the yard and the shop.**
Sparring, rungs 1–2 above. Then you need a tool you do not have, and
you buy it — **from a player's shop, with a player's mark on it**
(L26/L68). You have now met the economy as a customer, which is the
right way round: you understand *why* crafters matter before anyone
asks you to be one.

**Hour three — the first thing that is yours.**
You make something, badly, and it is signed with your name (L68). It is
worse than the one you bought. That comparison is the entire crafting
system taught in one moment, without a word of explanation.

Somewhere in here you die — cheaply. First deaths should happen on a
town road or spoke, where L17 costs only durability. **The death ladder
is taught from its bottom rung**, so the player learns that dying costs
something before they ever learn it can cost everything.

## 4. Rules the onboarding must obey

- **Never explain magic.** Not a hint, not a locked door, not a greyed
  entry. L7 and L36 depend on a new player having no idea it exists.
  The word does not appear.
- **Never give a marker.** Directions are spoken, in landmarks. *"Up
  the north road, past the burnt mill."* If a player cannot find the
  Vance farm from that, the world's signposting has failed and the fix
  is in the level design, not a HUD.
- **Never gate the floor.** L38 applies to onboarding too. A player who
  ignores every piece of advice and wanders off must still be able to
  make things, fight badly, and survive. Advice is available, not
  compulsory.
- **Never lock the player in.** The master can be quit at any moment. A
  player who wants to walk into the woods on minute three should be
  allowed to, and should find the world hard but not sealed.
- **Never repeat it.** A second character on the same account skips
  everything. The apprenticeship is offered, not enforced.

## 5. What it must not cost

**Onboarding is where a grounded game is most tempted to betray
itself.** The failure mode is a tutorial that quietly turns Marrowmark
into a normal MMO for three hours and then hands the player a different
game. Specific temptations to refuse:

- A quest log. There is no quest log. What you were asked to do is
  something you remember or ask about again.
- A "recommended" trade. There is no recommended trade.
- Combat that is easier during onboarding and then is not.
- An NPC who follows you and comments. The master stays where their
  work is; you come back to them.

## 6. The honest cost

**This design cannot onboard everyone, and pretending otherwise would
be dishonest.** Free-aim directional combat, no markers, no fast
travel, and a hidden best system will lose players who would have
enjoyed a gentler game. That is a real, accepted cost of L64/L65 and
L28/L29 — not a problem to be solved by adding the things those locks
removed.

What onboarding can do is make sure that the players who **would** love
this game are not lost to confusion in the first hour. The target is
not universal retention. It is that nobody quits without having
understood what they were being offered.

## 7. The gate

Modelled on `combat.md` §9 — a thing to test, not a feeling to have.

**After three hours, without ever being shown an interface element for
any of it, a new player can:**

1. Parry a heavy blow from an arc they were not told about in advance.
2. Name their trade and describe one thing they can make.
3. Point roughly toward the next town, and say why they would go.
4. Explain what dying cost them last time.
5. Name one person — player or NPC — they intend to go back to.

**Item 5 is the real gate.** The other four are competence; that one is
whether the world got its hooks in. If testers can do the first four
and not the fifth, the onboarding works and the *game* does not, and
that is a far more important thing to learn early.

---

## Open questions

- [ ] Do all six towns support the apprenticeship, or does a new player
      arrive somewhere specific? Per-town masters is content volume;
      one starting town fights L1's symmetry.
- [ ] How many trades can hire you at the start, and does the choice
      close anything off? (L18 is classless, so it must not.)
- [ ] Sparring partners: NPC only, or can players teach players? The
      second is enormously better for a living world and needs an
      incentive that is not exploitable.
- [ ] What does a returning player's second character actually skip,
      and how is that offered without a menu?
- [ ] Does the master ever become a real relationship — a source of
      work, rumour, and eventually the slow awakening path L36
      guarantees — or do they fade once you outgrow them?
- [ ] The first death should be cheap, but it should not be *staged*.
      How do you make it likely without arranging it?
