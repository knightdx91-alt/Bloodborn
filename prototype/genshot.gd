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

	# A town site: levelled ground waiting for a town, in the steepest
	# country there is. Hammarsted's wedge has 46 m of relief, so if a
	# platform reads anywhere it reads here.
	for w2 in WgTerrain.WEDGES:
		if t.biomes()[w2].town != "Hammarsted":
			continue
		var site := t.town_site(w2)
		gen.build_block(WorldGen.chunk_of(site), 4)
		await _settle()
		cam.position = site + Vector3(0.0, 230.0, 330.0)
		cam.look_at(site, Vector3.UP)
		await _shot("site_Hammarsted")
		_clear()

	# A road, from above and from on it.
	var segs := WgRoads.near(t, t.seed_value, 0.0, 0.0, 5000.0, 5000.0)
	if not segs.is_empty():
		var seg: Dictionary = segs[0]
		var mid: Vector2 = (seg["a"] as Vector2).lerp(seg["b"] as Vector2, 0.5)
		var at3 := Vector3(mid.x, gen.height_at(mid.x, mid.y), mid.y)
		gen.build_block(WorldGen.chunk_of(at3), 2)
		await _settle()
		cam.position = at3 + Vector3(0.0, 95.0, 95.0)
		cam.look_at(at3, Vector3.UP)
		await _shot("road_air")
		var along: Vector2 = ((seg["b"] as Vector2) - (seg["a"] as Vector2)).normalized()
		var eye3 := Vector3(mid.x - along.x * 26.0, 0.0, mid.y - along.y * 26.0)
		eye3.y = gen.height_at(eye3.x, eye3.z) + 1.7
		cam.position = eye3
		cam.look_at(at3 + Vector3(0, 1.5, 0), Vector3.UP)
		await _shot("road_ground")
		_clear()

	# WATER. From the air, so the valley reads, and from the bank, so
	# you can see whether it is a river or a blue stripe.
	var found_river := PackedVector2Array()
	for cx in range(-4, 5):
		for cz in range(-4, 5):
			var rp := WgRivers.trace(t, t.seed_value, cx, cz)
			if rp.size() > found_river.size():
				found_river = rp
	if found_river.size() > 6:
		var w3: Vector2 = found_river[found_river.size() / 2]
		var wat := Vector3(w3.x, gen.height_at(w3.x, w3.y), w3.y)
		print("river: %d points, mid at %.0f,%.0f, cut %.1f m"
			% [found_river.size(), wat.x, wat.z, t.river_cut(wat.x, wat.z)])
		gen.build_block(WorldGen.chunk_of(wat), 3)
		await _settle()
		cam.position = wat + Vector3(0.0, 210.0, 300.0)
		cam.look_at(wat, Vector3.UP)
		await _shot("river_air")
		# ACROSS the river, from its own bank. A diagonal offset put the
		# camera 100 m away in whatever direction, which on a meander is
		# as likely to be up the course as across it — the first bank
		# shot was a close-up of a reed.
		var flow: Vector2 = (found_river[found_river.size() / 2 + 1]
			- found_river[found_river.size() / 2 - 1]).normalized()
		var side := Vector2(-flow.y, flow.x) * 34.0
		var bank := Vector3(wat.x + side.x, 0.0, wat.z + side.y)
		bank.y = gen.height_at(bank.x, bank.z) + 2.2
		cam.position = bank
		cam.look_at(wat + Vector3(flow.x * 40.0, 0.0, flow.y * 40.0), Vector3.UP)
		await _shot("river_bank")
		_clear()

	# And the things between the places.
	var want_marks := ["stones", "tower", "shrine", "camp"]
	var marks: Dictionary = {}
	for cx in range(0, 30):
		for cz in range(0, 30):
			var m := WgLandmark.at_cell(t, t.seed_value, cx, cz)
			if m.is_empty() or (m["pieces"] as Array).is_empty():
				continue
			if want_marks.has(m["kind"]) and not marks.has(m["kind"]):
				marks[m["kind"]] = m
		if marks.size() == want_marks.size():
			break
	for kind in want_marks:
		if not marks.has(kind):
			continue
		var at2: Vector3 = marks[kind]["at"]
		gen.build_block(WorldGen.chunk_of(at2), 1)
		await _settle()
		var eye2 := at2 + Vector3(13.0, 0.0, 13.0)
		eye2.y = gen.height_at(eye2.x, eye2.z) + 4.0
		cam.position = eye2
		cam.look_at(at2 + Vector3(0, 1.5, 0), Vector3.UP)
		await _shot("mark_" + kind)
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

	# --- country, from the air and from the ground, in every wedge ---
	#
	# By WEDGE INDEX and the biome's own name, not by hardcoded angles
	# with hardcoded labels: the labels said "downs", "ironwood" and
	# "moor" for a week after those biomes had been renamed to the
	# Wheel's own six, so the files on disk were captioned with
	# country that no longer existed.
	# AROUND THE CAPITOL, not around the origin.
	#
	# This fanned out from (0,0) at 4.2 km, which toured all six wedges
	# for as long as (0,0) was Godsgrave. Since Thornfield became the
	# origin, (0,0) is 23.4 km out on one spoke and every one of these
	# six shots landed in the Hedges — six files, one biome, each
	# overwriting the last. Worth the note: the shift was checked
	# against the generator's asserts and against a render of the town,
	# and it still quietly broke the one tool whose whole job is to show
	# the six wedges apart.
	var tour := t.capitol_site()
	for wedge in WgTerrain.WEDGES:
		var ang: float = (float(wedge) + 0.5) / float(WgTerrain.WEDGES) * TAU
		var r := WgTerrain.CAPITOL_R + 4200.0
		var at := Vector3(tour.x + cos(ang) * r, 0.0, tour.z + sin(ang) * r)
		var label: String = String(t.biome_at(at.x, at.z).name).replace("the ", "")
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
