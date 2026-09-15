extends Node3D
## Thornfield — harvest-town visual pass (T1-T3 geometry + dressing).
##
## Real CC0 kit models (Quaternius packs, see assets/town/LICENSE-QUATERNIUS-CC0.txt)
## placed and dressed by code; terrain, roads, fields, hedge ring, wheat and
## small dressing are procedural. Visuals only: no NPCs, no dialogue, no
## systems, no audio. Walkable collision is included (StaticBody3D boxes).
##
## Lighting/material treatment is Look's (look.gd, read-only): this script
## only calls Look.build() and the material helpers.

const KIT := "res://assets/town/kit/"
const FARM := "res://assets/town/farm/"
const NATURE := "res://assets/town/nature/"
const PROPS := "res://assets/town/props/"

const RING_R := 55.0  # hedge-ring radius; town is ~110 m across

var _cache: Dictionary = {}
var _mats: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _blocks: Array = []  # Vector4(x0, z0, x1, z1) keep-clear rects for scatter


func _ready() -> void:
	_rng.seed = 20260914
	Look.build(self)
	# The yard's 60 m shadow range would clip the town's far side.
	for c in get_children():
		if c is DirectionalLight3D and (c as DirectionalLight3D).shadow_enabled:
			(c as DirectionalLight3D).directional_shadow_max_distance = 200.0
	_terrain()
	_roads()
	_fields()
	_hedge_ring()
	_gates()
	_market_square()
	_district_buildings()
	_cottages()
	_vance_farm()
	_burnt_mill()
	_delve_mouth()
	_orchard()
	_scatter()


# ---------------------------------------------------------------- assets ---

func _ps(path: String) -> PackedScene:
	if not _cache.has(path):
		_cache[path] = load(path) as PackedScene
	return _cache[path]


func _put(path: String, pos: Vector3, yaw: float = 0.0, parent: Node = null) -> Node3D:
	var inst: Node3D = (_ps(path) as PackedScene).instantiate()
	inst.position = pos
	inst.rotation.y = yaw
	(parent if parent != null else self).add_child(inst)
	return inst


func _kit(stem: String) -> String:
	return KIT + stem + ".gltf"


func _farm(stem: String) -> String:
	return FARM + stem + ".fbx"


func _nature(stem: String) -> String:
	return NATURE + stem + ".gltf"


func _props(stem: String) -> String:
	return PROPS + stem + ".gltf"


# -------------------------------------------------------------- materials ---

func _solid_mat(base: Color, tiles: float = 3.0, rough: float = 0.9) -> StandardMaterial3D:
	var key := "s_%s_%s" % [base.to_html(), tiles]
	if not _mats.has(key):
		_mats[key] = Look.solid_material(base, tiles, rough)
	return _mats[key]


func _ground_mat(base: Color, tiles: float = 11.0) -> StandardMaterial3D:
	var key := "g_%s_%s" % [base.to_html(), tiles]
	if not _mats.has(key):
		_mats[key] = Look.ground_material(base, tiles)
	return _mats[key]


# -------------------------------------------------------------- geometry ---

