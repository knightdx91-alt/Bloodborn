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
## Settled at **ten times the area**, which is sqrt(10) = 3.162x linear:
##
##     radius    28,460 m        (was 9,000)
##     across    56,921 m
##     area      ~2,545 km2      (was ~255)
##     crossing  211 minutes on foot, or ~84 with a mount at 2.5x
##
## 211 against the 200 asked for. The remaining risk is unchanged and
## is the one tech.md §1a names: filling it. Ten times the land is ten
## times that problem, and it is why the generator exists.
const WORLD_SCALE := 3.1623
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


var seed_value := 0
var _all: Array = []
var _shape: FastNoiseLite
var _detail: FastNoiseLite
var _warp: FastNoiseLite
var _border: FastNoiseLite


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

	# And a field to chew the wedge borders, so a biome edge is a
	# ragged transition rather than a radius line drawn on a map.
	_border = FastNoiseLite.new()
	_border.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_border.seed = world_seed + 9001
	_border.frequency = 1.0 / 800.0

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
	return Vector3(0.0, height_at(0.0, 0.0), 0.0)


## Which wedge, as a float index that can be rounded or blended.
func wedge_at(x: float, z: float) -> int:
	var angle := atan2(z, x)
	# Pushed off the true angle so the six seams are not radial lines.
	angle += _border.get_noise_2d(x, z) * 0.45
	var t := fposmod(angle / TAU, 1.0)
	return int(floor(t * float(WEDGES))) % WEDGES


func biome_at(x: float, z: float) -> Biome:
	return _all[wedge_at(x, z)]


## How far into the capitol's clearing, 0 outside and 1 at the middle.
## The hub is flatter and emptier than the country around it: it is the
## one place all six palettes meet (L86) and a place that reads as built
## rather than grown.
func capitol_blend(x: float, z: float) -> float:
	var r := sqrt(x * x + z * z)
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
	# Warp first. Sampling the shape at a bent coordinate is what turns
	# an even field into country with a grain to it.
	var wx := x + _warp.get_noise_2d(x, z) * 380.0
	var wz := z + _warp.get_noise_2d(x + 5000.0, z - 5000.0) * 380.0

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

	var h := combined * b.relief
	h += _detail.get_noise_2d(x, z) * (1.4 + b.relief * 0.06)

	# The capitol sits in a bowl of quiet ground.
	var cap := capitol_blend(x, z)
	if cap > 0.0:
		h = lerpf(h, 2.0, smoothstep(0.0, 0.85, cap))

	# And the world does not run for ever: the far edge falls away, so
	# the horizon is land ending rather than land stopping.
	var r := sqrt(x * x + z * z)
	if r > WORLD_R:
		h -= (r - WORLD_R) * 0.08
	return h


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
		var x := cos(ang) * TOWN_RING
		var z := sin(ang) * TOWN_RING
		_town_xz[w] = Vector2(x, z)
		_town_level[w] = _raw_height(x, z)
		# The site's own height IS the platform level, by construction —
		# the platform is levelled to the ground that was already there.
		_town_site[w] = Vector3(x, _town_level[w], z)


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
	var lift: float = clampf((h + b.relief) / (b.relief * 2.0 + 0.001), 0.0, 1.0)
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
