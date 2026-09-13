# Marrowmark — Combat

The specification behind L2 (BotW-style real-time action) and L39
(favor-the-defender netcode). Everything here exists to be built from:
if a line cannot be turned into a number or an animation, it does not
belong in this file.

**The gate this document serves (L39):** parry and dodge must feel
BotW-good at real MMO latency before anything else ships. That is the
first thing built and the first thing that can kill the project.

---

## 0. Reference points — what this is and isn't

A north star to compare a prototype against.

**Closest to:** *Dark Souls* / *Elden Ring* for the stamina economy,
attack commitment and reading an opponent. *Breath of the Wild* for
texture — mobility, physicality, freedom of approach (L2 names it, and
it is accurate for feel, though BotW does not actually spend stamina on
attacks; Marrowmark does). *Sword Art Online* for **techniques as
learned, committed motions that carry your body** (§3) — that idea is
genuinely right for this game and is developed below.

**Deliberately not *Skyrim*.** There, attacks cancel freely, light
attacks are free, and outcomes are decided by the character sheet —
perks and enchantments raise your numbers. Marrowmark inverts all
three: attacks are commitments, everything costs stamina, and **skill
buys options while gear buys numbers** (§3). A player with good hands
and a decent sword is dangerous here. That is L19's promise, and it is
the single most important thing not to lose.

**Deliberately not anime-physical either.** No midair multi-hits, no
gravity as a suggestion — see the athletic ceiling in §1.

## 1. The core loop **[core]**

Approach → read the telegraph → commit to an answer → recover → punish.

Every exchange is a series of **commitments**. You commit to an attack
and cannot cancel it; the enemy commits to theirs and cannot cancel it
either. Reading a commitment and answering correctly is the entire
skill of the game. This is why L39 specifies committed telegraph
animations rather than frame-perfect timing — the information is in
the *body*, and bodies are slow enough to survive 100ms of network.

**Three answers, always available, never gated by skill:**

| Answer | Costs | Beats | Loses to |
|--------|-------|-------|----------|
| **Dodge** | stamina, i-frames on a roll | quick attacks, unblockables | nothing directly — but recovery is punishable |
| **Parry** | stamina, tight window | heavy attacks (opens the attacker) | quick flurries, unblockables |
| **Disengage** | stamina, distance | everything | it surrenders position and tempo |

Disengage is listed as a first-class answer deliberately. L19 promises
a skilled newcomer *can always escape*. Escape must therefore never be
skill-gated, gear-gated, or made worse by losing — a fleeing player
with stamina gets away, period.

### Movement is part of the loop, not a pause in it **[core — L56]**

Fights should be **kinetic**. You move while you fight; you do not stop
moving in order to fight. Three rules carry that:

- **A dodge repositions, it does not merely evade.** Dodging *toward*,
  *around* and *through* are all real options, so exchanges circle
  rather than shuffling back and forth on a line. This one change does
  more for the feel of moving-while-fighting than anything else here.
- **Momentum feeds attacks.** A swing out of a sprint is not the
  standing swing — different reach, different commitment, different
  recovery. Without this, fights become run-over-stop-trade.
- **Terrain is fighting space.** Vault the cart, take the high ground,
  climb and drop. L55 already puts climbing on the stamina bar, so this
  needs no new economy — only the freedom to do it mid-fight.

### Mobility is afforded, never required **[core]**

**Standing your ground is a legitimate way to fight, not a failure to
play correctly.** A plate-armoured fighter behind a shield who plants
their feet and trades until the other person runs out of stamina is
playing Marrowmark exactly as intended. L18 is classless: the game
promises builds, and a game that only rewards footwork has one build
wearing different hats.

What everything above buys is *the option* to move — dodges that
reposition, momentum that feeds attacks, terrain worth using. Whether a
player takes that option is a build decision they make with armour,
weapon and skill.

**Both ends of the spectrum spend the same bar, differently:**

- **The mobile fighter** spends stamina on *movement* — dodges,
  techniques, sprints, climbs. They avoid damage entirely and cannot
  afford a mistake, because light armour does not forgive one.
- **The grounded fighter** spends stamina on *absorption* — blocking
  bleeds the bar instead of health (§2), and the shield is a battery
  (§5). They take the hit on purpose and win by outlasting.

That is the elegant part: it is one economy, not two systems. A tank is
not standing still doing nothing; a tank is fighting a **stamina war**
while the duellist fights a **positioning war**, and either can win.

