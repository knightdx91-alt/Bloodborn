class_name BeastTactics
extends RefCounted
## A boar's fight, which is not a swordsman's fight. design/combat.md §6.
##
## A faithful mirror of sim/Marrowmark.Sim/Combat/BeastTactics.cs — see
## stamina.gd for why the duplication exists.
##
## The Hedges shipped with the boar running `EnemyTactics`, the sparring
## partner's brain: it circled at the edge of its reach and threw a heavy
## overhead, a quick to the body and a whole-body sweep, because those are
## the three shapes a man with a sword has. A boar has one. It runs at you.
##
## The shape is deliberately different rather than tuned differently. A
## swordsman's fight is a conversation at a fixed distance; a boar's is a
## series of passes — it lines up, it commits, it cannot correct mid-run,
## and the answer is to not be there. §6 makes the wind-up the telegraph;
## here the telegraph is the whole approach.

enum Intent { STALK, CHARGE, GORE, WHEEL, BUSY }

var _p: Dictionary
var _state: int
var _charging := 0.0
var _wheeling := 0.0
var _since_gore := 0.0


func _init(seed_value: int = 1) -> void:
	_p = Tuning.load_section("beastTactics")
	# Never zero: the generator has a fixed point there.
	_state = seed_value if seed_value != 0 else 0x9E3779B9
	_since_gore = _p.get("recoverBetweenGoresSeconds", 1.4)


func is_charging() -> bool:
	return _charging > 0.0


func is_wheeling() -> bool:
	return _wheeling > 0.0


func charge_remaining() -> float:
	return _charging


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	_since_gore += delta

	if _charging > 0.0:
		_charging = maxf(0.0, _charging - delta)
		# A run that goes its full distance without hitting anything ends
		# in the wheel BY ITSELF, rather than waiting for the caller to
		# say so. A punish window that exists only while every caller
		# remembers to ask for it is not a rule. A test caught this: the
		# boar reached the end of its run and simply started another,
		# having never turned round — one charge a minute instead of
		# twenty.
		if _charging <= 0.0:
			_wheeling = _p.get("wheelSeconds", 1.35)
		return

	if _wheeling > 0.0:
		_wheeling = maxf(0.0, _wheeling - delta)


## Returns { intent }. `busy` is the caller saying an attack is already
## running.
func decide(distance_to_target: float, stamina: Stamina, busy: bool) -> Dictionary:
	if busy:
		return {"intent": Intent.BUSY}

	# A run in progress outranks everything. It cannot be aborted because
	# the target moved — that is what makes it dodgeable.
	if _charging > 0.0:
		return {"intent": Intent.CHARGE}

	# Spent the run. Turn round before doing anything else, which is the
	# window a player uses to close, heal or leave.
	if _wheeling > 0.0:
		return {"intent": Intent.WHEEL}

	# On top of the target: tusks, not a run. A charge needs room to build.
	if distance_to_target <= _p.get("goreRange", 1.8):
		if _since_gore < _p.get("recoverBetweenGoresSeconds", 1.4):
			return {"intent": Intent.WHEEL}
		return {"intent": Intent.GORE}

	# Far enough to build up speed, and able to pay for it.
	if distance_to_target <= _p.get("chargeRange", 9.0) \
			and stamina.can_afford(_p.get("chargeStaminaCost", 18.0)):
		_charging = _p.get("chargeSeconds", 1.15)
		return {"intent": Intent.CHARGE}

	return {"intent": Intent.STALK}


## Call when a charge actually starts, to pay for it.
func charged(stamina: Stamina) -> void:
	stamina.spend(_p.get("chargeStaminaCost", 18.0))


## Call when a charge ends by connecting or being interrupted. A run that
## simply runs out is handled in `tick`.
func spent() -> void:
	_charging = 0.0
	_wheeling = _p.get("wheelSeconds", 1.35)


## Call when the tusks are actually thrown.
func gored() -> void:
	_since_gore = 0.0


## xorshift32, the same generator `enemy_tactics.gd` uses, for the same
## reason: identical on every platform, which the server has to agree with.
func _next_roll() -> float:
	_state ^= (_state << 13) & 0xFFFFFFFF
	_state ^= _state >> 17
	_state ^= (_state << 5) & 0xFFFFFFFF
	return float(_state & 0xFFFFFF) / float(0x1000000)
