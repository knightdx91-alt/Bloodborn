extends Node
## Does the town keep hours?

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	TownState.reset()
	# --- the rule, mirrored ---
	print("--- the rule ---")
	var smith := {"postings": [
		{"place": "forge", "from": 6.0, "to": 19.0},
		{"place": "inn", "from": 19.0, "to": 22.0}], "fallback": "home"}
	var keeper := {"postings": [{"place": "inn", "from": 16.0, "to": 2.0}],
		"fallback": "home"}
	_ok("the smith is at his forge by day",
		RoutineRules.place_for(smith, 9.0) == "forge", "got %s" % RoutineRules.place_for(smith, 9.0))
	_ok("and in the inn in the evening",
		RoutineRules.place_for(smith, 20.0) == "inn", "got %s" % RoutineRules.place_for(smith, 20.0))
	_ok("and home when nothing covers the hour",
		RoutineRules.place_for(smith, 3.0) == "home", "got %s" % RoutineRules.place_for(smith, 3.0))
	_ok("a posting that wraps midnight covers both sides",
		RoutineRules.place_for(keeper, 23.0) == "inn"
			and RoutineRules.place_for(keeper, 0.5) == "inn"
			and RoutineRules.place_for(keeper, 3.0) == "home",
		"23:00=%s 00:30=%s 03:00=%s" % [RoutineRules.place_for(keeper, 23.0),
			RoutineRules.place_for(keeper, 0.5), RoutineRules.place_for(keeper, 3.0)])
	_ok("an hour past the dial wraps rather than falling through",
		RoutineRules.place_for(keeper, 24.5) == "inn", "got %s" % RoutineRules.place_for(keeper, 24.5))
	_ok("the town wakes and sleeps",
		not RoutineRules.waking(3.0) and RoutineRules.waking(9.0)
			and not RoutineRules.waking(23.0), "waking() disagrees")

	# --- the town, actually moving ---
	print("--- the town ---")
	var t: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(t)
	await get_tree().create_timer(2.5).timeout

	var clock: WorldClock = TownState.clock()
	_ok("the town registered its clock", clock != null, "TownState has no clock")
	if clock == null:
		print("FAILED")
		get_tree().quit()
		return

	var folk: Array = []
	for n in t.get_node("Population").get_children():
		if n is TownNPC and not (n as TownNPC).routine.is_empty():
			folk.append(n)
	_ok("people have routines", folk.size() >= 5,
		"only %d of the roster keep hours" % folk.size())

	# Noon: put the clock there and let them walk.
	clock.set_fraction(12.0 / 24.0)
	var before: Dictionary = {}
	for n in folk:
		before[(n as TownNPC).npc_id] = (n as Node3D).global_position
	await get_tree().create_timer(6.0).timeout
	var midday: Dictionary = {}
	var moved_at_noon := 0
	for n in folk:
		var id := (n as TownNPC).npc_id
		midday[id] = (n as Node3D).global_position
		if (midday[id] as Vector3).distance_to(before[id]) > 0.5:
			moved_at_noon += 1
	_ok("people walk to their daytime posts", moved_at_noon > 0,
		"nobody moved in six seconds of noon")

	# Now dusk. The inn should gain people who were not in it at noon.
	var inn: Vector3 = Places.ANCHORS["inn"]
	var at_inn_noon := 0
	for n in folk:
		if (midday[(n as TownNPC).npc_id] as Vector3).distance_to(inn) < 6.0:
			at_inn_noon += 1
	clock.set_fraction(20.5 / 24.0)
	await get_tree().create_timer(20.0).timeout
	var at_inn_dusk := 0
	for n in folk:
		if (n as Node3D).global_position.distance_to(inn) < 6.0:
			at_inn_dusk += 1
	_ok("the inn fills at dusk", at_inn_dusk > at_inn_noon,
		"%d at the inn at noon, %d at dusk" % [at_inn_noon, at_inn_dusk])
	print("      %d at the inn at noon, %d at dusk" % [at_inn_noon, at_inn_dusk])

	# And nobody is standing inside anybody else.
	var stacked := 0
	for a in folk:
		for b in folk:
			if a == b:
				continue
			if (a as Node3D).global_position.distance_to((b as Node3D).global_position) < 0.5:
				stacked += 1
	_ok("and they are not standing inside each other", stacked == 0,
		"%d overlapping pairs — the fan-out is not working" % stacked)

	TownState.reset()
	print("")
	print("hours: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
