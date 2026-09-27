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
## Metres from the centre to the outer edge of the world, per §1a.
const WORLD_R := 9000.0
## The capitol's clearing at the middle.
const CAPITOL_R := 2000.0

## One wedge's character. L86 makes this load-bearing rather than
## decorative: with no minimap, the land carries orientation, and a
## screenshot has to be locatable. Two wedges that differ only in tree
## count are two wedges nobody can tell apart.
class Biome extends RefCounted:
	var name := ""
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
	var out: Array = []

	var downs := Biome.new()
	downs.name = "the Harvest Downs"
	downs.ground = Color(0.42, 0.44, 0.23)
	downs.relief = 12.0
	downs.feature_size = 520.0
	downs.tree_density = 0.22
	downs.trees = ["CommonTree_1", "CommonTree_2", "CommonTree_3",
		"CommonTree_4", "CommonTree_5"]
	downs.rock_density = 0.05
	downs.bush_density = 0.30
	downs.grass_density = 1.0
	downs.height_tint = Color(0.52, 0.50, 0.30)
	out.append(downs)

	var iron := Biome.new()
	iron.name = "the Ironwood"
	iron.ground = Color(0.24, 0.26, 0.19)
	iron.relief = 42.0
	iron.feature_size = 330.0
	iron.tree_density = 0.85
	iron.trees = ["Pine_1", "Pine_2", "Pine_3", "CommonTree_2"]
	iron.rock_density = 0.22
	iron.bush_density = 0.20
	iron.grass_density = 0.5
	iron.height_tint = Color(0.34, 0.33, 0.28)
	out.append(iron)

	var moor := Biome.new()
	moor.name = "the Moor"
	moor.ground = Color(0.34, 0.29, 0.20)
	moor.relief = 26.0
	moor.feature_size = 610.0
	moor.tree_density = 0.05
	moor.trees = ["DeadTree_1", "DeadTree_2"]
	moor.rock_density = 0.34
	moor.bush_density = 0.42
	moor.grass_density = 0.7
	moor.height_tint = Color(0.44, 0.36, 0.26)
	out.append(moor)

	var fen := Biome.new()
	fen.name = "the Fen"
	fen.ground = Color(0.26, 0.31, 0.21)
	fen.relief = 5.0
	fen.feature_size = 700.0
	fen.tree_density = 0.30
	fen.trees = ["DeadTree_1", "CommonTree_3", "CommonTree_5"]
	fen.rock_density = 0.03
	fen.bush_density = 0.55
	fen.grass_density = 1.0
	fen.height_tint = Color(0.30, 0.34, 0.24)
	out.append(fen)

	var high := Biome.new()
	high.name = "the High Pines"
	high.ground = Color(0.28, 0.30, 0.24)
	high.relief = 68.0
	high.feature_size = 290.0
	high.tree_density = 0.70
	high.trees = ["Pine_1", "Pine_2", "Pine_3"]
	high.rock_density = 0.30
	high.bush_density = 0.12
	high.grass_density = 0.35
	high.height_tint = Color(0.56, 0.56, 0.54)
	out.append(high)

	var chalk := Biome.new()
	chalk.name = "the Chalk"
	chalk.ground = Color(0.55, 0.53, 0.38)
	chalk.relief = 16.0
	chalk.feature_size = 480.0
	chalk.tree_density = 0.08
	chalk.trees = ["CommonTree_1", "CommonTree_4"]
	chalk.rock_density = 0.16
	chalk.bush_density = 0.18
	chalk.grass_density = 0.8
	chalk.height_tint = Color(0.68, 0.66, 0.52)
	out.append(chalk)

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
func height_at(x: float, z: float) -> float:
	# Warp first. Sampling the shape at a bent coordinate is what turns
	# an even field into country with a grain to it.
	var wx := x + _warp.get_noise_2d(x, z) * 380.0
	var wz := z + _warp.get_noise_2d(x + 5000.0, z - 5000.0) * 380.0

	var b := biome_at(x, z)
	var shape := _shape.get_noise_2d(wx / (b.feature_size / 420.0),
		wz / (b.feature_size / 420.0))
	# Ridged, for the steeper country: folding the field about zero puts
	# creases in it where the smooth version has a plain hump.
	var ridged: float = 1.0 - absf(shape)
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
