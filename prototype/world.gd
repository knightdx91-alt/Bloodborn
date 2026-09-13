extends Node3D
## Marrowmark — tech.md §6 Stage 1, step 1: move and look.
## Built headless. Nothing from the game design is in here yet.

var player: CharacterBody3D
var cam: Camera3D

# Touch input: drag anywhere to steer, like a floating thumbstick.
var _touch_id := -1
var _touch_origin := Vector2.ZERO
var _touch_vec := Vector2.ZERO
const TOUCH_RANGE := 90.0  # pixels of drag for full tilt

const SPEED := 4.0
const SPRINT := 7.0
const GRAVITY := 18.0
const TURN := 10.0

func _ready() -> void:
	# ── Light ───────────────────────────────────────────────────────
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.1
	add_child(sun)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.17, 0.19)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.37, 0.42)
	e.ambient_light_energy = 0.8
	env.environment = e
	add_child(env)

	# ── Ground ──────────────────────────────────────────────────────
	const YARD := 30.0  # half-extent of the drill yard

	var ground := StaticBody3D.new()
	var gm := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(YARD * 2.0, YARD * 2.0)
	gm.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.42, 0.42, 0.40)
	gm.material_override = gmat
	ground.add_child(gm)
	var gcol := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(YARD * 2.0, 0.2, YARD * 2.0)
	gcol.shape = gbox
	gcol.position = Vector3(0, -0.1, 0)
	ground.add_child(gcol)

	# Yard walls. You should never be able to walk into the void —
	# falling out of the world is the least informative bug there is.
	for i in 4:
		var wall := CollisionShape3D.new()
		var wb := BoxShape3D.new()
		var along := YARD * 2.0 + 2.0
		wb.size = Vector3(along, 6.0, 1.0) if i < 2 else Vector3(1.0, 6.0, along)
		wall.shape = wb
		match i:
			0: wall.position = Vector3(0, 3, -YARD)
			1: wall.position = Vector3(0, 3, YARD)
			2: wall.position = Vector3(-YARD, 3, 0)
			3: wall.position = Vector3(YARD, 3, 0)
		ground.add_child(wall)

		# A low kerb so the wall is visible, not just felt.
		var kerb := MeshInstance3D.new()
		var km := BoxMesh.new()
		km.size = Vector3(along, 0.6, 0.6) if i < 2 else Vector3(0.6, 0.6, along)
		kerb.mesh = km
		kerb.position = Vector3(wall.position.x, 0.3, wall.position.z)
		var kmat := StandardMaterial3D.new()
		kmat.albedo_color = Color(0.26, 0.25, 0.24)
		kerb.material_override = kmat
		ground.add_child(kerb)

	add_child(ground)

	# ── Some blocks to walk around, so movement reads ───────────────
	for spot in [Vector3(6, 0.75, -4), Vector3(-5, 0.75, -7), Vector3(-7, 0.75, 3)]:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.5, 1.5, 1.5)
		b.mesh = bm
		b.position = spot
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(0.30, 0.29, 0.27)
		b.material_override = bmat
		add_child(b)

	# ── Training dummy (step 3 will make it react) ──────────────────
	var dummy := MeshInstance3D.new()
	dummy.mesh = CapsuleMesh.new()
	dummy.position = Vector3(3, 1, -2)
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.55, 0.38, 0.30)
	dummy.material_override = dmat
	add_child(dummy)

	# ── Player ──────────────────────────────────────────────────────
	player = CharacterBody3D.new()
	player.position = Vector3(0, 1, 2)
	var pm := MeshInstance3D.new()
	pm.mesh = CapsuleMesh.new()
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.72, 0.70, 0.66)
	pm.material_override = pmat
	player.add_child(pm)

	# A nose, so you can see which way you are facing.
	var nose := MeshInstance3D.new()
	var nm := BoxMesh.new()
	nm.size = Vector3(0.18, 0.18, 0.5)
	nose.mesh = nm
	nose.position = Vector3(0, 0.35, -0.55)
	nose.material_override = pmat
	player.add_child(nose)

	var pcol := CollisionShape3D.new()
	var caps := CapsuleShape3D.new()
	caps.height = 2.0
	caps.radius = 0.5
	pcol.shape = caps
	player.add_child(pcol)
	add_child(player)

	# ── Camera ──────────────────────────────────────────────────────
	cam = Camera3D.new()
	add_child(cam)
	_place_camera()

func _unhandled_input(event: InputEvent) -> void:
	# One finger, anywhere on screen. Where you first press becomes the
	# centre; dragging away from it steers. Nothing to aim at, which
	# matters on a phone where you cannot see your own thumb.
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_touch_origin = event.position
			_touch_vec = Vector2.ZERO
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			_touch_vec = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == _touch_id:
		var offset: Vector2 = event.position - _touch_origin
		_touch_vec = offset / TOUCH_RANGE
		if _touch_vec.length() > 1.0:
			_touch_vec = _touch_vec.normalized()

func _physics_process(delta: float) -> void:
	if player == null:
		return

	# Read WASD / arrows directly — no input map to configure.
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.z += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	# Touch overrides keys when a finger is down.
	if _touch_id != -1 and _touch_vec.length() > 0.15:
		dir = Vector3(_touch_vec.x, 0.0, _touch_vec.y)

	var pushed := dir.length()
	dir = dir.normalized()

	# On touch, how far you drag is how fast you go — so a small nudge
	# walks and a full push runs, without a separate sprint button.
	var speed := SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		speed = SPRINT
	elif _touch_id != -1:
		speed = lerp(SPEED * 0.45, SPRINT, clamp(pushed, 0.0, 1.0))

	player.velocity.x = dir.x * speed
	player.velocity.z = dir.z * speed

	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	else:
		player.velocity.y = -0.1

	player.move_and_slide()

	# Turn to face travel.
	if dir.length() > 0.01:
		var want := atan2(-dir.x, -dir.z)
		player.rotation.y = lerp_angle(player.rotation.y, want, TURN * delta)

	_place_camera()

func _place_camera() -> void:
	# A portrait phone has a narrow horizontal field of view, so the
	# camera pulls back on tall screens to keep the same amount of world
	# on screen. Without this the game is unplayable on a phone and fine
	# on a laptop, which is the worst kind of bug to find late.
	var vp := get_viewport().get_visible_rect().size
	var aspect: float = vp.x / max(vp.y, 1.0)

	# 0 on a wide screen, 1 on a tall phone in portrait.
	var tall: float = clamp((1.5 - aspect) / 1.1, 0.0, 1.0)

	# Portrait gets a steeper, slightly closer view. A tall screen shows
	# far too much sky at a laptop's camera angle, which makes the game
	# unplayable on a phone and fine everywhere else — the worst kind of
	# bug to find late.
	var height: float = lerp(3.2, 8.5, tall)
	var back: float = lerp(7.0, 6.0, tall)

	var focus := player.position + Vector3(0, 1.2, 0)
	cam.position = focus + Vector3(0, height, back)
	cam.look_at(focus, Vector3.UP)
