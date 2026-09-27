class_name WgSettlement
extends RefCounted
## Places people built: a street, houses along it, and the clutter of
## somebody living there.
##
## Same contract as WgScatter — hashed from the settlement cell, not
## drawn from a running stream — and the same reason. A hamlet must be
## the same hamlet every time the world streams past it, or it is not a
## place, it is weather.
##
## Buildings come from the modular kit (`assets/town/kit/`), which is
## `tech.md` §1's "modular kits over bespoke geometry" taken literally:
## the variation is in layout, material, roofline and wear, not in
## unique geometry nobody has time to model. A house is walls on a 2 m
## grid, corners, a roof, and whatever the owner leaves outside.

const KIT := "res://assets/town/kit/"
const PROPS := "res://assets/town/props/"
const NATURE := "res://assets/town/nature/"

## Metres per settlement cell. One candidate hamlet per cell.
const CELL := 900.0
## How many candidate cells actually get a hamlet.
const CHANCE := 0.55
## Nothing is built on a slope this steep.
const MAX_SLOPE := 0.11
## How far the flattest-spot search looks, and how finely.
const SEARCH := 7

## Roofs exist as 6x6, 6x8 and 8x8 only — there is no 8x6 in the kit.
## So a house is 3x3, 3x4 or 4x4 modules and the long axis is depth.
## Found by asking for `Roof_RoundTiles_8x6` and getting nothing, which
## is a missing roof rather than an error.
const PLANS := [Vector2i(3, 3), Vector2i(3, 4), Vector2i(4, 4)]


## Everything a settlement is made of.
class Built extends RefCounted:
	## { path, position, yaw, scale }
	var pieces: Array = []
	## Rect2(x, z, w, d) in world space — scatter stays out of these.
	var keep_clear: Array = []
	## { position, size } boxes you cannot walk through.
	var solids: Array = []
	## Where smoke should come from.
	var chimneys: Array = []
	var name := ""
	var kind := ""
	var centre := Vector3.ZERO
	var houses := 0


