class_name Fighter
extends CharacterBody3D
## One combatant — the player or an enemy. tech.md §6 Stage 1.
##
## Owns the body, the rig, the clips and the combat state, so that
## `world.gd` is about the fight rather than about skeletons. The player
## and the enemy are the same type on purpose: combat.md §8 promises one
## ruleset rather than two, and the cheapest way to keep that promise is
## for there to be nothing here that knows which is which.
##
## The RULES live in `rules/`, mirroring `sim/`. This is the body they
## move.

const CHARACTER := "res://assets/models/humanoid.fbx"
const SWORD_MODEL := "res://assets/models/weapon_sword.fbx"

const LOCOMOTION := {
	"idle": "res://assets/animations/anim_Idle.fbx",
	"walk": "res://assets/animations/anim_Walking.fbx",
	"run": "res://assets/animations/anim_Running.fbx",
	"roll": "res://assets/animations/anim_Quick_Roll_To_Run.fbx",
	"swing_heavy": "res://assets/animations/anim_Stable_Sword_Outward_Slash.fbx",
	"swing_quick": "res://assets/animations/anim_Sword_And_Shield_Slash.fbx",
	"hurt": "res://assets/animations/anim_Hit_Reaction.fbx",
}
const ONE_SHOT := ["roll", "swing_heavy", "swing_quick", "hurt"]

## "Quick Roll To Run" is a run, then a roll, then a run again. Only the
## roll is wanted, measured off the hips.
const ROLL_START := 0.60
const ROLL_END := 1.30

## Where the arm's angular velocity peaks in each swing clip, and how much
## of the clip to use. The window is then placed so that peak lands inside
## the live-blade window rather than anywhere in particular — so retuning
## a wind-up re-aims the animation automatically instead of silently
## desynchronising it from the telegraph a player is reading.
const SWINGS := {
	"swing_heavy": {"peak": 0.85, "window": 1.00},
	"swing_quick": {"peak": 0.76, "window": 0.80},
}
const HURT_START := 0.05
const HURT_END := 0.40

## How far down the blade the fist closes. Negative drops the pommel below
## the hand rather than inside it.
const SWORD_GRIP_ALONG_BLADE := -0.06

const WALK_CLIP_SPEED := 1.5
const RUN_CLIP_SPEED := 4.2
const WALK_TO_RUN := 2.0
const GRAVITY := 18.0
const TURN := 10.0

var stamina: Stamina
var health: Health
var harness: ArmourSet
var dodge: Dodge
var attack: Attack
var parry: Parry

var anim: AnimationPlayer
## Every surface of the character, each with its own material. A
## placeholder mannequin has one; a real character has several — body,
## head, hair, gear — and anything that assumes one silently paints a
## quarter of them.
var skins: Array[StandardMaterial3D] = []
var skin_base_colors: Array[Color] = []

var _dodge_dir := Vector3.FORWARD
var _dodge_travelled := 0.0
var _hurt_for := 0.0
var _stagger_for := 0.0
var _sword: Node3D
## Slot -> the nodes wearing it. L63 tracks head, torso, arms and legs
## separately because a broken piece comes off and that slot stays bare.
var _worn := {}

## Prototype scaffolding. Nothing on screen otherwise says a blow passed
## through you, and interface.md §2 forbids adding anything permanent to
## say so — this comes out when a real hit reaction and a real miss sound
## carry it instead.
var show_iframes := false
## Whether the player is still holding the guard up. A guard held past
## its window becomes a block rather than expiring.
var _guard_held := false
## Hitstop. Presentation only — see feel.gd for why the rules must not
## be frozen with it.
var _frozen_for := 0.0
var _speed_before_freeze := 1.0
const IFRAME_COLOR := Color(0.45, 0.80, 1.00)
var _iframes_shown := false

signal died

