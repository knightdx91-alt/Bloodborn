class_name WgChunk
extends Node3D
## One square of world, built from nothing but its own coordinates.
##
## The unit of streaming. A chunk knows its own (cx, cz) and asks
## WgTerrain, WgScatter and WgSettlement what is there — so it can be
## built, freed and built again without keeping anything, which is what
## lets a 255 km² world exist on a phone that can hold a few hundred
## metres of it at a time.
##
## Nothing here is a runtime system by intent. `tech.md` §1a: this
## drafts the land, the result gets baked and committed, and the
## committed land is what ships. Building at runtime is how the
## generator is developed and looked at, not how the game loads.

## Metres per chunk. 64 keeps a chunk's vertex grid at 65x65, which is
## a HeightMapShape3D with no scaling and a mesh small enough to throw
## away cheaply.
const SIZE := 64.0
## Vertices per side. One per metre, so the collision grid and the
## visual grid are the same grid and the body never stands in a hole
## the eye cannot see.
const VERTS := 65

var cx := 0
var cz := 0
var terrain: WgTerrain = null
var world_seed := 0

## What was put here, for harnesses to count without walking the tree.
var placed := 0
var settlements: Array[String] = []
var landmarks: Array[String] = []


func build(t: WgTerrain, chunk_x: int, chunk_z: int) -> void:
	terrain = t
	world_seed = t.seed_value
	cx = chunk_x
	cz = chunk_z
	position = Vector3(float(cx) * SIZE, 0.0, float(cz) * SIZE)

	var keep_clear: Array = []
	var hamlets: Array = []

	# NEIGHBOURING CELLS TOO.
	#
	# A hamlet sitting near a settlement-cell border puts houses and
	# keep-clear rects across the line. A chunk that only asked about
	# the cell its centre falls in would grow a wood through the
	# neighbour's walls — and the trees would be on the chunk that
	# owns the ground, so the fault would appear one chunk away from
	# the code that caused it.
	var scx := int(floor(position.x / WgSettlement.CELL))
	var scz := int(floor(position.z / WgSettlement.CELL))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var built := WgSettlement.cached(terrain, world_seed, scx + dx, scz + dz)
			if built.houses == 0 and built.pieces.is_empty():
				continue
			hamlets.append(built)
			keep_clear.append_array(built.keep_clear)

	# Landmarks, on their own finer grid. Same neighbour sweep and the
	# same reason: one near a cell border reaches over the line.
	var marks: Array = []
	var lcx := int(floor(position.x / WgLandmark.CELL))
	var lcz := int(floor(position.z / WgLandmark.CELL))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var mark := WgLandmark.cached(terrain, world_seed, lcx + dx, lcz + dz)
			if mark.is_empty() or (mark["pieces"] as Array).is_empty():
				continue
			marks.append(mark)
			keep_clear.append_array(mark["keep_clear"])

	_ground()
	_scatter(keep_clear)
	_settlements(hamlets)
	_landmarks(marks)


