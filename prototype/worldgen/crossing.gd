class_name WgCrossing
extends RefCounted
## Bridges, where a road meets a river.
##
## Roads were laid before rivers existed and nothing told them. Measured
## across 215 road segments in five widely separated patches, **ten ran
## straight through open water** and the deepest had the full 7 m
## channel under it — a cart track diving into a river and out the far
## side.
##
## **Why a bridge and not a ford**, which was the first idea and was
## wrong. A ford is where a river is naturally shallow and wide, and
## making one here means either raising the bed (which dams the river:
## the water surface would step up three metres at the crossing and
## back down after it, running uphill in between) or leaving the water
## where it is and wading 1.6 m at the bottom of the channel. The
## valley itself is not the problem — it falls 7 m over 150 m, which is
## a 5% grade a road takes without noticing. It is the last sixteen
## metres, where the bank drops into the channel, that no road can do.
## So: span it.
##
## **No bridge model survives in the shipping kit** — KayKit's two were
## cut from the APK along with 60 MB of everything else. This builds one
## from the pieces that did survive, the same way the standing stones
## were built from a scaled wall: a deck of floor tiles, a parapet of
## fence, and piers standing in the water.

## How far either side of the water the abutments reach, past the drawn
## sheet, so the deck lands on bank rather than on the lip of the cut.
const ABUTMENT := 7.0
## The deck, in metres. Wider than the track it carries (3.4 m), because
## a bridge you can fall off the side of while walking down the middle
## of the road is not a bridge.
const DECK_WIDTH := 6.0
const DECK_THICK := 0.5
## How far above the water the deck sits at its lowest.
const CLEARANCE := 1.2
## Metres between deck tiles and between piers.
const TILE := 3.0
const PIER_SPACING := 9.0

## How far outside the asked-for box a crossing is still traced whole.
## See `near`.
const WALK_MARGIN := 400.0

const KIT := "res://assets/town/kit/"
const PROPS := "res://assets/town/props/"


## Every bridge that could touch a rectangle of world.
##
## Takes the roads it is given rather than fetching them, because
## `WgRoads.near` walks the settlement grid and a chunk has already
## paid for that. It also keeps this out of the recursion that
## `_raw_height` exists to avoid: nothing here is asked by `height_at`.
static func near(terrain: WgTerrain, roads: Array,
		x0: float, z0: float, x1: float, z1: float) -> Array:
	var out: Array = []
	# Generous, because a bridge is placed from its own crossing point
	# and a chunk needs the ones just outside it too — a 40 m deck
	# reaches well across a 64 m chunk's border.
	var pad := 64.0
	var box := Rect2(x0 - pad, z0 - pad,
		(x1 - x0) + pad * 2.0, (z1 - z0) + pad * 2.0)
	# AND A BOX TO WALK WITHIN, which is the difference between this
	# costing a fraction of a millisecond and costing minutes.
	#
	# The Wheel's spokes are 23 km long. Walking one end to end at 4 m
	# steps is 5,850 river queries, and a query in country nothing has
	# looked at traces the 49 source cells that could reach it — so a
	# single chunk asking about a single spoke thrashed the river cache
	# past its 4,096-entry limit several times over. `threadcheck` found
	# it: streaming filled 21 of 25 chunks in 400 frames where it had
	# filled all 25 before, and a bare measurement of one chunk's
	# crossings ran past ten minutes.
	#
	# The margin is generous on purpose. A crossing is at most a couple
	# of hundred metres, and one is kept only if its MIDDLE is in `box`,
	# so 400 m of slack guarantees any crossing this call will keep was
	# walked whole — which is what makes the answer the same whichever
	# chunk asks.
	var walk := box.grow(WALK_MARGIN)
	for seg in roads:
		for span in _spans(terrain, seg, walk):
			if box.has_point(span["at"]):
				out.append(span)
	return out


