class_name WgTerrain
extends RefCounted
## The land itself: how high it is, and what grows there.
##
## Every value here is a **pure function of world position and the world
## seed.** Nothing is remembered between calls and nothing depends on
## the order things are asked for. That is not tidiness — it is the one
## property that makes chunked streaming possible at all. A chunk must
## come out identical whether it is built first, built last, or built
## again an hour later on somebody else's machine, or its edges will not
## meet its neighbours' and the seams will show as cliffs.
##
## It also makes the generator a CONTENT TOOL rather than a runtime
## system, which `tech.md` §1a settles: this runs offline, the result is
## baked and committed, and the committed land is what ships. A world
## rebuilt from a seed on arrival could not hold the clock, the
## territory, the contracts or the war.

## The Wheel (L1): six wedges around a capitol. Angle decides which,
## softened by noise so no border is a drawn line.
const WEDGES := 6
## HOW BIG THE WORLD IS, and where the number came from.
##
## Asked for from play: *"I want it 3x how long it would take you to
## cross Skyrim walking."*
##
## Skyrim is about 6 km across at a walking pace near 1.5 m/s, so
## walking it is roughly 65 minutes; three times that is ~200. The trap
## is that Marrowmark's walk is 4.5 m/s — 16 km/h, a running pace, three
## times Skyrim's — so matching a crossing TIME needs nine times the
## linear size, not three.
##
## Grown again the same day, to a **260-minute crossing** at the 4.5 m/s
## the walk ran at when the size was chosen:
##
##     radius    35,100 m        (9,000 x 3.9)
##     across    70,200 m
##     area      ~3,871 km2      (was ~255, then ~2,545)
##
## The walk was then slowed, which makes the real crossing longer than
## 260 — see `SIZED_AT_SPEED` below and `Fighter.WALK_SPEED_MAX`.
##
## The remaining risk is unchanged and is the one tech.md §1a names:
## filling it. This is fifteen times the land that section costed, and
## it is why the generator exists.
const WORLD_SCALE := 3.9

## The walking speed the world was SIZED against, 2026-09-27.
##
## Kept as its own constant because the size and the speed are now two
## decisions rather than one: the world was sized so that 4.5 m/s gives
## a 260-minute crossing, and the walk was then slowed on purpose. If
## the walk changes again the world does not have to, and a check that
## confused the two would drag the map around behind a feel tweak.
const SIZED_AT_SPEED := 4.5
## What the crossing was sized to take, in minutes, at that speed.
const SIZED_CROSSING_MIN := 260.0
const WORLD_R := 9000.0 * WORLD_SCALE
## The capitol's clearing at the middle.
const CAPITOL_R := 2000.0 * WORLD_SCALE

## One wedge's character. L86 makes this load-bearing rather than
## decorative: with no minimap, the land carries orientation, and a
## screenshot has to be locatable. Two wedges that differ only in tree
## count are two wedges nobody can tell apart.
class Biome extends RefCounted:
	var name := ""
	## Whose country this is (lore.md §5).
	var town := ""
	## How much more likely a settlement here is a ruin. The Wistwood
	## is "old forest with older ruins" and has to look like it.
	var ruin_bias := 0.0
	var ground: Color = Color(0.38, 0.40, 0.22)
	## Metres of relief. Flat country and hill country are the first
	## thing read from a silhouette.
	var relief := 18.0
	## Bigger is smoother. Small values give broken, busy ground.
	var feature_size := 420.0
	## Trees per 100 m², and which trees.
	var tree_density := 0.35
	var trees: Array[String] = []
	var rock_density := 0.10
	var bush_density := 0.25
	var grass_density := 0.9
	## How much the ground colour varies with height, so hills read as
	## a different material from the valleys rather than the same paint.
	var height_tint: Color = Color(0.46, 0.46, 0.34)


