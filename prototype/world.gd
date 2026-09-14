extends Node3D
## Marrowmark — tech.md §6 Stage 1, steps 1 to 5.
##
## A drill yard, a training dummy that does not fight back, and one enemy
## that does — with combat.md §6's three attack shapes. The rules live in
## `rules/`, mirroring `sim/`; the bodies live in `fighter.gd`. What is
## here is the fight: who is where, who hit whom, and the camera.

const SWORD_DAMAGE := 28.0
const ENEMY_DAMAGE := 22.0
const PLAYER_HEALTH := 140.0
const ENEMY_HEALTH := 110.0
const ENEMY_RESPAWN_SECONDS := 4.0
const PLAYER_RESPAWN_SECONDS := 2.5

const PLAYER_HOME := Vector3(0, 1, 2)
const ENEMY_HOME := Vector3(-4, 1, -5)

const DUMMY_MODEL := "res://assets/models/dummy.fbx"
const DUMMY_HOME := Vector3(3, 0, -2)
const DUMMY_COLOR := Color(0.55, 0.38, 0.30)
const DUMMY_RADIUS := 0.45
const DUMMY_HALF_HEIGHT := 0.75
const DUMMY_HEALTH := 120.0
const DUMMY_RESET_SECONDS := 3.0

const SPEED := 4.0
const SPRINT := 7.0
const SPRINT_THRESHOLD := 5.0
const EXHAUSTED_SPEED := 0.6
const ENEMY_SPEED := 2.4

var player: Fighter
var enemy: Fighter
var cam: Camera3D
var tactics: EnemyTactics
var feel: Feel

var dummy: Node3D
var _dummy_skin: StandardMaterial3D
var _dummy_health := 0.0
var _dummy_flash := 0.0
var _dummy_rock := 0.0
var _dummy_down := 0.0

var _enemy_down := 0.0
var _player_down := 0.0

# Touch input: drag anywhere to steer, like a floating thumbstick.
var _touch_id := -1
var _touch_origin := Vector2.ZERO
var _touch_vec := Vector2.ZERO
const TOUCH_RANGE := 90.0  # pixels of drag for full tilt

# What separates a tap from the beginning of a steer.
#
# The frame count is not redundant with the clock, and it is the clause
# that matters on a bad device: a press and a release the game only got to
# look at three frames apart are a tap whatever the wall clock says.
# Judged by the clock alone, a 70ms tap at 3fps measures as 959ms held and
# is silently thrown away.
const TAP_MILLISECONDS := 260
const TAP_FRAMES := 3
const TAP_SLOP := 24.0
## Movement past this means the finger is steering, not bracing. Much
## smaller than TAP_SLOP: a guard has to be handed back inside the
## fraction of a second it takes to raise, so this errs toward deciding
## early.
const GUARD_SLOP := 7.0
var _touch_started := 0
var _touch_started_frame := 0
var _touch_max_drag := 0.0
var _touch_dodged := false
var _touch_guarding := false

# Pad input. The shipping platforms are PC and three consoles (L15,
# L51) and none of them is a phone, so the pad — not the thumb — is the
# scheme whose feel actually has to be right. Touch stays because it is
# the only way to play this on the machine that is to hand.
#
# Buttons rather than triggers for attack and guard, which is both the
# genre convention (RB/LB, R1/L1) and the practical choice: a trigger
# arrives as an axis, so a press edge has to be invented from a
# threshold. The triggers are left free for §6's heavy and committed
# attacks, which are the things that will want a squeeze.
const PAD := 0
const PAD_ATTACK := JOY_BUTTON_RIGHT_SHOULDER
const PAD_GUARD := JOY_BUTTON_LEFT_SHOULDER
const PAD_DODGE := JOY_BUTTON_A
## Held, so it is polled rather than edged — which is what a trigger is
## good at, and why sprint gets one.
const PAD_SPRINT_AXIS := JOY_AXIS_TRIGGER_LEFT
const PAD_SPRINT_PULL := 0.5

## Below this the left stick is at rest. Matches the touch threshold.
const PAD_WALK_DEADZONE := 0.15
## The right stick has to be *pushed* to re-aim — higher, because a
## stick resting slightly off centre must not quietly change which arc
## you are about to swing.
const PAD_AIM_DEADZONE := 0.35
var _pad_vec := Vector2.ZERO
var _pad_aim := Vector2.ZERO
var _pad_guarding := false