## Where one road segment goes through water, and how far.
##
## Walked at a fixed step from the segment's own start, so the answer
## depends on the segment and the rivers alone. A road segment is
## already owned exactly once — the east-and-south rule in `WgRoads` —
## so a crossing is too, and two chunks cannot both build the same
## bridge.
static func _spans(terrain: WgTerrain, seg: Dictionary,
		walk: Rect2) -> Array:
	var a: Vector2 = seg["a"]
	var b: Vector2 = seg["b"]
	var run := a.distance_to(b)
	if run < 1.0:
		return []
	var dir := (b - a) / run
	var out: Array = []
	var step := 4.0
	var n := int(run / step)

	# CLIP THE RANGE, do not walk it and skip.
	#
	# Testing each step against the box and skipping was the first fix
	# and it was not enough. Thornfield sits ON the Wheel, so every
	# chunk around it is handed twelve segments 23 km long — 5,850 steps
	# each, 70,000 Rect2 tests a chunk, times two hundred chunks. It
	# cost the town enough that `hourcheck`'s townsfolk stopped fanning
	# out: four of four runs passed on the commit before this one and
	# one of four passed after.
	#
	# Intersecting the segment with the box first turns that into a
	# handful of steps. The indices are still counted from the
	# segment's own start, so a crossing is found at the same place
	# whichever chunk asks — which is the property the whole thing
	# rests on.
	var i0 := 0
	var i1 := n
	var span_t := _clip(a, b, walk)
	if span_t.x > span_t.y:
		return out
	i0 = maxi(int(floor(span_t.x * run / step)), 0)
	i1 = mini(int(ceil(span_t.y * run / step)), n)

	var i := i0
	while i <= i1:
		var p := a + dir * (float(i) * step)
		if terrain.river_distance(p.x, p.y) > WgRivers.SHEET:
			i += 1
			continue
		# Found water. Walk to the far side, then back up to dry land
		# either way, so the deck lands on bank.
		# ...and the far side is walked past the clip, so a crossing
		# that starts inside the box is still measured whole.
		var j := i
		while j <= n and terrain.river_distance(
				(a + dir * (float(j) * step)).x,
				(a + dir * (float(j) * step)).y) <= WgRivers.SHEET:
			j += 1
		var wet_from := a + dir * (float(i) * step)
		var wet_to := a + dir * (float(mini(j, n)) * step)
		var start := wet_from - dir * ABUTMENT
		var end := wet_to + dir * ABUTMENT
		out.append(_bridge(terrain, start, end, dir))
		i = j + 1
	return out


## The parameter range of a segment that lies inside a rectangle, as
## { x: t0, y: t1 }; t0 > t1 when it misses entirely. Liang-Barsky.
static func _clip(a: Vector2, b: Vector2, box: Rect2) -> Vector2:
	var d := b - a
	var t0 := 0.0
	var t1 := 1.0
	var lo := box.position
	var hi := box.position + box.size
	var p_side := PackedFloat32Array([-d.x, d.x, -d.y, d.y])
	var q_side := PackedFloat32Array([a.x - lo.x, hi.x - a.x,
		a.y - lo.y, hi.y - a.y])
	for k in 4:
		var pp: float = p_side[k]
		var qq: float = q_side[k]
		if absf(pp) < 0.0000001:
			# Parallel to this edge: either wholly inside it or wholly
			# outside, and outside means the segment misses the box.
			if qq < 0.0:
				return Vector2(1.0, 0.0)
			continue
		var r: float = qq / pp
		if pp < 0.0:
			t0 = maxf(t0, r)
		else:
			t1 = minf(t1, r)
	return Vector2(t0, t1)


static func _bridge(terrain: WgTerrain, start: Vector2, end: Vector2,
		dir: Vector2) -> Dictionary:
	var span := start.distance_to(end)
	# THE DECK IS A RAMP, NOT A LEVEL SLAB.
	#
	# A level deck at the higher bank leaves a step down at the lower
	# one, and a step is a thing you walk into. Straight from bank to
	# bank meets the ground exactly at both ends, and across a span this
	# short the slope is gentler than the valley the road just came
	# down.
	var h0 := terrain.height_at(start.x, start.y)
	var h1 := terrain.height_at(end.x, end.y)
	# ...but never so low that the river runs over it. The water is
	# worked out at the middle, which is the deepest part of the cut.
	var mid := start.lerp(end, 0.5)
	var water := terrain.water_at(mid.x, mid.y)
	var lowest: float = minf(h0, h1)
	if water > WgTerrain.NO_WATER and lowest < water + CLEARANCE:
		var lift: float = (water + CLEARANCE) - lowest
		h0 += lift
		h1 += lift
	return {
		"at": mid,
		"start": start,
		"end": end,
		"dir": dir,
		"span": span,
		"h0": h0,
		"h1": h1,
	}


## Is this point under a deck?
##
## The one question a check needs: a road may go through water as long
## as there is a bridge over the water where it does. Asked of the span
## rather than of the placed pieces, so it is answerable without
## building a chunk.
static func covers(bridge: Dictionary, x: float, z: float) -> bool:
	var a: Vector2 = bridge["start"]
	var b: Vector2 = bridge["end"]
	var ab := b - a
	var len2 := ab.length_squared()
	if len2 < 0.0001:
		return false
	var t: float = (Vector2(x, z) - a).dot(ab) / len2
	if t < 0.0 or t > 1.0:
		return false
	return Vector2(x, z).distance_to(a + ab * t) <= DECK_WIDTH * 0.5


