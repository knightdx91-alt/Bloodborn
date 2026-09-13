extends Node3D
## Marrowmark — tech.md §6 Stage 1, step 1: move and look.
## Built headless. Nothing from the game design is in here yet.

var player: CharacterBody3D
var cam: Camera3D

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
	var ground := StaticBody3D.new()
	var gm := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	gm.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.42, 0.42, 0.40)
	gm.material_override = gmat
	ground.add_child(gm)
	var gcol := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(40, 0.2, 40)
	gcol.shape = gbox
	gcol.position = Vector3(0, -0.1, 0)
	ground.add_child(gcol)
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
	dir = dir.normalized()

	var speed := SPRINT if Input.is_key_pressed(KEY_SHIFT) else SPEED

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
	var focus := player.position + Vector3(0, 1.2, 0)
	cam.position = focus + Vector3(0, 3.2, 7.0)
	cam.look_at(focus, Vector3.UP)
