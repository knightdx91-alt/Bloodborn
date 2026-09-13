extends Node3D
## Marrowmark — tech.md §6 Stage 1, step 1: move and look.
## Built headless. Nothing from the game design is in here yet.

var player: CharacterBody3D
var cam: Camera3D
var anim: AnimationPlayer

# The character and every clip are direct Mixamo downloads of the same
# skeleton, so the clips play exactly as they arrived — no retargeting.
# Anything that re-exports the character through Blender bakes a Z-up
# rest rotation into the rig and breaks this; see SPEC-character-v3.md.
const CHARACTER := "res://assets/models/humanoid.fbx"
const LOCOMOTION := {
	"idle": "res://assets/animations/anim_Idle.fbx",
	"walk": "res://assets/animations/anim_Walking.fbx",
	"run": "res://assets/animations/anim_Running.fbx",
	"roll": "res://assets/animations/anim_Quick_Roll_To_Run.fbx",
	"swing": "res://assets/animations/anim_Stable_Sword_Outward_Slash.fbx",
}

# "Quick Roll To Run" is a run, then a roll, then a run again. Only the
# roll is wanted, and these are where it starts and ends — measured off
# the hips, which drop from 0.70m to 0.18m and back over this window.
const ROLL_START := 0.60
const ROLL_END := 1.30

# Same treatment for the swing. The right arm peaks at 1800 deg/s at
# 0.85s into the clip, so the window is placed to put that moment inside
# the active window rather than anywhere in particular.
const SWING_START := 0.49
const SWING_END := 1.36

# The training sword and the dummy. These are NOT tuning and do not
# belong in shared/tuning/combat.json: combat.md §3 has raw damage
# coming from the weapon, and L4 has weapons coming from players, so
# there is no such thing in the design as "the damage of a sword" — it
# is rolled per item by the crafting system. These are stand-ins.
const SWORD_MODEL := "res://assets/models/weapon_sword.fbx"
# How far down the blade the fist closes, in metres. Negative slides the
# grip back so the pommel sits below the hand rather than inside it.
const SWORD_GRIP_ALONG_BLADE := -0.06
const SWORD_DAMAGE := 28.0
const DUMMY_HEALTH := 120.0
const DUMMY_RESET_SECONDS := 3.0
const DUMMY_MODEL := "res://assets/models/dummy.fbx"
const DUMMY_HOME := Vector3(3, 0, -2)
const DUMMY_COLOR := Color(0.55, 0.38, 0.30)
const DUMMY_RADIUS := 0.45
const DUMMY_HALF_HEIGHT := 0.75

var dummy: Node3D
var _dummy_skin: StandardMaterial3D
var _dummy_health := 0.0
var _dummy_flash := 0.0
var _dummy_rock := 0.0
var _dummy_down := 0.0

var stamina: Stamina
var dodge: Dodge
var attack: Attack
var _dodge_dir := Vector3.FORWARD
var _dodge_travelled := 0.0

# Prototype scaffolding, not a design decision. There is nothing to dodge
# yet, so the invulnerable window would otherwise be invisible. Both of
# these come out at step 3, when the dummy swings back.
const SHOW_DEBUG := true
var _phase_label: Label
var _skin: StandardMaterial3D
var _dodge_count := 0
var _swing_count := 0
var _last_release := "-"
var _skin_base_color := Color(1, 1, 1)

# Roughly the ground speed each clip was authored at. Used only to keep
# the feet from skating; it is a look, not a rule.
const WALK_CLIP_SPEED := 1.5
const RUN_CLIP_SPEED := 4.2
const WALK_TO_RUN := 2.0

# Touch input: drag anywhere to steer, like a floating thumbstick.
var _touch_id := -1
var _touch_origin := Vector2.ZERO
var _touch_vec := Vector2.ZERO
const TOUCH_RANGE := 90.0  # pixels of drag for full tilt

# What separates a tap from the beginning of a steer.
#
# The frame count is not redundant with the clock, and it is the clause
# that matters on a bad device: a press and a release the game only got
# to look at three frames apart are a tap whatever the wall clock says.
# Judged by the clock alone, a 70ms tap on a machine running at 3fps
# measures as 959ms held and is silently thrown away — which is exactly
# what happened, twice, before the numbers were put on screen.
const TAP_MILLISECONDS := 260
const TAP_FRAMES := 3
const TAP_SLOP := 24.0
var _touch_started := 0
var _touch_started_frame := 0
var _touch_max_drag := 0.0
var _touch_dodged := false

