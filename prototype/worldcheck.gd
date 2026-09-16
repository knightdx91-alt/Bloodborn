extends Node
## Is it one world?
##
## Reported from play: *"i want the whole thing to just be a big world,
## where you can go to the arena, and where ever else from the main
## town."* The Hedges was a separate SCENE behind a launcher button, and
## even after a signpost was added, taking it swapped one world for
## another. This is the difference between a road and a loading screen:
## the wood has to be standing in the same scene as the town, reachable
## by walking, with one player and one set of rules.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	TownState.reset()
	var world: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(world)
	await get_tree().create_timer(3.0).timeout

	var walker: TownWalker = null
	var wood: HedgeWood = null
	var field: Skirmish = null
	for n in world.get_children():
		if n is TownWalker: walker = n
		if n is HedgeWood: wood = n
		if n is Skirmish: field = n

	_ok("the town has a player", walker != null, "no TownWalker")
	_ok("and the Hedges is standing in the same world", wood != null,
		"no HedgeWood in town.tscn — the wood is still a separate scene")
	_ok("and there is one combat field for all of it", field != null,
		"no Skirmish")
	if walker == null or wood == null or field == null:
		_finish()
		return

	_ok("the wood is out of town, not on top of it",
		wood.global_position.distance_to(Vector3.ZERO) > 90.0,
		"it is %.0fm from the square" % wood.global_position.length())
	_ok("and close enough to be worth walking to",
		wood.global_position.distance_to(Vector3.ZERO) < 400.0,
		"%.0fm is a hike, not a journey" % wood.global_position.length())

	_ok("there is a boar in it", wood.boar != null, "the wood is empty")
	_ok("and it is in the same fight as you",
		field.fighters.has(walker) and field.fighters.has(wood.boar),
		"the player and the boar are not in one combat field")

	# THE POINT: you can walk there. No scene change, no load.
	var before: Node = walker.get_tree().current_scene
	walker.global_position = wood.global_position + Vector3(0, 1, 20)
	walker.velocity = Vector3.ZERO
	for f in 20:
		await get_tree().physics_frame
	_ok("standing in the wood does not change the scene",
		walker.get_tree().current_scene == before and is_instance_valid(walker),
		"walking into the Hedges swapped the world out from under you")
	_ok("and you are still on your feet out there",
		walker.is_on_floor(),
		"the wood has no ground under it — the body is at y=%.1f"
			% walker.global_position.y)

	# And the town is still behind you, in the same world.
	var pop := world.get_node_or_null("Population")
	_ok("Thornfield is still standing while you are in the wood",
		pop != null and pop.get_child_count() > 0,
		"the town stopped existing when you left it")

	# The boar fights you here, in the town's own scene.
	var boar_hp: float = wood.boar.health.current()
	wood.boar.global_position = walker.global_position + Vector3(0, 0, -1.1)
	for attempt in 8:
		walker.look_at(wood.boar.global_position, Vector3.UP)
		walker.try_attack()
		for f in 30:
			await get_tree().physics_frame
			wood.boar.global_position = walker.global_position \
				- walker.global_transform.basis.z * 1.1
		if wood.boar.health.current() < boar_hp:
			break
	print("      boar %.0f -> %.0f" % [boar_hp, wood.boar.health.current()])
	_ok("and a swing in the wood hurts it",
		wood.boar.health.current() < boar_hp,
		"the blade passes through — combat did not come with the region")

	_finish()


func _finish() -> void:
	TownState.reset()
	print("")
	print("world: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
