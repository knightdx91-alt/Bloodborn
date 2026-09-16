class_name Atmosphere
extends RefCounted
## The things that move when nothing else is happening.
##
## Thornfield was a good-looking diorama: solid buildings, real people,
## and a completely still frame between one bark and the next. Smoke off
## a roof does more for "somebody lives here" than another prop does,
## and it costs a particle system.
##
## **CPUParticles3D, deliberately.** The project is `gl_compatibility` on
## every platform including the web build and the APK (`tech.md`), and
## GPU particles are the riskier bet there. These are small counts on a
## handful of emitters; the CPU will not notice and the web build will
## not surprise us.

## Smoke thins out in the middle of the day and thickens at night, when a
## hearth is doing more than cooking. One number, from the same clock
## everything else reads (L89).
const SMOKE_DAY := 0.35
const SMOKE_NIGHT := 1.0


## One soft round puff, built at runtime so there is no texture to ship.
static func _puff() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	# Feathered rather than linear: a straight ramp still reads as a
	# disc with a visible edge.
	g.add_point(0.55, Color(1, 1, 1, 0.55))
	g.add_point(0.8, Color(1, 1, 1, 0.16))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


## A chimney, smoking.
static func chimney(parent: Node3D, at: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = at
	p.amount = 18
	p.lifetime = 4.5
	p.explosiveness = 0.0
	p.randomness = 0.55
	p.local_coords = false

	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.55, 0.55)
	p.mesh = mesh

	var mat := StandardMaterial3D.new()
	# A soft radial falloff, generated rather than authored. Without it a
	# billboarded quad is a hard-edged WHITE SQUARE hanging over the roof,
	# which is what the first version looked like from across the square.
	mat.albedo_texture = _puff()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	# Billboarded quads need this or every puff turns with the camera as
	# one flat sheet and reads as a decal rather than as smoke.
	mat.billboard_keep_scale = true
	mat.albedo_color = Color(0.70, 0.68, 0.66, 0.22)
	mat.disable_receive_shadows = true
	p.material_override = mat

	p.direction = Vector3.UP
	p.spread = 12.0
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.1
	# A breath of wind, so it leans instead of rising like a column.
	p.gravity = Vector3(0.35, 0.18, -0.2)
	p.damping_min = 0.15
	p.damping_max = 0.4
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0

	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.35))
	grow.add_point(Vector2(1.0, 2.6))
	p.scale_amount_curve = grow

	var fade := Gradient.new()
	fade.set_color(0, Color(0.72, 0.70, 0.67, 0.26))
	fade.set_color(1, Color(0.76, 0.76, 0.74, 0.0))
	p.color_ramp = fade

	parent.add_child(p)
	return p


## The forge, glowing. Warm, small, and stronger after dark — the one
## light in Thornfield that is somebody working rather than the sky.
static func forge(parent: Node3D, at: Vector3) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = at + Vector3(0, 1.1, 0)
	l.light_color = Color(1.0, 0.62, 0.28)
	l.omni_range = 7.5
	l.light_energy = 0.8
	l.shadow_enabled = false
	parent.add_child(l)
	return l


## Birds, crossing. Three of them on a slow circuit, high enough to read
## as distance rather than as geometry.
static func birds(parent: Node3D, centre: Vector3) -> Node3D:
	var flock := Node3D.new()
	flock.name = "Birds"
	flock.position = centre
	parent.add_child(flock)
	for i in 3:
		var b := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.5, 0.08, 0.16)
		b.mesh = m
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.12, 0.12, 0.14)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		b.material_override = mat
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flock.add_child(b)
	return flock


## Move the flock. Called from the town's _process with the elapsed time.
static func fly(flock: Node3D, t: float) -> void:
	if flock == null:
		return
	var n := flock.get_child_count()
	for i in n:
		var b := flock.get_child(i) as Node3D
		# Spread around one wide circuit rather than three, so they read
		# as a flock rather than as three independent objects.
		var a: float = t * 0.16 + float(i) * 0.5
		var r: float = 26.0 + 3.0 * float(i)
		b.position = Vector3(cos(a) * r, 15.0 + sin(t * 0.7 + float(i)) * 1.2,
			sin(a) * r)
		b.rotation.y = -a + PI * 0.5


## Birds are a dawn and dusk thing: out when the light is changing, not
## at midnight and not interestingly at noon.
##
## Keyed on the HOUR rather than on daylight(), which saturates — an
## earlier version asked for "halfway between dark and light" and got a
## band so narrow the flock was never visible at all, at any hour.
static func flying_hour(hour: float) -> bool:
	var h: float = fmod(hour, 24.0)
	if h < 0.0:
		h += 24.0
	return (h >= 5.0 and h < 8.5) or (h >= 16.5 and h < 20.0)


## Push the hour into everything that answers to it.
static func set_time(smokes: Array, forge_light: OmniLight3D,
		flock: Node3D, clock: WorldClock) -> void:
	if clock == null:
		return
	var day: float = clock.daylight()
	for s in smokes:
		if not is_instance_valid(s):
			continue
		# Opacity rather than particle COUNT. amount_ratio is a
		# GPUParticles3D property and does not exist here, and changing
		# `amount` on a CPU system restarts it — which would pop every
		# chimney in town each time the hour moved.
		var mat := (s as CPUParticles3D).material_override as StandardMaterial3D
		if mat != null:
			var thick: float = lerpf(SMOKE_NIGHT, SMOKE_DAY, day)
			mat.albedo_color.a = 0.22 * thick
	if is_instance_valid(forge_light):
		# Brightest at night, and never off: a forge banked overnight
		# still glows, and L20 wants a source for every light.
		forge_light.light_energy = lerpf(1.6, 0.45, day)
	if is_instance_valid(flock):
		flock.visible = flying_hour(clock.hour())
