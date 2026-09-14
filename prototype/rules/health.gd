class_name Health
extends RefCounted
## A fighter's life. design/combat.md §4.
##
## A faithful mirror of sim/Marrowmark.Sim/Combat/Health.cs — see
## stamina.gd for why the duplication exists.
##
## Deliberately plain: combat.md §4 rules out wound systems and
## dismemberment (L20 is grounded, not simulationist), so there is nothing
## here but a number and a floor. What dying *costs* is the death ladder
## (L17/L32), which is an economy concern and lives nowhere near here.

var _max: float
var _current: float

func _init(max_health: float) -> void:
	_max = max(max_health, 0.001)
	_current = _max

func max_value() -> float:
	return _max

func current() -> float:
	return _current

func fraction() -> float:
	return _current / _max

func is_dead() -> bool:
	return _current <= 0.0

func is_alive() -> bool:
	return not is_dead()

## Apply damage. Returns what was actually taken, capped at what was left
## — overkill is not tracked, because nothing in the design rewards it.
func take(amount: float) -> float:
	var taken: float = min(max(amount, 0.0), _current)
	_current -= taken
	return taken

## Restore. Cannot raise the dead — that is what shrines are for (L32).
func heal(amount: float) -> float:
	if is_dead():
		return 0.0
	var before := _current
	_current = min(_max, _current + max(amount, 0.0))
	return _current - before

func reset() -> void:
	_current = _max