**Armour weight sits on the same encumbrance channel as cargo (L55)** —
plate means a smaller bar to spend. That is the cost that keeps heavy
builds honest, and blocking is the payoff that makes the smaller bar
worth carrying.

**Armour can be changed on the road, and the armour decides how long
that takes (L58).** Stripping down is quick; getting into plate is a
minute and change, and faster with a second pair of hands. Mid-change
you are wearing what you started in, and an interruption loses the
progress — so armouring up is a gamble on having enough time, not a
free action. An ambusher can read a traveller's readiness at a
distance and pick their moment, which is the most grounded kind of
tension this design can produce.

**One budget, and armour and cargo compete for it (L57).** A fighter in
plate hauls almost nothing; a loaded hauler fights badly. That is not a
combat constraint that leaked into the economy — it is the point. It
means **you cannot be both the cargo and the muscle**, which turns
escort work into a real profession rather than a thing players do when
bored, and gives caravans (L26/L28) a reason to hire that no rule had
to invent.

**The ceiling: athletic, not supernatural.** Everything a trained human
body could plausibly do — leaping, vaulting, lunging, spinning
step-throughs. Nothing it could not: no double jumps, no air dashes, no
midair multi-hits, no wall-running. This is what keeps L20 grounded
while still feeling fast.

**And that ceiling is a deliberate saving.** The mortal world is bound
by human bodies, so the first time a player sees someone genuinely
break physics — an Incarnate's true form breaking the one rule its
spell obeys (L34) — it lands like a thunderclap. A game where everyone
already defies gravity has nothing left to spend when magic arrives.
The restraint here is what makes the secret worth keeping.

## 1b. Direction — where the blow goes **[core — L64, L65]**

**Five cutting arcs plus the thrust, aimed freely.** Not a menu of
targets: you point, the arc follows, and the nearest zone snaps on a
controller. Kingdom Come's system, and it shipped on consoles — thumb
precision is the cost, not the barrier.

**Direction is the other half of the telegraph, not a second system.**
§6's shapes (quick, heavy, committed) and the arc are read from one
animation: the weight shift says how hard, the wind-up says where. A
player tracks a single tell and gets both.

**Where blows land:**

| Arc | Lands on |
|-----|----------|
| Overhead | Head |
| Upper left / upper right | Torso |
| Lower left / lower right | Legs |
| Thrust | Torso — the gap-seeker |

This is what makes per-slot armour (L63) worth having. **Which piece of
a harness fails is a record of how its owner was fought.** Keep going
overhead and you ruin their helm; they finish the fight bare-headed,
and everyone watching can see it.

**Nothing is aimed at the arms** — arms are what you raise. Vambraces
wear from *blocking*, so a sword-arm that gives out after a day of
parrying is the most grounded failure this system can produce.

**Guards must match the arc.** An exact match blocks; an adjacent arc
glances it partly aside; anything else lands clean. **Only a thrust
guard stops a thrust** — no cut guard turns a point — which is why a
spear is frightening against someone reading edges. A blocked blow
still carries something through: blocking is a stamina war (§1), never
an off switch.

**And the guard is read from the body (L65).** No indicator, no marker,
nothing on screen — the same rule as §6's telegraphs and L20's refusal
of glowing tells. **This makes animation quality load-bearing rather
than decorative**: if a guard pose does not read at a glance, the
combat does not work, and no UI element may be added to rescue it.

> **Two costs, recorded rather than discovered later.**
> **Animation volume** is now the project's largest content risk —
> five arcs plus thrust, across six weapon families, times light and
> heavy, plus guard poses and directional hit reactions, is on the
> order of 300–400 clips for combat alone. That is beyond hand
> authoring for one person and makes `tech.md` §1's buy-the-content
> strategy load-bearing. **Mitigation: weapon families get different
> direction sets** — a dagger has all five and a thrust, a two-handed
> maul has an overhead and two side arcs and no thrust worth the name.
> Historically true, makes weapons feel distinct, and cuts the matrix
> by a third or more.
> **Onboarding** is now the hardest problem in the design. Free-aim
> directional combat read entirely off the body is the steepest
> learning curve in the genre, and the onboarding document still does
> not exist.

## 2. Stamina is the whole economy **[core]**

**One bar, and it is not only a combat system.** Stamina is the body's
exertion — it governs fighting *and* the physical cost of moving
through a world where nothing teleports (L28). The same bar that pays
for a parry pays for the climb up a riverbank with sixty pounds of ore
on your back.