# Prototype scaffolding, not a design decision. interface.md §2 gives an
# opponent no bars at all; these numbers exist to check the sums.
const SHOW_DEBUG := true
var _phase_label: Label
var _dodge_count := 0
var _swing_count := 0
var _parries := 0
var _parry_attempts := 0
var _last_release := "-"

func _ready() -> void:
	# Belt and braces with the project setting: an emulated click arrives
	# BEFORE the touch that caused it, so leaving this on fires a swing on
	# press and then blocks the second-finger dodge.
	Input.set_emulate_mouse_from_touch(false)

	_build_yard()

	player = Fighter.new()
	player.position = PLAYER_HOME
	add_child(player)
	# These tints exist to drag a pink mannequin toward linen and leather.
	# They multiply into the albedo, so when a real textured character
	# arrives (SPEC-character-v4.md) they should go back to white rather
	# than being kept — the character will bring its own colour.
	player.setup(PLAYER_HEALTH, Color(0.66, 0.92, 0.84), true, Fighter.CHARACTER,
		Look.IRON, Look.LEATHER, "mail")
	player.show_iframes = SHOW_DEBUG

	enemy = Fighter.new()
	enemy.position = ENEMY_HOME
	add_child(enemy)
	# Darker and colder, so the two are told apart by value rather than by
	# a marker over anyone's head (interface.md §2).
	# Darker kit as well as a darker body. interface.md §2 gives an
	# opponent no marker over their head, so the difference has to be in
	# the silhouette and the value.
	enemy.setup(ENEMY_HEALTH, Color(0.40, 0.62, 0.62), true, Fighter.CHARACTER,
		Color(0.26, 0.27, 0.30), Color(0.16, 0.13, 0.10), "light")
	tactics = EnemyTactics.new(20260914)
	feel = Feel.new()

	cam = Camera3D.new()
	add_child(cam)
	_place_camera()
	_build_interface()

func _build_yard() -> void:
	# Light, sky, haze and grade all live in look.gd — art-audio.md §5
	# puts the look in the treatment rather than the assets, and this is
	# that taken literally.
	Look.build(self)

	const YARD := 30.0  # half-extent of the drill yard

	# The visible ground runs far past the yard. It used to stop at the
	# wall, which left a hard black band of nothing beyond the fence —
	# the single most render-like thing in frame. You still cannot walk
	# out there: the collision box and the walls below stay yard-sized.
	const SEEN := 420.0
	var ground := StaticBody3D.new()
	var gm := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(SEEN, SEEN)
	gm.mesh = plane
	# Tiled to the same texel density as before, so a bigger plane does
	# not mean a smeared one.
	gm.material_override = Look.ground_material(Look.EARTH, SEEN / 5.45)
	ground.add_child(gm)
	var gcol := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(YARD * 2.0, 0.2, YARD * 2.0)
	gcol.shape = gbox
	gcol.position = Vector3(0, -0.1, 0)
	ground.add_child(gcol)

	# Yard walls. You should never be able to walk into the void — falling
	# out of the world is the least informative bug there is.
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
		kerb.material_override = Look.solid_material(Look.KERB, 6.0)
		ground.add_child(kerb)

	add_child(ground)

	# Blocks to fight around. combat.md §1: terrain is fighting space.
	var stone := Look.solid_material(Look.STONE, 2.4)
	for spot in [Vector3(6, 0.75, -4), Vector3(-5, 0.75, -7), Vector3(-7, 0.75, 3)]:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.5, 1.5, 1.5)
		b.mesh = bm
		b.position = spot
		b.material_override = stone
		add_child(b)

	_scatter(stone)

	dummy = Node3D.new()
	dummy.position = DUMMY_HOME
	var post := (load(DUMMY_MODEL) as PackedScene).instantiate()
	# It stands up on its own — the Z-up rotation is baked into the mesh
	# node — but its origin is at its middle, so it needs raising.
	post.position = Vector3(0, DUMMY_HALF_HEIGHT, 0)
	dummy.add_child(post)
	var dmesh := _find(post, "MeshInstance3D") as MeshInstance3D
	if dmesh != null:
		_dummy_skin = StandardMaterial3D.new()
		_dummy_skin.albedo_color = DUMMY_COLOR
		dmesh.material_override = _dummy_skin
	add_child(dummy)
	_dummy_health = DUMMY_HEALTH

