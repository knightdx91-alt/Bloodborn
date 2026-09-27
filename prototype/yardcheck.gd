extends Node
## Is the drill yard a PLACE in the world, and not a scene any more?
##
## The question this file exists to answer is not "does the yard
## build" — it is "is there exactly one world". So it asks about the
## yard from inside Thornfield: it is reached by walking, it stands on
## the town's ground rather than its own, it runs on the town's clock,
## and the fight in it is the town's fight.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	TownState.reset()

	var town: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(town)
	await get_tree().create_timer(3.0).timeout

	var yard := town.find_child("DrillYard", true, false) as DrillYard
	_ok("the yard is in Thornfield", yard != null,
		"no DrillYard node under the town")
	if yard == null:
		_finish()
		return

	# ── one world ────────────────────────────────────────────────────
	#
	# The yard used to bring its own everything. Each of these is a
	# thing it must NOT have brought, and the reason the arena was a
	# second world rather than a second place.
	_ok("and brings no ground of its own",
		_count(yard, "StaticBody3D", "Ground") == 0,
		"the yard built a floor; the town owns the floor")
	_ok("and no sky or light of its own",
		yard.find_children("*", "DirectionalLight3D", true, false).is_empty()
			and yard.find_children("*", "WorldEnvironment", true, false).is_empty(),
		"the yard built its own sky — L89 says one world, one hour")
	_ok("and no camera of its own",
		yard.find_children("*", "Camera3D", true, false).is_empty(),
		"the yard built a camera; the walker owns the camera")

	# The clock is the sharpest one: two clocks is two afternoons.
	var clock = town.get("clock")
	_ok("and runs on the town's clock", clock != null and clock == TownState.clock(),
		"the yard or the town is keeping its own hour")

	# ── you walk there ───────────────────────────────────────────────
	var sign := town.find_child("YardRoad", true, false)
	_ok("there is a sign on the road to it", sign != null,
		"no YardRoad waypost outside the south gate")
	if sign != null:
		_ok("and the sign is a sign, not a door",
			String(sign.get("destination")) == "",
			"the sign loads scene '%s' — that is a door with a picture of "
				% str(sign.get("destination")) + "a road on it")

	# The road has to actually reach it. A road that stops short of
	# where it is going is a prop, and the walk out is the whole point.
	#
	# What this does NOT catch, stated because it was mutation-tested
	# and found not to: moving YARD_AT. The road's length is derived
	# from YARD_AT, so both ends move together and the gap stays zero.
	# The bug it DOES catch is the road being pinned to a number — it
	# was pinned to 56, the south gate, for as long as the yard was a
	# menu button, and putting that constant back fails this by 64 m.
	var gap: float = absf(yard.global_position.z - DrillYard.YARD) \
		- _road_reaches_south(town)
	_ok("and the road reaches the yard", gap <= 1.0,
		"the road stops %.1f m short of the yard's north side" % gap)

	# ── the way in ───────────────────────────────────────────────────
	#
	# Three walls, not four. The fourth was right when the only way out
	# was a menu and wrong the moment the yard had a road to it.
	var probe := yard.global_position + Vector3(0, 1.0, -DrillYard.YARD)
	_ok("and the north side is open to walk in",
		not _solid_at(probe),
		"something is standing in the gateway at %s" % str(probe))
	_ok("but the other three sides are closed",
		_solid_at(yard.global_position + Vector3(0, 1.0, DrillYard.YARD))
			and _solid_at(yard.global_position + Vector3(-DrillYard.YARD, 1.0, 0))
			and _solid_at(yard.global_position + Vector3(DrillYard.YARD, 1.0, 0)),
		"a wall is missing — you can walk out of the back of the yard")

	# ── the fight is the town's fight ────────────────────────────────
	var walker := town.find_child("TownWalker", true, false) as Fighter
	if walker == null:
		for f in town.find_children("*", "CharacterBody3D", true, false):
			if f is TownWalker:
				walker = f as Fighter
	_ok("there is a player in the world", walker != null, "no walker")

	_ok("the yard has somebody to spar with",
		yard.swordsman != null and yard.swordsman.health != null,
		"no swordsman, or he has no combat state")
	_ok("and he is a man, not a boar",
		yard.swordsman != null and yard.swordsman.anim != null
			and yard.swordsman.anim.has_animation("roll"),
		"the sparring partner is wearing the wrong rig")
	_ok("and he is enlisted in the town's one fight",
		yard.skirmish != null and yard.skirmish.fighters.has(yard.swordsman),
		"the swordsman is not in the Skirmish — nothing would notice a blade")
	_ok("and the pell is a post in it",
		yard.skirmish != null and not yard.skirmish.posts.is_empty(),
		"the dummy takes no hits")
	_ok("and it is the SAME fight the walker is in",
		walker != null and yard.skirmish != null
			and yard.skirmish.fighters.has(walker),
		"two Skirmishes — the yard has its own combat again")

	# ── he minds his own yard ────────────────────────────────────────
	#
	# The leash is what makes the yard a place you can leave. Without
	# it a sparring partner follows you into the market square, which
	# is the walled-arena bug wearing an open-world coat.
	if yard.swordsman != null and walker != null:
		var home: Vector3 = yard.swordsman.global_position
		walker.global_position = Vector3(0, 1, 0)   # the market square
		# THREE SECONDS, not forty frames.
		#
		# At forty frames this check passed with the leash DELETED, which
		# is the only reason it is written this way. EnemyTactics returns
		# CLOSE at any range past 2.2 m, so an unleashed swordsman does
		# set off for the square — he just covers 1.6 m in two thirds of
		# a second at his 2.4 m/s, and the check was asking whether he
		# had moved 2. Long enough to be sure is 180 frames: he arrives
		# 7 m out, which no rounding explains away.
		for i in 180:
			await get_tree().physics_frame
		var strayed: float = yard.swordsman.global_position.distance_to(home)
		print("      after 3s in the square, he moved %.1f m" % strayed)
		_ok("and he does not follow you into town", strayed < 2.0,
			"the swordsman walked %.1f m after you left the yard" % strayed)

	_finish()


## How far south the main road's surface actually runs.
func _road_reaches_south(town: Node3D) -> float:
	var furthest := 0.0
	for m in town.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null or not (mi.mesh is PlaneMesh):
			continue
		var size: Vector2 = (mi.mesh as PlaneMesh).size
		# The road is the long thin north-south quad, not a field.
		if size.x > 8.0 or size.y < 40.0:
			continue
		furthest = maxf(furthest, mi.global_position.z + size.y * 0.5)
	return furthest


func _solid_at(where: Vector3) -> bool:
	var space := get_viewport().world_3d.direct_space_state
	var query := PhysicsPointQueryParameters3D.new()
	query.position = where
	query.collide_with_bodies = true
	return not space.intersect_point(query, 1).is_empty()


func _count(under: Node, cls: String, named: String) -> int:
	var n := 0
	for c in under.find_children("*", cls, true, false):
		if named == "" or c.name == named:
			n += 1
	return n


func _finish() -> void:
	if _fails.is_empty():
		print("\nyard: all clear")
	else:
		print("\nyard: FAILED — %s" % ", ".join(_fails))
	get_tree().quit()
