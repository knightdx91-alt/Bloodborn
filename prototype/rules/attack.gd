class_name Attack
extends RefCounted
## One fighter's swing. design/combat.md §1 and §6, tech.md §6 Stage 1 step 3.
##
## A faithful mirror of sim/Marrowmark.Sim/Combat/Attack.cs — see stamina.gd
## for why the duplication exists. The C# is the authority and is the copy
## with tests against it.
##
## Owns the rules, not the geometry: it says which phase the swing is in,
## whether the blade is live, and whether this swing has already landed.
## Where the target is, the caller works out and asks `reaches()`.

enum Phase { READY, WINDUP, ACTIVE, RECOVERY }

var _p: Dictionary
var _phase: int = Phase.READY
var _elapsed := 0.0
var _recovery_length := 0.0
var _hit_spent := false

func _init() -> void:
	_p = Tuning.load_section("attack")

func phase() -> int:
	return _phase

func elapsed() -> float:
	return _elapsed

## True while the blade is dangerous.
func is_active() -> bool:
	return _phase == Phase.ACTIVE

## True when free to move, swing again, dodge or parry.
func can_act() -> bool:
	return _phase == Phase.READY

func total_seconds() -> float:
	return _p.get("windupSeconds", 0.0) \
		+ _p.get("activeSeconds", 0.0) \
		+ _p.get("recoverySeconds", 0.0)

## How far through the wind-up, 0..1. The telegraph, and the animation
## layer's cue for how far the blade is drawn back.
func windup_fraction() -> float:
	if _phase == Phase.READY:
		return 0.0
	var windup: float = _p.get("windupSeconds", 0.0)
	if windup <= 0.0:
		return 1.0
	return min(_elapsed / windup, 1.0)

## Begin a swing, paying up front. False without touching the bar if one
## is already running — the swing is committed, so this is never a cancel.
## Paid for whether or not it connects: combat.md §2, a whiffed swing is
## paid for.
func try_start(stamina: Stamina, efficiency: float = 1.0) -> bool:
	if _phase != Phase.READY:
		return false

	var paid := stamina.spend(_p.get("staminaCost", 14.0), efficiency)

	_phase = Phase.WINDUP if _p.get("windupSeconds", 0.0) > 0.0 else Phase.ACTIVE
	_elapsed = 0.0
	_hit_spent = false
	_recovery_length = _p.get("recoverySeconds", 0.45)
	if not paid["afforded"]:
		_recovery_length *= _p.get("exhaustedRecoveryMultiplier", 1.5)

	return true

func tick(delta: float) -> void:
	if _phase == Phase.READY or delta <= 0.0:
		return

	_elapsed += delta

	var windup_ends: float = _p.get("windupSeconds", 0.0)
	var active_ends: float = windup_ends + _p.get("activeSeconds", 0.0)
	var recovery_ends: float = active_ends + _recovery_length

	if _elapsed >= recovery_ends:
		_phase = Phase.READY
		_elapsed = 0.0
		_hit_spent = false
	elif _elapsed >= active_ends:
		_phase = Phase.RECOVERY
	elif _elapsed >= windup_ends:
		_phase = Phase.ACTIVE

## Claim this swing's one hit. True at most once per swing, and only while
## the blade is live. One swing, one blow: an active window spanning
## several frames would otherwise land a hit on every one of them.
func try_consume_hit() -> bool:
	if not is_active() or _hit_spent:
		return false
	_hit_spent = true
	return true

## Whether a target `distance` metres away and `angle_degrees` off the
## attacker's facing is within this swing.
func reaches(distance: float, angle_degrees: float) -> bool:
	return distance <= _p.get("reach", 2.1) \
		and absf(angle_degrees) <= _p.get("arcDegrees", 110.0) * 0.5

func reach() -> float:
	return _p.get("reach", 2.1)

func reset() -> void:
	_phase = Phase.READY
	_elapsed = 0.0
	_hit_spent = false
