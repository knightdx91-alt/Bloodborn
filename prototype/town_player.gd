class_name TownWalker
extends Fighter
## Thornfield's player: a third-person stroller who can also fight.
## WASD/arrows + left-half touch stick, orbiting follow camera, a Talk
## chip near NPCs, and the same combat as anywhere else.
##
## It used to say here, in its own header, "never touches combat". That
## was true and it was the bug: `TownWalker` was a bare
## `CharacterBody3D` with a model and a Talk button, so the town had no
## attack, no dodge and no guard for ANY input scheme — pad included.
## Reported from play, and the answer decided there: **no place is
## excluded**.
##
## So it extends `Fighter` rather than growing its own combat.
## `Fighter` already owns the body, the rig, the clips, the attack, the
## dodge, the parry, stamina, health, the harness and the sound, and
## combat.md §8 promises ONE ruleset rather than two. A second
## implementation in the town would have been a second ruleset the day
## after it was written.

const MODEL := "res://assets/models/paladin.fbx"
const IDLE_CLIP := "res://assets/animations/anim_Idle.fbx"
const WALK_CLIP := "res://assets/animations/anim_Walking.fbx"
const SPEED := 4.5
## Matches world.gd's player so the town is not a different character.
const PLAYER_HEALTH := 100.0
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
## The same hands as world.gd, so the town is not a different game.
## A is shared: it talks when there is somebody to talk to and dodges
## when there is not, because in the yard A is the dodge and a player
## should not have to remember which building they are standing in.
const PAD_ATTACK := JOY_BUTTON_RIGHT_SHOULDER
const PAD_GUARD := JOY_BUTTON_LEFT_SHOULDER

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

var _cam: Camera3D
## Hit-stop, kick and shake. The town had none: it was world.gd's, along
## with the combat that caused it. A blow that does not move the view is
## a number changing somewhere, which is exactly what interface.md §2
## says the player should never be reading.
var feel: Feel = Feel.new()
var _stick_id := -1
var _stick_origin := Vector2.ZERO
var _stick_vec := Vector2.ZERO
var _stick_base: Panel
var _stick_knob: Panel
var _talk_btn: Button
var _back_btn: Button
## Combat on a thumb — see _layout_touch_ui.
var _attack_btn: Button
var _dodge_btn: Button
var _guard_btn: Button
var _touch_layer: CanvasLayer
var _stick_radius := STICK_BASE
var _near: TownNPC = null
## The road out, when you are standing at one. Shares the Talk chip and
## the pad's A: the verb is "the thing in front of you", and a second
## button for it would be a second thing to learn for no gain.
var _road: Waypost = null


func _ready() -> void:
	# Fighter builds the body, the rig and every clip — including the
	# ones this file used to load by hand. Its capsule is 2m CENTRED on
	# the origin and its model hangs a metre below to stand on its feet,
	# which is the offset this file once copied wrongly and buried the
	# walker to the waist. Inheriting it means there is now one answer
	# instead of two.
	setup(PLAYER_HEALTH, Color.WHITE, true, Fighter.CHARACTER,
		Look.IRON, Look.LEATHER, "mail")
	_build_camera()
	_build_touch_ui()
	TownNPC.player = self


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
	_cam.global_position = _camera_seat() + feel.offset()
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

	# The same combat chips as the yard and the Hedges, in the same
	# corner. Reported from play: "there isn't a way to do combat without
	# a controller." In the town that was not a missing gesture — there
	# was no combat here at all — but the fix has to arrive looking
	# identical, or the town is still a different game to a thumb.
	_attack_btn = UI.chip("Attack", scale)
	_dodge_btn = UI.chip("Dodge", scale)
	_guard_btn = UI.chip("Guard", scale)
	# Stacked ABOVE Talk, which already sits under the right thumb.
	var y: float = _talk_btn.position.y - 10.0 * scale
	for b in [_attack_btn, _dodge_btn, _guard_btn]:
		b.size = b.custom_minimum_size
		y -= b.size.y
		b.position = Vector2(vp.x - inset.z - gutter - b.size.x, y)
		y -= 10.0 * scale
		_touch_layer.add_child(b)

	_attack_btn.pressed.connect(_town_attack)
	_dodge_btn.pressed.connect(_town_dodge)
	_guard_btn.button_down.connect(try_parry)
	_guard_btn.button_up.connect(lower_guard)

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
	for b in [_attack_btn, _dodge_btn, _guard_btn]:
		if b != null:
			b.visible = touching
	if not touching:
		_talk_btn.visible = false
		_stick_id = -1
		_stick_vec = Vector2.ZERO
		_hide_stick()


