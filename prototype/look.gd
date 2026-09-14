class_name Look
extends RefCounted
## The treatment — light, sky, atmosphere and grade.
##
## `design/art-audio.md` §5 (L85): **the look lives in the treatment, not
## the assets.** "Palette, contrast curve and atmosphere carry more of the
## look than geometry does, and they are cheap to change globally and
## late." This file is that claim taken literally: everything here is code
## against a grey mannequin in a box, and it costs nothing.
##
## It is also where L86's regional palettes will live — the six wedges
## differ by light and colour rather than by unique architecture, so
## "which wedge am I in" is answered by swapping the numbers below.
##
## Exposure is set low on purpose. The first pass here was lit like a
## product shot — sun, sky and fill all near full — and everything in
## frame blew out to the same beige, which made every albedo choice
## pointless: a leather tint and a linen tint landed on the same white.
##
## Grounded, overcast, northern. L20 refuses the spectacular and L7/L36
## refuse any hint of magic, so there is nothing here that glows.

## Overcast daylight: a cold sky, a warm-ish low sun, and enough haze
## that distance reads.
const SKY_TOP := Color(0.17, 0.25, 0.36)
const SKY_HORIZON := Color(0.47, 0.50, 0.51)
const GROUND_HORIZON := Color(0.21, 0.21, 0.18)
const GROUND_BOTTOM := Color(0.13, 0.13, 0.12)

const SUN_COLOR := Color(1.0, 0.94, 0.82)
const FILL_COLOR := Color(0.46, 0.56, 0.72)

## The camera-following fill (see aim_fill).
const FILL_NODE := "CameraFill"
## Above the horizon, so it reads as bounced sky rather than a footlight.
const FILL_ELEVATION := -0.35   # radians, ~20°
## Around from the view direction, far enough to shape the figure and not
## so far that it swings behind them again.
const FILL_OFFSET := 0.70       # radians, ~40°
const FOG_COLOR := Color(0.44, 0.49, 0.53)

## The palette, in one place, because L86 makes each of the six wedges a
## different one of these and nothing else — "a screenshot is locatable".
## This is the drill yard: cold, damp, northern, nothing growing.
const EARTH := Color(0.25, 0.27, 0.20)
const STONE := Color(0.35, 0.36, 0.35)
const TIMBER := Color(0.22, 0.17, 0.12)
const KERB := Color(0.25, 0.25, 0.23)
const IRON := Color(0.46, 0.47, 0.50)
const LEATHER := Color(0.26, 0.19, 0.13)

static func build(into: Node3D) -> void:
	_sky(into)
	_lights(into)

static func _sky(into: Node3D) -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = SKY_HORIZON
	sky_material.sky_curve = 0.15
	sky_material.ground_horizon_color = GROUND_HORIZON
	sky_material.ground_bottom_color = GROUND_BOTTOM
	sky_material.ground_curve = 0.1
	sky_material.sun_angle_max = 40.0
	sky_material.sun_curve = 0.1

	var sky := Sky.new()
	sky.sky_material = sky_material

	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = sky

	# Light bounced off an overcast sky is what fills the shadows outdoors.
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_sky_contribution = 1.0
	e.ambient_light_energy = 0.45

	# Haze. Without it the drill yard ends in a hard edge against nothing,
	# and every distance reads the same.
	e.fog_enabled = true
	e.fog_light_color = FOG_COLOR
	e.fog_light_energy = 1.0
	e.fog_sun_scatter = 0.1
	e.fog_density = 0.0035
	e.fog_sky_affect = 0.4
	e.fog_aerial_perspective = 0.3

	# The contrast curve (§5). Filmic keeps highlights from clipping to
	# flat white, which is most of why an untonemapped render looks like
	# a render.
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 0.75
	e.tonemap_white = 6.0

	# The grade. **Contrast, not desaturation** — art-audio.md §2 is
	# blunt about this: "Dark here means *low light*, not desaturated
	# mud. The grey-brown cliché is both a visual dead end and genuinely
	# worse for reading a fight." The first pass here pulled saturation
	# to 0.82 and produced exactly that cliché. The mood comes out of
	# exposure and the contrast curve instead, and the colour stays.
	e.adjustment_enabled = true
	e.adjustment_brightness = 1.0
	e.adjustment_contrast = 1.16
	e.adjustment_saturation = 0.98

	var env := WorldEnvironment.new()
	env.environment = e
	into.add_child(env)

