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

	# --- the hand-in ---
	print("--- handing the paper in ---")
	var town: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(town)
	await get_tree().create_timer(2.5).timeout

	var clerk: TownNPC = null
	var anyone: TownNPC = null
	for n in town.get_node("Population").get_children():
		if not (n is TownNPC):
			continue
		if (n as TownNPC).pays_contracts and clerk == null:
			clerk = n as TownNPC
		elif anyone == null and (n as TownNPC).topics.size() > 0:
			anyone = n as TownNPC
	_ok("somebody keeps the board", clerk != null, "no NPC declares pays_contracts")
	if clerk == null:
		print("FAILED")
		get_tree().quit()
		return

	var live: TownWorldState = TownState.current()
	ConversationUI.open(clerk, {"state": live})
	await get_tree().process_frame
	await get_tree().process_frame
	var hand: Button = null
	for b in ConversationUI.current.find_children("*", "Button", true, false):
		if (b as Button).text.ends_with("— done"):
			hand = b as Button
	_ok("the clerk offers to settle finished work", hand != null,
		"no '— done' topic on a man holding a finished cull")

	# And nobody else does, because he is the one who keeps the paper.
	if anyone != null:
		ConversationUI.current.close()
		await get_tree().process_frame
		ConversationUI.open(anyone, {"state": live})
		await get_tree().process_frame
		var stray := false
		for b in ConversationUI.current.find_children("*", "Button", true, false):
			if (b as Button).text.ends_with("— done"):
				stray = true
		_ok("and nobody else does", not stray,
			"%s offered to settle it too" % anyone.display_name)
		ConversationUI.current.close()
		await get_tree().process_frame
		ConversationUI.open(clerk, {"state": live})
		await get_tree().process_frame
		for b in ConversationUI.current.find_children("*", "Button", true, false):
			if (b as Button).text.ends_with("— done"):
				hand = b as Button

	if hand != null:
		var coin_before: int = live.coin
		var pressure_before: int = int(live.boar_pressure["the Hedges west"])
		hand.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		_ok("handing it in pays", live.coin > coin_before,
			"coin stayed at %d" % live.coin)
		_ok("and the paper goes back", not live.contracts_taken.has(id),
			"still carrying it")
		_ok("and the boars are thinner",
			int(live.boar_pressure["the Hedges west"]) == pressure_before - 1,
			"pressure %d -> %d" % [pressure_before,
				int(live.boar_pressure["the Hedges west"])])

		# The board regenerates from the world, so the next posting for
		# that wood is a smaller job at a smaller price.
		var now_pay := 0
		for c in ContractBoardRules.generate(live):
			if String(c["id"]) == id:
				now_pay = int(c["pay"])
		_ok("and the next posting for that wood pays less",
			now_pay > 0 and now_pay < 4 + 3 * pressure_before,
			"pay is %d" % now_pay)

		var gone := true
		for b in ConversationUI.current.find_children("*", "Button", true, false):
			if (b as Button).text.ends_with("— done"):
				gone = false
		_ok("and he stops offering to settle it", gone,
			"the settled contract is still on his list")

	if ConversationUI.current != null:
		ConversationUI.current.close()

	TownState.reset()
	print("")
	print("hedges: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