static func biomes() -> Array:
	# THE WHEEL'S OWN SIX, from lore.md §5 — not six generic biomes
	# with a wedge index. Each is a named country with a town in it,
	# and the town's trade is what the country is for: Hammarsted has
	# the ore, Vellmark the grass to raise horses on, Greywater the
	# water to move goods along. A wedge whose character does not
	# explain its town is scenery with a label.
	#
	# Order is the ring order, wedge 0 first, going round.
	var out: Array = []

	# Thornfield — the "safe" starting feel that makes the rest darker.
	var hedges := Biome.new()
	hedges.name = "the Hedges"
	hedges.town = "Thornfield"
	hedges.ground = Color(0.42, 0.44, 0.23)
	hedges.relief = 12.0
	hedges.feature_size = 520.0
	hedges.tree_density = 0.22
	hedges.trees = ["CommonTree_1", "CommonTree_2", "CommonTree_3",
		"CommonTree_4", "CommonTree_5"]
	hedges.rock_density = 0.05
	hedges.bush_density = 0.30
	hedges.grass_density = 1.0
	hedges.height_tint = Color(0.52, 0.50, 0.30)
	out.append(hedges)

	# Hammarsted — scarred ore hills. Steep, bare and broken: the
	# country has been dug, and the trees went into the furnaces.
	var barrens := Biome.new()
	barrens.name = "the Ironbarrens"
	barrens.town = "Hammarsted"
	barrens.ground = Color(0.31, 0.24, 0.20)
	barrens.relief = 46.0
	barrens.feature_size = 300.0
	barrens.tree_density = 0.06
	barrens.trees = ["DeadTree_1", "DeadTree_2", "Pine_2"]
	barrens.rock_density = 0.46
	barrens.bush_density = 0.10
	barrens.grass_density = 0.25
	barrens.height_tint = Color(0.44, 0.31, 0.24)
	out.append(barrens)

	# Vellmark — open grass plains, for raising horses on.
	var reaches := Biome.new()
	reaches.name = "the Reaches"
	reaches.town = "Vellmark"
	reaches.ground = Color(0.49, 0.50, 0.27)
	reaches.relief = 9.0
	reaches.feature_size = 760.0
	reaches.tree_density = 0.04
	reaches.trees = ["CommonTree_1", "CommonTree_4"]
	reaches.rock_density = 0.04
	reaches.bush_density = 0.14
	reaches.grass_density = 1.0
	reaches.height_tint = Color(0.58, 0.56, 0.32)
	out.append(reaches)

	# Greywater — waterways and drowned meadows.
	var fens := Biome.new()
	fens.name = "the Fens"
	fens.town = "Greywater"
	fens.ground = Color(0.26, 0.31, 0.21)
	fens.relief = 5.0
	fens.feature_size = 700.0
	fens.tree_density = 0.30
	fens.trees = ["DeadTree_1", "CommonTree_3", "CommonTree_5"]
	fens.rock_density = 0.03
	fens.bush_density = 0.55
	fens.grass_density = 1.0
	fens.height_tint = Color(0.30, 0.34, 0.24)
	out.append(fens)

	# Candlerow — old forest with older ruins. Dense, dim, and the
	# wedge where the generator is told to leave more standing walls.
	var wist := Biome.new()
	wist.name = "the Wistwood"
	wist.town = "Candlerow"
	wist.ground = Color(0.22, 0.27, 0.18)
	wist.relief = 22.0
	wist.feature_size = 430.0
	wist.tree_density = 0.95
	wist.trees = ["CommonTree_2", "CommonTree_3", "CommonTree_5",
		"DeadTree_2", "Pine_1"]
	wist.rock_density = 0.14
	wist.bush_density = 0.48
	wist.grass_density = 0.6
	wist.height_tint = Color(0.28, 0.31, 0.22)
	wist.ruin_bias = 0.25
	out.append(wist)

	# Coldharrow — dark pine highlands, the dangerous frontier.
	var marches := Biome.new()
	marches.name = "the Marches"
	marches.town = "Coldharrow"
	marches.ground = Color(0.24, 0.28, 0.24)
	marches.relief = 68.0
	marches.feature_size = 290.0
	marches.tree_density = 0.70
	marches.trees = ["Pine_1", "Pine_2", "Pine_3"]
	marches.rock_density = 0.30
	marches.bush_density = 0.12
	marches.grass_density = 0.35
	marches.height_tint = Color(0.50, 0.52, 0.50)
	out.append(marches)

	return out


## THORNFIELD IS THE ORIGIN.
##
## The hand-built town stands at (0,0) and every coordinate in
## `town.gd`, and every harness that asserts one, is relative to that.
## Moving the town out to its site on the ring would have broken all of
## it at once, so the WORLD moves instead: these shift wheel
## coordinates so that wedge 0's town site lands exactly on the game's
## origin, and `_origin_h` drops its platform to exactly y = 0.
##
## The Wheel is unchanged — Godsgrave and the other five towns simply
## sit at their true offsets from Thornfield rather than from a point
## nobody stands on.
var _origin_x := 0.0
var _origin_z := 0.0
var _origin_h := 0.0

var seed_value := 0
var _all: Array = []
var _shape: FastNoiseLite
var _detail: FastNoiseLite
var _warp: FastNoiseLite
var _border: FastNoiseLite
var _swell: FastNoiseLite

## Metres the swell lifts or drops the land, on top of the wedge's own
## relief. See `_init`.
const SWELL := 30.0


