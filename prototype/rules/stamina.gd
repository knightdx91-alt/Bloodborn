class_name Stamina
extends RefCounted
## One fighter's stamina bar — the whole combat economy in one number.
## design/combat.md §2.
##
## A faithful mirror of sim/Marrowmark.Sim/Combat/Stamina.cs. The C# is the
## authority: it is what the server will run and what the tests cover. This
## exists only because Godot's web export cannot run C#, and the web export
## is what lets the game be played on a phone.
##
## Keep the two in step. If you change a rule, change it there first.

var _p: Dictionary
var _current: float
var _regen_delay_remaining := 0.0
var _since_last_dodge := INF
var _exhausted := false
var _consecutive_dodges := 0
var _encumbrance := 0.0

func _init() -> void:
	_p = Tuning.load_section("stamina")
	_current = max_value()

func max_value() -> float:
	return _p.get("max", 100.0)

## The bar actually available after what you are carrying. L55: encumbrance
## shrinks the bar rather than slowing recovery — a loaded traveller is
## limited, not broken.
func effective_max() -> float:
	return max_value() * (1.0 - _p.get("maxEncumbrancePenalty", 0.4) * _encumbrance)

func current() -> float:
	return _current

func fraction() -> float:
	return _current / effective_max()

func is_exhausted() -> bool:
	return _exhausted

func set_encumbrance(value: float) -> void:
	_encumbrance = clamp(value, 0.0, 1.0)
	_current = min(_current, effective_max())

## Cost of the next dodge, including chain escalation.
func next_dodge_cost(efficiency: float = 1.0) -> float:
	return _p.get("dodgeCost", 20.0) \
		* (1.0 + _p.get("dodgeChainEscalation", 0.5) * _consecutive_dodges) \
		* maxf(efficiency, 0.0)

func can_afford(cost: float) -> bool:
	return cost <= _current

func tick(delta: float) -> void:
	if delta <= 0.0:
		return

	if _since_last_dodge < INF:
		_since_last_dodge += delta
		if _since_last_dodge >= _p.get("dodgeChainWindowSeconds", 1.2):
			_consecutive_dodges = 0

	if _regen_delay_remaining > 0.0:
		_regen_delay_remaining -= delta
		if _regen_delay_remaining > 0.0:
			return
		# Spend the rest of this frame regenerating rather than dropping it,
		# so behaviour does not depend on frame rate.
		delta = -_regen_delay_remaining
		_regen_delay_remaining = 0.0

	var rate: float = _p.get("regenPerSecond", 25.0)
	if _exhausted:
		rate *= _p.get("exhaustedRegenMultiplier", 0.5)

	_current = min(effective_max(), _current + rate * delta)

	if _exhausted and _current >= effective_max() * _p.get("exhaustionRecoveryFraction", 0.3):
		_exhausted = false

## Spend stamina. The action always happens — combat.md §2: at zero you are
## not stunned, you are slow. Returns { afforded, spent, caused_exhaustion }.
func spend(cost: float, efficiency: float = 1.0) -> Dictionary:
	var actual: float = cost * maxf(efficiency, 0.0)
	var afforded: bool = actual <= _current
	var spent: float = min(actual, _current)

	_current -= spent
	_regen_delay_remaining = _p.get("regenDelaySeconds", 0.6)

	var caused := false
	if not afforded and not _exhausted:
		_exhausted = true
		caused = true

	return {"afforded": afforded, "spent": spent, "caused_exhaustion": caused}

## Spend a dodge, applying and then advancing the chain escalation.
func spend_dodge(efficiency: float = 1.0) -> Dictionary:
	var result := spend(next_dodge_cost(efficiency))
	_consecutive_dodges += 1
	_since_last_dodge = 0.0
	return result

## One tick of sprinting (L55). False once the bar is empty.
func sprint(delta: float, efficiency: float = 1.0) -> bool:
	return _exert(_p.get("sprintDrainPerSecond", 8.0), delta, efficiency)

func _exert(rate_per_second: float, delta: float, efficiency: float) -> bool:
	if delta <= 0.0:
		return _current > 0.0
	_current = max(0.0, _current - rate_per_second * delta * maxf(efficiency, 0.0))
	_regen_delay_remaining = _p.get("regenDelaySeconds", 0.6)
	return _current > 0.0

func reset() -> void:
	_current = effective_max()
	_regen_delay_remaining = 0.0
	_since_last_dodge = INF
	_exhausted = false
	_consecutive_dodges = 0
