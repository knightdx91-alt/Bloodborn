extends Node
## Is the Hedges a place, and does killing in it count as work?

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	TownState.reset()
	var state: TownWorldState = TownState.current()

	# THROUGH THORNFIELD, because there is no hedges.tscn any more.
	#
	# This used to load a scene whose whole job was to be the Hedges —
	# its own ground, its own sky, its own clock, its own copy of you.
	# The wood is a region inside the one world now, so the only honest
	# way to ask it anything is to walk into the world and find it.
	var town: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(town)
	await get_tree().create_timer(3.0).timeout

	var h := town.find_child("HedgeWood", true, false) as HedgeWood
	_ok("the Hedges is a place in the world", h != null,
		"no HedgeWood under Thornfield")
	if h == null:
		print("FAILED")
		get_tree().quit()
		return

	_ok("and it knows which wood it is", h.region_name() == "the Hedges west",
		"region '%s'" % h.region_name())

	var boar: Fighter = h.boar
	var you: Fighter = null
	for n in town.get_children():
		if n is TownWalker: you = n as Fighter
	_ok("there is a boar and a player", boar != null and you != null, "missing a body")
	if boar == null or you == null:
		print("FAILED")
		get_tree().quit()
		return

	_ok("the boar has combat state", boar.health != null and boar.stamina != null
		and boar.attack != null, "setup_beast left it inert")
	# The real question is whose SKELETON it is wearing, not whether it
	# is animated. "No AnimationPlayer" was a fair proxy while the boar
	# was six boxes; the moment a real one arrived with its own 20-bone
	# rig and four clips, that proxy inverted and failed the thing it was
	# meant to protect.
	var bones := -1
	for n in boar.find_children("*", "Skeleton3D", true, false):
		bones = (n as Skeleton3D).get_bone_count()
	_ok("the boar wears its own rig, not a man's", bones > 0 and bones != 65,
		"skeleton has %d bones; 65 is the Mixamo humanoid" % bones)
	_ok("and it is animated", boar.anim != null
		and boar.anim.has_animation("idle") and boar.anim.has_animation("beast_attack"),
		"missing idle or attack")
	_ok("and has no clips it cannot use",
		boar.anim != null and not boar.anim.has_animation("roll"),
		"a boar should not have a human roll")
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
	h.record_kill()
	_ok("a kill with no contract is not progress",
		state.contract_progress.is_empty() and state.contracts_taken.size() == before_taken,
		"progress %s" % str(state.contract_progress))

	# Now take the cull and kill again.
	var id := "cull-the-Hedges-west"
	ContractBoardRules.take(state, id)
	var want := ContractWorkRules.required(state, id)
	for i in want:
		h.record_kill()
	_ok("a kill with the paper in hand is progress",
		ContractWorkRules.done(state, id) == want,
		"done %d of %d" % [ContractWorkRules.done(state, id), want])
	_ok("and the contract can be handed in", ContractWorkRules.can_hand_in(state, id),
		"still not finishable")

	# And it survives being dropped and reloaded.
	#
	# This used to be called "the walk back to town" and it used to mean
	# a scene change, because the Hedges was a different scene. There is
	# no scene change to survive any more — you walk. What is still
	# worth asking, and is what this always actually tested, is whether
	# the work round-trips through the SAVE: drop the live state, read
	# it back off disk, and see if the cull is still there.
	TownState._state = null
	var after: TownWorldState = TownState.current()
	_ok("the work survives a save and reload", ContractWorkRules.can_hand_in(after, id),
		"progress lost through the save: %s" % str(after.contract_progress))

	# --- the hand-in ---
	#
	# In the SAME town, for the same reason. Loading town.tscn a second
	# time here would stand up a whole second copy of the world — the
	# exact thing this file's own subject is about removing.
	print("--- handing the paper in ---")
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
