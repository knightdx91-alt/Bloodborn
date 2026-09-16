class_name TownNPC
extends Node3D
## One townsfolk: body, bark timer, talk prompt, conversation entry.
## Bodies are the blocky humanoid placeholder with a tinted tunic; real
## civilian bodies arrive in the NPC art pass. Disposition reads through
## behavior (greeting warmth, name use, whether they stay) — never a
## number (brainstorm §9.3). NPCs stay where their work is; none follow.

const BODY := "res://assets/models/humanoid.fbx"
const IDLE := "res://assets/animations/anim_Idle.fbx"
const TALK_RANGE := 3.0

## The player (or mock player) the prompt measures distance to.
static var player: Node3D = null

var npc_id: String = ""
var display_name: String = "Someone"
var role: String = ""
var voice_card: String = ""
## Behavioral disposition — flags, not numbers.
var greeting_warm := true
var uses_name := false
var stays := true
## Conversation topics: Array of {topic, line, intent, intent_arg}.
var topics: Array = []
## Whether finished contract work can be handed in to this person.
var pays_contracts := false
## Crowd barks: role key into BarkBank, "" for silent named NPCs.
var bark_role: String = ""
var epoch: int = 0
## Seconds until this NPC leaves (Red Vigil rider); 0 = stays.
var departs_after: float = 0.0
var leave_target := Vector3.ZERO

var _label: Label3D
var _prompt: Label3D
var _bark_in: float = 0.0
var _bark_for: float = 0.0
var _leave_in: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(data: Dictionary) -> void:
	npc_id = String(data.get("id", "npc"))
	display_name = String(data.get("name", "Someone"))
	role = String(data.get("role", ""))
	voice_card = String(data.get("voice", ""))
	topics = data.get("topics", [])
	bark_role = String(data.get("barks", ""))
	pays_contracts = bool(data.get("pays_contracts", false))
	epoch = int(data.get("epoch", 0))
	departs_after = float(data.get("departs_after", 0.0))
	leave_target = data.get("leave_target", Vector3.ZERO)
	greeting_warm = bool(data.get("warm", true))
	uses_name = bool(data.get("uses_name", false))
	position = data.get("pos", Vector3.ZERO)
	rotation.y = float(data.get("yaw", 0.0))
	_rng.seed = hash(npc_id)
	_build_body(Color(data.get("tunic", Color(0.5, 0.42, 0.3))))
	_build_labels()
	_leave_in = departs_after
	_bark_in = _rng.randf_range(2.0, 9.0)


func _build_body(tunic: Color) -> void:
	var body := (load(BODY) as PackedScene).instantiate() as Node3D
	# ON the ground, not a metre into it.
	#
	# Fighter drops its model to Vector3(0, -1.0, 0) and is right to: a
	# CharacterBody3D's capsule is CENTRED on the origin, so the origin
	# sits at hip height and the model has to hang a metre below it to
	# stand on its feet.
	#
	# A TownNPC is a plain Node3D placed at ground level (roster poses are
	# all y = 0), its collision capsule runs from 0 to 1.8 and its name
	# labels sit at 1.95 and 2.15 — every one of those measured from the
	# FEET. So the offset that is correct in the drill yard buries a
	# townsman to the waist here, which is exactly how it was reported.
	# The same line, copied with its comment, did the same thing to the
	# player's spawn earlier.
	body.position = Vector3.ZERO
	body.rotation_degrees = Vector3(0, 180, 0)
	add_child(body)
	# Tint every surface toward the tunic color: crowd variety.
	for mi in _all(body, "MeshInstance3D"):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		for s in range(m.mesh.get_surface_count()):
			var base := m.get_active_material(s)
			var mat := (base.duplicate() as StandardMaterial3D) \
				if base is StandardMaterial3D else StandardMaterial3D.new()
			mat.albedo_color = mat.albedo_color.lerp(tunic, 0.75)
			m.set_surface_override_material(s, mat)
	# Idle clip on the Mixamo skeleton, same pattern as the fighters.
	var src := (load(IDLE) as PackedScene).instantiate()
	var src_anim := _find(src, "AnimationPlayer") as AnimationPlayer
	if src_anim != null:
		var clip: Animation = src_anim.get_animation(src_anim.get_animation_list()[0])
		clip.loop_mode = Animation.LOOP_LINEAR
		var skel := _find(body, "Skeleton3D")
		if skel != null:
			var anim := AnimationPlayer.new()
			skel.get_parent().add_child(anim)
			anim.root_node = anim.get_path_to(skel.get_parent())
			var lib := AnimationLibrary.new()
			lib.add_animation("idle", clip)
			anim.add_animation_library("", lib)
			anim.play("idle")
	src.queue_free()
	# Walkable collision, same convention as the town's code-placed boxes.
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.height = 1.8
	cap.radius = 0.35
	cs.shape = cap
	cs.position = Vector3(0, 0.9, 0)
	sb.add_child(cs)
	add_child(sb)