const SPEED := 4.0
const SPRINT := 7.0
const GRAVITY := 18.0
const TURN := 10.0
# Above this, you are sprinting and paying for it.
const SPRINT_THRESHOLD := 5.0
const EXHAUSTED_SPEED := 0.6

func _ready() -> void:
	# Belt and braces with the project setting: an emulated click arrives
	# BEFORE the touch that caused it, so leaving this on fires a swing on
	# press and then blocks the second-finger dodge.
	Input.set_emulate_mouse_from_touch(false)

	# ── Light ───────────────────────────────────────────────────────
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true  # without it the character floats
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

	# ── Training dummy ──────────────────────────────────────────────
	dummy = Node3D.new()
	dummy.position = DUMMY_HOME
	var post := (load(DUMMY_MODEL) as PackedScene).instantiate()
	# It stands up on its own — the Z-up rotation is already baked into
	# the mesh node — but its origin is at its middle, so it needs
	# raising onto the ground.
	post.position = Vector3(0, DUMMY_HALF_HEIGHT, 0)
	dummy.add_child(post)
	var dmesh := _find(post, "MeshInstance3D") as MeshInstance3D
	if dmesh != null:
		_dummy_skin = StandardMaterial3D.new()
		_dummy_skin.albedo_color = DUMMY_COLOR
		dmesh.material_override = _dummy_skin
	add_child(dummy)
	_dummy_health = DUMMY_HEALTH

	# ── Player ──────────────────────────────────────────────────────
	player = CharacterBody3D.new()
	player.position = Vector3(0, 1, 2)

	var body := (load(CHARACTER) as PackedScene).instantiate()
	# The capsule is two metres tall and centred on the player's origin,
	# so the character hangs a metre below it to stand on its feet.
	body.position = Vector3(0, -1.0, 0)
	# Mixamo characters face +Z. Travel here is toward -Z.
	body.rotation_degrees = Vector3(0, 180, 0)
	player.add_child(body)
	_rig(body)

	stamina = Stamina.new()
	dodge = Dodge.new()
	attack = Attack.new()

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

	_build_interface()

func _find(node: Node, cls: String) -> Node:
	if node.get_class() == cls:
		return node
	for child in node.get_children():
		var hit := _find(child, cls)
		if hit != null:
			return hit
	return null

func _rig(body: Node) -> void:
	var skel := _find(body, "Skeleton3D") as Skeleton3D
	if skel == null:
		push_warning("no Skeleton3D in the character; movement will be mute")
		return

	var lib := AnimationLibrary.new()
	for key in LOCOMOTION:
		var src := (load(LOCOMOTION[key]) as PackedScene).instantiate()
		var src_anim := _find(src, "AnimationPlayer") as AnimationPlayer
		var clip: Animation = src_anim.get_animation(src_anim.get_animation_list()[0])
		if key == "roll" or key == "swing":
			clip.loop_mode = Animation.LOOP_NONE
			_flatten_root_motion(clip)
		else:
			clip.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(key, clip)
		src.queue_free()

	# Own the skin material so the i-frame tint below has something to
	# write to. Scaffolding — see SHOW_DEBUG.
	if SHOW_DEBUG:
		var mesh := _find(body, "MeshInstance3D") as MeshInstance3D
		if mesh != null:
			var base := mesh.get_active_material(0)
			_skin = base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new()
			_skin_base_color = _skin.albedo_color
			mesh.material_override = _skin

	_arm(skel)

	anim = AnimationPlayer.new()
	skel.get_parent().add_child(anim)
	anim.root_node = anim.get_path_to(skel.get_parent())
	anim.add_animation_library("", lib)
	anim.play("idle")