static func _lights(into: Node3D) -> void:
	# A low sun. Long shadows do more for legibility than any amount of
	# geometry — they tell you where things are relative to the ground.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34, -52, 0)
	sun.light_color = SUN_COLOR
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	sun.directional_shadow_max_distance = 60.0
	into.add_child(sun)

	# A dim, cool fill — and it FOLLOWS THE CAMERA. See aim_fill().
	#
	# This is not decoration: combat.md §6 has the player reading attacks
	# off the body, and a figure lit from one side only loses its far edge
	# against the ground.
	#
	# It used to sit at a fixed 132°, opposite the sun, which was fine
	# while the camera was fixed too. The moment the camera could orbit,
	# there were angles you could stand at where both lights were behind
	# the fighter and you were looking at an unreadable silhouette —
	# reported from play as "you can't see a side of the character".
	var fill := DirectionalLight3D.new()
	fill.name = FILL_NODE
	fill.light_color = FILL_COLOR
	fill.light_energy = 0.26
	fill.shadow_enabled = false
	into.add_child(fill)
	aim_fill(into, 0.0)

## Point the fill from over the camera's shoulder, so whichever side of
## the fighter you have orbited around to is the side that is lit.
##
## The SUN does not move, and must not: it carries the shadows, and
## shadows that swung around the yard as you looked would destroy the
## thing they are there for — "long shadows do more for legibility than
## any amount of geometry". A world light that tracks the viewer is not a
## time of day, it is a torch, and the yard would stop reading as
## outdoors at all.
##
## So the sun stays put and the fill does the following. That split is
## the standard one for a reason: shadows stay honest, and the visible
## face is never a silhouette.
static func aim_fill(root: Node3D, camera_yaw: float) -> void:
	var fill := root.get_node_or_null(NodePath(FILL_NODE)) as DirectionalLight3D
	if fill == null:
		return
	# Offset from dead-on so it still SHAPES the figure. A light exactly
	# along the view direction is the flattest light there is — it erases
	# the form it was added to rescue.
	fill.rotation = Vector3(FILL_ELEVATION, camera_yaw + FILL_OFFSET, 0.0)

## Stone, timber, anything that is not ground. Same trick, tighter grain
## and a little less rough, so it reads as a different substance rather
## than as ground standing on end.
static func solid_material(base: Color, tiles: float = 3.0,
		rough: float = 0.85) -> StandardMaterial3D:
	var mat := ground_material(base, tiles)
	mat.roughness = rough
	return mat

## Iron. Rough, and only slightly metallic.
##
## The metallic value is low on purpose and it is not a stylistic choice:
## a metal surface is lit almost entirely by what it reflects, and there
## is nothing here to reflect but a procedural sky. At a realistic 0.75
## every piece of armour rendered as a black silhouette. Grounded iron is
## not a mirror anyway (L20), so this reads better and costs nothing.
static func metal_material(base: Color, rough: float = 0.52) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base
	mat.roughness = rough
	mat.metallic = 0.18
	mat.metallic_specular = 0.55
	return mat

## A ground material with some variation in it. A single flat colour is
## the single most render-like thing in any scene: real ground is
## blotchy, and the blotches are what give the eye scale and speed.
## `tiles` is how many times the texture repeats across the surface, NOT
## a size — setting it below 1 zooms *into* one smooth patch of noise and
## produces a flat colour, which looks exactly like having no texture at
## all and is how this was wrong the first time.
static func ground_material(base: Color, tiles: float = 11.0) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.006
	noise.fractal_octaves = 4

	# Raw noise runs the whole way from black to white, which multiplied
	# into an albedo reads as camouflage rather than as ground. The ramp
	# squeezes it into a narrow band around the base colour: the point is
	# variation you notice only by its absence.
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.74, 0.73, 0.71))
	ramp.set_color(1, Color(1.04, 1.03, 1.00))

	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = 256
	tex.height = 256
	# Seamless, because at this many tiles a visible seam every couple of
	# metres would be worse than no texture at all.
	tex.seamless = true
	tex.generate_mipmaps = true
	tex.color_ramp = ramp

	var mat := StandardMaterial3D.new()
	mat.albedo_color = base
	mat.albedo_texture = tex
	mat.uv1_scale = Vector3(tiles, tiles, tiles)
	mat.roughness = 0.95
	# Rough ground scatters; nothing out here is polished.
	mat.metallic = 0.0
	return mat
