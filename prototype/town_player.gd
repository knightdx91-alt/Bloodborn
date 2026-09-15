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
const STICK_RADIUS := 60.0

## Pad. Matches world.gd so the two scenes do not want different hands:
## left stick walks, A talks, Start goes back to the launcher.
const PAD := 0
const PAD_DEADZONE := 0.15
const PAD_TALK := JOY_BUTTON_A
const PAD_LEAVE := JOY_BUTTON_START

var systems: Dictionary = {}

var _anim: AnimationPlayer
var _cam: Camera3D
var _stick_id := -1
var _stick_origin := Vector2.ZERO
var _stick_vec := Vector2.ZERO
var _stick_base: Panel
var _stick_knob: Panel
var _talk_btn: Button
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
	# Mixamo capsule hangs a metre below the origin; characters face +Z.
	mdl.position = Vector3(0, -1.0, 0)
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
	add_child(_cam)
	_cam.global_position = global_position + Vector3(0, 5.2, 6.8)
	_cam.look_at(global_position + Vector3(0, 1.4, 0))


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
	var layer := CanvasLayer.new()
	add_child(layer)
	_stick_base = _circle_panel(STICK_RADIUS * 2.0, Color(1, 1, 1, 0.18))
	layer.add_child(_stick_base)
	_stick_knob = _circle_panel(STICK_RADIUS, Color(1, 1, 1, 0.35))
	layer.add_child(_stick_knob)
	_talk_btn = Button.new()
	_talk_btn.text = "Talk"
	_talk_btn.add_theme_font_size_override("font_size", 40)
	_talk_btn.custom_minimum_size = Vector2(190, 100)
	_talk_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_talk_btn.position = Vector2(-210, -190)
	_talk_btn.visible = false
	_talk_btn.pressed.connect(_on_talk_pressed)
	layer.add_child(_talk_btn)


func _show_stick(at: Vector2) -> void:
	_stick_base.position = at - Vector2(STICK_RADIUS, STICK_RADIUS)
	_stick_base.visible = true
	_stick_knob.position = at - Vector2(STICK_RADIUS / 2.0, STICK_RADIUS / 2.0)
	_stick_knob.visible = true


func _hide_stick() -> void:
	_stick_base.visible = false
	_stick_knob.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		var vw := get_viewport().get_visible_rect().size.x
		if t.pressed:
			if _stick_id == -1 and t.position.x < vw * 0.5:
				_stick_id = t.index
				_stick_origin = t.position
				_stick_vec = Vector2.ZERO
				_show_stick(t.position)
		elif t.index == _stick_id:
			_stick_id = -1
			_stick_vec = Vector2.ZERO
			_hide_stick()
	elif event is InputEventScreenDrag:
		var dr := event as InputEventScreenDrag
		if dr.index == _stick_id:
			var off := dr.position - _stick_origin
			if off.length() > STICK_RADIUS:
				off = off.normalized() * STICK_RADIUS
			_stick_vec = off / STICK_RADIUS
			_stick_knob.position = _stick_origin + off - Vector2(STICK_RADIUS / 2.0, STICK_RADIUS / 2.0)


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
		var d := dir.normalized()
		velocity.x = d.x * SPEED
		velocity.z = d.y * SPEED
		rotation.y = lerp_angle(rotation.y, atan2(d.x, d.y), 12.0 * delta)
		if _anim.current_animation != "walk":
			_anim.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, SPEED * 8.0 * delta)
		if _anim.current_animation != "idle":
			_anim.play("idle")
	velocity.y -= 22.0 * delta
	move_and_slide()


func _process(delta: float) -> void:
	_cam.global_position = _cam.global_position.lerp(
		global_position + Vector3(0, 5.2, 6.8), 6.0 * delta)
	_cam.look_at(global_position + Vector3(0, 1.4, 0))
	_near = null
	if ConversationUI.current == null:
		var pop := get_parent().get_node_or_null("Population")
		if pop != null:
			var best := TALK_RANGE
			for n in pop.get_children():
				if n is TownNPC and (n as TownNPC).stays:
					var d: float = ((n as Node3D).global_position - global_position).length()
					if d < best:
						best = d
						_near = n
	_talk_btn.visible = _near != null


func _on_talk_pressed() -> void:
	_try_talk()


func _try_talk() -> void:
	if _near != null and ConversationUI.current == null:
		_near.begin_talk(systems)


func _find(node: Node, cls: String) -> Node:
	if node.get_class() == cls:
		return node
	for child in node.get_children():
		var hit := _find(child, cls)
		if hit != null:
			return hit
	return null