func _quad(pos: Vector3, size: Vector2, mat: Material, yaw: float = 0.0,
		parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = yaw
	(parent if parent != null else self).add_child(mi)
	return mi


func _box(parent: Node, pos: Vector3, size: Vector3, mat: Material,
		yaw: float = 0.0, tilt: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = Vector3(tilt.x, yaw, tilt.z)
	parent.add_child(mi)
	return mi


func _solid(parent: Node, pos: Vector3, size: Vector3, yaw: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = yaw
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	parent.add_child(body)
	return body


func _block(x0: float, z0: float, x1: float, z1: float) -> void:
	_blocks.append(Vector4(x0, z0, x1, z1))


func _blocked(x: float, z: float, pad: float = 0.0) -> bool:
	for b in _blocks:
		var r := b as Vector4
		if x > r.x - pad and x < r.z + pad and z > r.y - pad and z < r.w + pad:
			return true
	return false


func _multimesh_box(count: int, mat: Material) -> MultiMeshInstance3D:
	# NOTE: MultiMesh instance colors do not render under GL Compatibility
	# (verified: set_instance_color is silently ignored), so per-instance
	# variation is done with separate tinted meshes instead.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	bm.material = mat
	mm.mesh = bm
	mm.instance_count = count
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mmi)
	return mmi


func _set_inst(mmi: MultiMeshInstance3D, i: int, pos: Vector3, yaw: float,
		scale: Vector3) -> void:
	var t := Transform3D(Basis(Vector3.UP, yaw).scaled(scale), pos)
	mmi.multimesh.set_instance_transform(i, t)


# ----------------------------------------------------------------- house ---

## Modular cottage/inn/smithy assembler. wm x dm wall modules (2 m each).
## Front (+z local) gets door + windows; brick swaps the plaster set.
func _house(pos: Vector3, yaw: float, wm: int, dm: int, opts: Dictionary = {}) -> Node3D:
	var brick: bool = opts.get("brick", false)
	var h := Node3D.new()
	h.position = pos
	h.rotation.y = yaw
	add_child(h)
	var wset := "Wall_UnevenBrick" if brick else "Wall_Plaster"
	var corner := "Corner_Exterior_Brick" if brick else "Corner_Exterior_Wood"
	var hw := float(wm)
	var hd := float(dm)
	var door_i := wm / 2
	for i in range(wm):
		var x := -hw + 1.0 + 2.0 * i
		var fstem := wset + "_Straight"
		if i == door_i:
			fstem = wset + "_Door_Flat"
		elif i == 0 or i == wm - 1:
			fstem = wset + "_Window_Wide_Flat"
		_put(_kit(fstem), Vector3(x, 0, hd), 0.0, h)
		var bstem := wset + "_Window_Wide_Flat" if (i % 2 == 0) else wset + "_Straight"
		_put(_kit(bstem), Vector3(x, 0, -hd), PI, h)
	for j in range(dm):
		var z := -hd + 1.0 + 2.0 * j
		var sstem := wset + "_Window_Wide_Flat" if (j == 1 or j == dm - 2) else wset + "_Straight"
		_put(_kit(sstem), Vector3(hw, 0, z), -PI / 2, h)
		_put(_kit(sstem), Vector3(-hw, 0, z), PI / 2, h)
	for cx in [-hw, hw]:
		for cz in [-hd, hd]:
			_put(_kit(corner), Vector3(cx, 0, cz), 0.0, h)
	var rw := wm * 2
	var rd := dm * 2
	var roof_h := 5.67 if rw < 8 else 6.78
	_put(_kit("Roof_RoundTiles_%dx%d" % [rw, rd]), Vector3(0, 3.12, 0), 0.0, h)
	if opts.get("chimney", true):
		var cy := 3.12 + (roof_h - 0.78) * 0.45
		_put(_kit("Prop_Chimney"), Vector3(hw * 0.35, cy, -hd * 0.35), 0.0, h)
	if opts.get("stoop", false):
		_put(_kit("Stairs_Exterior_Straight"),
			Vector3(-hw + 1.0 + 2.0 * door_i, 0, hd + 1.4), 0.0, h)
	if opts.get("vine", false):
		_put(_kit("Prop_Vine1"), Vector3(hw - 1.6, 2.12, hd + 0.24), 0.0, h)
	# walkable collision: one box per building
	_solid(h, Vector3(0, 2.5, 0), Vector3(wm * 2.0 + 0.4, 5.0, dm * 2.0 + 0.4))
	# keep-clear rect (world space; yaw is a multiple of 90 deg here)
	var w := float(wm * 2)
	var d := float(dm * 2)
	var ry := fmod(abs(yaw), PI)
	if abs(ry - PI / 2.0) < 0.1:
		var t := w
		w = d
		d = t
	_block(pos.x - w / 2 - 1.5, pos.z - d / 2 - 1.5, pos.x + w / 2 + 1.5, pos.z + d / 2 + 1.5)
	return h

# ---------------------------------------------------------------- terrain ---

func _terrain() -> void:
	# Base ground: dry harvest grass.
	_quad(Vector3.ZERO, Vector2(500, 500),
		_ground_mat(Color(0.38, 0.40, 0.22), 60.0))


func _roads() -> void:
	var dirt := _ground_mat(Color(0.44, 0.37, 0.27), 24.0)
	# North-south main road through both gates.
	_quad(Vector3(0, 0.04, 0), Vector2(5, 112), dirt)
	# East-west lane.
	_quad(Vector3(0, 0.04, 18), Vector2(102, 4), dirt)
	# Market square paving.
	_quad(Vector3(0, 0.06, 2), Vector2(28, 20),
		_ground_mat(Color(0.50, 0.47, 0.42), 20.0))
	_block(-14, -8, 14, 12)
	# Worn paths: square to granary row, to chapel, to inn.
	_quad(Vector3(22, 0.045, 2), Vector2(18, 3), dirt, 0.0)
	_quad(Vector3(8, 0.045, -16), Vector2(3, 22), dirt, 0.0)
	_quad(Vector3(-16, 0.045, 2), Vector2(10, 3), dirt, 0.0)


func _fields() -> void:
	# Color-banded farmland outside the ring. Slight y stagger, no z-fight.
	var wheat := _ground_mat(Color(0.66, 0.53, 0.26), 30.0)
	var green := _ground_mat(Color(0.34, 0.42, 0.20), 30.0)
	var plow := _ground_mat(Color(0.33, 0.25, 0.17), 30.0)
	_quad(Vector3(0, 0.02, -88), Vector2(100, 44), wheat)      # north wheat
	_quad(Vector3(85, 0.025, -60), Vector2(50, 40), green)     # NE pasture
	_quad(Vector3(90, 0.02, 10), Vector2(50, 40), plow)        # east plowed
	_quad(Vector3(85, 0.025, 65), Vector2(50, 40), wheat)      # SE wheat
	_quad(Vector3(0, 0.02, 85), Vector2(80, 40), green)        # south pasture
	_quad(Vector3(-85, 0.025, -60), Vector2(50, 40), green)    # NW pasture
	_quad(Vector3(-90, 0.02, 60), Vector2(50, 44), plow)       # SW plowed
	_wheat_field(Rect2(-48, -108, 96, 40))                     # wheat instances N
	_wheat_field(Rect2(62, 46, 46, 36))                        # wheat instances SE
	_scarecrow(Vector3(90, 0, 10), 0.6)
	_scarecrow(Vector3(-20, 0, -88), 2.4)


func _wheat_field(rect: Rect2) -> void:
	# Procedural wheat: thin golden boxes (quads shade to black edge-on),
	# three tints for variation.
	var tints := [Color(0.78, 0.62, 0.30), Color(0.72, 0.56, 0.26), Color(0.82, 0.67, 0.34)]
	var count := 2500
	var per := count / 3
	var mmis: Array = []
	for ti in range(3):
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		var b := BoxMesh.new()
		b.size = Vector3(0.08, 0.42, 0.08)
		b.material = _solid_mat(tints[ti], 1.0, 1.0)
		mm.mesh = b
		mm.instance_count = per
		var inst := MultiMeshInstance3D.new()
		inst.multimesh = mm
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(inst)
		mmis.append(mm)
	for i in range(count):
		var mm: MultiMesh = mmis[i % 3]
		var x := _rng.randf_range(rect.position.x, rect.position.x + rect.size.x)
		var z := _rng.randf_range(rect.position.y, rect.position.y + rect.size.y)
		var s := _rng.randf_range(0.8, 1.3)
		var yaw := _rng.randf_range(0.0, PI)
		mm.set_instance_transform(i / 3,
			Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)),
				Vector3(x, 0.19 * s, z)))


