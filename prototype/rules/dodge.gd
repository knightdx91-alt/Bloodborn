class_name Dodge
extends RefCounted
## One fighter's dodge. design/combat.md §1, tech.md §6 Stage 1 step 2.
##
## A faithful mirror of sim/Marrowmark.Sim/Combat/Dodge.cs — see stamina.gd
## for why the duplication exists. The C# is the authority and is the copy
## with tests against it.
##
## Owns the rules, not the animation: it says which phase you are in, whether
## blows land, whether you may act, and how far along the travel is. What
## direction, which clip and where the camera goes are the caller's problem.

enum Phase { READY, STARTUP, INVULNERABLE, RECOVERY }

var _p: Dictionary
var _phase: int = Phase.READY
var _elapsed := 0.0
var _distance := 0.0
var _recovery_length := 0.0

func _init() -> void:
	_p = Tuning.load_section("dodge")

func phase() -> int:
	return _phase

func elapsed() -> float:
	return _elapsed

## True while blows pass through — the only thing the damage layer asks.
func is_invulnerable() -> bool:
	return _phase == Phase.INVULNERABLE

## True when free to attack, block, parry or dodge again. False for the
## whole dodge, recovery included.
func can_act() -> bool:
	return _phase == Phase.READY

## Ground this dodge will cover, decided the moment it starts.
func distance() -> float:
	return _distance

func total_seconds() -> float:
	return _p.get("startupSeconds", 0.0) \
		+ _p.get("invulnerableSeconds", 0.0) \
		+ _p.get("recoverySeconds", 0.0)

## How far through the travel, 0..1. All of the movement happens during
## startup and the invulnerable window; recovery is spent standing still,
## which is what makes it punishable rather than merely slow.
func travel_fraction() -> float:
	if _phase == Phase.READY:
		return 0.0
	var moving: float = _p.get("startupSeconds", 0.0) + _p.get("invulnerableSeconds", 0.0)
	if moving <= 0.0:
		return 1.0
	return min(_elapsed / moving, 1.0)

## Metres travelled so far, eased so the dodge reads as a shove rather than
## a glide.
func travelled_distance() -> float:
	var inv := 1.0 - travel_fraction()
	return _distance * (1.0 - inv * inv * inv)

## Attempt a dodge, paying out of `stamina`. False without touching the bar
## if one is already running: combat.md §1 makes the dodge committed, so
## this is never a cancel.
##
## An unaffordable dodge still happens — it goes less far and recovers
## slower.
func try_start(stamina: Stamina, efficiency: float = 1.0) -> bool:
	if _phase != Phase.READY:
		return false

	var paid := stamina.spend_dodge(efficiency)

	_phase = Phase.STARTUP if _p.get("startupSeconds", 0.0) > 0.0 else Phase.INVULNERABLE
	_elapsed = 0.0
	if paid["afforded"]:
		_distance = _p.get("distance", 2.6)
		_recovery_length = _p.get("recoverySeconds", 0.35)
	else:
		_distance = _p.get("distance", 2.6) * _p.get("exhaustedDistanceFraction", 0.45)
		_recovery_length = _p.get("recoverySeconds", 0.35) \
			* _p.get("exhaustedRecoveryMultiplier", 1.6)

	return true

func tick(delta: float) -> void:
	if _phase == Phase.READY or delta <= 0.0:
		return

	_elapsed += delta

	var startup_ends: float = _p.get("startupSeconds", 0.0)
	var invulnerable_ends: float = startup_ends + _p.get("invulnerableSeconds", 0.0)
	var recovery_ends: float = invulnerable_ends + _recovery_length

	if _elapsed >= recovery_ends:
		_phase = Phase.READY
		_elapsed = 0.0
		_distance = 0.0
	elif _elapsed >= invulnerable_ends:
		_phase = Phase.RECOVERY
	elif _elapsed >= startup_ends:
		_phase = Phase.INVULNERABLE

func reset() -> void:
	_phase = Phase.READY
	_elapsed = 0.0
	_distance = 0.0