## Is this touch landing on a chip rather than on the world? Without the
## question, tapping Talk also starts a camera drag, because _input runs
## before the GUI gets a look at the event.
func _over_chip(at: Vector2) -> bool:
	for b in [_talk_btn, _back_btn, _attack_btn, _dodge_btn, _guard_btn]:
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
			elif k.keycode == KEY_J or k.keycode == KEY_ENTER:
				_town_attack()
			elif k.keycode == KEY_SPACE:
				_town_dodge()
			elif k.keycode == KEY_K:
				try_parry()
		elif not k.pressed and k.keycode == KEY_K:
			lower_guard()
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			PAD_TALK:
				# Talk to whoever is there, take the road if you are
				# standing at one, and otherwise dodge — which is what A
				# does everywhere else.
				if _near != null or _road != null:
					_try_talk()
				else:
					_town_dodge()
			PAD_LEAVE: _leave()
			PAD_ATTACK: _town_attack()
			PAD_GUARD: try_parry()
	elif event is InputEventJoypadButton and not event.pressed \
			and event.button_index == PAD_GUARD:
		lower_guard()


## Swing, in town.
##
## Thin wrappers rather than calls straight into Fighter, because a
## conversation is not a fight: with a panel open the same button is
## moving a highlight, and a sword coming out behind it would be the
## town answering an input meant for the menu.
func _town_attack() -> void:
	if UI.modal_open():
		return
	if try_attack():
		attack.arc = Attack.Arc.UPPER_RIGHT


func _town_dodge() -> void:
	if UI.modal_open():
		return
	# Aimed where you are steering, exactly as in the yard — a dodge
	# repositions (L56), so standing still is the only time it is purely
	# defensive.
	var dir := _input_dir()
	var away := -global_transform.basis.z
	if dir.length() > 0.15:
		var d2: Vector2 = dir.normalized().rotated(-_cam_yaw)
		away = Vector3(-d2.x, 0.0, -d2.y)
	try_dodge(away)


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
	# The combat clocks run here too now: windups, recoveries, i-frames
	# and stamina all tick whether or not there is anything to fight.
	tick(delta)
	feel.tick(delta)
	# art-audio.md §2: an exhausted character's camera behaves
	# differently, which says what a stamina bar would have to.
	feel.breathe(clamp(1.0 - stamina.fraction() * 2.2, 0.0, 1.0))

	var dir := _input_dir()
	var heading := Vector3.ZERO
	if dir.length() > 0.15:
		# Rotated into camera space. Without this, turning the camera
		# leaves "forward" pointing somewhere that is not forward on
		# screen, and the town becomes unwalkable the first time you
		# orbit behind yourself.
		var d2: Vector2 = dir.normalized().rotated(-_cam_yaw)
		# Fighter faces -Z, so the sign here is its convention, not this
		# file's preference.
		heading = Vector3(-d2.x, 0.0, -d2.y)

	# Fighter.move does the steering, the gravity, the animation and the
	# footsteps, and refuses to move a body that is mid-swing — which is
	# combat.md §6's telegraph, and has to hold in the town as much as
	# anywhere else.
	move(heading, SPEED, delta)

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
	_road = null
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
		# A person wins over a signpost. Somebody standing at the gate
		# should still be talkable, and a post does not mind waiting.
		if _near == null:
			for n in get_parent().get_children():
				# Only a road that actually GOES somewhere is an offer.
				# The Hedges sign is a sign now — the wood is down that
				# road in this same world, so there is nothing to press.
				if n is Waypost and (n as Waypost).destination != "" \
						and (n as Waypost).in_reach(self):
					_road = n as Waypost
					break

	_talk_btn.visible = (_near != null or _road != null) and InputMode.is_touch()
	if _road != null:
		_talk_btn.text = _road.label
	elif _near != null:
		_talk_btn.text = "Talk"


func _on_talk_pressed() -> void:
	_try_talk()


func _try_talk() -> void:
	if UI.modal_open():
		return
	if _near != null:
		_near.begin_talk(systems)
	elif _road != null:
		_road.travel(get_tree())


func _find(node: Node, cls: String) -> Node:
	if node.get_class() == cls:
		return node
	for child in node.get_children():
		var hit := _find(child, cls)
		if hit != null:
			return hit
	return null
