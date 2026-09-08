# Marrowmark — Combat

The specification behind L2 (BotW-style real-time action) and L39
(favor-the-defender netcode). Everything here exists to be built from:
if a line cannot be turned into a number or an animation, it does not
belong in this file.

**The gate this document serves (L39):** parry and dodge must feel
BotW-good at real MMO latency before anything else ships. That is the
first thing built and the first thing that can kill the project.

---

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

> ⚠️ **The inclusion/exclusion lists above are an interpretation**
> (2026-09-08) of the decision to extend stamina past combat. The
> principle is locked (L55); the boundaries are a judgement call and
> should be confirmed or corrected. The likeliest thing to revisit is
> whether encumbrance reduces the maximum bar (current model) or
> instead raises the cost of every action.

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

- **Durability (L3, L32):** wear on hit dealt and hit blocked; never
  mid-fight breakage. Clean technique wears less (§3).
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

**Contents:** one room, one player character, three enemies (one per
attack shape from §6), all six weapon families, a latency slider
injecting 0–150ms, and a stamina bar.

**It passes when:** a player who has never seen it can, inside ten
minutes, reliably parry a heavy, dodge a quick, and disengage from an
unblockable — and cannot tell from feel whether the slider is at 0ms
or 100ms.

**If it fails, nothing else in this repository matters.** Build it
first, and be willing to hear the answer.

---

## Open tuning questions

- [ ] Exact stamina costs, recovery frames, and parry window widths —
      numbers come from the prototype, not from paper.
- [ ] How many techniques per weapon family, and their unlock pacing
      against skill-by-use.
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
