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
			var found := WgSettlement.site(terrain, world_seed, scx + dx, scz + dz)
			if found.is_empty():
				continue
			var built := WgSettlement.build(terrain, world_seed, found)
			hamlets.append(built)
			keep_clear.append_array(built.keep_clear)

	_ground()
	_scatter(keep_clear)
	_settlements(hamlets)


## The ground mesh, and the ground you stand on, from the same grid.
func _ground() -> void:
	var half := SIZE * 0.5
	var step := SIZE / float(VERTS - 1)
	var heights := PackedFloat32Array()
	heights.resize(VERTS * VERTS)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in VERTS:
		for ix in VERTS:
			var lx := -half + float(ix) * step
			var lz := -half + float(iz) * step
			var h := terrain.height_at(position.x + lx, position.z + lz)
			heights[iz * VERTS + ix] = h
			st.set_color(terrain.ground_at(position.x + lx, position.z + lz))
			# UVs in WORLD metres, not chunk-local, so the ground
			# texture runs across a chunk border without restarting —
			# otherwise every seam is a visible tile reset even though
			# the heights match perfectly.
			st.set_uv(Vector2((position.x + lx) / 4.0, (position.z + lz) / 4.0))
			st.add_vertex(Vector3(lx, h, lz))

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
			st.add_index(a); st.add_index(b); st.add_index(c)
			st.add_index(b); st.add_index(d); st.add_index(c)
	st.generate_normals()

	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = st.commit()
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
	for item in items:
		_put(item)


func _settlements(hamlets: Array) -> void:
	var half := SIZE * 0.5
	var mine := Rect2(position.x - half, position.z - half, SIZE, SIZE)
	for built in hamlets:
		var any := false
		for piece in built.pieces:
			var p: Vector3 = piece["position"]
			# Only the pieces standing on THIS chunk. A hamlet spanning
			# a chunk border is built by both, each taking its half —
			# so it does not vanish when one chunk unloads, and is not
			# doubled where they overlap.
			if not mine.has_point(Vector2(p.x, p.z)):
				continue
			_put(piece)
			any = true
		for solid in built.solids:
			var p2: Vector3 = solid["position"]
			if not mine.has_point(Vector2(p2.x, p2.z)):
				continue
			_solid(p2, solid["size"], solid["yaw"])
		if any and not settlements.has(built.name):
			settlements.append(built.name)


func _put(item: Dictionary) -> void:
	var scene := load(item["path"]) as PackedScene
	if scene == null:
		return
	var inst := scene.instantiate() as Node3D
	if inst == null:
		return
	var p: Vector3 = item["position"]
	inst.position = p - position
	inst.rotation.y = item.get("yaw", 0.0)
	var s: float = item.get("scale", 1.0)
	if not is_equal_approx(s, 1.0):
		inst.scale = Vector3(s, s, s)
	add_child(inst)
	placed += 1


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