func _scarecrow(pos: Vector3, yaw: float) -> void:
	var s := Node3D.new()
	s.position = pos
	s.rotation.y = yaw
	add_child(s)
	var wood := _solid_mat(Color(0.30, 0.22, 0.14))
	var straw := _solid_mat(Color(0.72, 0.60, 0.34))
	var rag := _solid_mat(Color(0.45, 0.36, 0.26))
	_box(s, Vector3(0, 0.9, 0), Vector3(0.12, 1.8, 0.12), wood)
	_box(s, Vector3(0, 1.45, 0), Vector3(1.1, 0.1, 0.1), wood)
	_box(s, Vector3(0, 1.15, 0), Vector3(0.55, 0.7, 0.3), rag)
	var head := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.22
	sp.height = 0.44
	head.mesh = sp
	head.material_override = straw
	head.position = Vector3(0, 1.78, 0)
	s.add_child(head)


# -------------------------------------------------------------- hedge+gate ---

func _near_gate(deg: float, tol: float) -> bool:
	return abs(wrapf(deg - 90.0, -180.0, 180.0)) < tol \
		or abs(wrapf(deg - 270.0, -180.0, 180.0)) < tol


func _hedge_ring() -> void:
	# Trimmed defensive hedge: three tinted instanced runs for variation,
	# plus organic bush tops scattered along the crown.
	var greens := [Color(0.13, 0.22, 0.09), Color(0.17, 0.27, 0.11), Color(0.10, 0.18, 0.08)]
	var n := 150
	var per := n / 3
	var mmis: Array = []
	for gi in range(3):
		mmis.append(_multimesh_box(per, _solid_mat(greens[gi], 2.0)))
	for i in range(n):
		var a := TAU * i / n
		var deg := rad_to_deg(a)
		var mmi: MultiMeshInstance3D = mmis[i % 3]
		var slot := i / 3
		if _near_gate(deg, 4.0):
			_set_inst(mmi, slot, Vector3(0, -10, 0), 0.0, Vector3.ZERO)
			continue
		var x := cos(a) * RING_R
		var z := sin(a) * RING_R
		var w := _rng.randf_range(2.0, 2.6)
		var hh := _rng.randf_range(1.7, 2.2)
		_set_inst(mmi, slot, Vector3(x, hh * 0.5, z), -a + PI / 2, Vector3(w, hh, 1.5))
	# Bush tops for an untrimmed crown.
	var nb := 26
	for i in range(nb):
		var a := TAU * i / nb + 0.1
		var deg := rad_to_deg(a)
		if _near_gate(deg, 5.0):
			continue
		var x := cos(a) * RING_R
		var z := sin(a) * RING_R
		var b: Node3D = _put(_nature("Bush_Common"),
			Vector3(x, 1.6, z), _rng.randf_range(0, TAU))
		var sc := _rng.randf_range(1.2, 1.7)
		b.scale = Vector3(sc, sc * 0.8, sc)
	# Walkable collision: a segmented ring (skip gate gaps).
	for i in range(40):
		var a := TAU * i / 40
		var deg := rad_to_deg(a)
		if _near_gate(deg, 6.0):
			continue
		_solid(self, Vector3(cos(a) * RING_R, 1.0, sin(a) * RING_R),
			Vector3(9.0, 2.0, 2.0), -a + PI / 2)


func _gate(pos: Vector3) -> void:
	var g := Node3D.new()
	g.position = pos
	add_child(g)
	var timber := _solid_mat(Color(0.28, 0.20, 0.12))
	var iron := _solid_mat(Color(0.20, 0.20, 0.22), 3.0, 0.6)
	# Posts + lintel.
	_box(g, Vector3(-2.4, 1.75, 0), Vector3(0.5, 3.5, 0.5), timber)
	_box(g, Vector3(2.4, 1.75, 0), Vector3(0.5, 3.5, 0.5), timber)
	_box(g, Vector3(0, 3.6, 0), Vector3(5.8, 0.45, 0.6), timber)
	# Open gate leaves, swung inward.
	_box(g, Vector3(-1.7, 1.1, 1.3), Vector3(1.9, 2.2, 0.12), timber, 0.5)
	_box(g, Vector3(1.7, 1.1, 1.3), Vector3(1.9, 2.2, 0.12), timber, -0.5)
	_box(g, Vector3(-2.4, 3.9, 0), Vector3(0.7, 0.5, 0.7), iron)
	_box(g, Vector3(2.4, 3.9, 0), Vector3(0.7, 0.5, 0.7), iron)
	# Banners on the posts.
	_put(_props("Banner_1"), Vector3(-2.4, 2.9, 0.3), 0.0, g)
	_put(_props("Banner_1"), Vector3(2.4, 2.9, 0.3), 0.0, g)
	# Fence wings tying the gate into the hedge.
	for sx in [-1.0, 1.0]:
		for k in range(3):
			_put(_kit("Prop_WoodenFence_Single"),
				Vector3(sx * (3.4 + k * 2.05), 0, 0), PI / 2, g)
	_solid(g, Vector3(-2.4, 1.75, 0), Vector3(0.6, 3.5, 0.6))
	_solid(g, Vector3(2.4, 1.75, 0), Vector3(0.6, 3.5, 0.6))
	_block(pos.x - 4, pos.z - 3, pos.x + 4, pos.z + 3)