This is the right shape for Marrowmark specifically. L28 promises
distance is real; a stamina bar that stops at the edge of combat makes
travel free and quietly contradicts it. Making exertion continuous
across fighting, climbing, and hauling is what ties the two halves of
the game together.

**What it governs:**
- All combat actions — attacking, dodging, parrying, blocking.
- Sprinting, climbing, swimming, jumping.
- **Encumbrance**: what you carry reduces the bar you have to spend.
  Cargo (L17/L32) is physical and heavy, so hauling is felt before the
  bandits ever arrive.

**What it does not govern, deliberately:**
- **Walking.** A stamina cost on ordinary movement is misery, not
  tension.
- **Riding.** L28 makes mounts the speed system; taxing them makes the
  whole map worse. The horse has its own limits, not yours.
- **Crafting.** L38's floor rule — no stage may hard-fail a patient
  beginner, and a stamina gate on the flagship system would do exactly
  that.

> ✅ **Confirmed 2026-09-08.** The inclusion and exclusion lists above
> were flagged as interpretation when L55 was locked; they have since
> been reviewed and stand as written, including encumbrance reducing
> the maximum bar rather than raising the cost of every action.

- Attacks cost on **startup**, so a whiffed swing is paid for.
- Dodges cost a flat amount; consecutive dodges cost escalating
  amounts, so panic-rolling drains you.
- A **successful** parry refunds most of its cost. A failed one does
  not. Parry is the high-skill, high-reward answer by construction.
- Blocking bleeds stamina under pressure and breaks your guard at
  zero, leaving you open — the punishment for turtling.
- Sprinting drains slowly. **Fleeing is always affordable**: sprint
  drain is low enough that a player who disengages early escapes.
- **Climbing and swimming drain harder than sprinting**, because they
  are the movement options that should carry real risk — running out
  halfway up or halfway across is a consequence, not an inconvenience.
- **Encumbrance shrinks the bar, it does not slow regeneration.** A
  loaded traveller has less to spend and recovers at a normal rate;
  they are limited, not broken. A caravan guard who drops their load
  before a fight is making a real tactical choice.
- At zero stamina you are not stunned — you are *slow*. Recovery
  frames lengthen, and that is the vulnerability.

Exhaustion should read as a fighter running out of breath, not as a
status effect with an icon.

## 3. Where skill lives (the L18 problem) **[core]**

**The problem:** BotW has no stats. Marrowmark is classless skill-by-use
(L18) with a moderate vertical curve (L19). If skill raises damage
numbers, combat becomes a stat check and the action feel dies. If
skill does nothing, progression is a lie.

**The resolution: skill buys options and consistency; gear buys
numbers.**

Skill-by-use raises:
- **Stamina efficiency** — the same fight costs a veteran less.
- **Recovery frames** — veterans return to neutral sooner.
- **Technique access** — new moves per weapon family, unlocked by use.
  This is where progression is *felt*: a new verb, not a bigger number.
  **Techniques are primarily how you move** (L56): a dash-thrust that
  closes distance, a spinning step-through that puts you behind someone,
  a leaping overhead that crosses a gap, a pivot-cut that carries you
  laterally out of a heavy. Learning a weapon expands *where your body
  can go in a fight*, which is the most satisfying shape progression can
  take and costs nothing structurally — a technique is still a
  commitment, still stamina-priced, still readable by an opponent, so
  §6's grammar survives intact.
  This is Marrowmark's version of a Sword Skill, and it is why a veteran
  is frightening: not because they hit harder, but because they can be
  somewhere you did not expect, sooner than you thought possible.
- **Reliability** — reduced deviation on thrusts, less guard-break
  from awkward angles, steadier aim under stamina pressure.
- **Durability efficiency** — clean hits wear gear less (feeds L3/L32).
- **Parry window** — but only slightly, and capped early (see §7).

Skill does **not** meaningfully raise raw damage. Raw damage comes
from the weapon, and weapons come from players (L4). This is not a
compromise — it is the point. A master crafter's blade in a
newcomer's hands is genuinely dangerous, which is what makes crafters
famous and what makes L19's promise true.

## 4. Damage model **[core — the crafting bridge]**

Three damage types against three armor classes:

|          | Light | Mail | Plate |
|----------|-------|------|-------|
| **Cut**  | strong | weak | very weak |
| **Pierce** | fair | strong | fair |
| **Blunt** | fair | fair | strong |

