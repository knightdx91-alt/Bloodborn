extends Node3D
## Render the generated world and look at it.
##
## No check here proves anything. gencheck can tell you the hash does
## not stripe and the seams meet; it cannot tell you the country is
## worth walking across, and this project has been wrong often enough
## about geometry judged by arithmetic that looking is a rule.
##
##     godot --path prototype --quit-after 900 genshot.tscn

const OUT := "/tmp/gen/%s.jpg"

var gen: WorldGen


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/gen")
	Look.build(self)
	# Late morning. Dawn light is pretty and tells you nothing about a
# palette — the first pass was shot at 0.30 and every wedge came out
# blue.
	var clock := WorldClock.new(0.46)
	TownState.set_clock(clock)
	Look.set_time(self, clock)
	for c in get_children():
		if c is DirectionalLight3D and (c as DirectionalLight3D).shadow_enabled:
			(c as DirectionalLight3D).directional_shadow_max_distance = 400.0

	gen = WorldGen.new()
	gen.world_seed = 20260927
	add_child(gen)
	await get_tree().process_frame

	var cam := Camera3D.new()
	cam.far = 2200.0
	add_child(cam)
	cam.current = true

	# One of EACH KIND of place, because the point of having four is
	# that they look like four.
	var t := gen.terrain
	var want := ["street", "ring", "farmstead", "ruin"]
	var found_by_kind: Dictionary = {}
	for cx in range(0, 26):
		for cz in range(0, 26):
			var found := WgSettlement.site(t, t.seed_value, cx, cz)
			if found.is_empty():
				continue
			var b := WgSettlement.build(t, t.seed_value, found)
			if want.has(b.kind) and not found_by_kind.has(b.kind):
				found_by_kind[b.kind] = b
				print("%s: %s at %.0f,%.0f (%d houses)"
					% [b.kind, b.name, b.centre.x, b.centre.z, b.houses])
		if found_by_kind.size() == want.size():
			break

	for kind in want:
		if not found_by_kind.has(kind):
			continue
		var b2 = found_by_kind[kind]
		var c2 := WorldGen.chunk_of(b2.centre)
		gen.build_block(c2, 2)
		await _settle()
		cam.position = b2.centre + Vector3(30.0, 16.0, 30.0)
		cam.look_at(b2.centre + Vector3(0, 2, 0), Vector3.UP)
		await _shot("place_" + kind)
		_clear()

	var hamlet := Vector3.ZERO
	if found_by_kind.has("street"):
		hamlet = found_by_kind["street"].centre

	# --- a hamlet, from a man's height ---
	if hamlet != Vector3.ZERO:
		var hc := WorldGen.chunk_of(hamlet)
		gen.build_block(hc, 2)
		await _settle()
		cam.position = hamlet + Vector3(34.0, 9.0, 34.0)
		cam.look_at(hamlet + Vector3(0, 2, 0), Vector3.UP)
		await _shot("hamlet")

		var street_eye := hamlet + Vector3(9.0, 0.0, 16.0)
		street_eye.y = gen.height_at(street_eye.x, street_eye.z) + 1.7
		cam.position = street_eye
		cam.look_at(hamlet + Vector3(0, 2.0, 0), Vector3.UP)
		await _shot("hamlet_street")
		_clear()

	# --- country, from the air, in three different wedges ---
	var spots := {
		"downs": 0.4,
		"ironwood": 1.6,
		"moor": 2.8,
	}
	for label in spots:
		var ang: float = spots[label]
		var r := 4200.0
		var at := Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		at.y = gen.height_at(at.x, at.z)
		var c := WorldGen.chunk_of(at)
		gen.build_block(c, 3)
		await _settle()
		cam.position = at + Vector3(0.0, 180.0, 260.0)
		cam.look_at(at, Vector3.UP)
		await _shot("air_" + label)

		# EYE HEIGHT ABOVE THE GROUND UNDER THE CAMERA, not above the
		# ground under the subject.
		#
		# This put the camera at the TARGET's height and then moved it
		# 40 m away, so wherever the land rose in between the camera
		# ended up inside a hill, looking out through the back of it.
		# That is what the black foreground was in the ironwood shot —
		# and I spent two wrong theories on the generator's normals
		# before reading the chunk data and finding not one inverted
		# normal and not one dark vertex in 4,225.
		var eye := at + Vector3(0.0, 0.0, 40.0)
		eye.y = gen.height_at(eye.x, eye.z) + 1.7
		cam.position = eye
		cam.look_at(at + Vector3(0, 2.0, 0), Vector3.UP)
		await _shot("ground_" + label)
		_clear()

	print("done")
	get_tree().quit()


func _clear() -> void:
	for at in gen.live.keys():
		(gen.live[at] as WgChunk).queue_free()
	gen.live.clear()


func _settle() -> void:
	for i in 12:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_jpg(OUT % name, 0.9)
	print("  shot %s" % name)
