class_name TownWalker
extends CharacterBody3D
## Thornfield town walker: third-person stroller for the town scene.
## WASD/arrows + left-half touch stick. Fixed follow camera.
## Registers itself as TownNPC.player so talk prompts appear, and shows
## a Talk button near NPCs that opens their conversation.
## New files only: never touches combat (world.gd / main.tscn).

const MODEL := "res://assets/models/paladin.fbx"
const IDLE_CLIP := "res://assets/animations/anim_Idle.fbx"
const WALK_CLIP := "res://assets/animations/anim_Walking.fbx"
const SPEED := 4.5
const TALK_RANGE := 3.0
## Base thumbstick radius, scaled to the viewport at build time — the
## old fixed 60px was a comfortable thumb on the developer's window and
## a fingernail on a tall phone.
const STICK_BASE := 62.0

## Pad. Matches world.gd so the two scenes do not want different hands:
## left stick walks, A talks, Start goes back to the launcher.
const PAD := 0
const PAD_DEADZONE := 0.15
const PAD_TALK := JOY_BUTTON_A
const PAD_LEAVE := JOY_BUTTON_START

## Camera orbit, matching world.gd's so the two scenes do not want
## different hands.
##
## The town had NO camera control of any kind: a fixed follow at a
## hardcoded offset that never read the stick. Pad support was added
## here for walking and talking and the camera was simply forgotten, so
## "the camera is still the same" was exactly right — in this scene it
## had never been anything else.
const CAM_DISTANCE := 8.5
const CAM_HEIGHT := 5.2
const CAM_YAW_RATE := 2.8
const CAM_PITCH_RATE := 1.7
## Which way up the sticks are lives in Settings, not here — see the
## note in world.gd. Toggle it on the menu; it persists.
const CAM_PITCH_MIN := -0.20
const CAM_PITCH_MAX := 1.15
const CAM_STICK_DEADZONE := 0.18
## How far above the ground the camera is kept. Below this it sinks
## through the floor and the world is seen from underneath.
const GROUND_CLEARANCE := 0.6
const CAM_KEY_RATE := 1.8
## How far a finger on the RIGHT half of the screen swings the camera.
const CAM_DRAG_RATE := 0.006
var _cam_yaw := 0.0
var _cam_pitch := 0.0
var _look_id := -1
## Accumulated by a finger on the right half of the screen, spent once
## per frame. Touch has no camera otherwise, and a phone without a pad
## is the commonest way this is played.
var _look_drag := Vector2.ZERO

var systems: Dictionary = {}

var _anim: AnimationPlayer
var _cam: Camera3D
var _stick_id := -1
var _stick_origin := Vector2.ZERO
var _stick_vec := Vector2.ZERO
var _stick_base: Panel
var _stick_knob: Panel
var _talk_btn: Button
var _back_btn: Button
var _touch_layer: CanvasLayer
var _stick_radius := STICK_BASE
var _near: TownNPC = null


func _ready() -> void:
	_build_body()
	_build_camera()
	_build_touch_ui()
	TownNPC.player = self


func _build_body() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.height = 1.8
	cap.radius = 0.35
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	add_child(col)
	var mdl := (load(MODEL) as PackedScene).instantiate() as Node3D
	# The model's feet sit on ITS OWN origin — measured, not assumed: the
	# paladin mesh spans y 0.000 to 1.725. The capsule above is 1.8 tall
	# and offset up by half of that, so its bottom is on the node origin
	# too, and the two line up with no offset at all.
	#
	# This carried a -1.0 here, copied from world.gd where the capsule is
	# 2m CENTRED on the origin and the model genuinely does have to hang
	# a metre below it. With this capsule that sank the visible body one
	# metre into the floor — waist deep, reported from play. It went
	# unnoticed because the town had no floor to stand on until today,
	# so the walker fell past the problem.
	mdl.position = Vector3.ZERO
	add_child(mdl)
	var skel := _find(mdl, "Skeleton3D")
	_anim = AnimationPlayer.new()
	skel.get_parent().add_child(_anim)
	_anim.root_node = _anim.get_path_to(skel.get_parent())
	var lib := AnimationLibrary.new()
	var idle := _clip(IDLE_CLIP)
	idle.loop_mode = Animation.LOOP_LINEAR
	var walk := _clip(WALK_CLIP)
	walk.loop_mode = Animation.LOOP_LINEAR
	lib.add_animation("idle", idle)
	lib.add_animation("walk", walk)
	_anim.add_animation_library("", lib)
	_anim.play("idle")


