class_name WgRivers
extends RefCounted
## Water, and the valleys it cut.
##
## The largest thing missing from the country. `lore.md` §5 makes
## Greywater a river-port of barges and smugglers and the Fens
## "waterways and drowned meadows" — neither is possible on dry land,
## and a world with no water reads as a heath however good the hills
## are.
##
## **Rivers are carved, not painted.** A blue stripe on a hillside is
## the classic generator tell. These cut a valley into `height_at`
## itself, so the land falls toward the water from a long way off and
## the river is legible from a ridge a kilometre away — which is what
## makes it useful for navigation (L86) rather than decorative.
##
## **They run downhill**, which is the other classic tell and the thing
## worth checking: a river is traced by repeatedly stepping toward the
## lowest neighbouring ground, so it cannot climb by construction. It
## is still checked, because "by construction" is how the last five
## confident claims in this generator went.

## How far apart river sources are seeded.
## At 2600 m and a third of cells springing, the country had one river
## per 42 km2 — you could walk for an hour without crossing water, and
## the map of a 9 km square held three short threads and nothing else.
const SOURCE_CELL := 1700.0
## How many of those cells actually spring. Not all of them do: a source
## also has to be on local high ground, which about 45% of rolls are.
const SOURCE_CHANCE := 0.55
## Metres per traced step, and how many steps before a river gives up.
##
## 40 x 90 m = 3.6 km, which is deliberately short. The length decides
## how far away a source can be and still put water under your feet,
## and therefore how many sources have to be traced before a patch of
## ground knows its own height. At 90 steps that was a 8 km reach and
## 25x the tracing; at 40 it is two source cells in every direction.
const STEP := 90.0
const MAX_STEPS := 40
## THE CHANNEL HAS THREE PARTS, and the first cut had only two.
##
## It was a flat 7 m bed out to `CHANNEL`, then a single smoothstep all
## the way out to `VALLEY`. A smoothstep from 9 m to 150 m has barely
## moved at 25 m — it was still 6.6 m down — so the water surface, which
## sits 1.6 m above the bed, was above the ground for 25 m either side
## and the render showed a 50 m wide sheet of pale water lying across
## the country. A flood, not a river.
##
## So: a flat bed to `CHANNEL`, a bank that climbs from the bed to
## `SHELF` by `BANK`, and only then the long gentle fall of the valley
## floor out to `VALLEY`. The bank is what decides how wide the water
## looks; the valley is what makes it legible from a ridge (L86).
const CHANNEL := 9.0
const BANK := 24.0
const VALLEY := 150.0
## How deep the bed is below the valley floor, and how far the valley
## floor itself is below the open country.
const DEPTH := 7.0
const SHELF := 2.2
## How far the water surface stands above the bed, and how far out the
## sheet is drawn.
##
## The overhang matters: the sheet has to end INSIDE the bank, not at
## the waterline, or the edge of the water mesh is a straight cut across
## the river. At 16 m the bank has climbed past the surface by about a
## third of a metre, which buries it.
const RISE := 1.6
const SHEET := 16.0


