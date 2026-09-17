extends Node
## Where do the feet actually are?
##
## Reported from play: *"the player character is just a little bit off
## the ground."* The arithmetic says otherwise — the capsule is 2m tall
## and centred, so its bottom is a metre below the node, and `setup`
## hangs the body at exactly -1.0 to stand on it. That reasoning is what
## this exists to check, because it is also what let the bug ship.
##
## Measured off the SKINNED MESH's world AABB, not off the node: what
## floats is the model, and the node is where the arithmetic is right.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	TownState.reset()
	var town: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(town)
	await get_tree().create_timer(3.0).timeout

	var walker: TownWalker = null
	for n in town.get_children():
		if n is TownWalker: walker = n as TownWalker
	if walker == null:
		_ok("there is a player to stand up", false, "no TownWalker")
		_finish()
		return

	walker.global_position = Vector3(0.0, 1.0, -30.0)
	walker.velocity = Vector3.ZERO
	for f in 40:
		await get_tree().physics_frame

	# The ground under the feet, found honestly with a ray rather than
	# assumed to be y=0.
	var space := walker.get_world_3d().direct_space_state
	var down := PhysicsRayQueryParameters3D.create(
		walker.global_position + Vector3(0, 0.5, 0),
		walker.global_position + Vector3(0, -6.0, 0))
	down.exclude = [walker.get_rid()]
	var ground: float = 0.0
	var hit := space.intersect_ray(down)
	_ok("there is ground under the player", not hit.is_empty(), "the ray found nothing")
	if not hit.is_empty():
		ground = (hit["position"] as Vector3).y

	_ok("the body is resting on something", walker.is_on_floor(),
		"the character is in the air, which is a different bug")

	# Measured off the SKELETON, which is the only thing that follows the
	# pose. The first version of this check read the skinned mesh's AABB
	# and reported a gap of 0.000m while the frame showed daylight under
	# the boots — `get_aabb()` returns the REST bounds, which the
	# skeleton never touches, so it could not see this bug at any size.
	var skel := _skeleton(walker)
	_ok("the body has a skeleton to read", skel != null, "no Skeleton3D")
	if skel == null:
		_finish()
		return

	var lowest := INF
	var named := ""
	for name in ["mixamorig_LeftToeBase", "mixamorig_RightToeBase",
			"mixamorig_LeftFoot", "mixamorig_RightFoot"]:
		var b: int = skel.find_bone(name)
		if b == -1:
			continue
		var at: Vector3 = skel.global_transform \
			* skel.get_bone_global_pose(b).origin
		if at.y < lowest:
			lowest = at.y
			named = name
	_ok("and feet on it", named != "", "no toe or foot bone by Mixamo's names")
	if named == "":
		_finish()
		return

	print("      ground y=%.3f   %s y=%.3f   gap=%.3f m"
		% [ground, named, lowest, lowest - ground])
	# A toe bone sits inside the boot rather than on its sole, so a few
	# centimetres is the model, not a bug. A hand's width is the bug.
	_ok("the feet are on the ground, not above it",
		lowest - ground < 0.04,
		"the lowest foot bone is %.3fm above the ground it is standing "
			% (lowest - ground) + "on — visible in assets/evidence, and "
			+ "exactly what was reported from play")

	_finish()


func _skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for c in n.get_children():
		var hit := _skeleton(c)
		if hit != null:
			return hit
	return null


func _finish() -> void:
	TownState.reset()
	print("")
	print("feet: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