## The ground mesh, and the ground you stand on, from the same grid.
func _ground() -> void:
	var half := SIZE * 0.5
	var step := SIZE / float(VERTS - 1)
	var heights := PackedFloat32Array()
	heights.resize(VERTS * VERTS)

	# SAMPLE THE HEIGHTFIELD ONCE, WITH A BORDER, AND REUSE IT.
	#
	# The first cut asked `ground_at` per vertex, and `ground_at` asks
	# `slope_at`, and `slope_at` asks `height_at` four more times, so
	# every vertex cost five height samples instead of one.
	#
	# Worth fixing, but NOT where a chunk's time actually went — which
	# is worth writing down, because the guess was wrong by an order of
	# magnitude. Measured: the whole 67x67 heightfield is 9 ms and the
	# scatter decisions are 3 ms. Instantiating the models was 107 ms.
	# The noise was never the problem; one scene tree per tree was.
	#
	# The grid already holds every height needed. Taking slope from its
	# own neighbours costs nothing and is the same number. The border
	# ring exists so the edge vertices have neighbours to difference
	# against rather than a special case that flattens the chunk rim.
	var wide := VERTS + 2
	var grid := PackedFloat32Array()
	grid.resize(wide * wide)
	for iz in wide:
		for ix in wide:
			var wx := position.x - half + float(ix - 1) * step
			var wz := position.z - half + float(iz - 1) * step
			grid[iz * wide + ix] = terrain.height_at(wx, wz)

	# ARRAYS DIRECTLY, not SurfaceTool.
	#
	# SurfaceTool is a script call per vertex and per index, and at
	# 4,225 vertices and 24,576 indices that was 17.7 ms — the single
	# biggest item left in a chunk once the models were batched.
	# Writing the packed arrays and handing them to ArrayMesh does the
	# same work with no per-vertex call overhead.
	#
	# Normals come from the heightfield rather than from
	# `generate_normals()`: the grid already holds every neighbour, so
	# the true surface normal is two subtractions and a normalize, and
	# it is smooth across chunk borders for free because it is derived
	# from world-space heights rather than from this chunk's triangles.
	var verts := PackedVector3Array(); verts.resize(VERTS * VERTS)
	var norms := PackedVector3Array(); norms.resize(VERTS * VERTS)
	var cols := PackedColorArray(); cols.resize(VERTS * VERTS)
	var uvs := PackedVector2Array(); uvs.resize(VERTS * VERTS)

	for iz in VERTS:
		for ix in VERTS:
			var lx := -half + float(ix) * step
			var lz := -half + float(iz) * step
			var gi := (iz + 1) * wide + (ix + 1)
			var h: float = grid[gi]
			var vi := iz * VERTS + ix
			heights[vi] = h
			var dx: float = grid[gi + 1] - grid[gi - 1]
			var dz: float = grid[gi + wide] - grid[gi - wide]
			var slope: float = Vector2(dx, dz).length() / (2.0 * step)
			verts[vi] = Vector3(lx, h, lz)
			norms[vi] = Vector3(-dx, 2.0 * step, -dz).normalized()
			cols[vi] = terrain.shade(position.x + lx, position.z + lz, h, slope)
			# UVs in WORLD metres, not chunk-local, so the ground
			# texture runs across a chunk border without restarting —
			# otherwise every seam is a visible tile reset even though
			# the heights match perfectly.
			uvs[vi] = Vector2((position.x + lx) / 4.0, (position.z + lz) / 4.0)

	var idx := PackedInt32Array()
	idx.resize((VERTS - 1) * (VERTS - 1) * 6)
	var w := 0
	for iz in VERTS - 1:
		for ix in VERTS - 1:
			var a := iz * VERTS + ix
			var b := a + 1
			var c := a + VERTS
			var d := c + 1
			# CLOCKWISE SEEN FROM ABOVE, which is what Godot calls
			# front-facing. The first cut wound these the other way:
			# the ground rendered, took no light at all and came out
			# pure black under a lit sky, because every face on it was
			# pointing at the centre of the earth. A render caught it
			# in one frame; no arithmetic in the generator would have.
			idx[w] = a; idx[w + 1] = b; idx[w + 2] = c
			idx[w + 3] = b; idx[w + 4] = d; idx[w + 5] = c
			w += 6

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = mesh
	mi.mesh.surface_set_material(0, _ground_material())
	add_child(mi)

	var body := StaticBody3D.new()
	body.name = "GroundBody"
	var col := CollisionShape3D.new()
	var shape := HeightMapShape3D.new()
	shape.map_width = VERTS
	shape.map_depth = VERTS
	shape.map_data = heights
	col.shape = shape
	# One vertex per metre means the shape's own 1-unit spacing already
	# matches the mesh; no scaling, which is the whole reason for VERTS
	# being SIZE + 1.
	body.add_child(col)
	add_child(body)


## ONE material for the whole world, built once.
##
## The colour is per-vertex — biome, height and slope — which is what
## makes a biome border a blend rather than a seam, and means the world
## needs one material rather than one per biome.
##
## The texture is the town's own ground noise. Without it the vertex
## colour alone gives a perfectly flat field of one green, which reads
## as felt rather than as grass: the first render of a hamlet had good
## houses standing on a billiard table. Built statically because a
## 256x256 seamless NoiseTexture2D per chunk is the same image
## generated a hundred times.
static var _shared_ground: StandardMaterial3D = null

static func _ground_material() -> StandardMaterial3D:
	if _shared_ground != null:
		return _shared_ground
	var mat := Look.ground_material(Color.WHITE, 1.0)
	# White base and UVs already in metres, so the biome colour on each
	# vertex multiplies the noise instead of fighting it.
	mat.albedo_color = Color.WHITE
	mat.uv1_scale = Vector3.ONE
	mat.vertex_color_use_as_albedo = true
	_shared_ground = mat
	return _shared_ground


func _scatter(keep_clear: Array) -> void:
	var half := SIZE * 0.5
	var items := WgScatter.in_rect(terrain,
		position.x - half, position.z - half,
		position.x + half, position.z + half, keep_clear)
	_place(items)


func _settlements(hamlets: Array) -> void:
	var half := SIZE * 0.5
	var mine := Rect2(position.x - half, position.z - half, SIZE, SIZE)
	for built in hamlets:
		var here: Array = []
		for piece in built.pieces:
			var p: Vector3 = piece["position"]
			# Only the pieces standing on THIS chunk. A hamlet spanning
			# a chunk border is built by both, each taking its half —
			# so it does not vanish when one chunk unloads, and is not
			# doubled where they overlap.
			if not mine.has_point(Vector2(p.x, p.z)):
				continue
			here.append(piece)
		var any: bool = not here.is_empty()
		_place(here)
		for solid in built.solids:
			var p2: Vector3 = solid["position"]
			if not mine.has_point(Vector2(p2.x, p2.z)):
				continue
			_solid(p2, solid["size"], solid["yaw"])
		if any and not settlements.has(built.name):
			settlements.append(built.name)