func _init(world_seed: int = 20260927) -> void:
	seed_value = world_seed
	_all = biomes()

	# THE BIG SHAPE. One low-frequency field for where the hills are.
	_shape = FastNoiseLite.new()
	_shape.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_shape.seed = world_seed
	_shape.frequency = 1.0 / 900.0
	_shape.fractal_octaves = 4
	_shape.fractal_lacunarity = 2.1
	_shape.fractal_gain = 0.48

	# THE DETAIL, at a human scale — the bumps you walk over rather than
	# the hills you walk up.
	_detail = FastNoiseLite.new()
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_detail.seed = world_seed + 7717
	_detail.frequency = 1.0 / 70.0
	_detail.fractal_octaves = 3
	_detail.fractal_gain = 0.42

	# DOMAIN WARP, which is most of what stops generated land looking
	# generated. Straight fractal noise gives an even, woolly field with
	# the same character everywhere; warping the coordinates first bends
	# it into ridges, basins and valleys that read as though water and
	# weather put them there.
	_warp = FastNoiseLite.new()
	_warp.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_warp.seed = world_seed + 4241
	_warp.frequency = 1.0 / 1300.0

	# THE SWELL. Slow, world-wide, and belonging to no wedge.
	#
	# A map of the whole country showed the problem plainly: four of the
	# six wedges were featureless at map scale, because a wedge is one
	# relief number applied evenly over 645 km2 and four of those numbers
	# are small. The Fens SHOULD be flat — Greywater is drowned meadow,
	# not highland — but flat over an hour's walk is not flat country,
	# it is no country.
	#
	# So the world gets a second, much slower field underneath the
	# biomes: broad swells about 5 km across that lift and drop the whole
	# land by tens of metres regardless of whose wedge it is. It gives
	# the flat countries somewhere to be flat BETWEEN, and it makes the
	# steep ones vary instead of being uniformly steep. It also makes
	# each wedge's own texture rougher on the high ground, which is the
	# way real hill country reads: broken on the tops, smooth in the
	# bottoms.
	_swell = FastNoiseLite.new()
	_swell.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_swell.seed = world_seed + 1553
	_swell.frequency = 1.0 / 5200.0
	_swell.fractal_octaves = 2
	_swell.fractal_gain = 0.5

	# And a field to chew the wedge borders, so a biome edge is a
	# ragged transition rather than a radius line drawn on a map.
	_border = FastNoiseLite.new()
	_border.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_border.seed = world_seed + 9001
	_border.frequency = 1.0 / 800.0

	# THE ORIGIN, before anything samples the ground.
	#
	# Wedge 0 is the Hedges, which is Thornfield's. Its site becomes the
	# game's (0,0). `_origin_h` is read while it is still zero, so that
	# first call returns the true unshifted height; afterwards every
	# height is relative to it.
	var ang0 := 0.5 / float(WEDGES) * TAU
	_origin_x = cos(ang0) * TOWN_RING
	_origin_z = sin(ang0) * TOWN_RING
	_origin_h = 0.0
	_origin_h = _raw_height(0.0, 0.0)

	# Last, because it samples the fields above.
	_level_towns()


## How far out the six towns stand from the capitol.
##
## Derived in tech.md §1a rather than chosen: a twenty-minute spoke run
## at the 5 m/s that does not drain stamina. Six towns on that ring are
## also 6 km from each other, so the rim road comes out the same length
## without being tuned to — which is the main evidence the number is
## not arbitrary.
const TOWN_RING := 6000.0 * WORLD_SCALE


## Where a wedge's town stands: the middle of its arc, on the ring.
func town_site(wedge: int) -> Vector3:
	# A lookup. This used to call `height_at`, and WgSettlement.site
	# calls it twelve times per candidate cell — so siting one hamlet
	# meant twelve full heightfield evaluations to fetch six constants.
	if _town_site.is_empty():
		_level_towns()
	return _town_site[wedge]


## Godsgrave, at the middle of everything.
func capitol_site() -> Vector3:
	var x := -_origin_x
	var z := -_origin_z
	return Vector3(x, height_at(x, z), z)


## Which wedge, as a float index that can be rounded or blended.
func wedge_at(x: float, z: float) -> int:
	# Game coordinates in, wheel coordinates for the maths. Everything
	# public on this class takes the game's frame; only the three
	# primitives that read a position convert, which keeps the shift in
	# one layer instead of sprinkled through the file.
	var wx := x + _origin_x
	var wz := z + _origin_z
	var angle := atan2(wz, wx)
	# Pushed off the true angle so the six seams are not radial lines.
	angle += _border.get_noise_2d(wx, wz) * 0.45
	var t := fposmod(angle / TAU, 1.0)
	return int(floor(t * float(WEDGES))) % WEDGES


func biome_at(x: float, z: float) -> Biome:
	return _all[wedge_at(x, z)]


## How far into the capitol's clearing, 0 outside and 1 at the middle.
## The hub is flatter and emptier than the country around it: it is the
## one place all six palettes meet (L86) and a place that reads as built
## rather than grown.
func capitol_blend(x: float, z: float) -> float:
	var wx := x + _origin_x
	var wz := z + _origin_z
	var r := sqrt(wx * wx + wz * wz)
	if r >= CAPITOL_R:
		return 0.0
	return clampf(1.0 - r / CAPITOL_R, 0.0, 1.0)


