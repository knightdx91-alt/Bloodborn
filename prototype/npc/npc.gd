class_name TownNPC
extends Node3D
## One townsfolk: body, bark timer, talk prompt, conversation entry.
## Bodies are the blocky humanoid placeholder with a tinted tunic; real
## civilian bodies arrive in the NPC art pass. Disposition reads through
## behavior (greeting warmth, name use, whether they stay) — never a
## number (brainstorm §9.3). NPCs stay where their work is; none follow.

const BODY := "res://assets/models/humanoid.fbx"
const IDLE := "res://assets/animations/anim_Idle.fbx"

## Real townsfolk (Quaternius Ultimate Modular Characters, CC0).
##
## 62–63 bones with **24 baked clips each**, at correct human scale
## (~1.87 m, feet on the origin). Their rig is NOT the 65-bone Mixamo
## family, so none of the game's Mixamo clips retarget onto them — which
## is fine, because they bring their own Idle, Walk, Run and Wave, and
## that is the whole reason to prefer a pack that ships characters AND
## animations (`SPEC-asset-packs-v1.md`).
##
## Only the medieval-plausible half of the pack is listed. It also ships
## a spacesuit, a SWAT officer and a hoodie, which are excellent and not
## for Thornfield.
const FOLK := "res://assets/townsfolk/modular-characters/%s.glb"
## The three outfits in this pack that a medieval town can wear.
##
## `modular-characters` is a MODERN character set with a few fantasy
## extras — of its 21 bodies there is a spacesuit, a SWAT officer, beach
## shorts and flip-flops, a business suit, two mohawks and two hi-vis
## safety vests with hard hats. They were previously chosen here by
## FILENAME, which is how Smith Odo came to hammer iron in a hard hat and
## Clerk Fenwick to keep the boards in a navy business suit. Every entry
## below has been rendered and looked at; see
## `assets/evidence/townsfolk-catalogue.png`.
const OUTFITS := ["Male_Adventurer", "Female_Adventurer", "Female_Medieval"]

## Heads, which are portable — see `_swap_head`.
##
## On this rig a head is a face and hair and nothing else, so most of
## them carry no period at all and will sit on any of the outfits above.
## These are the ones wearing NOTHING: no hard hat, no crown, no witch's
## hat, no visor, no mohawk, no dyed streak. Eight of the pack's 21 are
## excluded on exactly that ground.
const HEADS := ["Female_Adventurer", "Female_Casual", "Female_Formal",
	"Female_Medieval", "Female_Soldier", "Female_Suit", "Male_Adventurer",
	"Male_Beach", "Male_Casual_2", "Male_Casual_Hoodie", "Male_Suit"]

## Who wears which outfit. Heads are dealt separately, so two people in
## the same outfit are still two people.
const BODIES := {
	"mara": "Female_Medieval",
	"odo": "Male_Adventurer",
	"pell": "Male_Adventurer",
	"sarella": "Female_Medieval",
	"fenwick": "Male_Adventurer",
	"vance": "Male_Adventurer",
	"tammas": "Male_Adventurer",
	"mira": "Female_Adventurer",
	"lamp": "Male_Adventurer",
	"vigil-rider": "Male_Adventurer",
}
## For the crowd, by the role their barks come from.
const CROWD := {
	"market": ["Female_Medieval", "Male_Adventurer", "Female_Adventurer"],
	"farmer": ["Male_Adventurer", "Female_Adventurer"],
	"child": ["Female_Adventurer", "Male_Adventurer"],
	"warden": ["Male_Adventurer", "Female_Adventurer"],
	"drover": ["Male_Adventurer", "Female_Medieval"],
	"granary": ["Male_Adventurer", "Female_Adventurer"],
	"brewery": ["Male_Adventurer", "Female_Medieval"],
	"chapel": ["Female_Medieval", "Female_Adventurer"],
	"apprentice": ["Male_Adventurer", "Female_Adventurer"],
}
const TALK_RANGE := 3.0
## Metres per second on the way to a posting.
const WALK_SPEED := 1.35

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
## What this person does with their day — postings by hour. Empty means
## they stand where they were placed, which is what everyone did before
## the town kept hours.
var routine: Dictionary = {}
## Which named place they are currently walking to, "" when settled.
var _bound_for := ""
var _spread := 0
## Where they were put at load: their home, for want of a better one.
var _home := Vector3.ZERO
## Seconds until this NPC leaves (Red Vigil rider); 0 = stays.
var departs_after: float = 0.0
var leave_target := Vector3.ZERO