func _gates() -> void:
	_gate(Vector3(0, 0, -RING_R))
	_gate(Vector3(0, 0, RING_R))

# ---------------------------------------------------------- market square ---

func _market_square() -> void:
	var c := Vector2(0, 2)
	# Village well at the center.
	_put(_farm("Well"), Vector3(c.x, 0, c.y))
	_solid(self, Vector3(c.x, 1.0, c.y), Vector3(1.6, 2.0, 1.6))
	# Seven stalls in an arc around the well, facing it.
	var stalls := ["Stall_Empty", "Stall_Empty", "Stall_Cart_Empty", "Stall_Empty",
		"Stall_Cart_Empty", "Stall_Empty", "Stall_Empty"]
	for i in range(stalls.size()):
		var a := deg_to_rad(25.0 + i * 51.4)
		var px := c.x + cos(a) * 8.5
		var pz := c.y + sin(a) * 8.5
		var yaw := atan2(-(c.x - px), -(c.y - pz)) + PI
		var st: Node3D = _put(_props(stalls[i]), Vector3(px, 0, pz), yaw)
		_solid(st, Vector3(0, 1.0, 0), Vector3(2.2, 2.0, 1.4))
		_dress_stall(st)
	# Two physical boards (geometry only, nonfunctional).
	_board(Vector3(11, 0, 13), -0.4)
	_board(Vector3(-9, 0, -5), 0.5)
	# Benches, lamps, clutter.
	_put(_props("Bench"), Vector3(-6, 0, 9), 0.3)
	_put(_props("Bench"), Vector3(7, 0, 8), -0.4)
	_put(_props("Bench"), Vector3(2, 0, -4), 1.7)
	for lp in [Vector3(-12, 0, -6), Vector3(12, 0, -6), Vector3(-12, 0, 10), Vector3(12, 0, 10)]:
		_lamp_post(lp)
	_crate_cluster(Vector3(-10, 0, 4), 4)
	_crate_cluster(Vector3(9, 0, -3), 3)


func _dress_stall(st: Node3D) -> void:
	# Market goods in front of the stall counter.
	var kind := _rng.randi_range(0, 2)
	var goods := _props("FarmCrate_Apple") if kind == 0 else \
		(_props("FarmCrate_Carrot") if kind == 1 else _props("Barrel_Apples"))
	_put(goods, Vector3(_rng.randf_range(-0.8, 0.8), 0, 1.1), _rng.randf_range(0, TAU), st)
	_put(_props("Bag"), Vector3(1.2, 0, 0.6), _rng.randf_range(0, TAU), st)
	if _rng.randf() < 0.5:
		_put(_props("Barrel"), Vector3(-1.3, 0, 0.7), 0.0, st)


func _board(pos: Vector3, yaw: float) -> void:
	var b := Node3D.new()
	b.position = pos
	b.rotation.y = yaw
	add_child(b)
	var timber := _solid_mat(Color(0.28, 0.20, 0.12))
	_box(b, Vector3(-0.8, 1.1, 0), Vector3(0.14, 2.2, 0.14), timber)
	_box(b, Vector3(0.8, 1.1, 0), Vector3(0.14, 2.2, 0.14), timber)
	_box(b, Vector3(0, 1.35, 0), Vector3(1.9, 1.3, 0.1), timber)
	_box(b, Vector3(0, 2.15, 0), Vector3(2.1, 0.1, 0.5), timber)
	_solid(b, Vector3(0, 1.1, 0), Vector3(2.0, 2.2, 0.5))


func _lamp_post(pos: Vector3) -> void:
	var p := Node3D.new()
	p.position = pos
	add_child(p)
	var iron := _solid_mat(Color(0.18, 0.18, 0.20), 3.0, 0.6)
	_box(p, Vector3(0, 1.5, 0), Vector3(0.16, 3.0, 0.16), iron)
	_box(p, Vector3(0, 2.95, 0), Vector3(0.7, 0.12, 0.12), iron)
	_put(_props("Lantern_Wall"), Vector3(0, 2.1, 0.35), 0.0, p)
	_solid(p, Vector3(0, 1.5, 0), Vector3(0.3, 3.0, 0.3))


func _crate_cluster(pos: Vector3, n: int) -> void:
	var kinds := ["Crate_Wooden", "Crate_Wooden", "Barrel", "Barrel_Apples", "Bag"]
	for i in range(n):
		var k: String = kinds[_rng.randi_range(0, kinds.size() - 1)]
		_put(_props(k), Vector3(pos.x + _rng.randf_range(-1.2, 1.2), 0,
			pos.z + _rng.randf_range(-1.2, 1.2)), _rng.randf_range(0, TAU))