## `character` names the model. It is a parameter rather than a constant
## because the placeholder will be replaced, and because the player and
## an enemy have no reason to be the same person.
func setup(max_health: float, tint: Color, carries_sword: bool = true,
		character: String = CHARACTER,
		iron: Color = Look.IRON, leather: Color = Look.LEATHER,
		armour_class: String = "mail") -> void:
	var body := (load(character) as PackedScene).instantiate()
	# The capsule is two metres tall and centred on the origin, so the
	# character hangs a metre below it to stand on its feet. Mixamo
	# characters face +Z; travel here is toward -Z.
	body.position = Vector3(0, -1.0, 0)
	body.rotation_degrees = Vector3(0, 180, 0)
	add_child(body)

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 2.0
	capsule.radius = 0.5
	shape.shape = capsule
	add_child(shape)

	var skel := _find(body, "Skeleton3D") as Skeleton3D
	if skel == null:
		push_warning("no Skeleton3D; this fighter will be mute")
		return

	_dress(body, tint)

	if carries_sword:
		_arm(skel)
	_worn = Armour.fit(skel, iron, leather)

	var lib := AnimationLibrary.new()
	for key in LOCOMOTION:
		var src := (load(LOCOMOTION[key]) as PackedScene).instantiate()
		var src_anim := _find(src, "AnimationPlayer") as AnimationPlayer
		var clip: Animation = src_anim.get_animation(src_anim.get_animation_list()[0])
		if key in ONE_SHOT:
			clip.loop_mode = Animation.LOOP_NONE
			_flatten_root_motion(clip)
		else:
			clip.loop_mode = Animation.LOOP_LINEAR
		lib.add_animation(key, clip)
		src.queue_free()

	anim = AnimationPlayer.new()
	skel.get_parent().add_child(anim)
	anim.root_node = anim.get_path_to(skel.get_parent())
	anim.add_animation_library("", lib)
	anim.play("idle")

	stamina = Stamina.new()
	health = Health.new(max_health)
	harness = ArmourSet.new(armour_class)
	dodge = Dodge.new()
	attack = Attack.new()
	parry = Parry.new()

## True while a roll, a swing, a guard or a hit reaction owns the body.
func is_busy() -> bool:
	return not dodge.can_act() or not attack.can_act() or not parry.can_act() \
		or _hurt_for > 0.0 or _stagger_for > 0.0

## Opened up by a parry. combat.md §6 promises a free punish, and this is
## what makes it free rather than merely fast.
func is_staggered() -> bool:
	return _stagger_for > 0.0

func tick(delta: float) -> void:
	dodge.tick(delta)
	attack.tick(delta)
	parry.tick(delta, _guard_held)
	stamina.tick(delta)
	if _hurt_for > 0.0:
		_hurt_for = max(0.0, _hurt_for - delta)
	if _stagger_for > 0.0:
		_stagger_for = max(0.0, _stagger_for - delta)
	_tick_freeze(delta)
	_show_iframes()

## A few frames of hesitation on a blow. The clocks above have already
## ticked: only the animation hesitates, so the parry window is still
## the length the server thinks it is.
func freeze(seconds: float) -> void:
	if anim == null or seconds <= 0.0:
		return
	if _frozen_for <= 0.0:
		_speed_before_freeze = anim.speed_scale
	_frozen_for = maxf(_frozen_for, seconds)
	anim.speed_scale = _speed_before_freeze * 0.04

func _tick_freeze(delta: float) -> void:
	if _frozen_for <= 0.0:
		return
	_frozen_for -= delta
	if _frozen_for <= 0.0:
		_frozen_for = 0.0
		if anim != null:
			anim.speed_scale = _speed_before_freeze

func is_frozen() -> bool:
	return _frozen_for > 0.0

func _show_iframes() -> void:
	if not show_iframes:
		return
	var invulnerable := dodge.is_invulnerable()
	if invulnerable == _iframes_shown:
		return
	_iframes_shown = invulnerable
	for i in skins.size():
		skins[i].albedo_color = IFRAME_COLOR if invulnerable else skin_base_colors[i]

## Move under the fighter's own steam, or under a dodge if one is running.
func move(desired: Vector3, speed: float, delta: float) -> void:
	if not attack.can_act() or not parry.can_act() or _hurt_for > 0.0 \
			or _stagger_for > 0.0:
		# A swing is committed: combat.md §6 makes the wind-up a telegraph,
		# and a telegraph you can walk out of tells nobody anything.
		velocity.x = 0.0
		velocity.z = 0.0
	elif not dodge.can_act():
		var reached: float = dodge.travelled_distance()
		var step: float = reached - _dodge_travelled
		_dodge_travelled = reached
		velocity.x = _dodge_dir.x * step / max(delta, 0.0001)
		velocity.z = _dodge_dir.z * step / max(delta, 0.0001)
	else:
		velocity.x = desired.x * speed
		velocity.z = desired.z * speed

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1

	move_and_slide()

	if desired.length() > 0.01 and not is_busy():
		rotation.y = lerp_angle(rotation.y, atan2(-desired.x, -desired.z), TURN * delta)

	_animate(Vector2(velocity.x, velocity.z).length())