var _label: Label3D
var _prompt: Label3D
var _anim: AnimationPlayer = null
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
	_home = position
	routine = data.get("routine", {})
	# A stable fan-out index, so the same person takes the same seat in
	# the inn every evening instead of shuffling on every load.
	_spread = abs(int(hash(npc_id))) % 12
	rotation.y = float(data.get("yaw", 0.0))
	_rng.seed = hash(npc_id)
	_build_body(Color(data.get("tunic", Color(0.5, 0.42, 0.3))))
	_build_labels()
	_leave_in = departs_after
	_bark_in = _rng.randf_range(2.0, 9.0)


## Which model this person wears. Falls back to the old blocky
## placeholder if the pack is ever missing, so the town still loads.
func _model_path() -> String:
	if BODIES.has(npc_id):
		return FOLK % String(BODIES[npc_id])
	if CROWD.has(bark_role):
		var options: Array = CROWD[bark_role]
		return FOLK % String(options[abs(int(hash(npc_id))) % options.size()])
	return ""


func _build_body(tunic: Color) -> void:
	var path := _model_path()
	if path != "" and ResourceLoader.exists(path):
		_build_person(path, tunic)
	else:
		_build_placeholder(tunic)

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


## A real person, with their own clips.
func _build_person(path: String, tunic: Color) -> void:
	var body := (load(path) as PackedScene).instantiate() as Node3D
	# Their origin is already at the feet — no metre to drop them by. The
	# -1.0 that is right for a centred capsule has buried three bodies in
	# this project; it does not get a fourth.
	body.position = Vector3.ZERO
	body.rotation_degrees = Vector3(0, 180, 0)
	add_child(body)

	# Three outfits would be three faces without this.
	_swap_head(body, HEADS[abs(int(hash(npc_id + "head"))) % HEADS.size()])

	# A wash of the tunic colour, so a crowd of six in the same tunic is
	# not six identical people. Multiplied into the texture rather than
	# replacing it, which would flatten them to silhouettes.
	for mi in _all(body, "MeshInstance3D"):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		for i in range(m.mesh.get_surface_count()):
			var base := m.get_active_material(i)
			var mat := (base.duplicate() as StandardMaterial3D) \
				if base is StandardMaterial3D else StandardMaterial3D.new()
			mat.albedo_color = mat.albedo_color.lerp(tunic, 0.22)
			m.set_surface_override_material(i, mat)

	_anim = _find(body, "AnimationPlayer") as AnimationPlayer
	if _anim != null and _anim.has_animation("Idle"):
		_anim.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
		if _anim.has_animation("Walk"):
			_anim.get_animation("Walk").loop_mode = Animation.LOOP_LINEAR
		_anim.play("Idle")


## The mesh that reaches highest: on this pack that is always the head.
##
## Measured off the MESH resource rather than the instance, because a
## skinned MeshInstance3D reports a padded AABB that covers everywhere
## the skin could deform to — which is most of the body, and would pick
## the wrong part.
func _head_of(body: Node3D) -> MeshInstance3D:
	var best: MeshInstance3D = null
	var best_top := -1e9
	for node in _all(body, "MeshInstance3D"):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		var box: AABB = mi.mesh.get_aabb()
		var top: float = box.position.y + box.size.y
		if top > best_top:
			best_top = top
			best = mi
	return best


## Put somebody else's head on this body.
##
## Every model in `modular-characters` is built on the SAME 62-bone rig
## and split into the same four or five parts, so a head is portable:
## reparent it under this skeleton and it deforms with everything else.
##
## That portability is what makes three medieval outfits enough for a
## town. Eleven period-neutral heads across three bodies is thirty-three
## distinguishable people, and not one of them is in a hard hat — which
## the previous approach, picking whole outfits by filename, could not
## manage without reaching for the spacesuit half of the pack.
func _swap_head(body: Node3D, head_model: String) -> void:
	var skel := _find(body, "Skeleton3D") as Skeleton3D
	if skel == null:
		return
	var mine := _head_of(body)
	if mine == null:
		return
	var path: String = FOLK % head_model
	if not ResourceLoader.exists(path):
		return
	var cut: Dictionary = _cut_head(head_model, path)
	if cut.is_empty():
		return

	mine.visible = false
	var worn := MeshInstance3D.new()
	worn.mesh = cut["mesh"]
	worn.skin = cut["skin"]
	worn.transform = cut["transform"]
	skel.add_child(worn)
	worn.skeleton = worn.get_path_to(skel)


