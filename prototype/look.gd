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

const SUN_NODE := "Sun"
const ENV_NODE := "Weather"

# ── The day (L89) ────────────────────────────────────────────────────
# The sun MOVES, on one clock everybody shares, and it rises east and
# sets west everywhere — which makes it the compass L80 forbids on
# screen. L80's first preference is to put information in the world,
# and a sun overhead is the oldest instrument there is.
#
# What lives here is only the LOOK. The clock itself is a rule and
# lives in sim/ (L88), because two players standing together have to
# see the same light and a renderer inventing its own hour cannot
# promise that.

## Noon, and the light at the ends of the day. Dawn and dusk run warm
## and weak; noon is neutral and strong.
const SUN_NOON := Color(1.0, 0.96, 0.88)
const SUN_LOW := Color(1.0, 0.72, 0.45)
const SUN_ENERGY_NOON := 1.15
const SUN_ENERGY_LOW := 0.35

## Night, and the first number L89 flagged open.
##
## The first attempt made night BLACK — a rendered frame at dusk showed
## nothing at all, not a silhouette. combat.md §6 needs an attack read
## off the body, so that is not atmosphere, it is the combat not working.
##
## The trap underneath it: ambient light here comes from the SKY
## (`AMBIENT_SOURCE_SKY`, contribution 1.0), so raising the ambient
## energy against a near-black night sky multiplies almost nothing. The
## night sky itself has to carry light — which is also true, since a
## clear night sky is deep blue and not black.
const AMBIENT_DAY := 0.45
const AMBIENT_NIGHT := 0.55
const SKY_TOP_NIGHT := Color(0.11, 0.15, 0.27)
const SKY_HORIZON_NIGHT := Color(0.20, 0.24, 0.34)

## The moon. Not a cheat and not "unexplained visibility" — L20 objects
## to light with no source, and the moon is a source. It is the same
## DirectionalLight3D as the sun, turned cold and weak once the sun is
## down, which costs nothing and keeps the shadow direction honest.
const MOON_COLOR := Color(0.58, 0.66, 0.92)
const MOON_ENERGY := 0.45
const SKY_HORIZON_DUSK := Color(0.55, 0.33, 0.22)
const FOG_NIGHT := Color(0.10, 0.12, 0.18)

## Where the sun stands at the start, and the fill's reference. Named
## rather than inline because aim_fill needs it too — the fill has to
## know when the camera is looking INTO the sun.
const SUN_ELEVATION := -0.59   # radians, ~34° above the horizon
const SUN_YAW := -0.91         # radians, ~-52°

## The camera-following fill (see aim_fill).
const FILL_NODE := "CameraFill"
## Above the horizon, so it reads as bounced sky rather than a footlight.
const FILL_ELEVATION := -0.35   # radians, ~20°
## Around from the view direction, far enough to shape the figure and not
## so far that it swings behind them again.
const FILL_OFFSET := 0.70       # radians, ~40°
## What the fill is worth with the sun behind the camera, where it is
## only stopping the far edge from dissolving into the ground.
const FILL_BASE := 0.26
## What is ADDED when the camera is looking straight into the sun, where
## it is the only thing lighting the face you can see.
##
## Large, and it has to be: at the base value a fighter with the sun
## behind them rendered as a PURE BLACK CUT-OUT against a bright sky.
## Chosen by photographing that exact frame at 0.26, 1.21, 1.80, 2.40 and
## 3.20 — the armour plates and the sword start reading around 2.4, and
## past that the yard stops looking backlit at all.
const FILL_BACKLIT := 2.15
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


