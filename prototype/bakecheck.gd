extends Node
## Does the country survive being written down?
##
## The whole case for baking rests on one property: a baked chunk is
## the SAME chunk. If the bake drifts from the generator by so much as
## a vertex, then what was checked, rendered and walked is not what
## ships — and the drift would show up as seams between a baked chunk
## and a generated neighbour, which is the worst possible symptom
## because it points at the streaming rather than at the format.

const DIR := "user://bakecheck"

var _fails: Array[String] = []


## Chunks worth probing for a river: a ring of them around a traced
## course, rather than a guess. There is one river per ~9 km2 and a
## chunk is 0.004 km2, so picking coordinates by eye finds dry land.
func _wet_candidates(t: WgTerrain) -> Array:
	var out: Array = []
	for cx in range(-3, 4):
		for cz in range(-3, 4):
			var path := WgRivers.trace(t, t.seed_value, cx, cz)
			if path.size() < 8:
				continue
			for i in [path.size() / 3, path.size() * 2 / 3]:
				var p: Vector2 = path[i]
				out.append(Vector2i(int(floor(p.x / WgChunk.SIZE)),
					int(floor(p.y / WgChunk.SIZE))))
			if out.size() >= 8:
				return out
	return out


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	var t := WgTerrain.new(20260927)
	var at := Vector2i(42, 45)

	var made := WgBake.gather(t, at)
	_ok("a chunk can be gathered", not made.is_empty()
		and (made["heights"] as PackedFloat32Array).size() == WgChunk.VERTS * WgChunk.VERTS,
		"gathered %d heights" % (made["heights"] as PackedFloat32Array).size())
	print("      %d heights, %d colour bytes, %d pieces, %d solids" % [
		(made["heights"] as PackedFloat32Array).size(),
		(made["colours"] as PackedByteArray).size(),
		(made["pieces"] as Array).size(),
		(made["solids"] as Array).size()])

	_ok("and written", WgBake.write(made, DIR), "the write failed")
	var back := WgBake.read(at, DIR)
	_ok("and read back", not back.is_empty(), "nothing came back")
	if back.is_empty():
		_finish()
		return

	# --- identical, not merely similar -----------------------------------
	_ok("it is the same chunk", (back["at"] as Vector2i) == at,
		"came back as %s" % str(back["at"]))

	var h0: PackedFloat32Array = made["heights"]
	var h1: PackedFloat32Array = back["heights"]
	var worst := 0.0
	for i in h0.size():
		worst = maxf(worst, absf(h0[i] - h1[i]))
	_ok("every height survives exactly", worst == 0.0,
		"worst height difference %.9f m" % worst)

	var c0: PackedByteArray = made["colours"]
	var c1: PackedByteArray = back["colours"]
	var cdiff := 0
	for i in c0.size():
		if c0[i] != c1[i]:
			cdiff += 1
	_ok("and every colour", cdiff == 0, "%d colour bytes differ" % cdiff)

	# --- water -----------------------------------------------------------
	#
	# ON A CHUNK THAT ACTUALLY HAS WATER IN IT. Comparing two fields of
	# the dry sentinel would pass however badly the water was written,
	# which is the whole failure mode this is here to catch — so the
	# first thing asserted is that a wet chunk was found at all.
	var wet_at := Vector2i(0, 0)
	var wet_n := 0
	for probe in _wet_candidates(t):
		var w: PackedFloat32Array = WgBake.gather(t, probe)["water"]
		var count := 0
		for v in w:
			if v > WgTerrain.NO_WATER:
				count += 1
		if count > wet_n:
			wet_n = count
			wet_at = probe
	_ok("a chunk with a river in it was found", wet_n > 20,
		"the wettest chunk probed has %d wet vertices" % wet_n)
	print("      chunk %s has %d wet vertices of %d"
		% [str(wet_at), wet_n, WgChunk.VERTS * WgChunk.VERTS])

	var wet_made := WgBake.gather(t, wet_at)
	WgBake.write(wet_made, DIR)
	var wet_back := WgBake.read(wet_at, DIR)
	var w0: PackedFloat32Array = wet_made["water"]
	var w1: PackedFloat32Array = wet_back.get("water", PackedFloat32Array())
	var wdiff := 0
	for i in w0.size():
		if i >= w1.size() or w0[i] != w1[i]:
			wdiff += 1
	_ok("and its water survives exactly", w0.size() == w1.size() and wdiff == 0,
		"wrote %d water levels, read %d, %d differ"
			% [w0.size(), w1.size(), wdiff])

	# And the sheet is actually built from it — a level that reads back
	# perfectly and is then never used is the same as not storing it.
	var wet_chunk := WgChunk.new()
	add_child(wet_chunk)
	wet_chunk.build_baked(wet_back, wet_at.x, wet_at.y)
	await get_tree().process_frame
	_ok("and a baked chunk has water standing on it",
		wet_chunk.find_child("Water", true, false) != null,
		"the baked chunk has no water mesh")
	wet_chunk.queue_free()

	# --- provenance, and the hand-edit path ------------------------------
	#
	# THE ONE THAT MATTERS. An override is cut to fit the land around
	# it; when the generator moves, that land moves and the override
	# does not, and the seam is a step you walk into. Rivers and the
	# swell both moved it by tens of metres in one day.
	var print_now := t.fingerprint()
	_ok("the generator has a fingerprint", print_now != 0,
		"fingerprint is zero, which is the 'not recorded' value")
	_ok("and it is the same one asked twice",
		WgTerrain.new(20260927).fingerprint() == print_now,
		"two terrains on one seed fingerprint differently")
	_ok("and a different world has a different one",
		WgTerrain.new(99).fingerprint() != print_now,
		"seed 99 fingerprints the same as seed 20260927")

	var stamped := WgBake.gather(t, at)
	stamped["fingerprint"] = print_now
	WgBake.write(stamped, DIR)
	_ok("a bake remembers which generator cut it",
		WgBake.stale(at, t, DIR) == WgBake.FRESH,
		"a bake stamped with the current fingerprint does not read fresh")

	stamped["fingerprint"] = print_now ^ 0x5a5a5a
	WgBake.write(stamped, DIR)
	_ok("and a bake from an older one is called stale",
		WgBake.stale(at, t, DIR) == WgBake.STALE,
		"a bake stamped with someone else's fingerprint reads fresh")
	WgBake.write(made, DIR)

	# The text path. `tech.md` §1a's case for baking is that a wrong
	# hill "becomes a file somebody edits" — which was true of the
	# mechanism and false of the practice until this existed.
	var text := WgBake.to_json(stamped)
	var parsed := WgBake.from_json(text)
	_ok("a chunk can be written out as text and read back",
		not parsed.is_empty() and (parsed["at"] as Vector2i) == at,
		"the round trip did not come back as chunk %s" % str(at))
	var jworst := 0.0
	var jh0: PackedFloat32Array = stamped["heights"]
	var jh1: PackedFloat32Array = parsed.get("heights", PackedFloat32Array())
	for i in jh0.size():
		jworst = maxf(jworst, absf(jh0[i] - (jh1[i] if i < jh1.size() else 1e9)))
	_ok("and every height survives the text exactly", jworst == 0.0,
		"worst height difference through JSON %.9f m" % jworst)
	var jwater: PackedFloat32Array = parsed.get("water", PackedFloat32Array())
	var jw0: PackedFloat32Array = stamped["water"]
	var jwd := 0
	for i in jw0.size():
		if i >= jwater.size() or jw0[i] != jwater[i]:
			jwd += 1
	_ok("and the water with it", jwd == 0,
		"%d water levels differ through JSON" % jwd)
	_ok("and what stands on it is there to be edited",
		(parsed["pieces"] as Array).size() == (stamped["pieces"] as Array).size()
			and text.contains("\"path\""),
		"the piece list did not survive, or is not readable text")

	var p0: Array = made["pieces"]
	var p1: Array = back["pieces"]
	_ok("and every piece is there", p0.size() == p1.size(),
		"wrote %d pieces, read %d" % [p0.size(), p1.size()])

	var moved := 0.0
	var wrong_model := 0
	var n: int = mini(p0.size(), p1.size())
	for i in n:
		var a: Dictionary = p0[i]
		var b: Dictionary = p1[i]
		if String(a["path"]) != String(b["path"]):
			wrong_model += 1
		moved = maxf(moved, (a["position"] as Vector3).distance_to(b["position"]))
	_ok("and is the right model", wrong_model == 0,
		"%d pieces came back as a different model" % wrong_model)
	# Positions go through float32 both ways, so this is exact rather
	# than merely close — a tolerance here would hide a real drift.
	_ok("and stands where it stood", moved == 0.0,
		"a piece moved %.9f m through the bake" % moved)

	_ok("and the solid walls survive",
		(made["solids"] as Array).size() == (back["solids"] as Array).size(),
		"wrote %d solids, read %d" % [(made["solids"] as Array).size(),
			(back["solids"] as Array).size()])

	# --- a baked chunk builds, and you can stand on it --------------------
	var chunk := WgChunk.new()
	add_child(chunk)
	chunk.build_baked(back, at.x, at.y)
	await get_tree().process_frame
	_ok("a baked chunk builds", chunk.get_child_count() > 1,
		"nothing came out of it")
	_ok("and has ground under it",
		chunk.find_child("GroundBody", true, false) != null,
		"no collision on a baked chunk")

	var ground := t.height_at(float(at.x) * WgChunk.SIZE, float(at.y) * WgChunk.SIZE)
	var body := CharacterBody3D.new()
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 2.0
	shape.radius = 0.4
	col.shape = shape
	body.add_child(col)
	body.position = Vector3(float(at.x) * WgChunk.SIZE, ground + 6.0,
		float(at.y) * WgChunk.SIZE)
	add_child(body)
	for i in 120:
		body.velocity.y -= 9.8 * (1.0 / 60.0)
		body.move_and_slide()
		await get_tree().physics_frame
	var rest := body.global_position.y
	_ok("and a body lands on the BAKED ground",
		rest > ground - 0.5 and rest < ground + 3.0,
		"dropped onto baked ground at %.1f and ended at %.1f" % [ground, rest])
	print("      baked ground %.2f m, body at rest %.2f m" % [ground, rest])

	# --- a stale bake is refused, not silently used ----------------------
	# Written through the real writer with a future version, because
	# the file is compressed and a test cannot reach in and poke the
	# header. An earlier cut of this copied the file byte for byte and
	# changed nothing, then asserted it would be refused — and passed
	# only while the file happened to be uncompressed.
	WgBake.write(made, DIR, WgBake.VERSION + 99)
	_ok("a bake from another version is refused",
		WgBake.read(at, DIR).is_empty(),
		"a stale bake was loaded as though it were current — which is "
			+ "how a week gets spent debugging the wrong world")

	_finish()


func _finish() -> void:
	print("")
	print("bake: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