This exists so that **material properties (L4) reach combat**. A
crafter choosing a harder alloy, a heavier head, or a finer edge is
choosing a position in this table. Armour choice is a real read on
what you expect to fight — and in war (L25) it is a read on what the
other Company fields.

Hit location is simple: torso, limbs, head. Head hits hurt more and
are harder to land. No dismemberment, no wound systems — L20 is
grounded, not simulationist.

**Time to kill** between comparable players: roughly 5–15 seconds.
Long enough that reads and stamina management decide it; short enough
that being ganked is not a ten-minute ordeal.

## 5. Weapon families

Each is a distinct set of verbs, not a damage number with a skin.

- **Sword & shield** — balanced; the shield is a stamina battery that
  trades mobility for safety.
- **Two-handed** — slow commitments, high reward, guard-breaking. Cut
  or blunt depending on the head.
- **Spear & polearm** — reach and spacing; the answer to shields;
  weak once inside its range.
- **Dagger & short blade** — fast, low commitment, pierce; wins on
  recovery frames, loses to armour.
- **Axe & mace** — guard-breakers; blunt or cut; slow recovery.
- **Bow & crossbow** — the ranged option. Draw is a commitment, aim
  sways under stamina, no auto-aim on any platform.

**Every family is viable unarmoured and unskilled** — L38's crafting
floor rule applied to combat: no weapon may hard-fail a beginner.

## 6. Enemy design vocabulary **[core]**

Enemies communicate through three attack shapes, and players learn to
read them in the first hour without a tutorial:

1. **Quick** — short windup, low damage, chains. *Answer: dodge.*
2. **Heavy** — long windup with a visible weight shift. *Answer:
   parry* (highly rewarded — stagger and a free punish).
3. **Committed/unblockable** — the longest windup, whole-body. *Answer:
   disengage.* Cannot be parried, badly punished if dodged late.

**Readability comes from animation and sound only.** No glowing
weapons, no red flash, no on-screen prompt. L20 is grounded: a
shoulder drops, a foot plants, a breath is audible, and steel scrapes
differently for a heavy swing. This is a **hard art and audio
requirement**, not a stretch goal — if the animation doesn't read,
the combat doesn't work, and no UI band-aid will save it.