func _arm(skel: Skeleton3D) -> void:
	# Put a sword in the right hand.
	#
	# There is no grip marker on a Mixamo hand, and guessing rotations is
	# a slow way to be wrong. The hand's own bones give the answer: the
	# fingers curl around the grip, so the blade runs along the line
	# across the knuckles — from the base of the little finger out past
	# the base of the index finger. That derivation holds for any hand in
	# any rig, which matters because every weapon in the game will use it.
	var hand := skel.find_bone("mixamorig_RightHand")
	var index := skel.find_bone("mixamorig_RightHandIndex1")
	var pinky := skel.find_bone("mixamorig_RightHandPinky1")
	if hand < 0:
		return

	var grip := BoneAttachment3D.new()
	grip.bone_idx = hand
	skel.add_child(grip)

	var sword := (load(SWORD_MODEL) as PackedScene).instantiate()
	grip.add_child(sword)

	if index >= 0 and pinky >= 0:
		var to_hand := skel.get_bone_global_rest(hand).affine_inverse()
		var grip_axis: Vector3 = (to_hand * skel.get_bone_global_rest(index).origin
			- to_hand * skel.get_bone_global_rest(pinky).origin).normalized()
		sword.quaternion = Quaternion(_longest_axis(sword), grip_axis)
		sword.position = grip_axis * SWORD_GRIP_ALONG_BLADE
	else:
		push_warning("no finger bones; the sword will be held badly")

func _longest_axis(weapon: Node3D) -> Vector3:
	# Which way the weapon points, measured rather than assumed. A blade
	# is much longer than it is wide, so the longest side of its bounding
	# box is the blade, and which end of that box the origin sits at says
	# which way it points. The sword's runs along its own -Z; assuming +Y
	# put it through the character's hip. Measuring works for the axe and
	# the spear too, which point somewhere else again.
	var box := AABB()
	var first := true
	for child in weapon.get_children():
		if child is MeshInstance3D:
			var mi := child as MeshInstance3D
			var a: AABB = mi.transform * mi.get_aabb()
			box = a if first else box.merge(a)
			first = false
	if first:
		return Vector3.UP

	var axis := 0
	for i in [1, 2]:
		if box.size[i] > box.size[axis]:
			axis = i

	var out := Vector3.ZERO
	# Away from the origin: the fist is at the grip, the point is not.
	out[axis] = 1.0 if box.position[axis] + box.size[axis] * 0.5 > 0.0 else -1.0
	return out

func _flatten_root_motion(clip: Animation) -> void:
	# The roll travels 5.8 metres in the clip. Movement is the character
	# controller's job — the server has no animations and still has to
	# agree where everybody is (combat.md §7) — so the horizontal travel
	# is zeroed out. The vertical dip stays: that IS the roll.
	for t in clip.get_track_count():
		if clip.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		if not String(clip.track_get_path(t)).ends_with("Hips"):
			continue
		for k in clip.track_get_key_count(t):
			var v: Vector3 = clip.track_get_key_value(t, k)
			clip.track_set_key_value(t, k, Vector3(0.0, v.y, 0.0))

func _animate(ground_speed: float) -> void:
	if anim == null:
		return
	if not dodge.can_act() or not attack.can_act():
		return  # the roll or the swing owns the body until it is over
	var want := "idle"
	var rate := 1.0
	if ground_speed > 0.15:
		if ground_speed < WALK_TO_RUN:
			want = "walk"
			rate = ground_speed / WALK_CLIP_SPEED
		else:
			want = "run"
			rate = ground_speed / RUN_CLIP_SPEED
	if anim.current_animation != want:
		anim.play(want, 0.15)
	# Kept near 1.0 on purpose. Pushing a clip past about 1.35x reads as
	# comical long before it stops skating, so the sprint is allowed to
	# slide a little rather than gabble.
	anim.speed_scale = clamp(rate, 0.7, 1.35)

