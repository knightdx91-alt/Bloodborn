extends Node
## Can you walk to the Hedges, and get home again?
##
## Reported from play: *"the hedges is a whole different place, it should
## be a place you can travel to from the main town."* It was reachable
## only from the launcher — a scene menu — so the town it belongs to had
## no road to it, and coming back dropped you in the middle of the square
## however far out you had walked. Both halves are what make somewhere
## read as a level rather than a place.
##
## Its own file, with ONE freshly built town, on purpose. These checks
## first lived at the end of `qacheck`, after a long sequence that stands
## up and tears down several towns, and there the walker reported itself
## thirty-eight metres in the air at a spot where a ray finds nothing but
## flat ground. A fresh scene says y=1.000, on the floor, stable. The
## reading was about the harness, not the game — which is the exact
## failure this project keeps paying for, so it does not get to live in
## the middle of a check about signposts.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	TownState.reset()
	var town: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(town)
	await get_tree().create_timer(2.5).timeout

	var post: Waypost = null
	var walker: TownWalker = null
	for n in town.get_children():
		if n is Waypost: post = n as Waypost
		if n is TownWalker: walker = n as TownWalker

	_ok("there is a signpost out of Thornfield", post != null,
		"no Waypost in the town, so the only way to the Hedges is the "
		+ "launcher menu")
	_ok("and somebody to walk it", walker != null, "no TownWalker")
	if post == null or walker == null:
		_finish()
		return

	_ok("it goes to the Hedges", post.destination == "res://hedges.tscn",
		"it points at '%s'" % post.destination)
	_ok("and stands on the road out, past the gate",
		post.global_position.z < -56.0 and absf(post.global_position.x) < 8.0,
		"it is at %s, which is not where the road leaves town"
			% str(post.global_position))

	# The road is not something you carry around with you.
	walker.global_position = Vector3(0.0, 1.0, 40.0)
	walker.velocity = Vector3.ZERO
	for f in 4:
		await get_tree().physics_frame
	_ok("the road is not on offer from the market square",
		not post.in_reach(walker),
		"you can leave town from anywhere in it")

	# Walk to it.
	walker.global_position = post.global_position + Vector3(-2.0, 1.0, 0.0)
	walker.velocity = Vector3.ZERO
	for f in 12:
		await get_tree().physics_frame
	print("      walker stands at %s, on the floor: %s"
		% [str(walker.global_position.round()), str(walker.is_on_floor())])
	_ok("a player can stand at the signpost",
		walker.is_on_floor() and absf(walker.global_position.y - 1.0) < 0.6,
		"the body ended at y=%.2f — the way out is not walkable ground"
			% walker.global_position.y)
	_ok("standing there offers the road", walker.get("_road") != null,
		"the signpost does not register")
	var chip: Button = walker.get("_talk_btn")
	_ok("and the chip says where it goes",
		chip != null and chip.text == post.label,
		"the chip reads '%s'" % ("nothing" if chip == null else chip.text))

	# Taking it records where you come back to, and goes.
	post.remember_way_home()
	var back: Dictionary = TownState.take_arrival()
	_ok("taking the road remembers the way home", not back.is_empty(),
		"nothing was recorded, so coming back lands at the default spawn")
	if not back.is_empty():
		_ok("and home is the gate, not the middle of the square",
			(back["at"] as Vector3).z < -40.0,
			"it would put you at %s" % str(back["at"]))

	town.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	# And the town honours it.
	TownState.set_arrival(Vector3(0.0, 1.0, -50.0), PI)
	var home: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(home)
	await get_tree().create_timer(2.5).timeout
	var arrived: TownWalker = null
	for n in home.get_children():
		if n is TownWalker: arrived = n as TownWalker
	_ok("coming back puts you where you came in",
		arrived != null and arrived.global_position.z < -40.0,
		"the walker is at %s"
			% ("nowhere" if arrived == null else str(arrived.global_position)))
	_ok("and arriving happens once", TownState.take_arrival().is_empty(),
		"the arrival survived being used, so every load lands at the gate")

	_finish()


func _finish() -> void:
	TownState.reset()
	print("")
	print("road: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
