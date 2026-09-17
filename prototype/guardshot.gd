extends Node
## What does a held guard look like?
##
## Reported from play: *"the guard button does nothing at all."* The
## cause was the multitouch bug in `ui.gd` and its two callers, and the
## checks now prove the guard goes up. They do not prove you can SEE it,
## and there is still no guard-pose clip — the brace is the heavy swing's
## own wind-up, held at a frozen frame. That is the most load-bearing
## single clip in `assets/SPEC-attack-clips.md`, so it is worth knowing
## what is standing in for it.

const OUT := "/tmp/guard"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	get_window().size = Vector2i(900, 700)
	TownState.reset()
	var town: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(town)
	await get_tree().create_timer(3.0).timeout

	var walker: TownWalker = null
	for n in town.get_children():
		if n is TownWalker: walker = n as TownWalker
	if walker == null:
		print("no walker")
		get_tree().quit()
		return

	walker.global_position = Vector3(0.0, 1.0, -30.0)
	walker.velocity = Vector3.ZERO
	var eye := Camera3D.new()
	add_child(eye)
	eye.fov = 42.0
	# Three-quarters on, which is how you see yourself over the shoulder.
	eye.global_position = walker.global_position + Vector3(2.6, 1.7, 3.2)
	eye.look_at(walker.global_position + Vector3(0.0, 0.9, 0.0))
	eye.current = true

	for f in 30:
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/a_idle.png" % OUT)

	walker.try_parry()
	for f in 20:
		await get_tree().physics_frame
	print("guard held=%s  parry phase=%d  guarding=%s"
		% [str(walker.get("_guard_held")), walker.parry.phase(),
			str(walker.parry.is_guarding())])
	var ap: AnimationPlayer = walker.anim
	print("anim=%s clip='%s' at=%.2f speed=%.2f has_heavy=%s busy=%s"
		% [str(ap != null), "" if ap == null else ap.current_animation,
			0.0 if ap == null else ap.current_animation_position,
			0.0 if ap == null else ap.speed_scale,
			"?" if ap == null else str(ap.has_animation("swing_heavy")),
			str(walker.is_busy())])
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/b_guard.png" % OUT)

	# And a good while later, because a block lasts as long as it is
	# held: if the pose decays back to idle while the guard is still up,
	# the body is lying about what it is doing, which is exactly what L65
	# forbids.
	for f in 180:
		await get_tree().physics_frame
	print("three seconds on: held=%s phase=%d guarding=%s"
		% [str(walker.get("_guard_held")), walker.parry.phase(),
			str(walker.parry.is_guarding())])
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/c_held.png" % OUT)

	TownState.reset()
	get_tree().quit()
