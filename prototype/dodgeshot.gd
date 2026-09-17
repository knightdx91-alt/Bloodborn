extends Node
## What does a standing backstep actually look like?
##
## Asked for from play: *"if you hit it while standing still, you roll
## backwards."* The rule is now in `Fighter.try_dodge` and two checks
## prove the body ends up behind where it started. Neither of them can
## say whether it READS as a backstep.
##
## There is one roll clip, and `try_dodge` turns the body to face the
## direction of the roll so it does not roll sideways. A backward dodge
## therefore spins the fighter round and rolls away — which may look like
## a retreat, or may look like turning tail. That is a judgement to make
## from the frame, so here are the frames.

const OUT := "/tmp/dodge"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	get_window().size = Vector2i(760, 560)
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

	var eye := Camera3D.new()
	add_child(eye)
	eye.fov = 46.0

	await _film(walker, eye, "back", Vector3.ZERO)
	await _film(walker, eye, "fwd", Vector3(0.0, 0.0, -1.0))

	TownState.reset()
	get_tree().quit()


## One dodge, photographed four times across its length, from a camera
## that does not move — so the frames can be read side by side.
func _film(walker: TownWalker, eye: Camera3D, tag: String,
		heading: Vector3) -> void:
	walker.revive()
	walker.global_position = Vector3(0.0, 1.0, -30.0)
	walker.velocity = Vector3.ZERO
	walker.rotation = Vector3.ZERO
	for f in 20:
		await get_tree().physics_frame

	# Side on, so travel reads across the frame rather than into it.
	eye.global_position = walker.global_position + Vector3(8.0, 2.2, 0.0)
	eye.look_at(walker.global_position + Vector3(0.0, 1.0, 0.0))
	eye.current = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(
		"%s/%s_0_before.png" % [OUT, tag])

	var from: Vector3 = walker.global_position
	walker.try_dodge(heading)
	var shot := 1
	for f in 45:
		await get_tree().physics_frame
		if f == 8 or f == 18 or f == 32:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(
				"%s/%s_%d.png" % [OUT, tag, shot])
			shot += 1
	var went: Vector3 = walker.global_position - from
	went.y = 0.0
	print("%s: travelled %s, ended facing %s"
		% [tag, str(went.round()), str((-walker.global_transform.basis.z).round())])