## The ground, in metres. The whole generator hangs off this one
## function, and it takes no state but the seed.
## The land before anybody levelled any of it.
##
## Split out because the town platforms below need to know how high the
## ground at a town site WOULD have been, and asking `height_at` for
## that would ask it about a site whose level it is in the middle of
## computing. A raw function that knows nothing about towns terminates;
## a clever one does not.
func _raw_height(x: float, z: float) -> float:
	# Into the wheel's frame first — see `_origin_x`.
	var gx := x + _origin_x
	var gz := z + _origin_z
	# Then warp. Sampling the shape at a bent coordinate is what turns
	# an even field into country with a grain to it.
	var wx := gx + _warp.get_noise_2d(gx, gz) * 380.0
	var wz := gz + _warp.get_noise_2d(gx + 5000.0, gz - 5000.0) * 380.0

	var b := biome_at(x, z)
	var shape := _shape.get_noise_2d(wx / (b.feature_size / 420.0),
		wz / (b.feature_size / 420.0))
	# Ridged, for the steeper country: folding the field about zero puts
	# creases in it where the smooth version has a plain hump.
	#
	# SOFTENED, with sqrt(s^2 + e) instead of abs(s). A true absolute
	# value makes a knife-edge crease, and a heightfield sampled at one
	# metre cannot represent one: the mesh straddles the fold, the
	# vertex normal comes out near-vertical on ground that is actually
	# folding hard, and the lighting goes wrong along every ridge in
	# the world. Measured against the true surface normal, the sharp
	# version was out by up to 45 degrees. The epsilon rounds the fold
	# to something a metre grid can actually carry.
	var ridged: float = 1.0 - sqrt(shape * shape + 0.012)
	var steep: float = clampf((b.relief - 20.0) / 50.0, 0.0, 1.0)
	var combined: float = lerpf(shape, ridged * 2.0 - 1.0, steep * 0.6)

	# The swell is sampled at the WARPED coordinate like the shape, so
	# the two agree about where a rise is rather than crossing each
	# other at a slight angle and cancelling into mush.
	var mood := _swell.get_noise_2d(wx, wz)
	var h := combined * b.relief * (1.0 + mood * 0.6) + mood * SWELL
	h += _detail.get_noise_2d(gx, gz) * (1.4 + b.relief * 0.06)

	# The capitol sits in a bowl of quiet ground.
	var cap := capitol_blend(x, z)
	if cap > 0.0:
		h = lerpf(h, 2.0, smoothstep(0.0, 0.85, cap))

	# And the world does not run for ever: the far edge falls away, so
	# the horizon is land ending rather than land stopping.
	var r := sqrt(gx * gx + gz * gz)
	if r > WORLD_R:
		h -= (r - WORLD_R) * 0.08
	# Everything is measured from Thornfield's ground, so the town's
	# own (0,0,0) needs no vertical fudge to sit on the world.
	return h - _origin_h


## How wide a town's levelled ground is, and how far the slope out of
## it reaches. A town is ~750 m across at the size §1a works out, so
## the platform is that plus room to stand back from the walls.
const TOWN_FLAT := 420.0
const TOWN_SKIRT := 320.0

## The six town sites, worked out once.
##
## `_town_level` is the height each platform aims at, from
## `_raw_height` so there is no recursion. `_town_xz` and `_town_site`
## exist because the first cut recomputed `cos(ang) * TOWN_RING` and
## `sin(ang) * TOWN_RING` for all six towns inside `height_at` — which
## is about 27,000 trig calls per chunk to produce six constants that
## never change.
var _town_level: PackedFloat32Array = PackedFloat32Array()
var _town_xz: PackedVector2Array = PackedVector2Array()
var _town_site: Array[Vector3] = []
## Squared, so the common case — a sample nowhere near any town — is
## a subtraction and a compare rather than a square root.
var _town_reach2 := 0.0


func _level_towns() -> void:
	_town_level.resize(WEDGES)
	_town_xz.resize(WEDGES)
	_town_site.resize(WEDGES)
	_town_reach2 = (TOWN_FLAT + TOWN_SKIRT) * (TOWN_FLAT + TOWN_SKIRT)
	for w in WEDGES:
		var ang := (float(w) + 0.5) / float(WEDGES) * TAU
		# In the GAME's frame, so wedge 0 comes out at (0,0) and the
		# rest at their true offsets from Thornfield.
		var x := cos(ang) * TOWN_RING - _origin_x
		var z := sin(ang) * TOWN_RING - _origin_z
		_town_xz[w] = Vector2(x, z)
		_town_level[w] = _raw_height(x, z)
		# The site's own height IS the platform level, by construction —
		# the platform is levelled to the ground that was already there.
		_town_site[w] = Vector3(x, _town_level[w], z)


## THE LAND BEFORE ANY RIVER CUT IT.
##
## Rivers are traced by walking downhill, and they must walk down THIS
## rather than down the finished land: tracing against ground a river
## has already cut lets it chase its own valley in circles, a loop that
## ends only by running out of steps.
func bare_height(x: float, z: float) -> float:
	return _platformed(x, z)


## Rivers near a point, traced once and kept.
##
## Lazily, by source cell, because tracing every river in 3,870 km2 to
## answer one height query would be absurd — and eagerly caching the
## whole world would be 1.4 million traces. A point can only be reached
## by a source within the trace's own length, which is why that length
## is bounded: it is what makes "which rivers matter here" a small,
## answerable question.
var _river_traced: Dictionary = {}
var _river_grid: Dictionary = {}
## Bucket side, and it is deliberately TWICE the valley half-width.
##
## A lookup must see every segment within `VALLEY` of the point. At a
## bucket of exactly VALLEY that takes the 3x3 block around the point —
## nine dictionary probes on every height sample in the world, and
## almost all of them miss, because almost nowhere is within 150 m of
## water. At twice VALLEY the point's own bucket already reaches 300 m
## one way, so only the 2x2 block on the side the point sits in is
## needed: four probes instead of nine, for the same coverage.
const RIVER_BUCKET := 300.0
const RIVER_CACHE_MAX := 4096