func _clip(path: String) -> Animation:
	var src := (load(path) as PackedScene).instantiate()
	var src_anim := _find(src, "AnimationPlayer") as AnimationPlayer
	var clip: Animation = src_anim.get_animation(src_anim.get_animation_list()[0])
	src.queue_free()
	return clip


func _build_camera() -> void:
	_cam = Camera3D.new()
	_cam.far = 400.0
	# Parented to the SCENE, not to the walker.
	#
	# It used to be a child of this body — which turns constantly, by
	# lerp_angle, to face wherever you are walking. The camera inherited
	# every degree of that while its global_position was being rewritten
	# each frame, so the two fought: jittery while walking, and a hard
	# jerk whenever you reversed and the body swung through 180°.
	#
	# A chase camera must not live under the thing it is chasing.
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_parent()
	host.add_child(_cam)
	_cam_pitch = atan2(CAM_HEIGHT, CAM_DISTANCE)
	_cam.global_position = _camera_seat()
	_cam.look_at(_focus(), Vector3.UP)


func _focus() -> Vector3:
	return global_position + Vector3(0, 1.4, 0)


## Where the camera stands: an orbit at constant distance, so the walker
## stays the same size in frame at every angle.
func _camera_seat() -> Vector3:
	var dist: float = sqrt(CAM_DISTANCE * CAM_DISTANCE + CAM_HEIGHT * CAM_HEIGHT)
	var pitch: float = _floored_pitch(dist)
	var off := Vector3(0.0, sin(pitch), cos(pitch)) * dist
	return _focus() + off.rotated(Vector3.UP, _cam_yaw)


## The pitch, floored so the camera never sinks through the ground.
##
## Tilting all the way down put the seat below y=0 and the world was
## seen from underneath. Clamping the PITCH rather than the resulting
## height keeps the orbit a circle — clamping the height alone would
## slide the camera inward and change how big the walker looks as you
## tilt.
func _floored_pitch(dist: float) -> float:
	var limit: float = asin(clampf(
		(GROUND_CLEARANCE - _focus().y) / maxf(dist, 0.01), -1.0, 1.0))
	return maxf(_cam_pitch, limit)


## Where the camera looks, flattened. Walking is measured against this:
## the moment a camera can turn, a world-space "forward" sends you
## somewhere that is not forward on screen.
func _camera_forward() -> Vector3:
	return Vector3(-sin(_cam_yaw), 0.0, -cos(_cam_yaw))


func _tick_camera(delta: float) -> void:
	# A menu owns the sticks while it is up. The right stick swinging the
	# camera round behind a dialogue box is the same press doing two
	# things at once, and it reads as the camera having a mind of its own.
	if UI.modal_open():
		_look_drag = Vector2.ZERO
		return
	var yaw: float = 0.0
	var pitch: float = 0.0
	var rx := Input.get_joy_axis(PAD, JOY_AXIS_RIGHT_X)
	var ry := Input.get_joy_axis(PAD, JOY_AXIS_RIGHT_Y)
	if absf(rx) > CAM_STICK_DEADZONE:
		yaw -= rx * CAM_YAW_RATE * Settings.yaw_sign()
	if absf(ry) > CAM_STICK_DEADZONE:
		pitch += ry * CAM_PITCH_RATE * Settings.pitch_sign()
	if Input.is_key_pressed(KEY_Q):
		yaw += CAM_KEY_RATE
	if Input.is_key_pressed(KEY_BRACKETRIGHT):
		yaw -= CAM_KEY_RATE
	_cam_yaw = wrapf(_cam_yaw + yaw * delta + _look_drag.x, -PI, PI)
	_cam_pitch = clampf(_cam_pitch + pitch * delta + _look_drag.y,
		CAM_PITCH_MIN, CAM_PITCH_MAX)
	_look_drag = Vector2.ZERO