static func cell_rng(world_seed: int, cx: int, cz: int, layer: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var h: int = world_seed ^ 0x5bf03635
	h = (h * 73856093) ^ (cx * 19349663) ^ (cz * 83492791) ^ (layer * 2654435761)
	h = h ^ (h >> 13)
	h = h * 1274126177
	rng.seed = absi(h)
	return rng


## Is there a hamlet in this cell, and where? Null if not.
##
## Separate from building it, because a chunk needs to know about
## settlements in NEIGHBOURING cells too — a hamlet near a cell border
## puts houses and keep-clear rects over the line, and a chunk that only
## asked about its own cell would grow trees through its neighbour's
## walls.
## BUILT ONCE PER CELL, not once per chunk that asks.
##
## A chunk sweeps its own settlement cell and the eight around it,
## because a hamlet near a border reaches over the line. That is
## correct and it meant every hamlet was sited and built up to NINE
## times — nine flattest-spot searches, nine sets of houses — and all
## but one chunk threw the result away.
##
## Deterministic output is cacheable output: the same cell always gives
## the same hamlet, so it only has to be worked out once. Bounded,
## because a walk across the world would otherwise keep every
## settlement it ever passed.
const CACHE_MAX := 512
static var _cache: Dictionary = {}

static func cached(terrain: WgTerrain, world_seed: int, cx: int, cz: int) -> Built:
	var key := "%d:%d:%d" % [world_seed, cx, cz]
	if _cache.has(key):
		return _cache[key]
	var found := site(terrain, world_seed, cx, cz)
	var out := build(terrain, world_seed, found) if not found.is_empty() else Built.new()
	if _cache.size() > CACHE_MAX:
		_cache.clear()
	_cache[key] = out
	return out


static func site(terrain: WgTerrain, world_seed: int, cx: int, cz: int) -> Dictionary:
	var rng := cell_rng(world_seed, cx, cz, 0)
	if rng.randf() > CHANCE:
		return {}

	# Somewhere in the cell, then walked to the flattest ground nearby.
	# People build on the level, and a house on a hillside floats at one
	# corner and buries itself at the other.
	var wx := (float(cx) + rng.randf_range(0.25, 0.75)) * CELL
	var wz := (float(cz) + rng.randf_range(0.25, 0.75)) * CELL
	var best := Vector2(wx, wz)
	var best_slope := 999.0
	for i in SEARCH:
		for j in SEARCH:
			var px: float = wx + (float(i) / float(SEARCH - 1) - 0.5) * CELL * 0.5
			var pz: float = wz + (float(j) / float(SEARCH - 1) - 0.5) * CELL * 0.5
			var s := terrain.slope_at(px, pz, 6.0)
			if s < best_slope:
				best_slope = s
				best = Vector2(px, pz)

	if best_slope > MAX_SLOPE:
		return {}
	# Not in the capitol's own ground: that is a city, hand-placed.
	if terrain.capitol_blend(best.x, best.y) > 0.25:
		return {}
	# And not on a TOWN SITE. The six sites are levelled ground waiting
	# for one of lore.md §5's towns, and a procedural hamlet standing
	# in the middle of where Hammarsted goes is a collision that would
	# only be discovered when somebody tried to put Hammarsted there.
	for w in WgTerrain.WEDGES:
		if Vector2(best.x, best.y).distance_to(
				Vector2(terrain.town_site(w).x, terrain.town_site(w).z)) \
				< WgTerrain.TOWN_FLAT + WgTerrain.TOWN_SKIRT:
			return {}

	return {
		"at": Vector3(best.x, terrain.height_at(best.x, best.y), best.y),
		"cell": Vector2i(cx, cz),
		"slope": best_slope,
	}


## Build the hamlet whose site this is.
static func build(terrain: WgTerrain, world_seed: int, found: Dictionary) -> Built:
	var out := Built.new()
	if found.is_empty():
		return out
	var cell: Vector2i = found["cell"]
	var at: Vector3 = found["at"]
	var rng := cell_rng(world_seed, cell.x, cell.y, 1)

	out.centre = at
	out.name = _name_for(rng)

	# WHAT KIND OF PLACE.
	#
	# Every settlement used to be the same shape — a street with houses
	# down both sides — which meant that whatever the terrain did, the
	# built world read as one idea repeated. Diversity in the country
	# without diversity in what people put on it is half a world.
	#
	# Weighted rather than uniform: a street is still the commonest
	# thing, because most places really are somewhere the road widened.
	# The wedge leans the odds. lore.md §5 calls the Wistwood "old
	# forest with older ruins", and a wedge whose description says
	# ruins should have more of them than the horse plains do — a
	# biome that differs only in tree species is a palette, not a
	# place.
	var bias: float = terrain.biome_at(at.x, at.z).ruin_bias
	# SHIFTED UP, not scaled down. The first cut multiplied the roll by
	# (1 - bias), which shrinks it toward the LOW end — and the low end
	# is "street". So the wedge described as having older ruins in it
	# got fewer ruins than the horse plains, exactly inverted, which
	# the check caught by comparing the two.
	var roll := clampf(rng.randf() + bias, 0.0, 0.999)
	if roll < 0.44:
		out.kind = "street"
		_street_village(out, terrain, at, rng)
	elif roll < 0.66:
		out.kind = "ring"
		_ring_village(out, terrain, at, rng)
	elif roll < 0.84:
		out.kind = "farmstead"
		_farmstead(out, terrain, at, rng)
	else:
		out.kind = "ruin"
		_ruin(out, terrain, at, rng)
	return out


## Somewhere the road widened. The commonest kind.
static func _street_village(out: Built, terrain: WgTerrain, at: Vector3,
		rng: RandomNumberGenerator) -> void:
	var street := rng.randf() * TAU
	var along := Vector3(cos(street), 0.0, sin(street))
	var across := Vector3(-sin(street), 0.0, cos(street))
	var count := rng.randi_range(3, 7)
	var spacing := 15.0

	# Which way the whole hamlet leans in material, so one is brick and
	# the next is plaster rather than every one a mixture of both.
	var mostly_brick := rng.randf() < 0.45

	var offset: float = -float(count - 1) * 0.5 * spacing
	for i in count:
		var side: int = 1 if (i % 2 == 0) else -1
		var down: float = offset + float(i) * spacing + rng.randf_range(-2.5, 2.5)
		var out_by: float = rng.randf_range(9.0, 13.0)
		var pos: Vector3 = at + along * down + across * float(side) * out_by
		pos.y = terrain.height_at(pos.x, pos.z)
		# Facing the street: the front wall looks back across.
		var yaw: float = street + (PI * 0.5 if side > 0 else -PI * 0.5)
		# Snapped to right angles, because the kit's corner pieces and
		# the keep-clear rect both assume it.
		yaw = round(yaw / (PI * 0.5)) * (PI * 0.5)
		var plan: Vector2i = PLANS[rng.randi() % PLANS.size()]
		var brick: bool = rng.randf() < (0.75 if mostly_brick else 0.25)
		_house(out, pos, yaw, plan.x, plan.y, brick, rng)
		out.houses += 1

	_street_props(out, terrain, at, along, across, float(count) * spacing, rng)


## Houses round a green, facing in. A place with a middle.
static func _ring_village(out: Built, terrain: WgTerrain, at: Vector3,
		rng: RandomNumberGenerator) -> void:
	var count := rng.randi_range(5, 8)
	var r := rng.randf_range(20.0, 28.0)
	var turn := rng.randf() * TAU
	var mostly_brick := rng.randf() < 0.45
	for i in count:
		var ang: float = turn + float(i) / float(count) * TAU
		var pos: Vector3 = at + Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		pos.y = terrain.height_at(pos.x, pos.z)
		# Facing the green, snapped to right angles because the kit's
		# corners and the keep-clear rect both assume it.
		var yaw: float = atan2(-(at.x - pos.x), -(at.z - pos.z))
		yaw = round(yaw / (PI * 0.5)) * (PI * 0.5)
		var plan: Vector2i = PLANS[rng.randi() % PLANS.size()]
		_house(out, pos, yaw, plan.x, plan.y,
			rng.randf() < (0.75 if mostly_brick else 0.25), rng)
		out.houses += 1

	# The green itself: a stall or two, benches, and nothing built.
	for i in rng.randi_range(3, 7):
		var ang := rng.randf() * TAU
		var d := rng.randf() * r * 0.55
		var p: Vector3 = at + Vector3(cos(ang) * d, 0.0, sin(ang) * d)
		p.y = terrain.height_at(p.x, p.z)
		const GREEN := ["Stall_Empty", "Stall_Cart_Empty", "Bench", "Barrel",
			"Crate_Wooden", "Table_Large", "Prop_Wagon"]
		out.pieces.append({
			"path": PROPS + GREEN[rng.randi() % GREEN.size()] + ".gltf",
			"position": p, "yaw": rng.randf() * TAU, "scale": 1.0,
		})
	out.keep_clear.append(Rect2(at.x - r - 10.0, at.z - r - 10.0,
		(r + 10.0) * 2.0, (r + 10.0) * 2.0))


## One family, working land. A house, a barn, fences and the tools.
static func _farmstead(out: Built, terrain: WgTerrain, at: Vector3,
		rng: RandomNumberGenerator) -> void:
	var face: float = round(rng.randf() * 4.0) * (PI * 0.5)
	var basis := Basis(Vector3.UP, face)

	var house_at: Vector3 = at + basis * Vector3(-9.0, 0.0, 0.0)
	house_at.y = terrain.height_at(house_at.x, house_at.z)
	_house(out, house_at, face, 3, 3, rng.randf() < 0.4, rng)
	out.houses += 1

	# The barn: the biggest plan, no windows to speak of, no chimney.
	var barn_at: Vector3 = at + basis * Vector3(11.0, 0.0, 4.0)
	barn_at.y = terrain.height_at(barn_at.x, barn_at.z)
	_house(out, barn_at, face + PI * 0.5, 4, 4, false, rng, true)
	out.houses += 1

	# A yard between them, fenced, with the work in it.
	for i in rng.randi_range(8, 16):
		var p: Vector3 = at + basis * Vector3(
			rng.randf_range(-6.0, 8.0), 0.0, rng.randf_range(-11.0, 11.0))
		p.y = terrain.height_at(p.x, p.z)
		const FARM := ["FarmCrate_Apple", "FarmCrate_Carrot", "FarmCrate_Empty",
			"Barrel_Apples", "Barrel", "Bucket_Wooden_1", "Prop_Wagon",
			"Crate_Wooden", "Bag", "Pouch_Large", "Workbench", "Anvil_Log"]
		out.pieces.append({
			"path": PROPS + FARM[rng.randi() % FARM.size()] + ".gltf",
			"position": p, "yaw": rng.randf() * TAU, "scale": 1.0,
		})
	var posts := rng.randi_range(8, 14)
	for i in posts:
		var t := float(i) / float(posts - 1)
		var p: Vector3 = at + basis * Vector3(
			lerpf(-8.0, 10.0, t), 0.0, -13.0)
		p.y = terrain.height_at(p.x, p.z)
		out.pieces.append({
			"path": KIT + "Prop_WoodenFence_Single.gltf",
			"position": p, "yaw": face, "scale": 1.0,
		})
	out.keep_clear.append(Rect2(at.x - 24.0, at.z - 24.0, 48.0, 48.0))


## Somewhere that was a place. Walls, no roofs, and the wood coming back.
static func _ruin(out: Built, terrain: WgTerrain, at: Vector3,
		rng: RandomNumberGenerator) -> void:
	var count := rng.randi_range(2, 4)
	for i in count:
		var ang := rng.randf() * TAU
		var d := rng.randf_range(0.0, 16.0)
		var pos: Vector3 = at + Vector3(cos(ang) * d, 0.0, sin(ang) * d)
		pos.y = terrain.height_at(pos.x, pos.z)
		var yaw: float = round(rng.randf() * 4.0) * (PI * 0.5)
		_shell(out, pos, yaw, rng.randi_range(3, 4), rng.randi_range(3, 4), rng)
	# Rubble and what was left behind.
	for i in rng.randi_range(5, 12):
		var p: Vector3 = at + Vector3(
			rng.randf_range(-20.0, 20.0), 0.0, rng.randf_range(-20.0, 20.0))
		p.y = terrain.height_at(p.x, p.z)
		const LEFT := ["Barrel", "Crate_Wooden", "Pot_1", "Cauldron",
			"Bucket_Metal", "Chest_Wood"]
		out.pieces.append({
			"path": PROPS + LEFT[rng.randi() % LEFT.size()] + ".gltf",
			"position": p, "yaw": rng.randf() * TAU, "scale": 1.0,
		})
	out.keep_clear.append(Rect2(at.x - 22.0, at.z - 22.0, 44.0, 44.0))


## A house with the roof gone and most of a wall with it.
##
## Built from the same kit as a standing house, which is the point: a
## ruin that shares no geometry with the houses around it reads as a
## prop rather than as the same village a hundred years later.
static func _shell(out: Built, pos: Vector3, yaw: float, wm: int, dm: int,
		rng: RandomNumberGenerator) -> void:
	var wset := "Wall_UnevenBrick"
	var hw := float(wm)
	var hd := float(dm)
	var basis := Basis(Vector3.UP, yaw)
	var put := func(stem: String, local: Vector3, extra: float) -> void:
		out.pieces.append({
			"path": KIT + stem + ".gltf",
			"position": pos + basis * local,
			"yaw": yaw + extra, "scale": 1.0,
		})
	for i in range(wm):
		var x := -hw + 1.0 + 2.0 * i
		# Gaps: a ruin with all four walls is a house somebody has
		# tidied.
		if rng.randf() < 0.55:
			put.call(wset + "_Straight", Vector3(x, 0, hd), 0.0)
		if rng.randf() < 0.45:
			put.call(wset + "_Window_Wide_Flat", Vector3(x, 0, -hd), PI)
	for j in range(dm):
		var z := -hd + 1.0 + 2.0 * j
		for sgn in [1.0, -1.0]:
			if rng.randf() < 0.5:
				put.call(wset + "_Straight", Vector3(hw * sgn, 0, z), -PI * 0.5 * sgn)
	for cx in [-hw, hw]:
		for cz in [-hd, hd]:
			if rng.randf() < 0.7:
				put.call("Corner_Exterior_Brick", Vector3(cx, 0, cz), 0.0)
	if rng.randf() < 0.6:
		put.call("Prop_Vine1", Vector3(hw - 1.6, 2.12, hd + 0.24), 0.0)
	out.keep_clear.append(Rect2(pos.x - float(wm) - 2.0, pos.z - float(dm) - 2.0,
		float(wm * 2) + 4.0, float(dm * 2) + 4.0))


static func _house(out: Built, pos: Vector3, yaw: float, wm: int, dm: int,
		brick: bool, rng: RandomNumberGenerator, barn: bool = false) -> void:
	var wset := "Wall_UnevenBrick" if brick else "Wall_Plaster"
	var corner := "Corner_Exterior_Brick" if brick else "Corner_Exterior_Wood"
	# The brick set is a smaller set: it has a flat door and one window
	# and no round-headed anything, so asking it for the plaster pieces
	# gets a hole where a wall should be.
	var has_round: bool = not brick
	var hw := float(wm)
	var hd := float(dm)
	var basis := Basis(Vector3.UP, yaw)

	var put := func(stem: String, local: Vector3, extra_yaw: float) -> void:
		out.pieces.append({
			"path": KIT + stem + ".gltf",
			"position": pos + basis * local,
			"yaw": yaw + extra_yaw,
			"scale": 1.0,
		})

	# A barn is a working building: big doors, no glazing, no hearth.
	var glazing: float = 0.0 if barn else 0.65
	var door_i := rng.randi_range(1, maxi(1, wm - 2))
	for i in range(wm):
		var x := -hw + 1.0 + 2.0 * i
		var front := wset + "_Straight"
		if i == door_i:
			front = wset + ("_Door_Round" if (has_round and rng.randf() < 0.4)
				else "_Door_Flat")
		elif rng.randf() < glazing:
			front = wset + "_Window_Wide_Flat"
		put.call(front, Vector3(x, 0, hd), 0.0)

		var back := wset + "_Straight"
		if rng.randf() < glazing * 0.6:
			back = wset + "_Window_Wide_Flat"
		put.call(back, Vector3(x, 0, -hd), PI)

	for j in range(dm):
		var z := -hd + 1.0 + 2.0 * j
		for s in [1.0, -1.0]:
			var stem := wset + "_Straight"
			if rng.randf() < glazing * 0.7:
				stem = wset + ("_Window_Thin_Round" if (has_round and rng.randf() < 0.5)
					else "_Window_Wide_Flat")
			put.call(stem, Vector3(hw * s, 0, z), -PI * 0.5 * s)

	for cx in [-hw, hw]:
		for cz in [-hd, hd]:
			put.call(corner, Vector3(cx, 0, cz), 0.0)

	put.call("Roof_RoundTiles_%dx%d" % [wm * 2, dm * 2], Vector3(0, 3.12, 0), 0.0)

	if not barn and rng.randf() < 0.8:
		var cy := 3.12 + 1.9
		var local := Vector3(hw * 0.35, cy, -hd * 0.35)
		put.call("Prop_Chimney" if rng.randf() < 0.6 else "Prop_Chimney2", local, 0.0)
		out.chimneys.append(pos + basis * (local + Vector3(0, 1.3, 0)))
	if not barn and rng.randf() < 0.35:
		put.call("Stairs_Exterior_Straight",
			Vector3(-hw + 1.0 + 2.0 * door_i, 0, hd + 1.4), 0.0)
	if rng.randf() < 0.3:
		put.call("Prop_Vine1", Vector3(hw - 1.6, 2.12, hd + 0.24), 0.0)

	out.solids.append({
		"position": pos + Vector3(0, 2.5, 0),
		"size": Vector3(wm * 2.0 + 0.4, 5.0, dm * 2.0 + 0.4),
		"yaw": yaw,
	})
	# Keep-clear, axis-aligned because yaw is a right angle here.
	var w := float(wm * 2) + 3.0
	var d := float(dm * 2) + 3.0
	if absf(fmod(absf(yaw), PI) - PI * 0.5) < 0.1:
		var t := w
		w = d
		d = t
	out.keep_clear.append(Rect2(pos.x - w * 0.5, pos.z - d * 0.5, w, d))


## The clutter that says somebody lives here rather than that somebody
## placed houses here.
static func _street_props(out: Built, terrain: WgTerrain, at: Vector3,
		along: Vector3, across: Vector3, length: float,
		rng: RandomNumberGenerator) -> void:
	const CLUTTER := ["Barrel", "Barrel_Apples", "Crate_Wooden", "Crate_Metal",
		"FarmCrate_Apple", "FarmCrate_Carrot", "FarmCrate_Empty", "Bag",
		"Bucket_Wooden_1", "Bucket_Metal", "Bench", "Stool", "Pot_1",
		"Chest_Wood", "Sack", "Rope_1", "Shelf_Simple"]
	const WORK := ["Anvil", "Anvil_Log", "Workbench", "Workbench_Drawers",
		"Cauldron", "Whetstone", "Table_Large"]
	const BIG := ["Stall_Empty", "Stall_Cart_Empty", "Prop_Wagon"]

	var n := rng.randi_range(6, 16)
	for i in n:
		var down := rng.randf_range(-0.5, 0.5) * length
		var side := rng.randf_range(-8.5, 8.5)
		var p: Vector3 = at + along * down + across * side
		p.y = terrain.height_at(p.x, p.z)
		var set: Array = CLUTTER
		var roll := rng.randf()
		if roll < 0.14:
			set = BIG
		elif roll < 0.32:
			set = WORK
		var stem: String = set[rng.randi() % set.size()]
		# Sack is in the pack as Pouch_Large; the name above is the one
		# a person reaches for and the kit does not have it.
		if stem == "Sack":
			stem = "Pouch_Large"
		out.pieces.append({
			"path": PROPS + stem + ".gltf",
			"position": p,
			"yaw": rng.randf() * TAU,
			"scale": 1.0,
		})

	# A fence line along one side, sometimes.
	if rng.randf() < 0.6:
		var fside: float = 11.0 if rng.randf() < 0.5 else -11.0
		var posts := rng.randi_range(4, 10)
		for i in posts:
			var down := (float(i) / float(posts) - 0.5) * length
			var p: Vector3 = at + along * down + across * fside
			p.y = terrain.height_at(p.x, p.z)
			out.pieces.append({
				"path": KIT + "Prop_WoodenFence_Single.gltf",
				"position": p,
				"yaw": atan2(-along.x, -along.z),
				"scale": 1.0,
			})

	out.keep_clear.append(Rect2(at.x - length * 0.5 - 6.0,
		at.z - length * 0.5 - 6.0, length + 12.0, length + 12.0))


static func _name_for(rng: RandomNumberGenerator) -> String:
	const HEAD := ["Thorn", "Ald", "Mere", "Bram", "Win", "Holt", "Cold",
		"Rook", "Stan", "Elm", "Fen", "Har", "Dun", "Kirk"]
	const TAIL := ["field", "ford", "wick", "combe", "stead", "barrow",
		"hollow", "gate", "mill", "bury", "moor", "reach"]
	return HEAD[rng.randi() % HEAD.size()] + TAIL[rng.randi() % TAIL.size()]