Monsters (L29's ecology) use the same three shapes with different
bodies. The warped things in deep places break the vocabulary
deliberately — a named horror whose heavy has no weight shift is
terrifying precisely because the grammar is otherwise reliable.

## 7. The latency contract (L39 in detail) **[core]**

**Favor the defender.** When client and server disagree about whether
a dodge or parry landed, the defender wins.

- **Client-authoritative defensive windows.** The client declares "I
  parried at t"; the server accepts it inside a tolerance envelope and
  reconciles. A defender never dies to a hit they clearly avoided on
  their own screen.
- **Server-authoritative damage, position, and death.** Attackers do
  not get client authority. This asymmetry is the whole stance: the
  worst an exploiting client can do is *survive* things, which is
  visible, statistically detectable, and bannable — rather than
  *kill* things, which is not recoverable.
- **Tolerance envelope tuned to ~100ms** and clamped hard. Beyond the
  clamp the envelope stops widening, so a player on a 400ms connection
  gets a fair-feeling game against monsters and a disadvantaged one in
  PvP. That is the correct trade.
- **Parry windows stay wide enough to survive the envelope.** This is
  why §3 caps skill-based window growth early: a window that scales
  freely with skill eventually shrinks below what netcode can
  adjudicate honestly.
- **No rollback of death.** A player who has seen themselves die stays
  dead. Reconciliation happens before the death resolves, never after.

**Anti-cheat posture:** detect statistically (impossible parry rates,
impossible windows), never by tightening the envelope. Tightening
punishes honest high-latency players and barely inconveniences
cheaters.

## 8. Hooks into locked systems

- **Durability (L3, L32, L59–L63):** wear on hit dealt and hit blocked.
  Clean technique wears less (§3). Performance holds until roughly half
  condition, then declines (L60). Every repair costs the item some of
  its ceiling, so gear eventually dies and crafters always have work
  (L59); anyone can repair, and the smith's skill decides what it costs
  the item (L61).
- **Breakage (L62, L63) — amends L3's original "no mid-fight
  breakage".** Weapons *do* break, but only at zero condition and only
  on the next use, after the whole decline above. **Never random.** A
  maintained weapon never fails, however long it is carried; a ruined
  one fails because its owner chose to keep swinging it. Armour is
  tracked per slot and pieces come off individually, so a harness
  degrades in visible steps. Two things this buys: backup weapons
  matter (and compete with cargo under L57), and visible damage lets a
  fighter **read that an opponent is one parry from disaster** without
  any UI at all.
- **Ordinary death (L17, L32):** combat produces the ~10% durability
  hit and, in wedges, the cargo drop.
- **War (L11, L25):** identical combat, enrollment-gated, with the
  one-equipped-piece stake. **No separate PvP balance pass** — one
  ruleset, or players learn two games.
- **Arena (L6):** identical combat with stakes removed.
- **Magic:** enters as additional verbs on the same stamina economy,
  never as a parallel system. Invisible until awakening (L18). A spell
  is a commitment like any other — telegraphed, interruptible,
  stamina-priced. Detail deferred until the magic vertical.
- **The Interior (L30):** no new mechanics. Entropy (no repair) makes
  the same combat progressively more desperate, which is the point.

## 9. Prototype gate — what must be proven first

The first build. No world, no economy, no NPCs, no magic, no
persistence, no other players.

**Contents:** one room **with obstacles worth moving around**, one
player character, three enemies (one per attack shape from §6), all six
weapon families, at least two movement techniques (§3), a latency
slider injecting 0–150ms, and a stamina bar.

**It passes when:** a player who has never seen it can, inside ten
minutes, reliably parry a heavy, dodge a quick, and disengage from an
unblockable — and cannot tell from feel whether the slider is at 0ms
or 100ms. **And when a tester who chooses to move can do so
fluidly** (L56) — the mobility must be *available* and feel good. It
must not be mandatory: a tester who picks a shield and holds ground
should also be winning fights. If only one of those two players is
having a good time, the design has failed.

**If it fails, nothing else in this repository matters.** Build it
first, and be willing to hear the answer.

> **Progress against this gate (2026-09-13).** `tech.md` §6 stages the
> route to it. Steps 1 to 3 are built and playable in a browser: a
> room with obstacles, a character, a dodge with invulnerability frames
> and a punishable recovery, and a committed swing against a training
> dummy. **Nothing of the gate itself is answered yet** — there are no
> enemies, one weapon rather than six, no techniques, no latency
> slider, and above all no verdict on feel, which this section is
> explicit can only come from a controller. The stamina bar exists.

---

## Open tuning questions

- [ ] Exact stamina costs, recovery frames, and parry window widths —
      numbers come from the prototype, not from paper.
- [ ] How many techniques per weapon family, and their unlock pacing
      against skill-by-use. Now heavier than it looks: L56 makes
      techniques the main expression of progression, so this is a
      content-volume question as well as a design one — and animation
      volume is a real burden solo (`tech.md` §1).
- [ ] **Does the 5–15s time-to-kill window apply per archetype or
      overall?** A shield-and-plate mirror match is a stamina war and
      will run longer than a duellist mirror by design. **Deferred to
      the prototype** (2026-09-08) — this is a feel question, and §9
      already says feel is judged with a controller. `sim/` tests one
      fighter profile until archetypes are real enough to measure.
- [x] **Armour weight versus cargo on the encumbrance channel** →
      **L57**: they share one budget, deliberately. You cannot be a
      mule in plate.
- [x] **Can armour be changed in the field?** → **L58**: yes,
      anywhere, and the armour class decides how long you are helpless
      doing it. Remaining: the actual durations, whether donning should
      also cost stamina (currently time-only, so heavy builds are not
      punished twice), and whether partial progress should survive an
      interruption (currently it does not).
- [ ] **Mobility versus the latency contract.** Fast positional change
      is the worst case for §7's reconciliation: a dash-thrust moves
      the attacker *and* the hit origin during the disagreement window.
      Must be answered in the Stage 2 prototype (`tech.md` §6), not on
      paper.
- [ ] Whether the damage triangle is multiplicative or additive, and
      how sharply — sharp enough to matter, soft enough that the
      wrong weapon is never useless (L38's floor rule).
- [ ] Mounted combat: exists at all, or dismount-to-fight? (L28 makes
      mounts the speed system; it does not require them to be
      platforms.)
- [ ] Group combat readability — how the three attack shapes stay
      legible in a 60v60 battle (`feasibility-review.md` T2).
- [ ] Anti-cheat detection thresholds for the client-authoritative
      window.