func _build_labels() -> void:
	_label = Label3D.new()
	_label.position = Vector3(0, 2.15, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 48
	_label.pixel_size = 0.006
	_label.modulate = Color(0.95, 0.92, 0.82)
	_label.outline_size = 8
	_label.visible = false
	add_child(_label)
	_prompt = Label3D.new()
	_prompt.position = Vector3(0, 1.95, 0)
	_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt.font_size = 40
	_prompt.pixel_size = 0.005
	_prompt.modulate = Color(0.85, 0.85, 0.9)
	_prompt.outline_size = 8
	_prompt.text = "[E] talk"
	_prompt.visible = false
	add_child(_prompt)


func _process(delta: float) -> void:
	# Bark timer for the crowd.
	if bark_role != "" and _bark_for <= 0.0:
		_bark_in -= delta
		if _bark_in <= 0.0:
			_say_bark()
	if _bark_for > 0.0:
		_bark_for -= delta
		if _bark_for <= 0.0:
			_label.visible = false
	# The Vigil rider waters his horse and leaves.
	if _leave_in > 0.0:
		_leave_in -= delta
		if _leave_in <= 0.0 and stays:
			_walk_away(delta)
	# Talk prompt by proximity.
	if stays and player != null and ConversationUI.current == null:
		var d: float = (player.global_position - global_position).length()
		_prompt.visible = d <= TALK_RANGE
	else:
		_prompt.visible = false


func _say_bark() -> void:
	var pool := BarkBank.lines(bark_role, epoch)
	if pool.is_empty():
		_bark_in = _rng.randf_range(8.0, 16.0)
		return
	_label.text = pool[_rng.randi_range(0, pool.size() - 1)]
	_label.visible = true
	_bark_for = _rng.randf_range(3.0, 5.0)
	_bark_in = _rng.randf_range(9.0, 22.0)


func _walk_away(delta: float) -> void:
	# Simple departure: face the gate, step, despawn at range.
	var to: Vector3 = leave_target - global_position
	to.y = 0.0
	if to.length() < 2.0:
		queue_free()
		return
	var step: Vector3 = to.normalized() * 2.2 * delta
	global_position += step
	rotation.y = atan2(-to.x, -to.z) + PI


## Say one line above the head (used by systems for confirmations).
func say_line(text: String, hold: float = 3.0) -> void:
	_label.text = text
	_label.visible = true
	_bark_for = hold


## Greeting, shaped by disposition behavior. Warmth, name use.
func greeting() -> String:
	var who := display_name if uses_name else "traveler"
	if greeting_warm:
		return "Well met, %s." % who
	return "What is it, %s." % who


## Open the text conversation. Called by the talk prompt / E key.
func begin_talk(systems: Dictionary) -> void:
	if not stays:
		return
	_prompt.visible = false
	ConversationUI.open(self, systems)


func _find(node: Node, cls: String) -> Node:
	if node.get_class() == cls:
		return node
	for child in node.get_children():
		var hit := _find(child, cls)
		if hit != null:
			return hit
	return null


func _all(node: Node, cls: String) -> Array:
	var out: Array = []
	_collect(node, cls, out)
	return out


func _collect(node: Node, cls: String, out: Array) -> void:
	if node.get_class() == cls:
		out.append(node)
	for child in node.get_children():
		_collect(child, cls, out)