## A handful of posts and stones. Nothing here is a feature — it exists
## because an empty plane gives the eye nothing to measure speed or
## distance against, and because a drill yard with nothing in it does not
## read as a place.
func _scatter(stone: StandardMaterial3D) -> void:
	var timber := Look.solid_material(Look.TIMBER, 5.0, 0.9)

	# A fence along two sides, just inside the kerb.
	for i in 22:
		var t := i / 21.0
		for corner in [Vector3(-26.0 + t * 52.0, 0, -27.0), Vector3(-27.0, 0, -26.0 + t * 52.0)]:
			var post := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = 0.09
			pm.bottom_radius = 0.12
			pm.height = 1.5 + fmod(i * 0.37, 0.5)
			post.mesh = pm
			post.position = corner + Vector3(0, pm.height * 0.5, 0)
			post.rotation.z = (fmod(i * 0.61, 1.0) - 0.5) * 0.12
			post.material_override = timber
			add_child(post)

	# Stones, biggest near the walls so the middle stays fightable.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260914
	for i in 34:
		var angle := rng.randf() * TAU
		var radius: float = lerp(9.0, 27.0, rng.randf())
		var rock := MeshInstance3D.new()
		var rm := SphereMesh.new()
		# Small and rounded. The first pass made them big and flat, which
		# reads as puddles rather than stone.
		var size: float = lerp(0.16, 0.42, radius / 27.0) * rng.randf_range(0.7, 1.4)
		rm.radius = size
		rm.height = size * 1.7
		rock.mesh = rm
		rock.position = Vector3(cos(angle) * radius, size * 0.45, sin(angle) * radius)
		rock.scale = Vector3(1.0, rng.randf_range(0.7, 1.0), rng.randf_range(0.85, 1.15))
		rock.rotation.y = rng.randf() * TAU
		rock.material_override = stone
		add_child(rock)

func _find(node: Node, cls: String) -> Node:
	if node.get_class() == cls:
		return node
	for child in node.get_children():
		var hit := _find(child, cls)
		if hit != null:
			return hit
	return null

# ── Input ────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_touch_origin = event.position
			_touch_vec = Vector2.ZERO
			_touch_started = Time.get_ticks_msec()
			_touch_started_frame = Engine.get_frames_drawn()
			_touch_max_drag = 0.0
			_touch_dodged = false
			_touch_guarding = false
		elif event.pressed:
			# A second finger, anywhere, dodges immediately. No button: the
			# interface is meant to stay off the screen (L81), a thumb
			# already steering cannot reach one, and in a fight the dodge
			# cannot afford to wait and see whether this was a tap.
			if _touch_guarding:
				_touch_guarding = false
				player.cancel_guard()
			_try_dodge()
			_touch_dodged = true
		elif not event.pressed and event.index == _touch_id:
			# A quick tap that went nowhere was not steering — it was an
			# attack. Attacking is the commonest thing you do, so it gets
			# the commonest gesture, and a swing is committed anyway.
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
			var tapped: bool = quick and _touch_max_drag <= TAP_SLOP \
					and not _touch_dodged
			if _touch_guarding:
				_touch_guarding = false
				# A quick release means that was a tap after all: take the
				# guard back and swing instead. Refused if it already
				# turned something, in which case it really was a guard.
				if not tapped or not player.cancel_guard():
					player.lower_guard()
					tapped = false
			if tapped:
				_try_attack(_arc_from(_touch_origin))
			_touch_id = -1
			_touch_vec = Vector2.ZERO
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			PAD_ATTACK: _try_attack(_arc_from_stick(_pad_aim))
			PAD_DODGE: _try_dodge()
			PAD_GUARD:
				# No speculative guard here, and nothing to take back. On
				# touch the guard has to be guessed at, because the same
				# thumb means steer, swing and brace; a pad has a button
				# for it, so the parry is exactly as manual as an input
				# gets — you hold it when you mean it and not before.
				_pad_guarding = true
				_try_parry()
	elif event is InputEventJoypadButton and not event.pressed \
			and event.button_index == PAD_GUARD:
		_pad_guarding = false
		if player != null:
			player.lower_guard()
	elif event is InputEventJoypadMotion:
		match event.axis:
			JOY_AXIS_LEFT_X: _pad_vec.x = event.axis_value
			JOY_AXIS_LEFT_Y: _pad_vec.y = event.axis_value
			JOY_AXIS_RIGHT_X: _pad_aim.x = event.axis_value
			JOY_AXIS_RIGHT_Y: _pad_aim.y = event.axis_value
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_try_dodge()
		elif event.keycode == KEY_J or event.keycode == KEY_ENTER:
			_try_attack()
		elif event.keycode == KEY_K:
			_try_parry()
	elif event is InputEventKey and not event.pressed and event.keycode == KEY_K:
		player.lower_guard()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_attack()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_try_parry()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		var offset: Vector2 = event.position - _touch_origin
		_touch_max_drag = maxf(_touch_max_drag, offset.length())
		# Take the speculative guard back the instant the finger moves at
		# all. This is checked here rather than in the physics step
		# because a guard can only be taken back while it is still being
		# raised — 0.06s — and waiting a frame for the physics step misses
		# that window. A guard that is properly up has to be paid for,
		# including a mistimed one: combat.md §2 is explicit that a failed
		# parry refunds nothing.
		if _touch_guarding and _touch_max_drag > GUARD_SLOP:
			_touch_guarding = false
			player.cancel_guard()
		_touch_vec = offset / TOUCH_RANGE
		if _touch_vec.length() > 1.0:
			_touch_vec = _touch_vec.normalized()