func _landmarks(marks: Array) -> void:
	var half := SIZE * 0.5
	var mine := Rect2(position.x - half, position.z - half, SIZE, SIZE)
	for mark in marks:
		var here: Array = []
		for piece in mark["pieces"]:
			var p: Vector3 = piece["position"]
			if not mine.has_point(Vector2(p.x, p.z)):
				continue
			here.append(piece)
		if not here.is_empty():
			_place(here)
			if not landmarks.has(mark["kind"]):
				landmarks.append(mark["kind"])


## Everything of one model, in ONE node.
##
## A chunk holds a few hundred trees, tufts, barrels and wall pieces,
## and instantiating each as its own scene tree cost 107 ms of the
## chunk's 142 — by far the largest single thing in the generator, and
## it would have been worse on a phone, where it is also a few hundred
## more draw calls every frame afterwards.
##
## A MultiMeshInstance3D draws any number of copies of one mesh from an
## array of transforms, in one call. So the pieces are grouped by model
## and each group becomes one node. The cost stops scaling with the
## number of trees and starts scaling with the number of DISTINCT
## trees, which is eighteen for the whole world.
##
## Collision is deliberately not included: a tree you can walk through
## is a smaller problem than a chunk that takes a fifth of a second to
## arrive, and what needs solidity — buildings — gets its box from
## `_solid` instead.
func _place(items: Array) -> void:
	var by_model: Dictionary = {}
	for item in items:
		var path: String = item["path"]
		if not by_model.has(path):
			by_model[path] = []
		by_model[path].append(item)

	for path in by_model:
		var parts := _model_parts(path)
		if parts.is_empty():
			continue
		var group: Array = by_model[path]
		for part in parts:
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = part["mesh"]
			mm.instance_count = group.size()
			for i in group.size():
				var item: Dictionary = group[i]
				var p: Vector3 = item["position"]
				# Scale may be a float or a Vector3.
				#
				# Uniform only, at first — which quietly defeated the
				# standing stones: the pack has no menhir, so they are
				# a wide flat rock stretched upward, and stretching it
				# uniformly just made a bigger wide flat rock lying in
				# the grass. A render showed a stone circle that was a
				# gravel patch.
				var raw = item.get("scale", 1.0)
				var scv: Vector3 = raw if raw is Vector3 else Vector3(raw, raw, raw)
				var basis := Basis(Vector3.UP, item.get("yaw", 0.0)).scaled(scv)
				var placement := Transform3D(basis, p - position)
				mm.set_instance_transform(i, placement * (part["xform"] as Transform3D))
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			# ONLY when the source node actually carried an override.
			#
			# A MultiMesh already draws the mesh's own per-surface
			# materials. Setting an override here forces ONE material
			# onto every surface, so the first pass painted the whole
			# hamlet in whichever material happened to be on surface 0:
			# tiled roofs and plastered walls all came out as clapboard,
			# and the trees came out as their own trunks. A render
			# caught it; the timing number that came with it looked
			# perfectly healthy.
			if part["material"] != null:
				mmi.material_override = part["material"]
			add_child(mmi)
		placed += group.size()


## The meshes inside a model file, with where they sit inside it.
##
## Cached across every chunk: the same eighteen trees and thirty-odd
## props are asked for everywhere, and loading and walking a scene to
## find its meshes is the expensive half of instantiating it.
static var _parts_cache: Dictionary = {}

static func _model_parts(path: String) -> Array:
	if _parts_cache.has(path):
		return _parts_cache[path]
	var out: Array = []
	var scene := load(path) as PackedScene
	if scene == null:
		_parts_cache[path] = out
		return out
	var root := scene.instantiate() as Node3D
	if root == null:
		_parts_cache[path] = out
		return out
	_collect(root, root, out)
	root.queue_free()
	_parts_cache[path] = out
	return out


static func _collect(node: Node, root: Node3D, out: Array) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			out.append({
				"mesh": mi.mesh,
				# Relative to the model's own root, so a wall piece whose
				# geometry sits off its origin lands where the file
				# intended rather than at the placement point.
				"xform": root.global_transform.affine_inverse() * mi.global_transform,
				# The node's own override, if it has one — NOT
				# `get_active_material`, which falls back to the mesh's
				# surface material and so always returns something.
				"material": mi.material_override,
			})
	for child in node.get_children():
		_collect(child, root, out)


func _solid(at: Vector3, size: Vector3, yaw: float) -> void:
	var body := StaticBody3D.new()
	body.position = at - position
	body.rotation.y = yaw
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	col.shape = box
	body.add_child(col)
	add_child(body)