## The source cell the last query was in, so a run of samples across
## one chunk does the 25-cell sweep once instead of 4,489 times. That
## sweep was formatting twenty-five dictionary keys as STRINGS per
## height query and cost 24 us a sample against a 2.4 us baseline.
var _river_last := Vector2i(-2147483647, -2147483647)


func _ensure_rivers(x: float, z: float) -> void:
	var cx := int(floor(x / WgRivers.SOURCE_CELL))
	var cz := int(floor(z / WgRivers.SOURCE_CELL))
	var here := Vector2i(cx, cz)
	if here == _river_last:
		return
	_river_last = here
	var reach: int = int(ceil(WgRivers.STEP * float(WgRivers.MAX_STEPS)
		/ WgRivers.SOURCE_CELL))
	for dx in range(-reach, reach + 1):
		for dz in range(-reach, reach + 1):
			var key := Vector2i(cx + dx, cz + dz)
			if _river_traced.has(key):
				continue
			_river_traced[key] = true
			var path := WgRivers.trace(self, seed_value, cx + dx, cz + dz)
			if path.size() < 2:
				continue
			# Bucket each segment into every cell it touches, so a
			# lookup only ever tests water that is actually near.
			for i in range(path.size() - 1):
				var a: Vector2 = path[i]
				var b: Vector2 = path[i + 1]
				var bx0 := int(floor(minf(a.x, b.x) / RIVER_BUCKET))
				var bx1 := int(floor(maxf(a.x, b.x) / RIVER_BUCKET))
				var bz0 := int(floor(minf(a.y, b.y) / RIVER_BUCKET))
				var bz1 := int(floor(maxf(a.y, b.y) / RIVER_BUCKET))
				for bx in range(bx0, bx1 + 1):
					for bz in range(bz0, bz1 + 1):
						var bk := Vector2i(bx, bz)
						# FLAT, pairwise: a bucket is a,b,a,b,... in one
						# PackedVector2Array rather than an Array of
						# two-element Arrays. Every height sample in the
						# world walks these, and an Array of Arrays makes
						# each segment two Variant lookups and a heap
						# object; the packed form is neither.
						if not _river_grid.has(bk):
							_river_grid[bk] = PackedVector2Array()
						var arr: PackedVector2Array = _river_grid[bk]
						arr.push_back(a)
						arr.push_back(b)
						_river_grid[bk] = arr
	if _river_traced.size() > RIVER_CACHE_MAX:
		_river_traced.clear()
		_river_grid.clear()
		_river_last = Vector2i(-2147483647, -2147483647)


## How much the water has taken out of the land here.
func river_cut(x: float, z: float) -> float:
	_ensure_rivers(x, z)
	return WgRivers.cut_for(_nearest_water(x, z))


## The last point this was asked about, and the answer.
##
## A chunk asks it TWICE for every vertex: once through `height_at`,
## which needs the cut, and once through `water_at`, which needs to
## know whether to put a surface there. Same point, same four bucket
## probes, same answer — 4,225 times a chunk.
var _water_at := Vector2(1e30, 1e30)
var _water_was := 0.0


## The 2x2 block of buckets that is guaranteed to hold every segment
## within `VALLEY` of the point — see `RIVER_BUCKET`.
func _nearest_water(x: float, z: float) -> float:
	if _water_at.x == x and _water_at.y == z:
		return _water_was
	_water_was = _nearest_water_raw(x, z)
	_water_at = Vector2(x, z)
	return _water_was


func _nearest_water_raw(x: float, z: float) -> float:
	var bxf := x / RIVER_BUCKET
	var bzf := z / RIVER_BUCKET
	var bx := int(floor(bxf))
	var bz := int(floor(bzf))
	# Which side of its own bucket the point is in decides which
	# neighbours can possibly be nearer than the far wall.
	var ox := bx - 1 if bxf - float(bx) < 0.5 else bx + 1
	var oz := bz - 1 if bzf - float(bz) < 0.5 else bz + 1
	# Unrolled. NOT because it was measured faster — it was not.
	#
	# The theory was that `for dx in [0, sx]` allocates two Arrays on
	# every height sample in the world. It does, and removing them moved
	# the cost by nothing: 1.79 us against 1.86. So the ~2 us a river
	# lookup adds to a height sample is the four Dictionary probes
	# themselves, and that is what a GDScript Dictionary costs. Kept
	# because it is no worse and says plainly which four buckets are
	# read; recorded because a sixth failed performance theory in this
	# generator is worth writing down rather than quietly deleting.
	var p := Vector2(x, z)
	var best := _probe(p, Vector2i(bx, bz), INF)
	if best > WgRivers.CHANNEL:
		best = _probe(p, Vector2i(ox, bz), best)
	if best > WgRivers.CHANNEL:
		best = _probe(p, Vector2i(bx, oz), best)
	if best > WgRivers.CHANNEL:
		best = _probe(p, Vector2i(ox, oz), best)
	return best


func _probe(p: Vector2, bk: Vector2i, best: float) -> float:
	if not _river_grid.has(bk):
		return best
	var arr: PackedVector2Array = _river_grid[bk]
	for i in range(0, arr.size(), 2):
		var d := WgRivers.to_segment(p, arr[i], arr[i + 1])
		if d < best:
			best = d
	return best