# ------------------------------------------------------- district buildings ---

func _district_buildings() -> void:
	_inn()
	_smithy()
	_chapel()
	_brewery()
	_granary_row()
	_carters_yard()


func _inn() -> void:
	# The Sheaf: 8x8 m plaster inn facing the square.
	_house(Vector3(-22, 0, 2), PI / 2, 4, 4,
		{"stoop": true, "vine": true, "chimney": true})
	var fx := -22 + 4 + 1.5  # front face x (faces +x after yaw)
	_put(_props("Bench"), Vector3(fx + 1.2, 0, -1), PI / 2)
	_put(_props("Table_Large"), Vector3(fx + 1.5, 0, 3), 0.2)
	_put(_props("Stool"), Vector3(fx + 1.0, 0, 4.4), 0.0)
	_put(_props("Barrel"), Vector3(fx + 0.8, 0, -3.4), 0.0)
	_put(_props("Barrel"), Vector3(fx + 1.6, 0, -3.1), 0.0)
	_lamp_post(Vector3(fx + 0.6, 0, 0.5))
	_inn_sign(Vector3(fx + 0.8, 0, -5.5))
	_crate_cluster(Vector3(-22, 0, 9), 3)


func _inn_sign(pos: Vector3) -> void:
	var s := Node3D.new()
	s.position = pos
	add_child(s)
	var timber := _solid_mat(Color(0.28, 0.20, 0.12))
	var wheat := _solid_mat(Color(0.72, 0.58, 0.30))
	_box(s, Vector3(0, 1.3, 0), Vector3(0.14, 2.6, 0.14), timber)
	_box(s, Vector3(0.45, 2.3, 0), Vector3(1.0, 0.12, 0.12), timber)
	# Hanging sheaf-sign: blank board with a wheat-sheaf bar.
	_box(s, Vector3(0.45, 1.75, 0), Vector3(0.9, 0.65, 0.08), timber)
	_box(s, Vector3(0.45, 1.75, 0.06), Vector3(0.5, 0.4, 0.02), wheat)


func _smithy() -> void:
	# 6x6 m brick smithy fronting the north road, forge gear outside.
	_house(Vector3(-10, 0, -28), PI / 2, 3, 3, {"brick": true, "chimney": true})
	var fx := -10 + 3 + 1.0
	_put(_props("Anvil_Log"), Vector3(fx + 1.5, 0, -28), 0.4)
	_put(_props("Anvil"), Vector3(fx + 2.6, 0, -26.5), -0.3)
	_put(_props("Whetstone"), Vector3(fx + 1.2, 0, -25.8), 0.9)
	_put(_props("Workbench"), Vector3(fx + 1.0, 0, -30.2), 1.65)
	_put(_props("Bucket_Metal"), Vector3(fx + 2.2, 0, -29.3), 0.0)
	_put(_props("Crate_Metal"), Vector3(fx + 0.6, 0, -24.6), 0.2)
	_block(fx - 1, -32, fx + 4, -24)


func _chapel() -> void:
	# Gleaner chapel: 6x8 m plaster + corner tower with spire roof.
	_house(Vector3(16, 0, -30), -PI / 2, 3, 4, {"stoop": true, "chimney": false})
	_tower(Vector3(23, 0, -35.5))
	_put(_props("Bench"), Vector3(11.5, 0, -27), -PI / 2)
	_put(_props("Bench"), Vector3(11.5, 0, -33), -PI / 2)
	_lamp_post(Vector3(11, 0, -30))
	_shrine(Vector3(28, 0, -25))


func _tower(pos: Vector3) -> void:
	var t := Node3D.new()
	t.position = pos
	add_child(t)
	var hw := 2.0
	for i in range(2):
		var x := -hw + 1.0 + 2.0 * i
		_put(_kit("Wall_Plaster_Straight"), Vector3(x, 0, hw), 0.0, t)
		_put(_kit("Wall_Plaster_Straight"), Vector3(x, 0, -hw), PI, t)
	for j in range(2):
		var z := -hw + 1.0 + 2.0 * j
		_put(_kit("Wall_Plaster_Window_Thin_Round"), Vector3(hw, 0, z), -PI / 2, t)
		_put(_kit("Wall_Plaster_Straight"), Vector3(-hw, 0, z), PI / 2, t)
	for cx in [-hw, hw]:
		for cz in [-hw, hw]:
			_put(_kit("Corner_Exterior_Wood"), Vector3(cx, 0, cz), 0.0, t)
	_put(_kit("Roof_Tower_RoundTiles"), Vector3(0, 3.12, 0), 0.0, t)
	# Simple cross finial.
	var timber := _solid_mat(Color(0.28, 0.20, 0.12))
	_box(t, Vector3(0, 10.6, 0), Vector3(0.18, 1.6, 0.18), timber)
	_box(t, Vector3(0, 10.8, 0), Vector3(0.9, 0.18, 0.18), timber)
	_solid(t, Vector3(0, 2.0, 0), Vector3(4.4, 4.0, 4.4))
	_block(pos.x - 3, pos.z - 3, pos.x + 3, pos.z + 3)


