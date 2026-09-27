class_name WgScatter
extends RefCounted
## What stands on the land: trees, rocks, bushes, grass.
##
## Placed **per cell, from a hash of the cell's own coordinates**, never
## from a running random stream. That distinction is the whole design.
##
## A sequential RNG — "walk the chunk, roll for each spot" — gives a
## different answer if the chunk is built at a different time, from a
## different corner, or after a neighbour. Trees would shuffle every
## time the world streamed in, and the same clearing would be a wood on
## the second visit. Hashing the CELL means a tree's existence and
## position depend on nothing but where it is, so a chunk can be built
## in any order, alone, twice, or on another machine, and come out the
## same.
##
## It also means scatter needs no chunk boundaries of its own. A chunk
## simply asks for the cells it covers.

## Metres per scatter cell. One candidate per cell per layer, which is
## why the cell is small: density below one-per-cell is expressed by
## rejecting candidates, and a cell much larger than the objects makes
## the rejections read as a grid.
const CELL := 7.0

## Nothing grows on a cliff.
const MAX_SLOPE := 0.62

const NATURE := "res://assets/town/nature/"


## A deterministic stream for one cell and one layer.
##
## `layer` keeps the trees from deciding the rocks: without it, every
## layer in a cell would draw from the same sequence and a cell with a
## tree would always be the cell with a rock, which reads as clumping
## nobody asked for.
static func cell_rng(world_seed: int, cx: int, cz: int, layer: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	# Mixed rather than added. `cx + cz` collides along every diagonal —
	# the first cut of this did exactly that, and the land came out
	# striped from north-east to south-west.
	var h: int = world_seed
	h = (h * 73856093) ^ (cx * 19349663) ^ (cz * 83492791) ^ (layer * 2654435761)
	h = h ^ (h >> 13)
	h = h * 1274126177
	rng.seed = absi(h)
	return rng


## Everything standing in a rectangle of world, as an array of
## { path, position, yaw, scale, kind }.
##
## Returned as DATA rather than as nodes, so the same call can build a
## chunk, answer a harness, or be baked to disk without three versions
## of the rules.
static func in_rect(terrain: WgTerrain, x0: float, z0: float,
		x1: float, z1: float, keep_clear: Array = [],
		roads: Array = []) -> Array:
	var out: Array = []
	var c0x := int(floor(x0 / CELL))
	var c0z := int(floor(z0 / CELL))
	var c1x := int(ceil(x1 / CELL))
	var c1z := int(ceil(z1 / CELL))

	for cx in range(c0x, c1x):
		for cz in range(c0z, c1z):
			_cell(terrain, cx, cz, x0, z0, x1, z1, keep_clear, roads, out)
	return out


static func _cell(terrain: WgTerrain, cx: int, cz: int,
		x0: float, z0: float, x1: float, z1: float,
		keep_clear: Array, roads: Array, out: Array) -> void:
	var b := terrain.biome_at(float(cx) * CELL, float(cz) * CELL)

	_try(terrain, b, cx, cz, 0, b.tree_density, b.trees,
		Vector2(0.75, 1.35), "tree", x0, z0, x1, z1, keep_clear, roads, out)
	_try(terrain, b, cx, cz, 1, b.rock_density,
		["RockPath_Round_Small_1", "RockPath_Round_Small_2",
			"RockPath_Round_Wide"],
		Vector2(0.6, 1.8), "rock", x0, z0, x1, z1, keep_clear, roads, out)
	_try(terrain, b, cx, cz, 2, b.bush_density,
		["Bush_Common", "Bush_Common_Flowers", "Fern_1"],
		Vector2(0.7, 1.3), "bush", x0, z0, x1, z1, keep_clear, roads, out)
	_try(terrain, b, cx, cz, 3, b.grass_density,
		["Grass_Common_Tall", "Grass_Wispy_Tall"],
		Vector2(0.8, 1.4), "grass", x0, z0, x1, z1, keep_clear, roads, out)


static func _try(terrain: WgTerrain, b, cx: int, cz: int, layer: int,
		density: float, kit: Array, scale_range: Vector2, kind: String,
		x0: float, z0: float, x1: float, z1: float,
		keep_clear: Array, roads: Array, out: Array) -> void:
	if kit.is_empty() or density <= 0.0:
		return
	var rng := cell_rng(terrain.seed_value, cx, cz, layer)
	if rng.randf() > density:
		return

	# Jittered inside its own cell, so the survivors are not on a grid.
	var x := (float(cx) + rng.randf()) * CELL
	var z := (float(cz) + rng.randf()) * CELL
	if x < x0 or x >= x1 or z < z0 or z >= z1:
		return

	# The capitol is cleared ground, not woodland.
	if kind == "tree" and terrain.capitol_blend(x, z) > 0.35:
		return
	if terrain.slope_at(x, z) > MAX_SLOPE:
		return
	for rect in keep_clear:
		var r: Rect2 = rect
		if r.has_point(Vector2(x, z)):
			return
	# Nothing grows in the ruts. Grass creeps back to the verge, which
	# is why this tests the wear rather than a flat width: a road with
	# a hard-edged empty strip beside it reads as a corridor.
	var worn := WgRoads.wear(roads, x, z)
	if worn > (0.25 if kind == "grass" else 0.02):
		return

	# NOTHING GROWS IN THE RIVER.
	#
	# A tree standing in open water is as old a generator tell as a
	# river running uphill, and the scatter had no idea water existed:
	# the first render of a bank had trees in the channel. The waterline
	# is the edge of the drawn sheet, so this is the same number the
	# mesh uses rather than a second one that can drift from it —
	# anything at the margin roots in the shallows, which is where bank
	# plants belong.
	if terrain.river_distance(x, z) <= WgRivers.SHEET:
		return

	out.append({
		"path": NATURE + kit[rng.randi() % kit.size()] + ".gltf",
		"position": Vector3(x, terrain.height_at(x, z), z),
		"yaw": rng.randf() * TAU,
		"scale": rng.randf_range(scale_range.x, scale_range.y),
		"kind": kind,
	})