func _steer() -> Vector3:
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
	# A pushed stick overrides both. Last writer wins on purpose: whatever
	# you are actually holding is what you meant.
	var stick := _pad_push()
	if stick > PAD_WALK_DEADZONE:
		dir = Vector3(_pad_vec.x, 0.0, _pad_vec.y)
	return dir

## How far the left stick is pushed, with the dead zone taken out and
## the remainder stretched back over the full range — otherwise the
## first fifth of the throw is dead and a walk sits in a sliver.
func _pad_push() -> float:
	var raw: float = _pad_vec.length()
	if raw <= PAD_WALK_DEADZONE:
		return 0.0
	return clampf((raw - PAD_WALK_DEADZONE) / (1.0 - PAD_WALK_DEADZONE), 0.0, 1.0)

## Where the right stick points is where you aim — the pad's answer to
## "where you tap is where you aim", and the same five arcs (L64). Held
## at rest it keeps the default, so you can fight without ever touching
## it and still swing.
##
## Screen space and stick space agree on sign: both count y downward, so
## pushing the stick forward reads as high, which is the cut it makes.
func _arc_from_stick(aim: Vector2) -> int:
	if aim.length() < PAD_AIM_DEADZONE:
		return Attack.Arc.UPPER_RIGHT
	var left: bool = aim.x < 0.0
	if aim.y < -0.35:
		# Straight forward is the overhead; forward and off to a side is
		# still a high cut. The same split the tap makes.
		if absf(aim.x) < 0.38:
			return Attack.Arc.OVERHEAD
		return Attack.Arc.UPPER_LEFT if left else Attack.Arc.UPPER_RIGHT
	if aim.y > 0.35:
		return Attack.Arc.LOWER_LEFT if left else Attack.Arc.LOWER_RIGHT
	return Attack.Arc.UPPER_LEFT if left else Attack.Arc.UPPER_RIGHT

# ── The fight ────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if player == null:
		return

	_check_hold()
	player.tick(delta)
	enemy.tick(delta)
	tactics.tick(delta)

	_move_player(delta)
	_run_enemy(delta)
	_resolve_swing(player, SWORD_DAMAGE, true)
	_resolve_swing(enemy, ENEMY_DAMAGE, false)
	_tick_dummy(delta)
	_tick_bodies(delta)

	feel.tick(delta)
	# art-audio.md §2: an exhausted character's camera behaves
	# differently. The bar is the last thing interface.md §2 allows on
	# screen, and this says the same thing without using it.
	feel.breathe(clamp(1.0 - player.stamina.fraction() * 2.2, 0.0, 1.0))

	_place_camera()
	_update_interface(delta)

func _move_player(delta: float) -> void:
	if _player_down > 0.0:
		player.move(Vector3.ZERO, 0.0, delta)
		return

	var dir := _steer()
	var pushed := dir.length()
	dir = dir.normalized()

	# On touch, how far you drag is how fast you go. The curve is squared
	# on purpose: a linear ramp put almost the whole stick above walking
	# pace, so the walk was unreachable by thumb.
	var speed := SPEED
	var stick := _pad_push()
	if Input.is_key_pressed(KEY_SHIFT) \
			or Input.get_joy_axis(PAD, PAD_SPRINT_AXIS) > PAD_SPRINT_PULL:
		speed = SPRINT
	elif stick > 0.0 or _touch_id != -1:
		# How far you push is how fast you go, on stick as on thumb. The
		# curve is squared because a linear ramp put almost the whole
		# throw above walking pace and the walk was unreachable. A stick
		# is finer than a drag, so this is the first number to suspect if
		# the pad feels different from the phone.
		var t: float = clamp(stick if stick > 0.0 else pushed, 0.0, 1.0)
		speed = lerp(SPEED * 0.32, SPRINT, t * t)

	# At zero stamina you are not stunned, you are slow (combat.md §2).
	if player.stamina.is_exhausted():
		speed *= EXHAUSTED_SPEED

	# Sprinting drains. L55 keeps the rate low on purpose — disengage is a
	# first-class answer, so fleeing has to stay affordable.
	if speed > SPRINT_THRESHOLD and not player.is_busy():
		player.stamina.sprint(delta)

	player.move(dir, speed, delta)