func _shrine(pos: Vector3) -> void:
	# Nonfunctional shrine stone with offerings (geometry only).
	var s := Node3D.new()
	s.position = pos
	s.rotation.y = 0.4
	add_child(s)
	var rock := _solid_mat(Color(0.42, 0.42, 0.40), 4.0)
	_box(s, Vector3(0, 1.05, 0), Vector3(0.9, 2.3, 0.65), rock, 0.0,
		Vector3(0.06, 0, 0.04))
	_box(s, Vector3(0.8, 0.15, 0.4), Vector3(0.5, 0.3, 0.4), rock, 0.7)
	_box(s, Vector3(-0.7, 0.12, -0.3), Vector3(0.4, 0.24, 0.35), rock, 1.9)
	_put(_props("Mug"), Vector3(0.35, 0.32, 0.75), 0.0, s)
	_put(_props("Pouch_Large"), Vector3(-0.3, 0.30, 0.7), 1.2, s)
	_put(_props("Pouch_Large"), Vector3(0.05, 0.30, 0.95), 2.6, s)
	# Corn-dolly: crossed bound wheat sticks leaning on the stone.
	var wheat := _solid_mat(Color(0.72, 0.58, 0.30))
	_box(s, Vector3(-0.55, 0.5, 0.45), Vector3(0.07, 1.0, 0.07), wheat, 0.0,
		Vector3(0.0, 0, 0.35))
	_box(s, Vector3(-0.55, 0.62, 0.45), Vector3(0.55, 0.07, 0.07), wheat, 0.0,
		Vector3(0.0, 0, 0.35))
	_solid(s, Vector3(0, 1.0, 0), Vector3(1.4, 2.0, 1.2))


func _brewery() -> void:
	# 6x8 m brick brewery, vats and barrels outside.
	_house(Vector3(22, 0, 30), -PI / 2, 3, 4, {"brick": true, "chimney": true})
	var fx := 22 - 3 - 1.0
	_put(_props("Cauldron"), Vector3(fx - 1.5, 0, 28), 0.0)
	_put(_props("Pot_1"), Vector3(fx - 1.2, 0, 30.5), 0.0)
	_put(_props("Barrel"), Vector3(fx - 1.0, 0, 32.5), 0.0)
	_put(_props("Barrel"), Vector3(fx - 2.0, 0, 32.0), 0.0)
	_put(_props("Barrel_Holder"), Vector3(fx - 2.8, 0, 29), 0.3)
	_put(_props("Crate_Wooden"), Vector3(fx - 0.8, 0, 26.5), 0.5)
	_block(fx - 4, 26, fx + 1, 34)


func _granary_row() -> void:
	# Three tall silos — the town's navigation silhouette — plus a big barn.
	for i in range(3):
		var p := Vector3(34, 0, -6 + i * 8)
		_put(_farm("Silo"), p, 0.15 * i)
		_solid(self, p + Vector3(0, 4.5, 0), Vector3(3.8, 9.0, 3.8))
	_block(31, -9, 37, 13)
	_put(_farm("BigBarn"), Vector3(34, 0, -17), PI / 2)
	_solid(self, Vector3(34, 2.5, -17), Vector3(9.0, 5.0, 8.5), PI / 2)
	_block(29, -22, 39, -12)
	_crate_cluster(Vector3(30, 0, 4), 5)
	_put(_props("Barrel"), Vector3(30.5, 0, -2), 0.0)
	# Fence rails edging the yard.
	for k in range(4):
		_put(_farm("Fence"), Vector3(28.5, 0, -10 + k * 5.9), PI / 2)


func _carters_yard() -> void:
	# Open barn, wagon, paddock.
	_put(_farm("OpenBarn"), Vector3(-26, 0, 33), 0.2)
	_solid(self, Vector3(-26, 2.0, 33), Vector3(6.5, 4.0, 7.0), 0.2)
	_put(_kit("Prop_Wagon"), Vector3(-19, 0, 30), 1.1)
	_put(_props("Crate_Wooden"), Vector3(-23, 0, 29.5), 0.4)
	_put(_props("Rope_1"), Vector3(-21.5, 0.85, 32.5), 0.0)
	# Paddock fence rectangle.
	var x0 := -34.0
	var x1 := -16.0
	var z0 := 26.0
	var z1 := 40.0
	var w := x1 - x0
	var d := z1 - z0
	for k in range(int(w / 5.9) + 1):
		_put(_farm("Fence"), Vector3(x0 + k * 5.9, 0, z0), PI / 2)
		_put(_farm("Fence"), Vector3(x0 + k * 5.9, 0, z1), PI / 2)
	for k in range(int(d / 5.9) + 1):
		_put(_farm("Fence"), Vector3(x0, 0, z0 + k * 5.9), 0.0)
		_put(_farm("Fence"), Vector3(x1, 0, z0 + k * 5.9), 0.0)
	_block(x0 - 1, z0 - 1, x1 + 1, z1 + 1)

# ----------------------------------------------------------------- cottages ---

func _cottages() -> void:
	# Eight cottages along the lane and the north road, varied.
	_cottage(Vector3(-12, 0, 28), PI, 3, 4, false, true)    # faces lane
	_cottage(Vector3(8, 0, 28), PI, 3, 3, false, false)
	_cottage(Vector3(-32, 0, 8), -PI / 2, 3, 4, false, true)
	_cottage(Vector3(-32, 0, -12), -PI / 2, 3, 3, true, false)
	_cottage(Vector3(20, 0, -14), PI / 2, 3, 4, false, false)
	_cottage(Vector3(-10, 0, -16), -PI / 2, 3, 3, false, true)
	_cottage(Vector3(10, 0, -22), PI / 2, 3, 4, true, false)
	_cottage(Vector3(30, 0, 24), PI / 2, 3, 3, false, false)


