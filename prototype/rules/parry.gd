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

enum Phase { READY, STARTUP, OPEN, RECOVERY }
enum Outcome { NOT_PARRYING, PARRIED, TOO_EARLY, TOO_LATE, UNPARRYABLE }

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

func tick(delta: float) -> void:
	if _phase == Phase.READY or delta <= 0.0:
		return

	_elapsed += delta

	var startup_ends: float = _p.get("startupSeconds", 0.0)
	var open_ends: float = startup_ends + _p.get("openSeconds", 0.28)
	var recovery_ends: float = open_ends + _recovery_length

	if _elapsed >= recovery_ends:
		_phase = Phase.READY
		_elapsed = 0.0
		_spent = false
	elif _elapsed >= open_ends:
		_phase = Phase.RECOVERY
	elif _elapsed >= startup_ends:
		_phase = Phase.OPEN

## A blow has arrived. Says what became of it, and refunds on success —
## combat.md §2: a successful parry refunds most of its cost, a failed one
## does not. One parry turns one blow: a guard held open through a flurry
## would beat exactly what §1 says parry loses to.
func meet(incoming: Attack, stamina: Stamina) -> int:
	match _phase:
		Phase.READY: return Outcome.NOT_PARRYING
		Phase.STARTUP: return Outcome.TOO_EARLY
		Phase.RECOVERY: return Outcome.TOO_LATE

	if _spent:
		return Outcome.TOO_LATE
	if not incoming.can_be_parried():
		return Outcome.UNPARRYABLE

	_spent = true
	var s := Tuning.load_section("stamina")
	stamina.refund(s.get("parryCost", 15.0) * s.get("parryRefundFraction", 0.8))

	# Drop straight out of the window into the short recovery: the reward
	# is the punish, and it is only a reward if you are free to take it.
	_phase = Phase.RECOVERY
	_elapsed = _p.get("startupSeconds", 0.0) + _p.get("openSeconds", 0.28)
	_recovery_length = _p.get("successRecoverySeconds", 0.12)
	return Outcome.PARRIED

func reset() -> void:
	_phase = Phase.READY
	_elapsed = 0.0
	_spent = false
	_recovery_length = _p.get("recoverySeconds", 0.55)
