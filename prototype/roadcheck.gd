extends Node
## Does the road out of Thornfield lead anywhere, on foot?
##
## Reported from play, twice. First: *"the hedges is a whole different
## place, it should be a place you can travel to from the main town"* —
## answered with a signpost that changed scenes, which is better than a
## menu and still a door. Then: *"i want the whole thing to just be a big
## world."*
##
## So the wood stands in the same scene now and the sign is a SIGN: it
## says what is down the road and points at it, and there is nothing to
## press because there is nothing to load. What this checks is that the
## road exists, that it is going where the sign says, and that a body can
## walk it.
##
## Its own file with ONE freshly built world, on purpose. These checks
## first sat at the end of `qacheck`, after a long sequence that stands
## up and tears down several towns, and there the walker reported itself
## thirty-eight metres in the air at a spot where a ray down finds flat
## ground. The reading was about the harness, not the game.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	TownState.reset()
	var town: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(town)
	await get_tree().create_timer(3.0).timeout

	var post: Waypost = null
	var walker: TownWalker = null
	var wood: HedgeWood = null
	for n in town.get_children():
		if n is Waypost: post = n as Waypost
		if n is TownWalker: walker = n as TownWalker
		if n is HedgeWood: wood = n as HedgeWood

	_ok("there is a signpost out of Thornfield", post != null, "no Waypost")
	_ok("and somebody to walk the road", walker != null, "no TownWalker")
	_ok("and a wood at the end of it", wood != null, "no HedgeWood")
	if post == null or walker == null or wood == null:
		_finish()
		return

	_ok("the sign is a sign, not a door", post.destination == "",
		"it still loads '%s', which would be a SECOND Hedges with its own "
			% post.destination + "boar and its own clock")
	_ok("and it names what is down the road",
		post.reads.findn("Hedges") != -1,
		"the sign reads '%s'" % post.reads)
	_ok("it stands past the gate, on the way",
		post.global_position.z < -56.0
			and post.global_position.z > wood.global_position.z
			and absf(post.global_position.x) < 8.0,
		"the sign at %s is not between the gate and the wood at %s"
			% [str(post.global_position), str(wood.global_position)])

	# The walk itself. Sampled along the road, because a road you cannot
	# stand on is scenery — and the first version of this signpost sat
	# inside the gate's own timbers and threw the body sixty-four metres
	# into the air.
	var gaps: Array[String] = []
	var z := -58.0
	while z > wood.global_position.z + 10.0:
		walker.global_position = Vector3(0.0, 1.0, z)
		walker.velocity = Vector3.ZERO
		for f in 10:
			await get_tree().physics_frame
		if not walker.is_on_floor() or absf(walker.global_position.y - 1.0) > 0.8:
			gaps.append("z=%.0f (y=%.1f)" % [z, walker.global_position.y])
		z -= 20.0
	_ok("and the whole road is walkable", gaps.is_empty(),
		"the body is not standing at: %s" % ", ".join(gaps))

	_ok("a sign offers nothing to press", walker.get("_road") == null,
		"the sign hijacks the Talk chip for a road you simply walk down")

	# The handoff itself still works, for roads that DO lead elsewhere —
	# the arena is still a scene.
	town.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	TownState.set_arrival(Vector3(0.0, 1.0, -50.0), PI)
	var home: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(home)
	await get_tree().create_timer(2.5).timeout
	var arrived: TownWalker = null
	for n in home.get_children():
		if n is TownWalker: arrived = n as TownWalker
	_ok("an arrival still places you where you came in",
		arrived != null and arrived.global_position.z < -40.0,
		"the walker is at %s"
			% ("nowhere" if arrived == null else str(arrived.global_position)))
	_ok("and arriving happens once", TownState.take_arrival().is_empty(),
		"the arrival survived being used")

	_finish()


func _finish() -> void:
	TownState.reset()
	print("")
	print("road: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
