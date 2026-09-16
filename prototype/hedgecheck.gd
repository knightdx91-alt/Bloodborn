extends Node
## Is the Hedges a place, and does killing in it count as work?

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	TownState.reset()
	var state: TownWorldState = TownState.current()

	var h: Node3D = load("res://hedges.tscn").instantiate() as Node3D
	add_child(h)
	await get_tree().create_timer(3.0).timeout

	_ok("the Hedges knows where it is", String(h.get("place")) == "hedges"
		and String(h.get("region")) == "the Hedges west",
		"place '%s' region '%s'" % [str(h.get("place")), str(h.get("region"))])

	var boar: Fighter = h.get("enemy")
	var you: Fighter = h.get("player")
	_ok("there is a boar and a player", boar != null and you != null, "missing a body")
	if boar == null or you == null:
		print("FAILED")
		get_tree().quit()
		return

	_ok("the boar has combat state", boar.health != null and boar.stamina != null
		and boar.attack != null, "setup_beast left it inert")
	_ok("and no humanoid rig", boar.anim == null,
		"the boar has an AnimationPlayer, so it is wearing a man")
	_ok("and stands on the ground", boar.global_position.y > -0.5,
		"boar at y=%.2f" % boar.global_position.y)

	# It should look like an animal: wider and longer than it is tall.
	var low := INF
	var box := AABB()
	var first := true
	for m in boar.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in 8:
			var c: Vector3 = mi.global_transform * mi.get_aabb().get_endpoint(i)
			low = minf(low, c.y)
			if first:
				box = AABB(c, Vector3.ZERO)
				first = false
			else:
				box = box.expand(c)
	_ok("the boar is on its feet", low > boar.global_position.y - 0.25,
		"lowest mesh point is %.2f below" % (boar.global_position.y - low))
	_ok("and reads as an animal, not a man",
		box.size.z > box.size.y and box.size.y < 1.4,
		"bounds %s — taller than it is long is a person" % str(box.size))

	# Killing without a contract is allowed and is not work.
	var before_taken := state.contracts_taken.size()
	h.call("_report_kill")
	_ok("a kill with no contract is not progress",
		state.contract_progress.is_empty() and state.contracts_taken.size() == before_taken,
		"progress %s" % str(state.contract_progress))

	# Now take the cull and kill again.
	var id := "cull-the-Hedges-west"
	ContractBoardRules.take(state, id)
	var want := ContractWorkRules.required(state, id)
	for i in want:
		h.call("_report_kill")
	_ok("a kill with the paper in hand is progress",
		ContractWorkRules.done(state, id) == want,
		"done %d of %d" % [ContractWorkRules.done(state, id), want])
	_ok("and the contract can be handed in", ContractWorkRules.can_hand_in(state, id),
		"still not finishable")

	# And it survives the walk back to town.
	TownState._state = null
	var after: TownWorldState = TownState.current()
	_ok("the work survives the walk back", ContractWorkRules.can_hand_in(after, id),
		"progress lost between scenes: %s" % str(after.contract_progress))

	TownState.reset()
	print("")
	print("hedges: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