func _run_enemy(delta: float) -> void:
	if _enemy_down > 0.0 or _player_down > 0.0:
		enemy.move(Vector3.ZERO, 0.0, delta)
		return

	var to_player: Vector3 = player.global_position - enemy.global_position
	to_player.y = 0.0
	var distance := to_player.length()
	var heading := to_player.normalized()

	var decision := tactics.decide(distance, enemy.stamina, enemy.is_busy())
	match decision["intent"]:
		EnemyTactics.Intent.ATTACK:
			# Face the player before committing. The wind-up is the
			# telegraph (combat.md §6) and a telegraph aimed elsewhere
			# teaches nothing.
			enemy.rotation.y = atan2(-heading.x, -heading.z)
			if enemy.try_attack(EnemyTactics.section_for(decision["shape"])):
				# He aims as well. A heavy comes down overhead, a quick
				# goes for the body, and the whole-body swing takes the
				# legs — so a harness wears unevenly and which piece
				# fails says something about the fight.
				enemy.attack.arc = [Attack.Arc.UPPER_RIGHT,
					Attack.Arc.OVERHEAD, Attack.Arc.LOWER_LEFT][decision["shape"]]
				tactics.threw(decision["shape"])
			enemy.move(Vector3.ZERO, 0.0, delta)
		EnemyTactics.Intent.CLOSE:
			enemy.move(heading, ENEMY_SPEED, delta)
		_:
			# Circling, or busy. Keep facing the player so the next
			# wind-up is readable from the start.
			if not enemy.is_busy():
				enemy.rotation.y = lerp_angle(
					enemy.rotation.y, atan2(-heading.x, -heading.z), 6.0 * delta)
			enemy.move(Vector3.ZERO, 0.0, delta)

## Geometry here, rules in sim/. The blade is live for a tenth of a second
## and connects at most once, so this asks once and the swing is spent
## whatever else it passes through.
func _resolve_swing(who: Fighter, weapon_damage: float, is_player: bool) -> void:
	if not who.attack.is_active():
		return

	var targets: Array = []
	if is_player:
		if _dummy_down <= 0.0:
			targets.append({"at": dummy.global_position, "radius": DUMMY_RADIUS, "dummy": true})
		if _enemy_down <= 0.0:
			targets.append({"at": enemy.global_position, "radius": 0.5, "dummy": false})
	elif _player_down <= 0.0:
		targets.append({"at": player.global_position, "radius": 0.5, "dummy": false})

	var facing: Vector3 = -who.global_transform.basis.z
	for target in targets:
		var to_target: Vector3 = target["at"] - who.global_position
		to_target.y = 0.0
		var angle: float = rad_to_deg(facing.signed_angle_to(to_target, Vector3.UP))
		if not who.attack.reaches(to_target.length() - target["radius"], angle):
			continue
		if not who.attack.try_consume_hit():
			return

		var damage: float = weapon_damage * who.attack.damage_multiplier()
		var blow: Vector3 = to_target.normalized()
		var weight: float = who.attack.damage_multiplier()
		if target["dummy"]:
			_impact(who, null, blow, weight)
			_hit_dummy(damage)
		elif is_player:
			_land(who, enemy, damage, "player", blow, weight)
		else:
			_land(who, player, damage, "enemy", blow, weight)
		return

## Hitstop and a camera shove. Presentation only — feel.gd says why the
## rules are not allowed to stop with it.
func _impact(attacker: Fighter, victim: Fighter, blow: Vector3, weight: float) -> void:
	var stop := Feel.hitstop_for(weight)
	attacker.freeze(stop)
	if victim != null:
		victim.freeze(stop)
	# Taking one shoves the view harder than landing one.
	var strength: float = 0.05 + 0.055 * weight
	if victim == player:
		strength *= 1.8
	feel.kick(blow, strength)