## The bridge, as pieces and as something solid to stand on.
##
## Returns { pieces, solids, keep_clear } in the shape `WgChunk` and
## `WgBake` already handle, so a bridge streams, bakes and reads back
## like anything else that stands on the land.
##
## EVERY NUMBER HERE IS AGAINST A MEASURED MODEL. The first cut guessed
## that `Floor_Brick` was a one-metre tile and scaled its width by six;
## it is two metres square and two centimetres thick, so the render came
## back with a twelve-metre slab of paper across the river. The sizes
## are: Floor_Brick 2.00 x 0.02 x 2.00, Prop_WoodenFence_Single
## 2.06 x 0.84 x 0.12 running along its own X, Wall_UnevenBrick_Straight
## 2.00 x 3.12 x 0.41, also along X, standing on y = 0.
##
## `yaw` puts a piece's local +Z along the crossing, which is what the
## square deck tile wants. The fence and the pier run along their own X,
## so they get a quarter turn on top of it — the same convention
## `WgSettlement._house` uses to turn a wall run through a corner.
static func build(terrain: WgTerrain, bridge: Dictionary) -> Dictionary:
	var start: Vector2 = bridge["start"]
	var end: Vector2 = bridge["end"]
	var dir: Vector2 = bridge["dir"]
	var span: float = bridge["span"]
	var h0: float = bridge["h0"]
	var h1: float = bridge["h1"]
	var yaw := atan2(dir.x, dir.y)

	var pieces: Array = []
	var solids: Array = []

	var tiles := maxi(int(round(span / TILE)), 2)
	for i in tiles:
		var t := (float(i) + 0.5) / float(tiles)
		var p := start.lerp(end, t)
		var y := lerpf(h0, h1, t)
		# A plank of deck: the 2 m tile stretched to the full width and
		# to a tile's length, and thickened from 2 cm to 40 cm so it
		# reads as a deck rather than as a sheet of paper. It is
		# centred on its own origin, so it hangs half its thickness
		# below the walking surface.
		pieces.append({
			"path": KIT + "Floor_Brick.gltf",
			"position": Vector3(p.x, y - DECK_THICK * 0.5, p.y),
			"yaw": yaw,
			"scale": Vector3(DECK_WIDTH / 2.0, DECK_THICK / 0.02,
				TILE * 1.03 / 2.0),
		})
		# A parapet either side. Without one the deck reads as a path
		# painted on the water rather than as a thing standing over it.
		var side := Vector2(-dir.y, dir.x) * (DECK_WIDTH * 0.5 - 0.25)
		for sgn in [1.0, -1.0]:
			pieces.append({
				"path": KIT + "Prop_WoodenFence_Single.gltf",
				"position": Vector3(p.x + side.x * sgn, y,
					p.y + side.y * sgn),
				"yaw": yaw + PI * 0.5,
				"scale": Vector3(TILE * 1.03 / 2.06, 1.3, 1.0),
			})

	# Piers, standing on the bed and carrying the deck. They are what
	# makes the span read as built rather than as floating — and each
	# one is cut to the ground under it, so a pier in the channel is
	# taller than one on the shelf instead of every pier being the same
	# guessed length.
	var piers := maxi(int(span / PIER_SPACING), 1)
	for i in range(1, piers):
		var t := float(i) / float(piers)
		var p := start.lerp(end, t)
		var y := lerpf(h0, h1, t)
		var bed := terrain.height_at(p.x, p.y)
		var tall: float = maxf(y - bed, 0.5)
		pieces.append({
			"path": KIT + "Wall_UnevenBrick_Straight.gltf",
			"position": Vector3(p.x, bed - 0.2, p.y),
			"yaw": yaw + PI * 0.5,
			"scale": Vector3(1.2, (tall + 0.2) / 3.12, 2.9),
		})

	# ONE SOLID FOR THE WHOLE DECK, not one per tile.
	#
	# A body walking a bridge made of thirteen separate boxes catches on
	# every join. The deck is a single box along the crossing, thick
	# enough that a fast walker cannot tunnel through it, and the ramp
	# is close enough to flat over this span that a level box is what
	# the feet want anyway.
	var centre := start.lerp(end, 0.5)
	solids.append({
		"position": Vector3(centre.x, (h0 + h1) * 0.5 - DECK_THICK * 0.5,
			centre.y),
		"size": Vector3(DECK_WIDTH, DECK_THICK, span),
		"yaw": yaw,
	})

	# Nothing grows on a bridge, and nothing is built at its ends.
	#
	# The AABB of the deck's own four corners, not a square of the
	# span: a 40 m bridge running north gets a 40x6 rect, and a square
	# would have cleared 1,600 m2 of country for a thing 240 m2 wide.
	var half := Vector2(-dir.y, dir.x) * (DECK_WIDTH * 0.5 + 2.0)
	var lo := start + half
	var hi := lo
	for corner in [start - half, end + half, end - half]:
		lo = Vector2(minf(lo.x, corner.x), minf(lo.y, corner.y))
		hi = Vector2(maxf(hi.x, corner.x), maxf(hi.y, corner.y))
	var keep_clear: Array = [Rect2(lo, hi - lo)]

	return {"pieces": pieces, "solids": solids, "keep_clear": keep_clear}