static func cell_rng(world_seed: int, cx: int, cz: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var h: int = world_seed ^ 0x1f3d5b79
	h = (h * 73856093) ^ (cx * 19349663) ^ (cz * 83492791)
	h = h ^ (h >> 13)
	h = h * 1274126177
	rng.seed = absi(h)
	return rng


## IS THERE A SPRING HERE? Its own function because the fingerprint
## that guards baked overrides has to ask this of sixty cells without
## tracing sixty rivers — and because asking it twice in two places is
## how the two answers drift apart.
static func springs(terrain: WgTerrain, world_seed: int,
		cx: int, cz: int) -> bool:
	var rng := cell_rng(world_seed, cx, cz)
	if rng.randf() > SOURCE_CHANCE:
		return false
	return _springs(terrain, Vector2(
		(float(cx) + rng.randf()) * SOURCE_CELL,
		(float(cz) + rng.randf()) * SOURCE_CELL))


static func _springs(terrain: WgTerrain, p: Vector2) -> bool:
	# A SPRING IS ON LOCAL HIGH GROUND, not above some number.
	#
	# Two absolute thresholds failed here, and the second failed for an
	# interesting reason. Heights are measured from Thornfield's own
	# ground, so "above 12 m" means something different in every wedge
	# depending on where the origin happened to fall; scaling it by the
	# biome's relief did not help, because a wedge's mean height is not
	# zero either. One cell in 169 sprang.
	#
	# Higher than the land around it is the same question asked with no
	# frame of reference at all, and it is what actually defines a
	# spring.
	var h0 := terrain.bare_height(p.x, p.y)
	var around := 0.0
	for k in 4:
		var a: float = float(k) / 4.0 * TAU
		around += terrain.bare_height(
			p.x + cos(a) * 400.0, p.y + sin(a) * 400.0)
	#
	# The margin is 0, not "a metre above". Measured across 58 rolled
	# candidates the spread of `h0 - mean` was min -17.2, median -0.8,
	# p75 +2.8, max +23.0: the land is close enough to flat at a 400 m
	# radius that a metre of margin cuts the survivors to nothing, and
	# "higher than its surroundings at all" is the honest reading of
	# local high ground.
	if h0 <= around / 4.0:
		return false
	return true


## Trace one river from its source, as a list of points.
##
## Uses `_bare_height` — the land BEFORE any river cut it — so a river
## follows the shape of the country rather than the shape of itself.
## Tracing against the cut land would let a river chase its own valley
## in circles, which is a loop that terminates only by running out of
## steps.
static func trace(terrain: WgTerrain, world_seed: int, cx: int, cz: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var rng := cell_rng(world_seed, cx, cz)
	if rng.randf() > SOURCE_CHANCE:
		return out

	var p := Vector2(
		(float(cx) + rng.randf()) * SOURCE_CELL,
		(float(cz) + rng.randf()) * SOURCE_CELL)
	if not _springs(terrain, p):
		return out

	out.append(p)
	# The source's own height, which is the ceiling for the whole
	# course — see the stop below.
	var h0 := terrain.bare_height(p.x, p.y)
	var here := h0
	var climbed := 0
	# WATER HAS MOMENTUM, and the first cut did not.
	#
	# Steepest-descent over all eight neighbours, at a 90 m step against
	# relief that is often only a few metres, wandered: the course folded
	# back across itself again and again inside its own 150 m valley, and
	# the result was not a river but a 500 m wide patch of land uniformly
	# 7 m lower than its surroundings. Measured across a section of one,
	# every sample from -250 m to +100 m was cut the full 7 m. Country
	# with a step in it, not a valley with water in it.
	#
	# Keeping a heading and only turning within a cone of it is what a
	# body of moving water actually does, and it is the whole difference
	# between a line and a blob.
	var heading := 0.0
	var have_heading := false
	const TURN := 0.72        # ~41 degrees per 90 m step
	for i in MAX_STEPS:
		var best := p
		var best_h := INF
		var best_a := heading
		for k in 9:
			var off: float = (float(k) / 8.0 - 0.5) * 2.0 * TURN
			var a: float = heading + off + rng.randf_range(-0.06, 0.06)
			if not have_heading:
				a = float(k) / 8.0 * TAU + rng.randf_range(-0.2, 0.2)
			var q := p + Vector2(cos(a), sin(a)) * STEP
			var qh := terrain.bare_height(q.x, q.y)
			if qh < best_h:
				best_h = qh
				best = q
				best_a = a
		heading = best_a
		have_heading = true

		# A RIVER NEVER CLIMBS ABOVE ITS OWN SOURCE.
		#
		# The pooling allowance below lets a course rise for a few steps
		# so a hollow fills and overflows instead of ending the river.
		# That was written against country where 90 m of step was a
		# metre or two of height; once the swell went in, four rising
		# steps could gain 23 m, and gencheck caught a "river" doing
		# exactly that. Water fills a hollow to the level it came in at
		# and no higher, so that is the hard stop — and it is what makes
		# "rivers run downhill" true of the whole course rather than of
		# each step.
		if best_h >= h0:
			break

		# A HOLLOW IS NOT THE END OF A RIVER.
		#
		# The first cut stopped the moment no neighbour was lower, and
		# every river died within four steps: at a 90 m step against
		# detail noise of about 70 m wavelength, small dips are
		# everywhere and each one looked like the sea. Real water fills
		# a hollow and goes over the lip, so a few rising steps are
		# allowed — but only a few, or a "river" would wander uphill
		# across the whole map.
		if best_h >= here:
			climbed += 1
			if climbed > 4:
				break
		else:
			climbed = 0
		here = best_h
		p = best
		out.append(p)
		# THERE IS NO SEA LEVEL HERE, so there was no "reached the low
		# country" to stop at. This loop used to break at `best_h < 1.0`,
		# and that one line was why no river in the world was longer than
		# a puddle: heights are measured from Thornfield's own ground, so
		# 0 m is an arbitrary datum, and about half the Fens, the Hedges
		# and the Reaches sits below 1 m. Every source that sprang died on
		# its first or second step and failed the `size() > 6` test. The
		# same mistake as the two absolute spring thresholds above, made a
		# third time in the same function.
		#
		# A river now ends where water ends: it runs its course, or it
		# pools (`climbed`, above).
	# A handful of points is a puddle.
	return out if out.size() > 6 else PackedVector2Array()


## How deep the water has cut the land, `d` metres from the channel.
##
## Lives here rather than in `WgTerrain` so there is exactly one copy of
## the curve: the terrain owns WHICH water is near a point, this owns
## what being that near to water does to the ground.
static func cut_for(d: float) -> float:
	if d >= VALLEY:
		return 0.0
	if d <= CHANNEL:
		return DEPTH
	if d < BANK:
		return lerpf(DEPTH, SHELF, smoothstep(CHANNEL, BANK, d))
	# The land leans toward the water from a long way off, rather than
	# stepping down to it.
	var t: float = 1.0 - smoothstep(BANK, VALLEY, d)
	return SHELF * t * t


static func to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len2 := ab.length_squared()
	if len2 < 0.0001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / len2, 0.0, 1.0)
	return p.distance_to(a + ab * t)
