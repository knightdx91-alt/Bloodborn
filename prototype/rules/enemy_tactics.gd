class_name EnemyTactics
extends RefCounted
## One enemy's choice of what to throw and when. design/combat.md §6,
## tech.md §6 Stage 1 step 5.
##
## A faithful mirror of sim/Marrowmark.Sim/Combat/EnemyTactics.cs — see
## stamina.gd for why the duplication exists.
##
## Deliberately not clever. §6's claim is that a player learns the three
## shapes in the first hour by reading them, and that only happens if the
## enemy keeps throwing all three. An opponent that picked optimally would
## jab forever and teach nothing.

enum Intent { CLOSE, CIRCLE, ATTACK, BUSY }

var _p: Dictionary
var _state: int
var _since_last_attack := 0.0
var _quick_chain := 0

func _init(seed_value: int = 1) -> void:
	_p = Tuning.load_section("enemyTactics")
	# Never zero: the generator below has a fixed point there.
	_state = seed_value if seed_value != 0 else 0x9E3779B9
	_since_last_attack = _p.get("recoverBetweenAttacksSeconds", 1.1)

func since_last_attack() -> float:
	return _since_last_attack

func quick_chain() -> int:
	return _quick_chain

func tick(delta: float) -> void:
	if delta > 0.0:
		_since_last_attack += delta

## Returns { intent, shape }. `busy` is the caller saying an attack is
## already running — the enemy is as committed to its swings as the player
## is to theirs.
func decide(distance_to_target: float, stamina: Stamina, busy: bool) -> Dictionary:
	if busy:
		return {"intent": Intent.BUSY, "shape": Attack.Shape.QUICK}

	if distance_to_target > _p.get("engageRange", 2.2):
		return {"intent": Intent.CLOSE, "shape": Attack.Shape.QUICK}

	if _since_last_attack < _p.get("recoverBetweenAttacksSeconds", 1.1):
		return {"intent": Intent.CIRCLE, "shape": Attack.Shape.QUICK}

	# Checked here, not inside the choice, so the affordability rule below
	# cannot override it. It did once, and an exhausted enemy jabbed
	# forever and never taught the parry.
	var capped: bool = _quick_chain >= int(_p.get("maxQuickChain", 3))
	var shape := _choose_shape(distance_to_target)

	# It swings while broke and exhausts itself, as a player does
	# (combat.md §2) — but while it has a choice it does not reach for the
	# dearest option. When the chain is capped it has no choice, and
	# overextending is good: that is the punish window to wait for.
	if not capped and shape != Attack.Shape.QUICK \
			and not stamina.can_afford(_cost_of(shape)):
		shape = Attack.Shape.QUICK

	return {"intent": Intent.ATTACK, "shape": shape}

## Call when an attack is actually thrown.
func threw(shape: int) -> void:
	_since_last_attack = 0.0
	_quick_chain = _quick_chain + 1 if shape == Attack.Shape.QUICK else 0

static func section_for(shape: int) -> String:
	match shape:
		Attack.Shape.QUICK: return "enemyQuick"
		Attack.Shape.COMMITTED: return "enemyCommitted"
		_: return "enemyHeavy"

func _cost_of(shape: int) -> float:
	return Tuning.load_section(section_for(shape)).get("staminaCost", 14.0)

func _choose_shape(distance: float) -> int:
	if _quick_chain >= int(_p.get("maxQuickChain", 3)):
		return Attack.Shape.COMMITTED \
			if _next_roll() < _p.get("committedWeightAfterChain", 0.35) \
			else Attack.Shape.HEAVY

	var roll := _next_roll()
	if distance <= _p.get("pressureRange", 1.6):
		var q: float = _p.get("quickWeightClose", 0.55)
		if roll < q:
			return Attack.Shape.QUICK
		if roll < q + _p.get("heavyWeightClose", 0.30):
			return Attack.Shape.HEAVY
		return Attack.Shape.COMMITTED

	var qf: float = _p.get("quickWeightFar", 0.35)
	if roll < qf:
		return Attack.Shape.QUICK
	if roll < qf + _p.get("heavyWeightFar", 0.40):
		return Attack.Shape.HEAVY
	return Attack.Shape.COMMITTED

## xorshift32, masked to 32 bits because GDScript ints are 64-bit signed.
## Deterministic and identical to the C#, which a fight the server has to
## agree about needs.
func _next_roll() -> float:
	_state ^= (_state << 13) & 0xFFFFFFFF
	_state ^= (_state >> 17)
	_state ^= (_state << 5) & 0xFFFFFFFF
	_state &= 0xFFFFFFFF
	return float(_state & 0xFFFFFF) / float(0x1000000)