func _land(attacker: Fighter, victim: Fighter, damage: float, by: String,
		blow: Vector3, weight: float) -> void:
	_impact(attacker, victim, blow, weight)

	# The guard gets first refusal. combat.md §6 makes parry the answer to
	# a heavy, and the committed attack unparryable — the rule for which
	# lives in sim/, not here.
	match victim.meet(attacker.attack, damage):
		Parry.Outcome.BLOCKED:
			# §1: a blocked blow still carries something through. Blocking
			# is a stamina war, never an off switch.
			var through: float = damage * victim.parry.blocked_fraction()
			var hurt := victim.hurt(through, attacker.attack.arc)
			if SHOW_DEBUG:
				print("BLOCKED %s's blow — %.0f through, %.0f stamina left%s" % [
					by, hurt["taken"], victim.stamina.current(),
					"  GUARD BROKEN" if not victim.parry.is_guarding() else ""])
			return
		Parry.Outcome.PARRIED:
			attacker.stagger(victim.parry.stagger_seconds())
			# A parry is a clang, not a shove: it rattles rather than
			# throwing the view, because nothing moved.
			attacker.freeze(Feel.STOP_PARRY)
			victim.freeze(Feel.STOP_PARRY)
			feel.shake(0.075)
			_parries += 1
			if SHOW_DEBUG:
				print("PARRIED %s's blow — staggered for %.2fs, %s at %.0f stamina" % [
					by, victim.parry.stagger_seconds(),
					"you" if by == "enemy" else "the enemy",
					victim.stamina.current()])
			return
		Parry.Outcome.UNPARRYABLE:
			if SHOW_DEBUG:
				print("guard was up, but that one cannot be parried")
		Parry.Outcome.TOO_EARLY:
			if SHOW_DEBUG:
				print("guard came up too early")
		Parry.Outcome.TOO_LATE:
			if SHOW_DEBUG:
				print("guard came up too late")

	# The damage triangle (combat.md §4) is built and tested in sim/ and is
	# deliberately not wired up here. It resolves a blow against armour
	# class and hit location, and nobody in this yard is wearing anything.
	var landed := victim.hurt(damage, attacker.attack.arc)
	if not SHOW_DEBUG:
		return
	if landed["taken"] <= 0.0:
		print("%s's blow passed through — i-frames" % by)
		return
	const WHERE := ["the head", "the body", "an arm", "a leg"]
	print("%s hit %s for %.0f%s, target at %.0f%%" % [
		by, WHERE[landed["slot"]], landed["taken"],
		"  (bare — no armour there)" if landed["bare"] else "",
		victim.health.fraction() * 100.0])
	if landed["broke"]:
		print("   ^ that piece is GONE — %s is bare there now" % (
			"the enemy" if by == "player" else "you"))

func _tick_bodies(delta: float) -> void:
	if enemy.health.is_dead() and _enemy_down <= 0.0:
		_enemy_down = ENEMY_RESPAWN_SECONDS
	if player.health.is_dead() and _player_down <= 0.0:
		_player_down = PLAYER_RESPAWN_SECONDS

	if _enemy_down > 0.0:
		_enemy_down -= delta
		enemy.rotation.x = lerp_angle(enemy.rotation.x, -PI * 0.45, 5.0 * delta)
		if _enemy_down <= 0.0:
			enemy.revive()
			enemy.position = ENEMY_HOME
			tactics = EnemyTactics.new(Time.get_ticks_msec())

	if _player_down > 0.0:
		_player_down -= delta
		player.rotation.x = lerp_angle(player.rotation.x, -PI * 0.45, 5.0 * delta)
		if _player_down <= 0.0:
			# No death ladder here. What dying costs (L17/L32: durability,
			# cargo, the Interior) is an economy concern and is a long way
			# from Stage 1.
			player.revive()
			player.position = PLAYER_HOME
			enemy.revive()
			enemy.position = ENEMY_HOME

## The guard comes up the moment a finger lands, and stays up while it is
## held. That is the whole of the fix for the thing that was wrong here.
##
## It used to be raised on a TIMER — 260ms after the touch, whether you
## meant it or not — which meant the player never chose the moment. You
## cannot time a parry you did not ask for, and resting a thumb on the
## screen cost 15 stamina. It felt automatic because it *was*.
##
## Raising it on press instead means the input layer has to commit before
## it knows whether this is a tap, a steer or a guard. So it raises one
## speculatively and takes it back if the touch turns out to be something
## else — `cancel_guard()` refunds it whole, and refuses once the guard
## has actually turned a blow.
func _check_hold() -> void:
	if _touch_id == -1 or _touch_dodged or player == null:
		return

	if _touch_max_drag > GUARD_SLOP:
		# A steer. The drag handler will normally have given the guard
		# back already; this is the backstop for a finger that moved
		# without a drag event reaching us first.
		if _touch_guarding:
			_touch_guarding = false
			player.cancel_guard()
		return

	if not _touch_guarding and player.parry.can_act() and not player.is_busy():
		_touch_guarding = true
		_try_parry()

