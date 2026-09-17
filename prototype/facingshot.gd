extends Node
## Photograph which way people are pointing, because the bug was visible
## and every check passed.
##
## Reported from play: *"the walking controls are inverted, and the npcs
## are walking backwards."* The fixes are in `town_player.gd` and
## `npc/npc.gd` and both are guarded by checks that fail when the bug is
## put back. This is the other half of the evidence: a frame.
##
## Two shots, both from the same place. A townsperson takes a step with
## the camera set square to their travel, and the player walks forward
## with the camera behind them. If a face is pointing at the camera in
## the first, or the player's back is not to it in the second, the frame
## says so and no amount of arithmetic argues.

const OUT := "/tmp/facing"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	get_window().size = Vector2i(1100, 620)
	TownState.reset()
	var town: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(town)
	await get_tree().create_timer(3.0).timeout

	var walker: TownWalker = null
	var folk: TownNPC = null
	for n in town.get_children():
		if n is TownWalker: walker = n as TownWalker
	for n in town.get_children():
		for m in n.get_children():
			if m is TownNPC and (m as TownNPC).stays and folk == null:
				folk = m as TownNPC

	var eye := Camera3D.new()
	add_child(eye)
	eye.current = true
	eye.fov = 50.0

	# --- one: a townsperson walking ---------------------------------------
	#
	# Shove them twelve metres off their posting so `_keep_hours` has
	# somewhere to walk, let their own code take thirty small steps, then
	# stand the camera square to whichever way they actually travelled.
	# Walking away from the lens is what right looks like; a face is what
	# wrong looks like, and the frame does not care what the maths says.
	if folk != null:
		var at: Vector3 = folk.global_position + Vector3(12.0, 0.0, 6.0)
		folk.global_position = at
		for f in 30:
			folk.call("_keep_hours", 0.05)
			await get_tree().process_frame
		var went: Vector3 = folk.global_position - at
		went.y = 0.0
		var face: Vector3 = -folk.global_transform.basis.z
		if went.length() < 0.05:
			print("the townsperson did not move — no frame worth taking")
		else:
			var dir: Vector3 = went.normalized()
			print("townsperson travelled %s, facing %s, dot %.2f"
				% [str(dir.round()), str(face.round()), face.dot(dir)])
			# Off their left shoulder, square to the walk.
			var side := Vector3(-dir.z, 0.0, dir.x)
			eye.global_position = (folk.global_position + side * 5.5
				+ Vector3(0.0, 2.2, 0.0) - dir * 1.5)
			eye.look_at(folk.global_position + Vector3(0.0, 1.0, 0.0))
			eye.current = true
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(
				"%s/npc_walking.png" % OUT)
	else:
		print("no townsperson found")

	# --- two: the player pressing forward ---------------------------------
	#
	# Camera behind, looking up the road, and hold W. Forward should
	# carry them AWAY from the lens.
	if walker != null:
		walker.global_position = Vector3(0.0, 1.0, -62.0)
		walker.velocity = Vector3.ZERO
		walker.set("_cam_yaw", 0.0)
		for f in 8:
			await get_tree().physics_frame
		var from: Vector3 = walker.global_position
		eye.global_position = from + Vector3(0.0, 2.6, 7.0)
		eye.look_at(from + Vector3(0.0, 1.0, -6.0))
		_hold(KEY_W, true)
		for f in 40:
			await get_tree().physics_frame
		_hold(KEY_W, false)
		eye.global_position = from + Vector3(0.0, 2.6, 7.0)
		eye.look_at(from + Vector3(0.0, 1.0, -6.0))
		eye.current = true
		var moved: Vector3 = walker.global_position - from
		moved.y = 0.0
		print("player held forward and moved %s (camera at +Z behind them)"
			% str(moved.round()))
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(
			"%s/player_forward.png" % OUT)
	else:
		print("no walker found")

	TownState.reset()
	get_tree().quit()


func _hold(key: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = key
	e.physical_keycode = key
	e.pressed = down
	Input.parse_input_event(e)