func _unhandled_input(event: InputEvent) -> void:
	# One finger, anywhere on screen. Where you first press becomes the
	# centre; dragging away from it steers. Nothing to aim at, which
	# matters on a phone where you cannot see your own thumb.
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_touch_origin = event.position
			_touch_vec = Vector2.ZERO
			_touch_started = Time.get_ticks_msec()
			_touch_started_frame = Engine.get_frames_drawn()
			_touch_max_drag = 0.0
			_touch_dodged = false
		elif event.pressed:
			# A second finger, anywhere, dodges immediately. No button:
			# the interface is meant to stay off the screen (L81), a thumb
			# already steering cannot reach one, and in a fight the dodge
			# cannot afford to wait and see whether this was a tap.
			_try_dodge()
			_touch_dodged = true
		elif not event.pressed and event.index == _touch_id:
			# A quick tap that went nowhere was not steering — it was an
			# attack. Attacking is the commonest thing you do, so it gets
			# the commonest gesture, and a swing is committed anyway:
			# lifting the steering thumb to tap costs nothing, because you
			# could not have moved during it.
			#
			# Judged on how far the finger travelled while down, not on
			# where the release landed: a touchend does not reliably carry
			# a position, and reading one put the release 694 pixels from
			# the press and silently ate every tap.
			var held := Time.get_ticks_msec() - _touch_started
			var frames := Engine.get_frames_drawn() - _touch_started_frame
			if SHOW_DEBUG:
				_last_release = "held %dms / %d frames, drag %dpx" % [
					held, frames, roundi(_touch_max_drag)]
			var quick: bool = held <= TAP_MILLISECONDS or frames <= TAP_FRAMES
			# Not if this gesture already dodged — the second finger is
			# the dodge, and lifting it should not also swing.
			if quick and _touch_max_drag <= TAP_SLOP and not _touch_dodged:
				_try_attack()
			_touch_id = -1
			_touch_vec = Vector2.ZERO
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_try_dodge()
		elif event.keycode == KEY_J or event.keycode == KEY_ENTER:
			_try_attack()
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_try_attack()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		var offset: Vector2 = event.position - _touch_origin
		_touch_max_drag = maxf(_touch_max_drag, offset.length())
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
	# The curve is squared on purpose: a linear ramp put almost the whole
	# stick above walking pace, so the walk was unreachable by thumb.
	var speed := SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		speed = SPRINT
	elif _touch_id != -1:
		var t: float = clamp(pushed, 0.0, 1.0)
		speed = lerp(SPEED * 0.32, SPRINT, t * t)

	# At zero stamina you are not stunned, you are slow (combat.md §2).
	if stamina.is_exhausted():
		speed *= EXHAUSTED_SPEED

	# Sprinting drains. L55 keeps the rate low on purpose — disengage is
	# a first-class answer, so fleeing has to stay affordable.
	if speed > SPRINT_THRESHOLD and dodge.can_act():
		stamina.sprint(delta)

	dodge.tick(delta)
	attack.tick(delta)
	stamina.tick(delta)
	_resolve_swing()
	_tick_dummy(delta)

	var busy: bool = not dodge.can_act() or not attack.can_act()
	if not attack.can_act():
		# A swing is committed: combat.md §6 makes the wind-up a
		# telegraph, and a telegraph you can walk out of tells nobody
		# anything.
		player.velocity.x = 0.0
		player.velocity.z = 0.0
	elif not dodge.can_act():
		# The dodge owns movement while it runs. It is committed by
		# design, so steering does nothing until it ends.
		var reached: float = dodge.travelled_distance()
		var step: float = reached - _dodge_travelled
		_dodge_travelled = reached
		player.velocity.x = _dodge_dir.x * step / max(delta, 0.0001)
		player.velocity.z = _dodge_dir.z * step / max(delta, 0.0001)
	else:
		player.velocity.x = dir.x * speed
		player.velocity.z = dir.z * speed

	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	else:
		player.velocity.y = -0.1

	player.move_and_slide()

	_animate(Vector2(player.velocity.x, player.velocity.z).length())

	# Turn to face travel. Not while dodging or swinging — both were
	# aimed when they started and cannot be steered.
	if dir.length() > 0.01 and not busy:
		var want := atan2(-dir.x, -dir.z)
		player.rotation.y = lerp_angle(player.rotation.y, want, TURN * delta)

	_place_camera()
	_update_interface(delta)

func _try_attack() -> void:
	if player == null or not attack.can_act() or not dodge.can_act():
		return
	if not attack.try_start(stamina):
		return

	anim.play("swing", 0.05)
	anim.seek(SWING_START, true)
	anim.speed_scale = (SWING_END - SWING_START) / max(attack.total_seconds(), 0.01)

	_swing_count += 1
	if SHOW_DEBUG:
		print("swing %d  stamina %.0f" % [_swing_count, stamina.current()])