func _try_parry() -> void:
	if player == null or _player_down > 0.0:
		return
	if not player.try_parry():
		return
	_parry_attempts += 1
	if SHOW_DEBUG:
		print("guard up (%d)  stamina %.0f" % [_parry_attempts, player.stamina.current()])

## Prototype scaffolding. It exists because "the pad does nothing" has
## two completely different causes — the cable, or the mapping — and
## from inside the fight they look identical.
func _pad_status() -> String:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return "none connected"
	const ARCS := ["overhead", "upper left", "upper right",
		"lower left", "lower right", "thrust"]
	return "%s   aim %s   move %.2f%s" % [
		Input.get_joy_name(pads[0]),
		ARCS[_arc_from_stick(_pad_aim)],
		_pad_push(),
		"   GUARD" if _pad_guarding else "",
	]

## Where you tap is where you aim. L64 gives five cutting arcs chosen by
## free aim rather than a menu — Kingdom Come's system — and a screen is
## already an aiming surface, so the tap carries it for nothing. High
## centre goes overhead and finds the helm; low goes for the legs.
##
## L65 keeps this off the screen: there is no reticle and there will not
## be one. You learn where you are aiming by watching where the blow
## lands, which is the same way you learn everything else here.
func _arc_from(where: Vector2) -> int:
	var vp := get_viewport().get_visible_rect().size
	var x: float = where.x / maxf(vp.x, 1.0)
	var y: float = where.y / maxf(vp.y, 1.0)
	var left: bool = x < 0.5
	if y < 0.34:
		# Straight down the middle is the overhead; off to a side up
		# there is still a high cut.
		if absf(x - 0.5) < 0.18:
			return Attack.Arc.OVERHEAD
		return Attack.Arc.UPPER_LEFT if left else Attack.Arc.UPPER_RIGHT
	if y > 0.66:
		return Attack.Arc.LOWER_LEFT if left else Attack.Arc.LOWER_RIGHT
	return Attack.Arc.UPPER_LEFT if left else Attack.Arc.UPPER_RIGHT

func _try_attack(arc: int = Attack.Arc.UPPER_RIGHT) -> void:
	if player == null or _player_down > 0.0:
		return
	if not player.try_attack():
		return
	player.attack.arc = arc
	_swing_count += 1
	if SHOW_DEBUG:
		const ARCS := ["overhead", "upper left", "upper right",
			"lower left", "lower right", "thrust"]
		print("swing %d  %s  stamina %.0f" % [
			_swing_count, ARCS[arc], player.stamina.current()])

func _try_dodge() -> void:
	if player == null or _player_down > 0.0:
		return

	# Aim it wherever you are steering. L56: a dodge repositions — toward,
	# around and through are real options — so standing still is the only
	# case that has to be invented, and backward is the safe reading.
	if not player.try_dodge(_steer()):
		return
	_dodge_count += 1
	if SHOW_DEBUG:
		print("dodge %d  stamina %.0f  next cost %.0f" % [
			_dodge_count, player.stamina.current(), player.stamina.next_dodge_cost()])

# ── Training dummy ───────────────────────────────────────────────────

func _hit_dummy(amount: float) -> void:
	_dummy_health = max(0.0, _dummy_health - amount)
	_dummy_flash = 1.0
	_dummy_rock = 1.0
	if SHOW_DEBUG:
		print("hit the dummy for %.0f, at %.0f" % [amount, _dummy_health])
	if _dummy_health <= 0.0:
		_dummy_down = DUMMY_RESET_SECONDS

func _tick_dummy(delta: float) -> void:
	if dummy == null:
		return

	_dummy_flash = max(0.0, _dummy_flash - delta * 4.0)
	_dummy_rock = max(0.0, _dummy_rock - delta * 3.0)

	if _dummy_down > 0.0:
		_dummy_down -= delta
		dummy.rotation.x = lerp_angle(dummy.rotation.x, -PI * 0.45, 6.0 * delta)
		if _dummy_down <= 0.0:
			_dummy_health = DUMMY_HEALTH
			dummy.rotation = Vector3.ZERO
	else:
		# Rocks back and settles. The only feedback there is, and the only
		# kind there should be: interface.md §2 gives an opponent no bars.
		dummy.rotation.x = -_dummy_rock * 0.28
		dummy.rotation.z = _dummy_rock * 0.10

	if _dummy_skin != null:
		_dummy_skin.albedo_color = DUMMY_COLOR.lerp(Color(1, 0.92, 0.85), _dummy_flash)