## Put the sky where the clock says it is (L89).
##
## Called every frame with the shared clock. Everything visual is blended
## against ONE number, `daylight()` — sun angle, sun colour, sun energy,
## sky, ambient and fog — so nothing re-derives the hour for itself and
## drifts out of step with the rest.
##
## The sun's BEARING is the part that must not be fudged: east at
## sunrise, south at noon, west at sunset, because L89 makes it the
## compass and a compass that drifts is a puzzle.
static func set_time(root: Node3D, clock: WorldClock) -> void:
	var sun := root.get_node_or_null(NodePath(SUN_NODE)) as DirectionalLight3D
	var env := root.get_node_or_null(NodePath(ENV_NODE)) as WorldEnvironment
	if sun == null or env == null:
		return

	var light: float = clock.daylight()

	# Godot's DirectionalLight3D shines along its own -Z. Pitch is the
	# sun's elevation; yaw is its bearing, offset by 180° because the
	# light travels AWAY from where the sun stands.
	sun.rotation = Vector3(
		-deg_to_rad(clock.sun_elevation_degrees()),
		deg_to_rad(clock.sun_azimuth_degrees() + 180.0),
		0.0)
	var elevation: float = clock.sun_elevation_degrees()
	if elevation > -1.0:
		sun.light_color = SUN_LOW.lerp(SUN_NOON, light)
		sun.light_energy = lerpf(SUN_ENERGY_LOW, SUN_ENERGY_NOON, light)
	else:
		# Sun down: the same light becomes the moon, cold and weak, and
		# comes from the opposite side of the sky so shadows still point
		# somewhere honest rather than simply vanishing.
		sun.light_color = MOON_COLOR
		sun.light_energy = MOON_ENERGY
		sun.rotation = Vector3(
			-deg_to_rad(maxf(-elevation, 12.0)),
			deg_to_rad(clock.sun_azimuth_degrees()),
			0.0)

	var e: Environment = env.environment
	e.ambient_light_energy = lerpf(AMBIENT_NIGHT, AMBIENT_DAY, light)
	e.fog_light_color = FOG_NIGHT.lerp(FOG_COLOR, light)

	var sky_mat := e.sky.sky_material as ProceduralSkyMaterial
	if sky_mat != null:
		sky_mat.sky_top_color = SKY_TOP_NIGHT.lerp(SKY_TOP, light)
		# The horizon runs through dusk orange on its way between the
		# two, which is what makes a sunset read as one rather than as
		# the lights being turned down.
		var warm: float = 1.0 - absf(light * 2.0 - 1.0)
		var horizon: Color = SKY_HORIZON_NIGHT.lerp(SKY_HORIZON, light)
		sky_mat.sky_horizon_color = horizon.lerp(SKY_HORIZON_DUSK, warm * 0.55)
		sky_mat.ground_horizon_color = horizon.lerp(GROUND_HORIZON, 0.5)

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
	env.name = ENV_NODE
	env.environment = e
	into.add_child(env)

static func _lights(into: Node3D) -> void:
	# A low sun. Long shadows do more for legibility than any amount of
	# geometry — they tell you where things are relative to the ground.
	var sun := DirectionalLight3D.new()
	sun.name = SUN_NODE
	sun.rotation = Vector3(SUN_ELEVATION, SUN_YAW, 0.0)
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

	# And it gets STRONGER the further the camera turns into the sun.
	#
	# This is the case that was actually reported: stand so the sun is
	# behind the fighter and the side you are looking at is the side the
	# sun never reaches, so they go to a dark shape. A fill that is the
	# same strength all the way round cannot fix that without being so
	# strong everywhere else that it flattens the light the rest of the
	# time — which art-audio.md §5 has already been burnt by once.
	#
	# So it is spent where it is needed and nowhere else: nothing extra
	# with the sun behind you, everything when you are looking at it.
	#
	# Both directions are flattened to the ground. Elevation is not part
	# of the question — the sun is 34° up whatever the camera does, and
	# only the horizontal relationship decides which face is lit.
	var looking := Vector2(-sin(camera_yaw), -cos(camera_yaw))
	var sunward := Vector2(-sin(SUN_YAW), -cos(SUN_YAW))
	# +1 when the camera looks the same way the light travels (the lit
	# face is toward you), -1 when it stares into it (the lit face is
	# away). Only the second half is a problem.
	var backlit: float = clampf(-looking.dot(sunward), 0.0, 1.0)
	# Squared, so the boost concentrates on the angles that are actually
	# a problem and the scene keeps its normal light over most of the
	# turn. A linear ramp put half the extra fill into the three-quarter
	# angles, which never needed it.
	fill.light_energy = FILL_BASE + FILL_BACKLIT * backlit * backlit

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
