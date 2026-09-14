class_name Parry
extends RefCounted
## One fighter's parry. design/combat.md §1, §2 and §6; tech.md §6 Stage 1
## step 6. The hardest single-player piece, and the one L39 turns on.
##
## A faithful mirror of sim/Marrowmark.Sim/Combat/Parry.cs — see stamina.gd
## for why the duplication exists.
##
## What makes it the high-skill answer is not the window — it is that
## failing costs more than not trying. A parry that merely wasted its
## stamina would be free to spam.
##
## Directional guards (L64/L65) are not here yet. `Targeting` in sim/
## already implements that resolution; wiring it up needs guard poses to
## read it off, which is §1's animation bill.

enum Phase { READY, STARTUP, OPEN, BLOCKING, RECOVERY }
enum Outcome { NOT_PARRYING, PARRIED, TOO_EARLY, TOO_LATE, UNPARRYABLE, BLOCKED }

var _p: Dictionary
var _phase: int = Phase.READY
var _elapsed := 0.0
var _recovery_length := 0.0
var _spent := false

func _init() -> void:
	_p = Tuning.load_section("parry")
	_recovery_length = _p.get("recoverySeconds", 0.55)

func phase() -> int:
	return _phase

func elapsed() -> float:
	return _elapsed

## True while blows are being turned.
func is_open() -> bool:
	return _phase == Phase.OPEN

## True while the guard is up but past its window: blows are stopped
## rather than turned, and the bar pays for it.
func is_blocking() -> bool:
	return _phase == Phase.BLOCKING

## True while the guard is up at all.
func is_guarding() -> bool:
	return _phase == Phase.STARTUP or _phase == Phase.OPEN or _phase == Phase.BLOCKING

## How much of a blocked blow still gets through. combat.md §1: blocking
## is a stamina war, never an off switch.
func blocked_fraction() -> float:
	return _p.get("blockedFraction", 0.35)

## True when free to act. False for the whole attempt.
func can_act() -> bool:
	return _phase == Phase.READY

func stagger_seconds() -> float:
	return _p.get("staggerSeconds", 0.9)

## Begin a parry, paying up front. False without touching the bar if one
## is already running — like every other commitment here, never a cancel.
func try_start(stamina: Stamina) -> bool:
	if _phase != Phase.READY:
		return false
	stamina.spend(Tuning.load_section("stamina").get("parryCost", 15.0))
	_phase = Phase.STARTUP if _p.get("startupSeconds", 0.0) > 0.0 else Phase.OPEN
	_elapsed = 0.0
	_spent = false
	_recovery_length = _p.get("recoverySeconds", 0.55)
	return true

## `holding` is the player still holding the guard up. The window passing
## with the guard still raised is what turns a parry attempt into a
## block, rather than the attempt simply expiring.
func tick(delta: float, holding: bool = false) -> void:
	if _phase == Phase.READY or delta <= 0.0:
		return

	# A block lasts as long as it is held. Nothing expires it but letting
	# go, or the bar running dry.
	if _phase == Phase.BLOCKING:
		if not holding:
			lower()
		return

	_elapsed += delta

	var startup_ends: float = _p.get("startupSeconds", 0.0)
	var open_ends: float = startup_ends + _p.get("openSeconds", 0.28)
	var recovery_ends: float = open_ends + _recovery_length

	if _elapsed >= open_ends and _phase != Phase.RECOVERY and holding and not _spent:
		_phase = Phase.BLOCKING
		return

	if _elapsed >= recovery_ends:
		_phase = Phase.READY
		_elapsed = 0.0
		_spent = false
	elif _elapsed >= open_ends:
		_phase = Phase.RECOVERY
	elif _elapsed >= startup_ends:
		_phase = Phase.OPEN

## Drop the guard. Lowering it is quick; it is raising it at the wrong
## moment that costs.
func lower() -> void:
	if not is_guarding():
		return
	_phase = Phase.RECOVERY
	_elapsed = _p.get("startupSeconds", 0.0) + _p.get("openSeconds", 0.28)
	_recovery_length = _p.get("successRecoverySeconds", 0.12)

## Take it back as though it never happened, refunding the whole cost.
## Not a game rule — it is for an input layer that cannot tell a tap from
## the beginning of a guard without starting one to find out. Refused
## once the guard has done something, so it can never undo a parry.
func cancel(stamina: Stamina) -> bool:
	if _phase != Phase.STARTUP or _spent:
		return false
	stamina.refund(Tuning.load_section("stamina").get("parryCost", 15.0))
	reset()
	return true

## A blow has arrived. Says what became of it, and refunds on success —
## combat.md §2: a successful parry refunds most of its cost, a failed one
## does not. One parry turns one blow: a guard held open through a flurry
## would beat exactly what §1 says parry loses to.
func meet(incoming: Attack, stamina: Stamina, damage: float = 0.0) -> int:
	if _phase == Phase.READY:
		return Outcome.NOT_PARRYING

	# Checked before anything else the guard might do with it. §6 calls
	# the committed attack unblockable, not merely unparryable — a guard
	# is the wrong answer to it however it is held.
	if not incoming.can_be_parried():
		return Outcome.UNPARRYABLE

	match _phase:
		Phase.STARTUP: return Outcome.TOO_EARLY
		Phase.RECOVERY: return Outcome.TOO_LATE
		Phase.BLOCKING: return _block(stamina, damage)

	if _spent:
		return Outcome.TOO_LATE

	_spent = true
	var s := Tuning.load_section("stamina")
	stamina.refund(s.get("parryCost", 15.0) * s.get("parryRefundFraction", 0.8))

	# Drop straight out of the window into the short recovery: the reward
	# is the punish, and it is only a reward if you are free to take it.
	_phase = Phase.RECOVERY
	_elapsed = _p.get("startupSeconds", 0.0) + _p.get("openSeconds", 0.28)
	_recovery_length = _p.get("successRecoverySeconds", 0.12)
	return Outcome.PARRIED

## Stop a blow rather than turn it. Costs the bar in proportion to what
## it stopped, and emptying the bar breaks the guard — §2's punishment
## for turtling.
func _block(stamina: Stamina, damage: float) -> int:
	var paid := stamina.spend(damage * _p.get("blockStaminaPerDamage", 0.55))
	if not paid["afforded"]:
		_phase = Phase.RECOVERY
		_elapsed = _p.get("startupSeconds", 0.0) + _p.get("openSeconds", 0.28)
		_recovery_length = _p.get("brokenGuardRecoverySeconds", 1.2)
	return Outcome.BLOCKED

func reset() -> void:
	_phase = Phase.READY
	_elapsed = 0.0
	_spent = false
	_recovery_length = _p.get("recoverySeconds", 0.55)