## Where the water surface is, or `NO_WATER` if this point is dry.
##
## Taken from the land BEFORE the cut rather than from the finished
## ground, so the surface is as smooth as the country is: reading it off
## `height_at` would make the water copy every ripple in its own bed,
## and a river with a bumpy surface is not a river.
##
## It still slopes, because `_platformed` slopes — which is right. A
## river runs downhill and its surface goes with it.
const NO_WATER := -1.0e9

func water_at(x: float, z: float) -> float:
	_ensure_rivers(x, z)
	if _nearest_water(x, z) > WgRivers.SHEET:
		return NO_WATER
	# A platform is not to be flooded. The cut fades out across the
	# skirt (see `height_at`), so the water has to fade with it and then
	# stop: drawing a sheet at the open-country level over ground that
	# has been levelled back up would put a river through the market.
	var t := town_blend(x, z)
	if t > 0.25:
		return NO_WATER
	return _platformed(x, z) - WgRivers.DEPTH * (1.0 - t) + WgRivers.RISE


## How far the nearest water is, for anything that needs to keep off it.
func river_distance(x: float, z: float) -> float:
	_ensure_rivers(x, z)
	return _nearest_water(x, z)


## The ground, with the towns' own ground levelled into it.
##
## People build on the flat, and 750 m of town on a hillside is 750 m
## of houses floating at one corner and buried at the other. So each
## town site gets a platform at the height the land was already at
## there — levelled, not raised — with a skirt easing out to the
## country around it. The capitol gets the same treatment through
## `capitol_blend`, which predates this.
##
## The land is READY for a town here. There is no town: see STATUS.
func height_at(x: float, z: float) -> float:
	# WATER DOES NOT CUT THROUGH A TOWN.
	#
	# A platform is engineered ground: it is the one place in the world
	# where people have already decided what the land does. A 7 m channel
	# through the middle of Thornfield's market would put the smithy in a
	# ravine. So the cut is faded out across the same skirt the platform
	# uses, which reads as the river being bridged or culverted where the
	# town meets it rather than as water stopping at a line.
	var cut := river_cut(x, z)
	if cut <= 0.0:
		return _platformed(x, z)
	return _platformed(x, z) - cut * (1.0 - town_blend(x, z))


## How much a point belongs to a town's levelled ground: 1 on the flat,
## 0 past the skirt. `capitol_blend` is the same idea, older.
func town_blend(x: float, z: float) -> float:
	var best := capitol_blend(x, z)
	for w in _town_xz.size():
		var t2: Vector2 = _town_xz[w]
		var dx := x - t2.x
		var dz := z - t2.y
		var d2 := dx * dx + dz * dz
		if d2 > _town_reach2:
			continue
		best = maxf(best, 1.0 - smoothstep(TOWN_FLAT,
			TOWN_FLAT + TOWN_SKIRT, sqrt(d2)))
	return clampf(best, 0.0, 1.0)


## The land with the town platforms in it, but no water.
func _platformed(x: float, z: float) -> float:
	var h := _raw_height(x, z)
	if _town_xz.is_empty():
		return h
	for w in _town_xz.size():
		var t2: Vector2 = _town_xz[w]
		var dx := x - t2.x
		var dz := z - t2.y
		var d2 := dx * dx + dz * dz
		if d2 > _town_reach2:
			continue
		var t: float = 1.0 - smoothstep(TOWN_FLAT, TOWN_FLAT + TOWN_SKIRT,
			sqrt(d2))
		return lerpf(h, _town_level[w], t)
	return h


## A NUMBER THAT CHANGES WHENEVER THE GENERATOR DOES.
##
## A baked chunk is an OVERRIDE: it deliberately differs from what the
## generator would make there, because differing is the whole point of
## having baked it. So "is this bake stale" cannot be asked by
## regenerating that chunk and comparing — that question calls every
## hand edit stale and is therefore useless.
##
## It has to be asked of the GENERATOR, away from the chunk. If the
## land the generator makes has moved, an override cut to fit the old
## land no longer meets its neighbours, and the seam is a hole you walk
## into. This session made exactly that change twice over — rivers cut
## 7 m channels, and the swell moved whole regions by tens of metres —
## and nothing would have noticed.
##
## Sampled over the whole world and across everything a chunk is made
## of: height, ground colour, water, roads, and what stands on the
## land. A change to any of those rules moves this number.
var _fingerprint := 0