func _circle_panel(d: float, color: Color) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = int(d / 2.0)
	sb.corner_radius_top_right = int(d / 2.0)
	sb.corner_radius_bottom_left = int(d / 2.0)
	sb.corner_radius_bottom_right = int(d / 2.0)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(d, d)
	p.size = Vector2(d, d)
	p.visible = false
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _build_touch_ui() -> void:
	_touch_layer = CanvasLayer.new()
	add_child(_touch_layer)
	_layout_touch_ui()
	# Rebuilt on resize because every number in it is a fraction of the
	# viewport, and a phone changes viewport when it rotates.
	get_viewport().size_changed.connect(_layout_touch_ui)
	# And hidden the moment a pad is picked up. InputMode follows the last
	# input the player actually used, so plugging a controller in takes
	# the thumb controls off the screen without asking, and unplugging it
	# puts them back.
	InputMode.scheme_changed.connect(_on_scheme_changed)


func _layout_touch_ui() -> void:
	for c in _touch_layer.get_children():
		c.queue_free()

	var scale := UI.scale_for(self)
	var inset := UI.safe_inset(self)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_stick_radius = maxf(STICK_BASE * scale, 54.0)

	_stick_base = _circle_panel(_stick_radius * 2.0, Color(1, 1, 1, 0.16))
	_touch_layer.add_child(_stick_base)
	_stick_knob = _circle_panel(_stick_radius, Color(1, 1, 1, 0.34))
	_touch_layer.add_child(_stick_knob)

	var gutter: float = maxf(16.0, vp.x * 0.025)

	# Talk sits under the right thumb, clear of the bottom edge and of
	# any gesture bar.
	_talk_btn = UI.chip("Talk", scale)
	_talk_btn.size = _talk_btn.custom_minimum_size
	_talk_btn.position = Vector2(
		vp.x - inset.z - gutter - _talk_btn.size.x,
		vp.y - inset.w - maxf(gutter, vp.y * 0.10) - _talk_btn.size.y)
	_talk_btn.visible = false
	_talk_btn.pressed.connect(_on_talk_pressed)
	_touch_layer.add_child(_talk_btn)

	# And a way out. Thornfield was a one-way door on a touch device:
	# leaving was bound to Escape and to Start, and a phone without a pad
	# has neither, so the only exit was the task switcher. Top right,
	# away from where a look-drag starts.
	_back_btn = UI.chip("Back", scale)
	_back_btn.size = _back_btn.custom_minimum_size
	_back_btn.position = Vector2(
		vp.x - inset.z - gutter - _back_btn.size.x,
		inset.y + gutter)
	_back_btn.pressed.connect(_leave)
	_touch_layer.add_child(_back_btn)

	_apply_scheme()


func _on_scheme_changed(_scheme: int) -> void:
	_apply_scheme()


## On-screen controls exist only while the player is actually using a
## thumb. A pad or a keyboard leaves the screen to the world, which is
## interface.md §1's whole point.
func _apply_scheme() -> void:
	if _back_btn == null:
		return
	var touching: bool = InputMode.is_touch()
	_back_btn.visible = touching
	if not touching:
		_talk_btn.visible = false
		_stick_id = -1
		_stick_vec = Vector2.ZERO
		_hide_stick()


## Is this touch landing on a chip rather than on the world? Without the
## question, tapping Talk also starts a camera drag, because _input runs
## before the GUI gets a look at the event.
func _over_chip(at: Vector2) -> bool:
	for b in [_talk_btn, _back_btn]:
		if b != null and b.visible and b.get_global_rect().has_point(at):
			return true
	return false


func _show_stick(at: Vector2) -> void:
	_stick_base.position = at - Vector2(_stick_radius, _stick_radius)
	_stick_base.visible = true
	_stick_knob.position = at - Vector2(_stick_radius / 2.0, _stick_radius / 2.0)
	_stick_knob.visible = true


func _hide_stick() -> void:
	_stick_base.visible = false
	_stick_knob.visible = false