func try_dodge(direction: Vector3) -> bool:
	if is_busy():
		return false
	_dodge_dir = direction.normalized() if direction.length() > 0.01 \
		else -global_transform.basis.z
	if not dodge.try_start(stamina):
		return false
	_dodge_travelled = 0.0
	# One roll clip, so the fighter turns to face the dodge rather than
	# rolling sideways. assets/SPEC-dodge-clips.md asks for the four
	# directional clips that fix this.
	rotation.y = atan2(-_dodge_dir.x, -_dodge_dir.z)
	anim.play("roll", 0.06)
	anim.seek(ROLL_START, true)
	anim.speed_scale = (ROLL_END - ROLL_START) / max(dodge.total_seconds(), 0.01)
	return true

## Swing. `section` names the tuning block — "attack" for the player's
## sword, or one of combat.md §6's three shapes for an enemy.
func try_attack(section: String = "attack") -> bool:
	if is_busy():
		return false

	var swing := Attack.new(section)
	if not swing.try_start(stamina):
		return false
	attack = swing

	var key: String = "swing_quick" if swing.shape() == Attack.Shape.QUICK \
		else "swing_heavy"
	var clip: Dictionary = SWINGS[key]
	var window: float = clip["window"]
	var total: float = max(swing.total_seconds(), 0.01)
	# Put the clip's fastest moment inside the live-blade window.
	var live_at: float = (swing.windup_seconds() + total * 0.0) / total
	var start: float = clamp(clip["peak"] - window * live_at, 0.0, 2.0)

	anim.play(key, 0.05)
	anim.seek(start, true)
	anim.speed_scale = window / total
	return true

## Raise the guard. combat.md §6: the answer to a heavy — and, held past
## its window, §2's block.
func try_parry() -> bool:
	if is_busy():
		return false
	if not parry.try_start(stamina):
		return false
	_guard_held = true
	# No guard-pose clip yet, so the hit reaction stands in for the brace.
	# L65 reads the guard off the body and forbids any UI element to
	# rescue it, which makes this a placeholder for the single most
	# load-bearing pose in the design. assets/SPEC-attack-clips.md asks
	# for the real one.
	anim.play("hurt", 0.04)
	anim.seek(HURT_START, true)
	anim.speed_scale = 0.5
	return true

## Let the guard down. Holding it is what makes it a block.
func lower_guard() -> void:
	_guard_held = false

## Take back a guard that was only raised to find out whether the touch
## was a tap. Refunds it whole, and refuses once the guard has done
## anything — it can never undo a parry.
func cancel_guard() -> bool:
	_guard_held = false
	return parry.cancel(stamina)

## Meet an incoming blow with whatever this fighter is doing about it.
## Returns the Parry.Outcome — the caller applies the stagger, because
## staggering is something that happens to the *attacker*.
func meet(incoming: Attack, damage: float = 0.0) -> int:
	return parry.meet(incoming, stamina, damage)

## Opened up by a parry that landed.
func stagger(seconds: float) -> void:
	attack.reset()
	_stagger_for = seconds
	anim.play("hurt", 0.05)
	anim.seek(HURT_START, true)
	anim.speed_scale = (HURT_END - HURT_START) / max(seconds, 0.01)

## Take a blow along an arc. Returns { taken, slot, broke, bare }.
##
## The arc decides which piece of the harness meets it (L64), the damage
## triangle decides what that piece is worth against this kind of blow
## (§4), and a piece worn to nothing comes off then and there (L63).
## Zero damage if the dodge's invulnerable window ate it, which is the
## whole point of the dodge.
func hurt(amount: float, arc: int = Attack.Arc.UPPER_RIGHT,
		damage_type: String = "cut") -> Dictionary:
	var miss := {"taken": 0.0, "slot": -1, "broke": false, "bare": false}
	if dodge.is_invulnerable() or health.is_dead():
		return miss

	var slot := ArmourSet.slot_for(arc)
	var blow := harness.resolve(slot, amount, damage_type)
	if blow["broke"]:
		# L63: it does not merely stop protecting. It comes off.
		shed(slot)

	var taken := health.take(blow["damage"])
	var out := {"taken": taken, "slot": slot,
		"broke": blow["broke"], "bare": blow["bare"]}
	if health.is_dead():
		died.emit()
		return out

	# A hit reaction interrupts whatever was happening, including a swing.
	# Being hit mid-wind-up costing you the swing is most of what makes
	# reading a telegraph worth anything.
	attack.reset()
	_hurt_for = HURT_END - HURT_START
	anim.play("hurt", 0.04)
	anim.seek(HURT_START, true)
	anim.speed_scale = 1.0
	return out

## L63: a piece that breaks does not merely stop protecting — it comes
## off, and the slot is bare for the rest of the fight. The damage side
## of that is not built yet; this is the half that makes it visible.
func shed(slot: int) -> void:
	for mount in _worn.get(slot, []):
		(mount as Node3D).visible = false

func wearing(slot: int) -> bool:
	var mounts: Array = _worn.get(slot, [])
	return not mounts.is_empty() and (mounts[0] as Node3D).visible

