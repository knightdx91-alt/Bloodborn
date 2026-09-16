extends Node
## Does the boar fight like a boar?
##
## The Hedges shipped with the boar running `EnemyTactics` — the sparring
## partner's brain. It circled at the edge of its reach and threw a heavy
## overhead, a quick to the body and a whole-body sweep, because those are
## the shapes a man with a sword has. Nothing here passes against that,
## which is the point: these are the differences, not the similarities.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	# --- The rule, on its own ---------------------------------------------
	var t := BeastTactics.new(20260916)
	var bar := Stamina.new()

	_ok("far off, it stalks rather than charging",
		t.decide(40.0, bar, false)["intent"] == BeastTactics.Intent.STALK,
		"it committed to a run from across the field")
	_ok("at charging range, it charges",
		t.decide(6.0, bar, false)["intent"] == BeastTactics.Intent.CHARGE,
		"it did not commit with the ground to do it in")

	# THE difference from a swordsman. Once it commits it cannot re-aim,
	# which is the only reason stepping aside beats it.
	var steered := false
	for i in 20:
		t.tick(1.0 / 30.0)
		if t.decide(1.0, bar, false)["intent"] != BeastTactics.Intent.CHARGE:
			steered = true
	_ok("and a committed run cannot be steered onto a target that moved",
		not steered,
		"the player side-stepped and it turned with them — that is a homing "
		+ "missile, and the dodge stops meaning anything")

	# A spent run is the punish window, and it arrives without being asked.
	var t2 := BeastTactics.new(1)
	t2.decide(6.0, bar, false)
	for i in 60:
		t2.tick(1.0 / 30.0)
	_ok("a run that goes its distance ends in the wheel by itself",
		t2.is_wheeling(),
		"the caller has to ask for the punish window, so it is not a rule")

	var t3 := BeastTactics.new(2)
	_ok("on top of you it gores instead, because a charge needs room",
		t3.decide(1.0, bar, false)["intent"] == BeastTactics.Intent.GORE,
		"it tried to run from knife range")

	var flat := Stamina.new()
	flat.spend(flat.current())
	_ok("an exhausted boar stops charging",
		BeastTactics.new(3).decide(6.0, flat, false)["intent"]
			== BeastTactics.Intent.STALK,
		"it charged on an empty bar — the state change a player can SEE "
		+ "is gone")

	# --- And in the Hedges ------------------------------------------------
	var h: Node3D = load("res://hedges.tscn").instantiate() as Node3D
	add_child(h)
	await get_tree().create_timer(1.5).timeout

	var boar: Fighter = h.get("enemy")
	var you: Fighter = h.get("player")
	_ok("the Hedges runs the beast brain, not the swordsman's",
		h.get("beast") != null, "still on EnemyTactics")
	_ok("and there is a boar and a player", boar != null and you != null,
		"missing a body")

	if boar != null and you != null:
		# Stand well back and watch it come. The Hedges spawns the two of
		# them 1.7m apart, which is inside gore range — a check that
		# measured from there would only ever watch it use its tusks and
		# would conclude, wrongly, that it never charges.
		you.global_position = boar.global_position + Vector3(8.0, 0, 0)
		for i in 10:
			await get_tree().physics_frame

		var start: Vector3 = boar.global_position
		var gap_before: float = boar.global_position.distance_to(you.global_position)
		var closest := gap_before
		var fastest := 0.0
		var was: Vector3 = boar.global_position
		for i in 300:
			await get_tree().physics_frame
			# Hold the player still: this measures the BOAR.
			you.velocity = Vector3.ZERO
			var moved: float = boar.global_position.distance_to(was) * 60.0
			fastest = maxf(fastest, moved)
			was = boar.global_position
			closest = minf(closest,
				boar.global_position.distance_to(you.global_position))
		print("      it closed from %.1fm to %.1fm, peaking at %.1f m/s"
			% [gap_before, closest, fastest])
		_ok("it comes at you", closest < gap_before - 1.0,
			"%.1fm to %.1fm — it stayed where it was" % [gap_before, closest])
		_ok("and a run is faster than a walk", fastest > 3.0,
			"peaked at %.1f m/s, which is strolling" % fastest)
		_ok("but it does move under its own steam",
			boar.global_position.distance_to(start) > 1.0,
			"it never left home")

	print("")
	print("boar: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
