class_name WgRoads
extends RefCounted
## What joins the places up.
##
## A world of settlements with nothing running between them does not
## read as inhabited — it reads as a map with pins in it. The design
## needs roads for their own sake too: spokes, the rim road, caravans,
## escorts and banditry are all content that assumes a route somebody
## has to take.
##
## **Deterministic without global knowledge.** A road cannot be planned
## by looking at the whole world, because nothing here ever has the
## whole world in hand. Instead every settlement cell links only to its
## EAST and SOUTH neighbours: each possible link is therefore owned by
## exactly one cell, every chunk works out the same links from the same
## hashes, and no link is ever drawn twice or missed at a border.
##
## Roads TINT and CLEAR; they do not cut. Flattening the ground under a
## road would mean `height_at` knowing where settlements are, and
## settlements are sited by searching `height_at` for level ground —
## which is a loop. A track that follows the contours is also what a
## medieval road actually did.

## How wide the worn ground reads, in metres.
const WIDTH := 3.4
## And how far out the edge fades.
const VERGE := 2.2
## Roads longer than this are not roads, they are two places that do
## not know each other.
const MAX_SPAN := WgSettlement.CELL * 1.9


## THE WHEEL'S OWN ROADS: six spokes and the rim.
##
## These are not found, they are the map. `brainstorm.md` §1: six great
## roads from the towns to the capitol, safe-ish; a rim road town to
## town, less safe; off-road in the wedges, dangerous, where the good
## materials are. That gradient is a design promise about where risk
## lives, and it needs the roads to actually exist for the off-road to
## mean anything.
##
## Built once — twelve segments for the whole world.
static var _wheel: Array = []

static func wheel(terrain: WgTerrain) -> Array:
	if not _wheel.is_empty():
		return _wheel
	var towns: Array = []
	for w in WgTerrain.WEDGES:
		var t := terrain.town_site(w)
		towns.append(Vector2(t.x, t.z))
	var hub := Vector2.ZERO
	for i in towns.size():
		# A spoke in, and a rim segment on to the next town. Each is
		# produced once, so the no-duplicates rule holds for these the
		# same way it does for the hamlet links.
		_wheel.append({"a": towns[i], "b": hub, "kind": "spoke"})
		_wheel.append({"a": towns[i], "b": towns[(i + 1) % towns.size()],
			"kind": "rim"})
	return _wheel


## Every road segment that could touch a rectangle of world.
##
## Returned as { a: Vector2, b: Vector2 } in world XZ.
static func near(terrain: WgTerrain, world_seed: int,
		x0: float, z0: float, x1: float, z1: float) -> Array:
	var out: Array = []
	var pad := WgSettlement.CELL
	var c0x := int(floor((x0 - pad) / WgSettlement.CELL))
	var c0z := int(floor((z0 - pad) / WgSettlement.CELL))
	var c1x := int(ceil((x1 + pad) / WgSettlement.CELL))
	var c1z := int(ceil((z1 + pad) / WgSettlement.CELL))

	# The Wheel's roads first, if they pass anywhere near.
	var box := Rect2(x0 - pad, z0 - pad, (x1 - x0) + pad * 2.0, (z1 - z0) + pad * 2.0)
	for seg in wheel(terrain):
		if _segment_near_rect(seg["a"], seg["b"], box):
			out.append(seg)

	for cx in range(c0x, c1x + 1):
		for cz in range(c0z, c1z + 1):
			var here := WgSettlement.cached(terrain, world_seed, cx, cz)
			if here.houses == 0 and here.pieces.is_empty():
				continue
			var a := Vector2(here.centre.x, here.centre.z)
			# East and south only. Each link is owned once.
			for step in [Vector2i(1, 0), Vector2i(0, 1)]:
				var other := WgSettlement.cached(terrain, world_seed,
					cx + step.x, cz + step.y)
				if other.houses == 0 and other.pieces.is_empty():
					continue
				var b := Vector2(other.centre.x, other.centre.z)
				if a.distance_to(b) > MAX_SPAN:
					continue
				out.append({"a": a, "b": b})
	return out


## How worn the ground is here: 1 on the track, 0 off it.
static func wear(segments: Array, x: float, z: float) -> float:
	if segments.is_empty():
		return 0.0
	var p := Vector2(x, z)
	var best := INF
	for seg in segments:
		var d := _to_segment(p, seg["a"], seg["b"])
		if d < best:
			best = d
		if best <= WIDTH * 0.5:
			return 1.0
	if best >= WIDTH * 0.5 + VERGE:
		return 0.0
	return 1.0 - (best - WIDTH * 0.5) / VERGE


## Does a segment come within the box at all?
##
## Cheap and generous: a spoke is six kilometres long and would
## otherwise be distance-tested against every vertex of every chunk in
## the world, most of which are nowhere near it.
static func _segment_near_rect(a: Vector2, b: Vector2, box: Rect2) -> bool:
	if box.has_point(a) or box.has_point(b):
		return true
	var centre := box.get_center()
	var reach := box.size.length() * 0.5 + WIDTH + VERGE
	return _to_segment(centre, a, b) <= reach


static func _to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len2 := ab.length_squared()
	if len2 < 0.0001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / len2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


## The colour of a worn track. Not a biome colour — a road is the same
## churned earth everywhere, which is part of how it reads as a road
## rather than as a stripe of differently-coloured field.
static func surface() -> Color:
	return Color(0.42, 0.35, 0.26)
