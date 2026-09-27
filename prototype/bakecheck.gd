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