func _resolve_swing() -> void:
	# Geometry here, rules in sim/. The blade is live for a tenth of a
	# second and connects at most once, so this asks once and then the
	# swing is spent whatever else it passes through.
	if not attack.is_active() or dummy == null or _dummy_down > 0.0:
		return

	var to_target: Vector3 = dummy.global_position - player.global_position
	to_target.y = 0.0
	var facing: Vector3 = -player.global_transform.basis.z
	var angle: float = rad_to_deg(facing.signed_angle_to(to_target, Vector3.UP))

	# The dummy is a post, not a point: measure to its surface.
	if not attack.reaches(to_target.length() - DUMMY_RADIUS, angle):
		return
	if not attack.try_consume_hit():
		return

	_hit_dummy(SWORD_DAMAGE)

func _hit_dummy(amount: float) -> void:
	# The damage triangle (combat.md §4) is built and tested in sim/ and
	# is deliberately NOT wired up here. It resolves a blow against
	# armour class and hit location, and a straw dummy has neither — it
	# arrives with the armoured enemy at step 5, where it can be seen to
	# matter.
	_dummy_health = max(0.0, _dummy_health - amount)
	_dummy_flash = 1.0
	_dummy_rock = 1.0
	if SHOW_DEBUG:
		print("hit for %.0f, dummy at %.0f" % [amount, _dummy_health])
	if _dummy_health <= 0.0:
		_dummy_down = DUMMY_RESET_SECONDS

func _tick_dummy(delta: float) -> void:
	if dummy == null:
		return

	_dummy_flash = max(0.0, _dummy_flash - delta * 4.0)
	_dummy_rock = max(0.0, _dummy_rock - delta * 3.0)

	if _dummy_down > 0.0:
		_dummy_down -= delta
		# Toppled. There is no death here worth modelling — L17's death
		# ladder is an economy concern, and this is a bag of straw.
		dummy.rotation.x = lerp_angle(dummy.rotation.x, -PI * 0.45, 6.0 * delta)
		if _dummy_down <= 0.0:
			_dummy_health = DUMMY_HEALTH
			dummy.rotation = Vector3.ZERO
	else:
		# Rocks back from the blow and settles. The only feedback there
		# is, and the only kind there should be: interface.md §2 gives an
		# opponent no bars at all, so a hit has to read off the body.
		dummy.rotation.x = -_dummy_rock * 0.28
		dummy.rotation.z = _dummy_rock * 0.10

	if _dummy_skin != null:
		_dummy_skin.albedo_color = DUMMY_COLOR.lerp(Color(1, 0.92, 0.85), _dummy_flash)

func _try_dodge() -> void:
	if player == null or not dodge.can_act() or not attack.can_act():
		return

	# Aim it at wherever you are steering. L56: a dodge repositions — the
	# whole point is that toward, around and through are real options —
	# so standing still is the only case that has to be invented, and
	# backward is the safe reading of no input.
	var steer := Vector3.ZERO
	if _touch_id != -1 and _touch_vec.length() > 0.15:
		steer = Vector3(_touch_vec.x, 0.0, _touch_vec.y)
	else:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): steer.z -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): steer.z += 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): steer.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): steer.x += 1.0

	if steer.length() > 0.01:
		_dodge_dir = steer.normalized()
	else:
		_dodge_dir = -player.global_transform.basis.z

	if not dodge.try_start(stamina):
		return
	_dodge_travelled = 0.0
	_dodge_count += 1
	if SHOW_DEBUG:
		print("dodge %d  stamina %.0f  next cost %.0f" % [
			_dodge_count, stamina.current(), stamina.next_dodge_cost()])

	# One roll clip, so the character is turned to face the dodge rather
	# than rolling sideways. Four directional clips would fix this
	# properly; see assets/SPEC-dodge-clips.md.
	player.rotation.y = atan2(-_dodge_dir.x, -_dodge_dir.z)

	anim.play("roll", 0.06)
	anim.seek(ROLL_START, true)
	# Stretch the clip across however long this particular dodge lasts —
	# an unpaid one recovers slower, and the roll has to still be rolling.
	anim.speed_scale = (ROLL_END - ROLL_START) / max(dodge.total_seconds(), 0.01)

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
	# Framed for a person, not a capsule. The old distance was set when
	# the player was an untextured pill and nothing was lost by it being
	# small; a character has to be close enough to read.
	var height: float = lerp(2.4, 6.0, tall)
	var back: float = lerp(4.6, 4.4, tall)

	var focus := player.position + Vector3(0, 1.0, 0)
	cam.position = focus + Vector3(0, height, back)
	cam.look_at(focus, Vector3.UP)