func _input(event: InputEvent) -> void:
	# A menu owns the screen while it is up — L90. Without this the world
	# keeps taking drags behind the dialogue box.
	if UI.modal_open():
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		var vw := get_viewport().get_visible_rect().size.x
		if t.pressed:
			if _over_chip(t.position):
				return
			if _stick_id == -1 and t.position.x < vw * 0.5:
				_stick_id = t.index
				_stick_origin = t.position
				_stick_vec = Vector2.ZERO
				_show_stick(t.position)
			elif _look_id == -1 and t.position.x >= vw * 0.5:
				_look_id = t.index
		elif t.index == _stick_id:
			_stick_id = -1
			_stick_vec = Vector2.ZERO
			_hide_stick()
		elif t.index == _look_id:
			_look_id = -1
	elif event is InputEventScreenDrag:
		var dr := event as InputEventScreenDrag
		if dr.index == _look_id:
			_look_drag += Vector2(
				-dr.relative.x * Settings.yaw_sign(),
				-dr.relative.y * Settings.pitch_sign()) * CAM_DRAG_RATE
			return
		if dr.index == _stick_id:
			var off := dr.position - _stick_origin
			if off.length() > _stick_radius:
				off = off.normalized() * _stick_radius
			_stick_vec = off / _stick_radius
			_stick_knob.position = _stick_origin + off \
				- Vector2(_stick_radius / 2.0, _stick_radius / 2.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo:
			if k.keycode == KEY_E:
				_try_talk()
			elif k.keycode == KEY_ESCAPE:
				_leave()
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			PAD_TALK: _try_talk()
			PAD_LEAVE: _leave()


## Back to the launcher. Without this, picking Thornfield was a one-way
## door — there was no way to reach the drill yard again short of killing
## the app, which on a phone means the task switcher.
func _leave() -> void:
	if ConversationUI.current != null:
		ConversationUI.current.close()
		return
	get_tree().change_scene_to_file("res://launcher.tscn")


func _input_dir() -> Vector2:
	# Likewise the left stick: it is the menu's d-pad while a menu is
	# open. Without this you walk out of the conversation you are holding
	# — the same stick press both moves the highlight and moves you.
	if UI.modal_open():
		return Vector2.ZERO
	var kv := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		kv.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		kv.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		kv.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		kv.y += 1.0
	if _stick_vec.length() > 0.2:
		kv = _stick_vec
	# And the pad. The town used to take WASD and the on-screen stick
	# only, which meant that on the APK — the way this is actually played
	# — a plugged-in controller did nothing at all here while working
	# fine in the yard. Same axes and the same dead zone as world.gd.
	var pad := Vector2(
		Input.get_joy_axis(PAD, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(PAD, JOY_AXIS_LEFT_Y))
	if pad.length() > PAD_DEADZONE:
		kv = pad
	return kv


func _physics_process(delta: float) -> void:
	var dir := _input_dir()
	if dir.length() > 0.15:
		# Rotated into camera space. Without this, turning the camera
		# leaves "forward" pointing somewhere that is not forward on
		# screen, and the town becomes unwalkable the first time you
		# orbit behind yourself.
		var d2: Vector2 = dir.normalized().rotated(-_cam_yaw)
		var d := Vector3(d2.x, 0.0, d2.y)
		velocity.x = d.x * SPEED
		velocity.z = d.z * SPEED
		rotation.y = lerp_angle(rotation.y, atan2(d.x, d.z), 12.0 * delta)
		if _anim.current_animation != "walk":
			_anim.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, SPEED * 8.0 * delta)
		if _anim.current_animation != "idle":
			_anim.play("idle")
	velocity.y -= 22.0 * delta
	move_and_slide()

	# The camera is placed HERE, in the physics step, immediately after
	# the body has moved — and set outright rather than lerped toward.
	#
	# It used to run in _process and chase the seat with a lerp, which
	# produced exactly the reported jerk. The body moves on the fixed
	# physics tick and Godot 4.3 does not interpolate 3D bodies between
	# them, so a camera following at display rate samples a target that
	# is stepping; the lerp then adds a lag that overshoots and snaps
	# whenever you change direction, which is why reversing was the worst
	# case.
	#
	# The drill yard never had this: world.gd has always placed its
	# camera inside _physics_process. Same fix, same place.
	_tick_camera(delta)
	_cam.global_position = _camera_seat()
	_cam.look_at(_focus(), Vector3.UP)


func _process(_delta: float) -> void:
	_near = null
	if not UI.modal_open():
		var pop := get_parent().get_node_or_null("Population")
		if pop != null:
			var best := TALK_RANGE
			for n in pop.get_children():
				if n is TownNPC and (n as TownNPC).stays:
					var d: float = ((n as Node3D).global_position - global_position).length()
					if d < best:
						best = d
						_near = n
	_talk_btn.visible = _near != null and InputMode.is_touch()


func _on_talk_pressed() -> void:
	_try_talk()


func _try_talk() -> void:
	if _near != null and not UI.modal_open():
		_near.begin_talk(systems)


func _find(node: Node, cls: String) -> Node:
	if node.get_class() == cls:
		return node
	for child in node.get_children():
		var hit := _find(child, cls)
		if hit != null:
			return hit
	return null