func fingerprint() -> int:
	# WORKED OUT ONCE. It samples eight hundred cells and a spiral of
	# the finished land, which is nothing to pay once and a great deal
	# to pay per chunk — and the bake tool stamps every chunk it writes.
	if _fingerprint != 0:
		return _fingerprint
	var h := 0x811c9dc5
	var hub := capitol_site()
	for i in 24:
		# A spiral out from the capitol, so the samples cross every
		# wedge at several radii rather than clustering in one country.
		#
		# TWENTY-FOUR, not forty. Each point is in a different part of
		# the world, so each one is a cold river-cache sweep — 49 source
		# cells traced to answer one height query. That made the spiral
		# 6 ms a sample, which is forty times what a warm one costs.
		var a := float(i) / 24.0 * TAU * 5.0
		var r := (0.08 + 0.88 * float(i) / 24.0) * WORLD_R
		var x := hub.x + cos(a) * r
		var z := hub.z + sin(a) * r
		# ROUNDED TO INTEGERS before hashing. A hash of raw floats would
		# be a hash of the last bit of a transcendental function, which
		# is not something two builds have to agree about.
		h = _mix(h, int(round(height_at(x, z) * 64.0)))
		h = _mix(h, int(round(minf(river_distance(x, z), 9999.0))))
		var c := ground_at(x, z)
		h = _mix(h, int(round(c.r * 255.0)) * 65536
			+ int(round(c.g * 255.0)) * 256 + int(round(c.b * 255.0)))

	# AND THE WATER, ASKED WHERE THE WATER IS.
	#
	# The spiral above does not catch a change to the rivers, and this
	# was found by making one: dropping DEPTH from 7.0 m to 6.9 m left
	# the fingerprint bit-identical. Of course it did — one river per
	# 9.4 km2 means a blind sample is a kilometre and a half from the
	# nearest channel, where the cut has no effect at all and
	# `river_distance` has already given up and returned its ceiling.
	#
	# A fingerprint that misses the exact change that moved the land
	# this afternoon is not a fingerprint. So it asks ON the rivers:
	# where the course goes, and how deep the water has cut there.
	for k in 6:
		var path := WgRivers.trace(self, seed_value, 3 + k * 5, -7 - k * 4)
		h = _mix(h, path.size())
		for i in range(0, path.size(), 4):
			var q: Vector2 = path[i]
			h = _mix(h, int(round(q.x * 2.0)) ^ int(round(q.y * 2.0)))
			h = _mix(h, int(round(river_cut(q.x, q.y) * 128.0)))
			var w := water_at(q.x, q.y)
			h = _mix(h, 0 if w <= NO_WATER else int(round(w * 64.0)))

	# THE SIX TOWN SITES, and each wedge's own scatter.
	#
	# Both added after a miss. Widening a town platform by a metre moved
	# nothing, because no blind sample in 3,870 km2 lands on one of six
	# platforms; and changing which trees grow in the Fens moved
	# nothing, because the eight scatter rects below all happened to sit
	# in other wedges. A fingerprint has to be asked where the rule
	# lives, not only where the sampler happened to walk.
	for w in WEDGES:
		var site := town_site(w)
		h = _mix(h, int(round(site.x)) ^ int(round(site.z)))
		for f in [0.0, 0.75, 1.0, 1.4]:
			var d: float = TOWN_FLAT * float(f)
			h = _mix(h, int(round(height_at(site.x + d, site.z) * 64.0)))
			h = _mix(h, int(round(town_blend(site.x + d, site.z) * 4096.0)))
		# ...and what grows in that wedge, sampled in the wedge rather
		# than wherever the scatter loop below happens to fall.
		var near_town := WgScatter.in_rect(self,
			site.x + 900.0, site.z + 900.0,
			site.x + 1020.0, site.z + 1020.0)
		h = _mix(h, near_town.size())
		for item in near_town:
			var tp: Vector3 = item["position"]
			h = _mix(h, hash(item["path"]) ^ int(round(tp.z * 4.0)))

	# HOW OFTEN a river springs, over enough cells to see it.
	#
	# The six courses above catch the shape of a river. They do NOT
	# catch how many there are: nudging `SOURCE_CHANCE` from 0.55 to
	# 0.56 left all six with the same verdict and the fingerprint
	# unmoved. Sixty was not enough either, and the arithmetic says why:
	# moving a chance by one point in a hundred flips one cell in a
	# hundred, so sixty cells miss it more often than not. Four hundred
	# catch it 98 times in 100, and the verdict is cheap —
	# `WgRivers.springs` exists so this can ask four hundred cells
	# without tracing four hundred rivers.
	for k in 400:
		h = _mix(h, 1 if WgRivers.springs(self, seed_value,
			-31 + (k % 20), 19 - (k / 20)) else 0)

	# THE ROADS, which no height or colour sample sees at all: the wear
	# is blended into a chunk's vertex colours, not into `ground_at`.
	# Widening a track by half a metre changed nothing here until this
	# went in.
	var segs := WgRoads.near(self, seed_value, 0.0, 0.0, 4000.0, 4000.0)
	h = _mix(h, segs.size())
	# WHERE the roads run: every endpoint, which is a cheap loop.
	for seg in segs:
		var a2: Vector2 = seg["a"]
		var b2: Vector2 = seg["b"]
		h = _mix(h, int(round(a2.x)) ^ int(round(a2.y * 3.0)))
		h = _mix(h, int(round(b2.x)) ^ int(round(b2.y * 3.0)))
	# And HOW WIDE they are worn, at a dozen points only: `wear` tests
	# the sample against every segment it was given, so a dozen calls
	# against 1,800 segments is 21,600 tests and 260 calls was 1.4
	# million — which was almost the whole of this function's two
	# seconds.
	for i in range(0, segs.size(), maxi(segs.size() / 12, 1)):
		var seg2: Dictionary = segs[i]
		var mid: Vector2 = (seg2["a"] as Vector2).lerp(seg2["b"] as Vector2, 0.5)
		h = _mix(h, int(round(WgRoads.wear(segs, mid.x, mid.y) * 1024.0)))
		h = _mix(h, int(round(WgRoads.wear(segs,
			mid.x + 6.0, mid.y + 6.0) * 1024.0)))

	# And what stands on the land, which no height sample would catch.
	#
	# Same arithmetic as the springs: a one-point change in the chance
	# flips one cell in a hundred, so it takes hundreds of cells to see
	# it. A landmark cell is cheap to ask, so it gets four hundred; a
	# settlement site walks a grid of slope samples, so it gets eight
	# and a coarser change is the price.
	# NEIGHBOURING CELLS, not four hundred scattered ones.
	#
	# Scattered was 1.7 seconds and stayed 1.7 seconds after the gate
	# was made cheap, which is how it became clear the gate was never
	# the cost. `stands` asks `river_distance`, and a point in a part of
	# the world nothing has looked at yet traces the 49 source cells
	# that could reach it — so four hundred points a kilometre apart is
	# four hundred cold sweeps, and past 4,096 traced cells the cache
	# throws itself away and starts again. Twenty by twenty adjacent
	# cells is 6.8 km of country and one sweep.
	#
	# It costs nothing in what this catches: how often a landmark
	# stands is one number for the whole world, and what a landmark IS
	# per biome is the six built in full below.
	for k in 400:
		h = _mix(h, 1 if WgLandmark.stands(self, seed_value,
			23 + (k % 20), -17 + (k / 20)) else 0)
	# And a few built in full, for what a landmark IS rather than
	# whether one is there.
	for k in 6:
		var mark := WgLandmark.at_cell(self, seed_value,
			41 + k * 13, -29 - k * 7)
		h = _mix(h, 1 if mark.is_empty() else
			(mark["pieces"] as Array).size() + 2)
		if not mark.is_empty():
			h = _mix(h, hash(mark["kind"]))
	for k in 8:
		var cx := 9 + k * 37
		var cz := -14 - k * 23
		var found := WgSettlement.site(self, seed_value, cx, cz)
		h = _mix(h, 1 if found.is_empty() else 2)
		if not found.is_empty():
			var at3: Vector3 = found["at"]
			h = _mix(h, int(round(at3.x)) ^ int(round(at3.z)))
		var items := WgScatter.in_rect(self,
			float(cx) * 128.0, float(cz) * 128.0,
			float(cx) * 128.0 + 96.0, float(cz) * 128.0 + 96.0)
		h = _mix(h, items.size())
		for item in items:
			var ip: Vector3 = item["position"]
			h = _mix(h, hash(item["path"]) ^ int(round(ip.x * 4.0)))
	# Never zero: zero is the "no provenance recorded" value a bake
	# written by hand has, and a fingerprint that could collide with it
	# would call an unstamped chunk fresh.
	_fingerprint = maxi(h & 0x7fffffff, 1)
	return _fingerprint