func _cottage(pos: Vector3, yaw: float, wm: int, dm: int, brick: bool, vine: bool) -> void:
	var h: Node3D = _house(pos, yaw, wm, dm,
		{"brick": brick, "vine": vine, "chimney": _rng.randf() < 0.7})
	# Door-side clutter in local space.
	var hd := float(dm)
	var fx := Vector3(0, 0, hd + 1.6)
	var kinds := [_props("Barrel"), _props("Crate_Wooden"), _props("Bucket_Wooden_1")]
	_put(kinds[_rng.randi_range(0, 2)], h.position + fx.rotated(Vector3.UP, yaw),
		_rng.randf_range(0, TAU))
	if _rng.randf() < 0.4:
		_put(_props("Bench"), h.position + (fx + Vector3(1.6, 0, 0.4)).rotated(Vector3.UP, yaw),
			yaw + PI / 2 + _rng.randf_range(-0.2, 0.2))
	# Fence bits edging the plot.
	if _rng.randf() < 0.6:
		var dir := Vector3(1, 0, 0).rotated(Vector3.UP, yaw)
		for k in range(3):
			_put(_kit("Prop_WoodenFence_Single"),
				pos + dir * (4.5 + k * 2.05) + Vector3(0, 0, hd * 0.4).rotated(Vector3.UP, yaw),
				yaw + PI / 2)
	# Washing line behind some cottages.
	if _rng.randf() < 0.35:
		_washing_line(pos + Vector3(0, 0, -hd - 3.5).rotated(Vector3.UP, yaw), yaw)


func _washing_line(pos: Vector3, yaw: float) -> void:
	var w := Node3D.new()
	w.position = pos
	w.rotation.y = yaw
	add_child(w)
	var wood := _solid_mat(Color(0.30, 0.22, 0.14))
	_box(w, Vector3(-1.6, 0.85, 0), Vector3(0.1, 1.7, 0.1), wood)
	_box(w, Vector3(1.6, 0.85, 0), Vector3(0.1, 1.7, 0.1), wood)
	_box(w, Vector3(-0.8, 1.62, 0), Vector3(1.65, 0.03, 0.03), wood, 0.0, Vector3(0, 0, 0.06))
	_box(w, Vector3(0.8, 1.62, 0), Vector3(1.65, 0.03, 0.03), wood, 0.0, Vector3(0, 0, -0.06))
	var cloths := [Color(0.82, 0.78, 0.68), Color(0.65, 0.60, 0.50), Color(0.75, 0.70, 0.60)]
	for i in range(3):
		var cm := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.55, 0.7)
		cm.mesh = qm
		cm.material_override = _solid_mat(cloths[i], 2.0)
		cm.position = Vector3(-1.0 + i * 1.0, 1.25, 0)
		w.add_child(cm)


# --------------------------------------------------------------- vance farm ---

func _vance_farm() -> void:
	# Farmstead south of the hedge: barn, small barn, paddock, coop, well.
	_put(_farm("Barn"), Vector3(16, 0, 80), 0.3)
	_solid(self, Vector3(16, 2.5, 80), Vector3(8.5, 5.0, 9.0), 0.3)
	_put(_farm("SmallBarn"), Vector3(29, 0, 84), -0.25)
	_solid(self, Vector3(29, 2.0, 84), Vector3(7.0, 4.0, 7.0), -0.25)
	_put(_farm("ChickenCoop"), Vector3(24, 0, 74), 1.2)
	_put(_farm("Well"), Vector3(20, 0, 77))
	_solid(self, Vector3(20, 1.0, 77), Vector3(1.6, 2.0, 1.6))
	_put(_props("Crate_Wooden"), Vector3(13, 0, 76), 0.5)
	_put(_props("Barrel"), Vector3(33, 0, 80), 0.0)
	var x0 := 8.0
	var x1 := 38.0
	var z0 := 70.0
	var z1 := 92.0
	for k in range(int((x1 - x0) / 5.9) + 1):
		_put(_farm("Fence"), Vector3(x0 + k * 5.9, 0, z0), PI / 2)
		_put(_farm("Fence"), Vector3(x0 + k * 5.9, 0, z1), PI / 2)
	for k in range(int((z1 - z0) / 5.9) + 1):
		_put(_farm("Fence"), Vector3(x0, 0, z0 + k * 5.9), 0.0)
		_put(_farm("Fence"), Vector3(x1, 0, z0 + k * 5.9), 0.0)
	_block(x0 - 1, z0 - 1, x1 + 1, z1 + 1)


# ---------------------------------------------------------------- burnt mill ---