## Put the whole harness back on. Respawn only — nothing in the design
## repairs armour mid-fight (L59: repair is a crafter's job).
func rearm() -> void:
	for slot in _worn:
		for mount in _worn[slot]:
			(mount as Node3D).visible = true

func revive() -> void:
	health.reset()
	stamina.reset()
	dodge.reset()
	attack.reset()
	parry.reset()
	_guard_held = false
	harness.reset()
	rearm()
	_hurt_for = 0.0
	_stagger_for = 0.0
	_frozen_for = 0.0
	rotation = Vector3.ZERO
	if anim != null:
		anim.play("idle")

func _animate(ground_speed: float) -> void:
	if anim == null or is_busy() or is_frozen():
		return
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
	# Kept near 1.0 on purpose: a clip pushed past about 1.35x reads as
	# comical long before it stops skating.
	anim.speed_scale = clamp(rate, 0.7, 1.35)

## Give this fighter its own copy of every material on its body, tinted.
##
## Two things here exist for the character that has not arrived yet. It
## walks EVERY mesh rather than the first, because a real character is
## several meshes and tinting only one would paint the body and leave the
## head grey. And it multiplies into `albedo_color` rather than replacing
## it, because on a textured model multiplying tints the texture while
## replacing would flatten it to a solid colour — which is exactly the
## kind of thing that would cost a round with the artist to discover.
func _dress(body: Node, tint: Color) -> void:
	for mesh in _all(body, "MeshInstance3D"):
		var mi := mesh as MeshInstance3D
		for surface in maxi(mi.mesh.get_surface_count() if mi.mesh else 0, 1):
			var base := mi.get_active_material(surface)
			var mat: StandardMaterial3D = base.duplicate() \
				if base is StandardMaterial3D else StandardMaterial3D.new()
			mat.albedo_color = mat.albedo_color * tint
			mi.set_surface_override_material(surface, mat)
			skins.append(mat)
			skin_base_colors.append(mat.albedo_color)

## Every descendant of a class, not just the first.
func _all(node: Node, cls: String) -> Array[Node]:
	var found: Array[Node] = []
	if node.get_class() == cls:
		found.append(node)
	for child in node.get_children():
		found.append_array(_all(child, cls))
	return found

func _arm(skel: Skeleton3D) -> void:
	# There is no grip marker on a Mixamo hand, and guessing rotations is a
	# slow way to be wrong. The hand's own bones give the answer: the
	# fingers curl around the grip, so the blade runs along the line across
	# the knuckles. That holds for any hand in any rig.
	var hand := skel.find_bone("mixamorig_RightHand")
	var index := skel.find_bone("mixamorig_RightHandIndex1")
	var pinky := skel.find_bone("mixamorig_RightHandPinky1")
	if hand < 0:
		return

	var grip := BoneAttachment3D.new()
	grip.bone_idx = hand
	skel.add_child(grip)

	_sword = (load(SWORD_MODEL) as PackedScene).instantiate()
	grip.add_child(_sword)

	if index >= 0 and pinky >= 0:
		var to_hand := skel.get_bone_global_rest(hand).affine_inverse()
		var grip_axis: Vector3 = (to_hand * skel.get_bone_global_rest(index).origin
			- to_hand * skel.get_bone_global_rest(pinky).origin).normalized()
		_sword.quaternion = Quaternion(_longest_axis(_sword), grip_axis)
		_sword.position = grip_axis * SWORD_GRIP_ALONG_BLADE
	else:
		push_warning("no finger bones; the sword will be held badly")

func _longest_axis(weapon: Node3D) -> Vector3:
	# Which way the weapon points, measured rather than assumed. A blade is
	# much longer than it is wide, so the longest side of its bounding box
	# is the blade, and which end of that box the origin sits at says which
	# way it points. The sword's runs along its own -Z; assuming +Y put it
	# through the character's hip.
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
	# Movement is the character controller's job — the server has no
	# animations and still has to agree where everybody is (combat.md §7) —
	# so horizontal travel is zeroed. The vertical dip stays: that IS the
	# roll.
	for t in clip.get_track_count():
		if clip.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		if not String(clip.track_get_path(t)).ends_with("Hips"):
			continue
		for k in clip.track_get_key_count(t):
			var v: Vector3 = clip.track_get_key_value(t, k)
			clip.track_set_key_value(t, k, Vector3(0.0, v.y, 0.0))

func _find(node: Node, cls: String) -> Node:
	if node.get_class() == cls:
		return node
	for child in node.get_children():
		var hit := _find(child, cls)
		if hit != null:
			return hit
	return null