# ── Interface ────────────────────────────────────────────────────────
# interface.md §2. There is no persistent HUD: the stamina bar fades in
# the moment the bar moves and fades out once you are full and rested.
# In a fight it is effectively always there; walking down a road it
# never is.

var _bar_root: Control
var _bar_fill: ColorRect
var _bar_alpha := 0.0
var _last_stamina := 0.0

const BAR_FADE_IN := 12.0
const BAR_FADE_OUT := 2.2
const BAR_LINGER := 0.9
var _bar_linger := 0.0

func _build_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_bar_root = Control.new()
	_bar_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bar_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_bar_root)

	var back := ColorRect.new()
	back.color = Color(0, 0, 0, 0.45)
	_bar_root.add_child(back)

	_bar_fill = ColorRect.new()
	_bar_fill.color = Color(0.85, 0.83, 0.72)
	_bar_root.add_child(_bar_fill)

	_bar_root.modulate.a = 0.0
	_last_stamina = stamina.current()

	if SHOW_DEBUG:
		_phase_label = Label.new()
		_phase_label.position = Vector2(12, 10)
		_phase_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.78))
		layer.add_child(_phase_label)

func _update_interface(delta: float) -> void:
	if _bar_root == null:
		return

	var vp := get_viewport().get_visible_rect().size
	# Low and centred, under the character rather than pinned to a corner
	# — the eye is already there and does not have to travel.
	var width: float = minf(vp.x * 0.46, 320.0)
	var height := 5.0
	var left := (vp.x - width) * 0.5
	var top: float = vp.y - maxf(vp.y * 0.10, 46.0)

	var fraction: float = clamp(stamina.fraction(), 0.0, 1.0)
	(_bar_root.get_child(0) as ColorRect).position = Vector2(left, top)
	(_bar_root.get_child(0) as ColorRect).size = Vector2(width, height)
	_bar_fill.position = Vector2(left, top)
	_bar_fill.size = Vector2(width * fraction, height)
	_bar_fill.color = Color(0.78, 0.35, 0.28) if stamina.is_exhausted() \
		else Color(0.85, 0.83, 0.72)

	# "It appears while it is moving" — so the trigger is the bar
	# changing, not being in combat. Nothing here knows what combat is.
	var moving: bool = absf(stamina.current() - _last_stamina) > 0.01
	_last_stamina = stamina.current()
	var rested: bool = fraction >= 0.999 and not stamina.is_exhausted()

	if moving and not rested:
		_bar_linger = BAR_LINGER
	else:
		_bar_linger = max(0.0, _bar_linger - delta)

	var target: float = 1.0 if _bar_linger > 0.0 else 0.0
	var rate: float = BAR_FADE_IN if target > _bar_alpha else BAR_FADE_OUT
	_bar_alpha = move_toward(_bar_alpha, target, rate * delta)
	_bar_root.modulate.a = _bar_alpha

	if not SHOW_DEBUG:
		return

	# Scaffolding. Nothing swings back yet, so the invulnerable window
	# would otherwise be invisible. Out at step 3.
	const DODGE_NAMES := ["ready", "startup", "INVULNERABLE", "recovery"]
	const SWING_NAMES := ["ready", "windup", "LIVE", "recovery"]
	_phase_label.text = "dodge %s   swing %s   stamina %d%%%s\ndummy %d%%   dodges %d   swings %d   fps %d\nlast release: %s" % [
		DODGE_NAMES[dodge.phase()],
		SWING_NAMES[attack.phase()],
		roundi(fraction * 100.0),
		"  EXHAUSTED" if stamina.is_exhausted() else "",
		roundi(_dummy_health / DUMMY_HEALTH * 100.0),
		_dodge_count,
		_swing_count,
		roundi(Engine.get_frames_per_second()),
		_last_release,
	]
	if _skin != null:
		_skin.albedo_color = Color(0.45, 0.80, 1.00) if dodge.is_invulnerable() \
			else _skin_base_color
