class_name WgLandmark
extends RefCounted
## The things between the places.
##
## `tech.md` §1a: "generate the country between towns; hand-place only
## what players will remember." This is the half of that sentence the
## generator is allowed to do — not the delve mouth that a quest hangs
## off, but the standing stones you navigate by and the burnt wagon you
## tell somebody about.
##
## It matters more here than it would in most worlds because of L86:
## there is no minimap, the land carries orientation, and orientation
## needs things to orient BY. Six biomes of empty country all look the
## same once you are standing in them.
##
## Rarer than settlements and on a finer grid, so the country has
## something in it without having something in it everywhere.

const KIT := "res://assets/town/kit/"
const PROPS := "res://assets/town/props/"
const NATURE := "res://assets/town/nature/"

const CELL := 340.0
const CHANCE := 0.30
## Landmarks sit on ground you could stand on, but not only on the flat
## — a stone ring on a shoulder of hill is better than one in a bowl.
const MAX_SLOPE := 0.22


static func cell_rng(world_seed: int, cx: int, cz: int, layer: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var h: int = world_seed ^ 0x2f9a1c73
	h = (h * 73856093) ^ (cx * 19349663) ^ (cz * 83492791) ^ (layer * 2654435761)
	h = h ^ (h >> 13)
	h = h * 1274126177
	rng.seed = absi(h)
	return rng


## What stands in this cell, if anything: { pieces, keep_clear, kind, at }.
## Cached per cell, for the same reason WgSettlement is: a chunk asks
## about nine cells and eight of the answers belong to its neighbours.
## Guarded for the same reason WgSettlement's is: chunks are prepared
## on worker threads, and a Dictionary read during another thread's
## write fails intermittently and looks like a generator bug.
const CACHE_MAX := 512
static var _cache: Dictionary = {}
static var _lock := Mutex.new()

static func cached(terrain: WgTerrain, world_seed: int, cx: int, cz: int) -> Dictionary:
	var key := "%d:%d:%d" % [world_seed, cx, cz]
	_lock.lock()
	var hit: bool = _cache.has(key)
	var got: Dictionary = _cache[key] if hit else {}
	_lock.unlock()
	if hit:
		return got

	var out := at_cell(terrain, world_seed, cx, cz)
	_lock.lock()
	if _cache.size() > CACHE_MAX:
		_cache.clear()
	_cache[key] = out
	_lock.unlock()
	return out


static func at_cell(terrain: WgTerrain, world_seed: int, cx: int, cz: int) -> Dictionary:
	var rng := cell_rng(world_seed, cx, cz, 0)
	if rng.randf() > CHANCE:
		return {}

	var x := (float(cx) + rng.randf_range(0.2, 0.8)) * CELL
	var z := (float(cz) + rng.randf_range(0.2, 0.8)) * CELL
	if terrain.slope_at(x, z, 4.0) > MAX_SLOPE:
		return {}
	# Not standing in a river. A stone circle is put up on dry ground
	# and a camp is pitched on it; the pieces reach out about 20 m from
	# the centre, so the margin covers the water plus its banks.
	if terrain.river_distance(x, z) < 40.0:
		return {}
	# Not inside the capitol, which is built rather than found.
	if terrain.capitol_blend(x, z) > 0.3:
		return {}

	var at := Vector3(x, terrain.height_at(x, z), z)
	var out := {"pieces": [], "keep_clear": [], "at": at, "kind": ""}
	var b := terrain.biome_at(x, z)

	var roll := rng.randf()
	if roll < 0.28:
		out["kind"] = "stones"
		_stones(out, terrain, at, rng)
	elif roll < 0.50:
		out["kind"] = "camp"
		_camp(out, terrain, at, rng)
	elif roll < 0.70:
		out["kind"] = "shrine"
		_shrine(out, terrain, at, rng)
	elif roll < 0.86:
		out["kind"] = "tower"
		_tower(out, terrain, at, rng)
	else:
		out["kind"] = "boulders"
		_boulders(out, terrain, at, rng, b)
	return out


## A ring of standing stones. The clearest thing to navigate by that
## costs nothing but rocks.
static func _stones(out: Dictionary, terrain: WgTerrain, at: Vector3,
		rng: RandomNumberGenerator) -> void:
	var n := rng.randi_range(5, 9)
	var r := rng.randf_range(5.0, 9.0)
	var turn := rng.randf() * TAU
	for i in n:
		var ang: float = turn + float(i) / float(n) * TAU + rng.randf_range(-0.1, 0.1)
		var p := at + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		p.y = terrain.height_at(p.x, p.z)
		# A ROUGH STONE SLAB STOOD ON END, not a rock scaled upward.
		#
		# The first two attempts used RockPath_Round_Wide, which is a
		# path of pebbles rather than a boulder — so scaling it
		# vertically made taller pebbles, and the circle rendered as a
		# gravel patch twice running. The pack has no menhir. An
		# uneven-brick wall slab, narrowed and leaned, is the nearest
		# honest thing in the library: it is stone, it stands, and at
		# the distance a landmark is read from it does the job.
		out["pieces"].append({
			"path": KIT + "Wall_UnevenBrick_Straight.gltf",
			"position": p,
			"yaw": ang + PI * 0.5 + rng.randf_range(-0.25, 0.25),
			"scale": Vector3(
				rng.randf_range(0.30, 0.52),
				rng.randf_range(0.85, 1.45),
				rng.randf_range(0.30, 0.52)),
		})
	out["keep_clear"].append(Rect2(at.x - r - 4.0, at.z - r - 4.0,
		(r + 4.0) * 2.0, (r + 4.0) * 2.0))


## Somebody stopped here, and did not move on.
static func _camp(out: Dictionary, terrain: WgTerrain, at: Vector3,
		rng: RandomNumberGenerator) -> void:
	const GEAR := ["Prop_Wagon", "Barrel", "Crate_Wooden", "Cauldron",
		"Bag", "Pouch_Large", "Bucket_Wooden_1", "Chest_Wood", "Stool",
		"Torch_Metal", "Rope_1", "Pot_1"]
	var n := rng.randi_range(4, 9)
	for i in n:
		var ang := rng.randf() * TAU
		var d := rng.randf_range(0.5, 6.0)
		var p := at + Vector3(cos(ang) * d, 0.0, sin(ang) * d)
		p.y = terrain.height_at(p.x, p.z)
		var stem: String = GEAR[rng.randi() % GEAR.size()]
		var path := PROPS + stem + ".gltf"
		if stem == "Prop_Wagon":
			path = KIT + stem + ".gltf"
		out["pieces"].append({
			"path": path, "position": p,
			"yaw": rng.randf() * TAU, "scale": 1.0,
		})
	out["keep_clear"].append(Rect2(at.x - 9.0, at.z - 9.0, 18.0, 18.0))


## A wayshrine: somewhere to stop on a road that has no inn.
static func _shrine(out: Dictionary, terrain: WgTerrain, at: Vector3,
		rng: RandomNumberGenerator) -> void:
	var yaw: float = round(rng.randf() * 4.0) * (PI * 0.5)
	var basis := Basis(Vector3.UP, yaw)
	var put := func(path: String, local: Vector3, extra: float) -> void:
		out["pieces"].append({
			"path": path, "position": at + basis * local,
			"yaw": yaw + extra, "scale": 1.0,
		})
	# Three walls and an arch, open to the road.
	put.call(KIT + "Wall_Arch.gltf", Vector3(0, 0, 2.0), 0.0)
	put.call(KIT + "Wall_Plaster_Straight.gltf", Vector3(0, 0, -2.0), PI)
	put.call(KIT + "Wall_Plaster_Straight.gltf", Vector3(2.0, 0, 0), -PI * 0.5)
	put.call(KIT + "Wall_Plaster_Straight.gltf", Vector3(-2.0, 0, 0), PI * 0.5)
	for cx in [-2.0, 2.0]:
		for cz in [-2.0, 2.0]:
			put.call(KIT + "Corner_Exterior_Wood.gltf", Vector3(cx, 0, cz), 0.0)
	put.call(PROPS + "CandleStick.gltf", Vector3(0, 0, -1.2), 0.0)
	if rng.randf() < 0.6:
		put.call(PROPS + "Banner_1.gltf", Vector3(1.6, 0, -1.6), 0.0)
	if rng.randf() < 0.5:
		put.call(PROPS + "Torch_Metal.gltf", Vector3(-1.6, 0, 1.4), 0.0)
	out["keep_clear"].append(Rect2(at.x - 7.0, at.z - 7.0, 14.0, 14.0))


## A tower, alone. Visible a long way, which is the whole job.
static func _tower(out: Dictionary, terrain: WgTerrain, at: Vector3,
		rng: RandomNumberGenerator) -> void:
	var yaw: float = round(rng.randf() * 4.0) * (PI * 0.5)
	var basis := Basis(Vector3.UP, yaw)
	var brick := rng.randf() < 0.6
	var wall := ("Wall_UnevenBrick" if brick else "Wall_Plaster") + "_Straight"
	var corner := "Corner_Exterior_Brick" if brick else "Corner_Exterior_Wood"
	var put := func(path: String, local: Vector3, extra: float) -> void:
		out["pieces"].append({
			"path": path, "position": at + basis * local,
			"yaw": yaw + extra, "scale": 1.0,
		})
	var hw := 2.0
	# Two storeys of a 2x2 shaft, then the tower roof.
	for level in [0.0, 3.12]:
		for i in 2:
			var o := -hw + 1.0 + 2.0 * float(i)
			put.call(KIT + wall + ".gltf", Vector3(o, level, hw), 0.0)
			put.call(KIT + wall + ".gltf", Vector3(o, level, -hw), PI)
			put.call(KIT + wall + ".gltf", Vector3(hw, level, o), -PI * 0.5)
			put.call(KIT + wall + ".gltf", Vector3(-hw, level, o), PI * 0.5)
		for cx in [-hw, hw]:
			for cz in [-hw, hw]:
				put.call(KIT + corner + ".gltf", Vector3(cx, level, cz), 0.0)
	put.call(KIT + "Roof_Tower_RoundTiles.gltf", Vector3(0, 6.24, 0), 0.0)
	out["keep_clear"].append(Rect2(at.x - 8.0, at.z - 8.0, 16.0, 16.0))


## Where the ground gave up its bones. Biome-flavoured: the moor and the
## high pines have them, the fen does not.
static func _boulders(out: Dictionary, terrain: WgTerrain, at: Vector3,
		rng: RandomNumberGenerator, b) -> void:
	if b.rock_density < 0.12:
		return
	var n := rng.randi_range(8, 18)
	for i in n:
		var ang := rng.randf() * TAU
		var d := rng.randf_range(0.0, 11.0)
		var p := at + Vector3(cos(ang) * d, 0.0, sin(ang) * d)
		p.y = terrain.height_at(p.x, p.z)
		const ROCKS := ["RockPath_Round_Small_1", "RockPath_Round_Small_2",
			"RockPath_Round_Wide"]
		out["pieces"].append({
			"path": NATURE + ROCKS[rng.randi() % ROCKS.size()] + ".gltf",
			"position": p, "yaw": rng.randf() * TAU,
			"scale": rng.randf_range(1.2, 3.4),
		})
	out["keep_clear"].append(Rect2(at.x - 13.0, at.z - 13.0, 26.0, 26.0))