static func _mix(h: int, v: int) -> int:
	var n: int = (h ^ (v & 0xffffffff)) * 16777619
	n = n & 0xffffffff
	return n ^ (n >> 15)


## The surface normal, from finite differences. Used to keep trees off
## cliffs and to tint steep ground as rock.
func slope_at(x: float, z: float, step: float = 2.0) -> float:
	var hx := height_at(x + step, z) - height_at(x - step, z)
	var hz := height_at(x, z + step) - height_at(x, z - step)
	return Vector2(hx, hz).length() / (2.0 * step)


## Ground colour at a point: the biome's, shifted by height and by how
## steep it is, so a hillside is not the valley floor repainted.
func ground_at(x: float, z: float) -> Color:
	return shade(x, z, height_at(x, z), slope_at(x, z))


## The same answer as `ground_at`, for a caller that already knows the
## height and the slope.
##
## A chunk does: it samples the heightfield once into a grid and can
## difference that grid for nothing. Asking `ground_at` instead made
## every vertex cost five more height samples, which is where a chunk's
## build time actually went.
func shade(x: float, z: float, h: float, slope: float) -> Color:
	var b := biome_at(x, z)
	# Scaled by the relief AND the swell, because since the swell exists
	# a height of 30 m says nothing about whether this is high ground for
	# here. Without it every flat wedge's tint saturates the moment the
	# land rises at all, and the Fens come out the colour of a hilltop.
	var span: float = b.relief + SWELL
	var lift: float = clampf((h + span) / (span * 2.0), 0.0, 1.0)
	var c: Color = b.ground.lerp(b.height_tint, lift * 0.55)
	var s: float = clampf(slope / 1.3, 0.0, 1.0)
	# Steep ground shows its bones — but only where it is genuinely
	# steep. At 0.8 toward grey over a 0.9 slope range, the steeper
	# wedges came out uniformly slate and lost the palette L86 makes
	# load-bearing: the Ironwood and the Moor were the same colour,
	# which is two wedges nobody can tell apart.
	c = c.lerp(Color(0.40, 0.39, 0.36), s * 0.42)
	var cap := capitol_blend(x, z)
	if cap > 0.0:
		c = c.lerp(Color(0.47, 0.45, 0.41), smoothstep(0.0, 0.9, cap) * 0.7)
	return c