func _burnt_mill() -> void:
	# The burnt mill, ~80 m north: charred windmill, dead trees, rubble.
	var p := Vector3(-14, 0, -135)
	var mill: Node3D = _put(_farm("Windmill"), p, -0.4)
	_char(mill)
	mill.rotation.z = 0.07 # fire-weakened lean
	_solid(self, p + Vector3(0, 5, 0), Vector3(7.0, 10.0, 3.0), -0.4)
	# Scorched earth: flat dark disc, not a hard-edged square.
	var disc := CylinderMesh.new()
	disc.top_radius = 9.0
	disc.bottom_radius = 9.0
	disc.height = 0.05
	var scorch := MeshInstance3D.new()
	scorch.mesh = disc
	scorch.material_override = _solid_mat(Color(0.16, 0.14, 0.12), 8.0, 1.0)
	scorch.position = p + Vector3(0, 0.025, 0)
	add_child(scorch)
	_put(_nature("DeadTree_1"), p + Vector3(-7, 0, 4), 0.8)
	_put(_nature("DeadTree_2"), p + Vector3(6, 0, -5), 2.2)
	for i in range(6):
		_char(_put(_kit("Prop_Brick1"),
			p + Vector3(_rng.randf_range(-5, 5), 0, _rng.randf_range(-5, 5)),
			_rng.randf_range(0, TAU)))
	_block(p.x - 10, p.z - 10, p.x + 10, p.z + 10)


func _char(inst: Node3D) -> void:
	var char_mat := _solid_mat(Color(0.13, 0.11, 0.10), 2.0, 0.95)
	var stack: Array = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			(n as MeshInstance3D).material_override = char_mat
		for c in n.get_children():
			stack.append(c)


# --------------------------------------------------------------- delve mouth ---

func _delve_mouth() -> void:
	# Simple cold landmark far NE: dark stone ring around a black pit.
	var p := Vector3(120, 0, -115)
	var cold := _solid_mat(Color(0.36, 0.39, 0.45), 4.0)
	var dark := _solid_mat(Color(0.22, 0.24, 0.30), 4.0)
	for i in range(7):
		var a := TAU * i / 7
		var tilt := _rng.randf_range(0.08, 0.22)
		_box(self, p + Vector3(cos(a) * 4.5, 1.6, sin(a) * 4.5),
			Vector3(1.1, 4.2, 1.1), cold, -a, Vector3(tilt, 0, 0))
	_quad(p + Vector3(0, 0.06, 0), Vector2(7.5, 7.5),
		_solid_mat(Color(0.03, 0.035, 0.05), 2.0, 1.0))
	_quad(p + Vector3(0, 0.03, 0), Vector2(14, 14),
		_ground_mat(Color(0.30, 0.32, 0.34), 12.0))
	_solid(self, p + Vector3(0, 1.0, 0), Vector3(7, 2.0, 7))
	_block(p.x - 8, p.z - 8, p.x + 8, p.z + 8)


# ------------------------------------------------------------------- nature ---

func _orchard() -> void:
	# Orchard wood, west wedge: rows of fruit trees.
	var variants := ["CommonTree_1", "CommonTree_2", "CommonTree_3", "CommonTree_4", "CommonTree_5"]
	for ix in range(6):
		for iz in range(5):
			var x := -115.0 + ix * 9.0 + _rng.randf_range(-1.5, 1.5)
			var z := -22.0 + iz * 9.0 + _rng.randf_range(-1.5, 1.5)
			var t: Node3D = _put(_nature(variants[_rng.randi_range(0, 4)]),
				Vector3(x, 0, z), _rng.randf_range(0, TAU))
			var s := _rng.randf_range(0.85, 1.2)
			t.scale = Vector3(s, s, s)
			_solid(self, Vector3(x, 1.5, z), Vector3(0.8, 3.0, 0.8))


func _scatter() -> void:
	# Grass tufts and ferns inside the ring; pines on the far horizon.
	var tufts := ["Grass_Common_Tall", "Grass_Wispy_Tall", "Fern_1"]
	for i in range(110):
		var a := _rng.randf_range(0, TAU)
		var r := _rng.randf_range(8, 52)
		var x := cos(a) * r
		var z := sin(a) * r
		if _blocked(x, z, 0.5):
			continue
		if abs(x) < 3.5 and abs(z) < 56.0:  # main road
			continue
		if abs(z - 18.0) < 3.0 and abs(x) < 52.0:  # lane
			continue
		_put(_nature(tufts[_rng.randi_range(0, 2)]), Vector3(x, 0, z),
			_rng.randf_range(0, TAU))
	# A few shade trees inside the ring.
	for i in range(7):
		var a := _rng.randf_range(0, TAU)
		var r := _rng.randf_range(38, 50)
		var x := cos(a) * r
		var z := sin(a) * r
		if _blocked(x, z, 3.0):
			continue
		var t: Node3D = _put(_nature("CommonTree_%d" % _rng.randi_range(1, 5)),
			Vector3(x, 0, z), _rng.randf_range(0, TAU))
		var s := _rng.randf_range(0.9, 1.3)
		t.scale = Vector3(s, s, s)
		_solid(self, Vector3(x, 1.5, z), Vector3(0.8, 3.0, 0.8))
	# Pines on the far horizon for depth.
	for i in range(26):
		var a := _rng.randf_range(0, TAU)
		var r := _rng.randf_range(150, 230)
		var x := cos(a) * r
		var z := sin(a) * r
		var t: Node3D = _put(_nature("Pine_%d" % _rng.randi_range(1, 3)),
			Vector3(x, 0, z), _rng.randf_range(0, TAU))
		var s := _rng.randf_range(1.2, 2.0)
		t.scale = Vector3(s, s, s)
	# Stepping stones at the gates.
	for gz in [-RING_R, RING_R]:
		for k in range(4):
			_put(_nature("RockPath_Round_Wide"),
				Vector3(_rng.randf_range(-1, 1), 0, gz + (k - 1.5) * 2.2),
				_rng.randf_range(0, TAU))