## Heads, cut once and shared.
##
## A donor is a whole character — every mesh and every clip — and this
## only ever wants one mesh off it. Building one per townsperson meant 34
## full character scenes instantiated and thrown away to keep 34 heads,
## when there are only eleven distinct heads to keep.
##
## Static, because the saving is across NPCs rather than within one. The
## mesh and skin are shared resources and the wearer only ever reads
## them, so sharing is safe; each NPC still gets its own MeshInstance3D,
## which is what carries the skeleton path and the colour wash.
static var _heads: Dictionary = {}

static func _cut_head(head_model: String, path: String) -> Dictionary:
	if _heads.has(head_model):
		return _heads[head_model]

	var donor := (load(path) as PackedScene).instantiate() as Node3D
	var best: MeshInstance3D = null
	var best_top := -1e9
	for node in _every(donor, "MeshInstance3D"):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		var box: AABB = mi.mesh.get_aabb()
		var top: float = box.position.y + box.size.y
		if top > best_top:
			best_top = top
			best = mi

	var cut := {}
	if best != null:
		cut = {"mesh": best.mesh, "skin": best.skin,
			"transform": best.transform}
	donor.free()
	_heads[head_model] = cut
	return cut


## The same walk as `_all`, as a static so `_cut_head` can use it.
static func _every(node: Node, cls: String) -> Array:
	var out := []
	if node.get_class() == cls:
		out.append(node)
	for c in node.get_children():
		out.append_array(_every(c, cls))
	return out


## The blocky stand-in the town used before real people arrived.
func _build_placeholder(tunic: Color) -> void:
	var body := (load(BODY) as PackedScene).instantiate() as Node3D
	body.position = Vector3.ZERO
	body.rotation_degrees = Vector3(0, 180, 0)
	add_child(body)
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
	# Keeping hours. The clock is L89's, shared and server-authoritative,
	# and where somebody should be at a given hour is a RULE
	# (rules/routine.gd) rather than anything this scene decides.
	_keep_hours(delta)
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


## Walk to wherever the hour says this person should be.
##
## Walked rather than teleported, on purpose: a town where people appear
## in new places whenever you look away is not more alive than a town of
## statues, it is just a stranger one. Seeing the smith cross the square
## at dusk is the whole point, and it costs nothing but a lerp.
func _keep_hours(delta: float) -> void:
	if routine.is_empty() or not stays:
		return
	var clock: WorldClock = TownState.clock()
	if clock == null:
		return

	var want := RoutineRules.place_for(routine, clock.hour())
	if want != _bound_for:
		_bound_for = want

	var target: Vector3 = _home if want == "home" else Places.spot(want, _spread)
	target.y = position.y
	var gap: Vector3 = target - position
	gap.y = 0.0
	if gap.length() < 0.35:
		_play("Idle")
		return
	_play("Walk")

	# Ambling pace. They are going to work, not to a fire.
	var step: Vector3 = gap.normalized() * WALK_SPEED * delta
	if step.length() > gap.length():
		step = gap
	global_position += step
	rotation.y = lerp_angle(rotation.y, atan2(gap.x, gap.z), 4.0 * delta)


## Their own clips, by name. The pack's rig is not Mixamo's, so these are
## the pack's names rather than the game's.
func _play(clip: String) -> void:
	if _anim == null or not _anim.has_animation(clip):
		return
	if _anim.current_animation != clip:
		_anim.play(clip, 0.2)


func _say_bark() -> void:
	var clock: WorldClock = TownState.clock()
	var pool := BarkBank.lines(bark_role, epoch, TownState.current(),
		clock.hour() if clock != null else -1.0)
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
## What they say when you walk up.
##
## **The town remembers, a little.** brainstorm.md §9.3 asks for memory
## that is "small and lossy" — three to five facts, decaying, not a
## transcript — and the smallest honest version of that is a greeting
## that knows whether you have done anything for this town. You are a
## stranger until you thin the Hedges, and then you are not.
##
## Deliberately not a reputation NUMBER: L47 refuses a disposition
## score, and this reads through behaviour exactly as that lock asks.
func greeting() -> String:
	var who := display_name if uses_name else "traveler"
	var state: TownWorldState = TownState.current()
	var clock: WorldClock = TownState.clock()
	var late: bool = clock != null and not RoutineRules.waking(clock.hour())

	if state != null and int(state.culls_completed) > 0:
		# Known, because of what you did rather than because of a number
		# going up somewhere.
		if late:
			return "Still up? The Hedges sleep easier than you do, %s." % who
		return "It's you. The Hedges are quieter for you — sit, if you like." \
			if greeting_warm else "You again. The boars are fewer, I'll grant you that."

	if late:
		return "Late to be about, %s." % who
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
