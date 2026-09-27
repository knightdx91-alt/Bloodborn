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

	# Find a hamlet to look at, so one of the shots is of the thing
	# that is hardest to get right.
	var t := gen.terrain
	var hamlet := Vector3.ZERO
	for cx in range(3, 18):
		for cz in range(3, 18):
			var found := WgSettlement.site(t, t.seed_value, cx, cz)
			if found.is_empty():
				continue
			var b := WgSettlement.build(t, t.seed_value, found)
			if b.houses >= 4:
				hamlet = b.centre
				print("looking at %s, %d houses, at %.0f,%.0f"
					% [b.name, b.houses, hamlet.x, hamlet.z])
				break
		if hamlet != Vector3.ZERO:
			break

	# --- a hamlet, from a man's height ---
	if hamlet != Vector3.ZERO:
		var hc := WorldGen.chunk_of(hamlet)
		gen.build_block(hc, 2)
		await _settle()
		cam.position = hamlet + Vector3(34.0, 9.0, 34.0)
		cam.look_at(hamlet + Vector3(0, 2, 0), Vector3.UP)
		await _shot("hamlet")

		cam.position = hamlet + Vector3(9.0, 2.2, 16.0)
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

		cam.position = at + Vector3(0.0, 2.0, 40.0)
		cam.look_at(at + Vector3(0, 3.0, 0), Vector3.UP)
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