# ── Camera ───────────────────────────────────────────────────────────

func _place_camera() -> void:
	# A portrait phone has a narrow horizontal field of view, so the camera
	# pulls back on tall screens to keep the same amount of world on
	# screen. Without this the game is unplayable on a phone and fine on a
	# laptop, which is the worst kind of bug to find late.
	var vp := get_viewport().get_visible_rect().size
	var aspect: float = vp.x / max(vp.y, 1.0)

	# 0 on a wide screen, 1 on a tall phone in portrait.
	var tall: float = clamp((1.5 - aspect) / 1.1, 0.0, 1.0)

	# Framed for a person, not a capsule. The old distance was set when the
	# player was an untextured pill and nothing was lost by it being small.
	var height: float = lerp(2.4, 6.0, tall)
	var back: float = lerp(4.6, 4.4, tall)

	var focus := player.position + Vector3(0, 1.0, 0)
	cam.position = focus + Vector3(0, height, back) + feel.offset()
	cam.look_at(focus, Vector3.UP)

# ── Interface ────────────────────────────────────────────────────────
# interface.md §2. There is no persistent HUD: the stamina bar fades in
# the moment the bar moves and fades out once you are full and rested. In
# a fight it is effectively always there; walking down a road it never is.

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
	_last_stamina = player.stamina.current()

	if SHOW_DEBUG:
		_phase_label = Label.new()
		_phase_label.position = Vector2(12, 10)
		_phase_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.78))
		layer.add_child(_phase_label)

func _update_interface(delta: float) -> void:
	if _bar_root == null:
		return

	var vp := get_viewport().get_visible_rect().size
	# Low and centred, under the character rather than pinned to a corner —
	# the eye is already there and does not have to travel.
	var width: float = minf(vp.x * 0.46, 320.0)
	var height := 5.0
	var left := (vp.x - width) * 0.5
	var top: float = vp.y - maxf(vp.y * 0.10, 46.0)

	var fraction: float = clamp(player.stamina.fraction(), 0.0, 1.0)
	(_bar_root.get_child(0) as ColorRect).position = Vector2(left, top)
	(_bar_root.get_child(0) as ColorRect).size = Vector2(width, height)
	_bar_fill.position = Vector2(left, top)
	_bar_fill.size = Vector2(width * fraction, height)
	_bar_fill.color = Color(0.78, 0.35, 0.28) if player.stamina.is_exhausted() \
		else Color(0.85, 0.83, 0.72)

	# "It appears while it is moving" — so the trigger is the bar changing,
	# not being in combat. Nothing here knows what combat is.
	var moving: bool = absf(player.stamina.current() - _last_stamina) > 0.01
	_last_stamina = player.stamina.current()
	var rested: bool = fraction >= 0.999 and not player.stamina.is_exhausted()

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

	const DODGE_NAMES := ["ready", "startup", "INVULNERABLE", "recovery"]
	const SWING_NAMES := ["ready", "windup", "LIVE", "recovery"]
	const GUARD_NAMES := ["-", "raising", "OPEN", "BLOCKING", "caught"]
	_phase_label.text = (
		"you: dodge %s  swing %s  guard %s\n"
		+ "    stamina %d%%%s  health %d%%  armour %d/4\n"
		+ "enemy: %s %s%s  health %d%%  armour %d/4\n"
		+ "dummy %d%%   dodges %d   swings %d   parried %d/%d   fps %d\n"
		+ "last release: %s\n"
		+ "pad: %s"
	) % [
		DODGE_NAMES[player.dodge.phase()],
		SWING_NAMES[player.attack.phase()],
		GUARD_NAMES[player.parry.phase()],
		roundi(fraction * 100.0),
		"  EXHAUSTED" if player.stamina.is_exhausted() else "",
		roundi(player.health.fraction() * 100.0),
		player.harness.intact_pieces(),
		["quick", "heavy", "COMMITTED"][enemy.attack.shape()],
		SWING_NAMES[enemy.attack.phase()],
		"  STAGGERED" if enemy.is_staggered() else "",
		roundi(enemy.health.fraction() * 100.0),
		enemy.harness.intact_pieces(),
		roundi(_dummy_health / DUMMY_HEALTH * 100.0),
		_dodge_count,
		_swing_count,
		_parries,
		_parry_attempts,
		roundi(Engine.get_frames_per_second()),
		_last_release,
		_pad_status(),
	]
