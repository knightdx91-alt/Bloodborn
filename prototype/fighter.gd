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

const CHARACTER := "res://assets/models/paladin.fbx"
const ENEMY_CHARACTER := "res://assets/models/skeleton_zombie.fbx"
const NIGHTSHADE_MODEL := "res://assets/models/nightshade.fbx"
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
## Measured off the clips rather than eyeballed: `from` is where the
## right hand first rises above a tenth of its peak angular speed (the
## moment the body stops being at rest), `peak` is where that speed
## maxes (the strike), and `to` is where it settles for good.
const SWINGS := {
	"swing_heavy": {"from": 0.42, "peak": 0.90, "to": 1.80},
	"swing_quick": {"from": 0.02, "peak": 0.82, "to": 1.53},
	# The boar, measured the same way off its own rig: the Head bone's
	# speed over the 1.125s clip, sampled frame by frame. Guessing these
	# would desynchronise the telegraph from the rules, which is the
	# whole thing the two-stage swing exists to prevent.
	"beast_attack": {"from": 0.281, "peak": 0.362, "to": 0.824},
}

## A four-legged thing's model and its clips. Its own 20-bone rig, so
## none of the Mixamo locomotion above applies to it.
const BEAST := {
	"boar": {
		"model": "res://assets/models/boar.fbx",
		"clips": {
			"idle": "res://assets/animations/boar_Idle.fbx",
			"walk": "res://assets/animations/boar_Walk.fbx",
			"run": "res://assets/animations/boar_Run.fbx",
			"beast_attack": "res://assets/animations/boar_Attack.fbx",
		},
	},
	"wolf": {
		"model": "res://assets/models/wolf.fbx",
		"clips": {
			"idle": "res://assets/animations/wolf_Idle.fbx",
			"walk": "res://assets/animations/wolf_Walk.fbx",
			"run": "res://assets/animations/wolf_Run.fbx",
			"beast_attack": "res://assets/animations/wolf_Attack.fbx",
		},
	},
}

## A clip pushed much past this reads as comical long before it stops
## skating. When the tuning is faster than the animation can honestly go,
## the rate clamps here and `_swing_strain` records by how much — the
## number to move is then the tuning, not this.
const SWING_RATE_MAX := 1.25
const SWING_RATE_MIN := 0.70

## Where in the heavy swing the blade is up and the body is braced —
## between the clip's first motion and its strike. A stand-in for the
## guard pose `assets/SPEC-attack-clips.md` asks for, and a far better
## one than the hit reaction, which used to do this job and meant a
## fighter bracing and a fighter being hit looked identical.
const GUARD_POSE_AT := 0.72
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
## What this fighter's weapon does before the arc's multiplier.
##
## Held here rather than passed in at every swing, because it is a fact
## about the fighter and the thing they are carrying. It used to be two
## constants in world.gd handed to a resolve function per call, which
## worked exactly as long as combat happened in one scene with one
## player and one enemy.
var weapon_damage := 28.0
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

## Which clip the current swing is playing, and whether its rate has
## already been handed over from the wind-up to the strike.
var _swing_clip := ""
## Four-legged, on its own rig: no roll clip, no guard pose, one attack.
var is_beast := false
var _swing_struck := false
## How much faster than SWING_RATE_MAX the tuning asked the clip to run.
## 1.0 means the animation kept up; above that, the swing is being shown
## slower than it actually resolves, and the tuning is the thing to fix.
var _swing_strain := 1.0

## Distance walked since the last footstep. Placeholder gait: the step
## clips are not cut to the walk cycle, so there is no keyframe to hang
## them off. Metres travelled is the honest stand-in — it speeds up when
## you run and stops dead when you do, which is what the ear is checking.
var _stride := 0.0
const STRIDE := 1.55
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
		clip = _match_units(clip, skel)
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

## A four-legged thing, built from boxes, with no rig and no sword.
##
## Separate from setup() rather than a flag inside it, because setup()'s
## no-skeleton path returns EARLY and never reaches the lines that make
## stamina, health and the rest — a beast going down that path would have
## a body and no combat state at all. The tuned humanoid path is not
## touched by this.
##
## Everything below the neck is placeholder: art-audio.md §5 puts the
## look in the treatment rather than in bought assets, and there is no
## boar in the asset set. What matters for the slice is that it reads as
## AN ANIMAL AND NOT A MAN at a glance — four legs, low to the ground,
## tusks — because a blood-warped boar wearing a humanoid rig would be a
## lie in the wrong direction, and the fiction of the cull contract rests
## on it.
func setup_beast(max_health: float, kind: String = "boar") -> void:
	is_beast = true
	var spec: Dictionary = BEAST.get(kind, BEAST["boar"])

	var body := (load(String(spec["model"])) as PackedScene).instantiate() as Node3D
	# Unlike the Mixamo characters, this rig's origin is already at the
	# feet, so there is no metre to drop it by. The same -1.0 offset that
	# is correct for a CharacterBody3D's centred capsule would bury it —
	# it has buried three bodies in this project already.
	body.position = Vector3.ZERO
	# Faces +Z like everything else here; travel is toward -Z.
	body.rotation_degrees = Vector3(0, 180, 0)
	add_child(body)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 1.0, 1.7)
	shape.shape = box
	shape.position = Vector3(0, 0.5, 0)
	add_child(shape)

	stamina = Stamina.new()
	health = Health.new(max_health)
	harness = ArmourSet.new("none")
	dodge = Dodge.new()
	attack = Attack.new()
	parry = Parry.new()

	var skel := _find(body, "Skeleton3D") as Skeleton3D
	if skel == null:
		push_warning("beast '%s' has no Skeleton3D; it will be mute" % kind)
		return

	var lib := AnimationLibrary.new()
	for key in spec["clips"]:
		var src := (load(String(spec["clips"][key])) as PackedScene).instantiate()
		var src_anim := _find(src, "AnimationPlayer") as AnimationPlayer
		if src_anim != null and src_anim.get_animation_list().size() > 0:
			# The exporter names each take after its armature and action;
			# the game asks for "walk", so the name is dropped here rather
			# than being spread through the caller.
			var made: Animation = src_anim.get_animation(src_anim.get_animation_list()[0])
			made.loop_mode = Animation.LOOP_NONE if key == "beast_attack" \
				else Animation.LOOP_LINEAR
			lib.add_animation(key, made)
		src.queue_free()

	anim = AnimationPlayer.new()
	skel.get_parent().add_child(anim)
	anim.root_node = anim.get_path_to(skel.get_parent())
	anim.add_animation_library("", lib)
	anim.play("idle")


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
	_tick_swing()
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
	_tick_steps(delta)

	if desired.length() > 0.01 and not is_busy():
		rotation.y = lerp_angle(rotation.y, atan2(-desired.x, -desired.z), TURN * delta)

	_animate(Vector2(velocity.x, velocity.z).length())

## A footstep every STRIDE metres of ground actually covered.
##
## Off the floor there is nothing to step on, and a dodge is a push
## rather than a gait, so neither counts.
func _tick_steps(delta: float) -> void:
	if not is_on_floor() or not dodge.can_act():
		return
	var moved: float = Vector2(velocity.x, velocity.z).length() * delta
	if moved < 0.001:
		# Standing still resets, so the first step after a stop lands on
		# the footfall rather than half a stride into it.
		_stride = 0.0
		return
	_stride += moved
	if _stride < STRIDE:
		return
	_stride -= STRIDE
	Sound.step(self, global_position)

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
	# A beast has its own rig and its own short clip list. Asking whether
	# the clip exists rather than whether there is a player at all is
	# what lets one body type be missing a roll without every caller
	# having to know which body it is holding.
	if anim == null or not anim.has_animation("roll"):
		return true
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

	# A beast has one attack, on its own rig. The shape the rules chose
	# still decides the timing; there is simply not a second clip to
	# choose between.
	var key := "beast_attack" if is_beast \
		else ("swing_quick" if swing.shape() == Attack.Shape.QUICK else "swing_heavy")
	var clip: Dictionary = SWINGS[key]
	var windup: float = maxf(swing.windup_seconds(), 0.01)

	# The swing is played in two stages, wind-up then strike, so the
	# clip's fastest moment lands on the live-blade window by
	# construction rather than by arithmetic done once at the start.
	#
	# It used to be one stage, and it SEEKED PAST THE WIND-UP to make the
	# peak line up — 0.5s into a 2.0s clip, which is halfway through the
	# slash. Every swing therefore began by snapping the arm from
	# standing to mid-cut in a single frame, and a 0.05s blend cannot
	# hide that. Starting at the clip's own first movement instead means
	# the pose it blends from is very nearly the pose it is already in.
	_swing_clip = key
	_swing_struck = false
	var rate: float = (clip["peak"] - clip["from"]) / windup
	_swing_strain = maxf(1.0, rate / SWING_RATE_MAX)

	if anim == null or not anim.has_animation(key):
		return true
	anim.play(key, 0.10)
	anim.seek(clip["from"], true)
	anim.speed_scale = clampf(rate, SWING_RATE_MIN, SWING_RATE_MAX)
	return true

## Hand the clip over from the wind-up to the follow-through the moment
## the blade goes live, so the strike reads at a sane rate whatever the
## recovery is tuned to.
func _tick_swing() -> void:
	if _swing_clip == "":
		return
	if attack.can_act():
		_swing_clip = ""
		_swing_struck = false
		return
	if _swing_struck or attack.phase() == Attack.Phase.WINDUP:
		return
	_swing_struck = true
	Sound.swing(self, global_position + Vector3(0, 1.25, 0))
	if is_frozen():
		return
	var clip: Dictionary = SWINGS[_swing_clip]
	var rest: float = maxf(attack.total_seconds() - attack.windup_seconds(), 0.01)
	if anim == null or not anim.has_animation(_swing_clip):
		return
	anim.speed_scale = clampf((clip["to"] - clip["peak"]) / rest,
			SWING_RATE_MIN, SWING_RATE_MAX)

## Raise the guard. combat.md §6: the answer to a heavy — and, held past
## its window, §2's block.
func try_parry() -> bool:
	if is_busy():
		return false
	if not parry.try_start(stamina):
		return false
	_guard_held = true
	# Still no guard-pose clip, but this no longer borrows the HIT
	# REACTION to stand in for one, which was actively misleading: a
	# fighter bracing and a fighter being struck played the same
	# animation, so the sword came up by itself every time you were hit
	# and the brace read as a flinch. Reported from play, and exactly the
	# failure L65 warns about — the guard is read off the body, so a body
	# that lies about it breaks the fight.
	#
	# Held on the heavy swing's own wind-up instead: blade up, weight
	# back, and unmistakably not a flinch. assets/SPEC-attack-clips.md
	# still asks for the real pose, which is the most load-bearing single
	# clip in the design.
	_swing_clip = ""
	if anim == null or not anim.has_animation("swing_heavy"):
		return true
	anim.play("swing_heavy", 0.12)
	anim.seek(GUARD_POSE_AT, true)
	anim.speed_scale = 0.0
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
	if anim == null or not anim.has_animation("hurt"):
		return
	anim.play("hurt", 0.05)
	anim.seek(HURT_START, true)
	anim.speed_scale = (HURT_END - HURT_START) / max(seconds, 0.01)

## Take a blow along an arc. Returns { taken, slot, broke, bare, class }.
##
## The arc decides which piece of the harness meets it (L64), the damage
## triangle decides what that piece is worth against this kind of blow
## (§4), and a piece worn to nothing comes off then and there (L63).
## Zero damage if the dodge's invulnerable window ate it, which is the
## whole point of the dodge.
##
## `class` is what the blow MET — read before the harness is worn down,
## because resolve() can break the piece as it computes. Asked afterwards
## a blow that broke the last of the mail reads as "none", and audio.md
## §4 (L87) hangs the player's only reading of the damage triangle off
## exactly that answer.
func hurt(amount: float, arc: int = Attack.Arc.UPPER_RIGHT,
		damage_type: String = "cut") -> Dictionary:
	var miss := {"taken": 0.0, "slot": -1, "broke": false, "bare": false,
		"class": "none"}
	if dodge.is_invulnerable() or health.is_dead():
		return miss

	var slot := ArmourSet.slot_for(arc)
	var met := harness.protection_at(slot)
	var blow := harness.resolve(slot, amount, damage_type)
	if blow["broke"]:
		# L63: it does not merely stop protecting. It comes off.
		shed(slot)

	var taken := health.take(blow["damage"])
	var out := {"taken": taken, "slot": slot, "class": met,
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

## Put a clip into the same units as the skeleton it will drive.
##
## Mixamo clips are authored in metres: the walk puts the pelvis at
## 1.016. A character exported from Blender in CENTIMETRES has bone rests
## a hundred times larger (pelvis 104.27) with a 0.01 scale on the
## armature node to compensate — which looks perfectly right standing
## still, and folds the body up the instant a metre-authored position
## track drives the pelvis to a hundredth of its height. `brute.fbx` and
## `raider.fbx` are both like this; rendered, they collapse into heaps
## while the paladin walks past them.
##
## **This is not the retargeting SPEC-character-v3 forbids.** That mapped
## bone to bone and corrected rest orientations, and the right fix was to
## delete it. This reads one number off each side and scales one kind of
## track — which is what an importer does. The rest pose is already
## correct on these files (1.10° from the Mixamo reference, better than
## the working player model's 16°), so there is nothing else to fix.
##
## The proper fix is still at source: export the armature in metres. When
## that happens this becomes a no-op on its own, because the ratio goes
## to 1 — it does not have to be found and removed.
static func _match_units(clip: Animation, skel: Skeleton3D) -> Animation:
	var hips := skel.find_bone("mixamorig_Hips")
	if hips == -1:
		return clip
	var rest: float = skel.get_bone_rest(hips).origin.length()
	var authored := 0.0
	for t in clip.get_track_count():
		if clip.track_get_type(t) == Animation.TYPE_POSITION_3D \
				and str(clip.track_get_path(t)).findn("Hips") != -1:
			authored = (clip.track_get_key_value(t, 0) as Vector3).length()
	if authored <= 0.0001 or rest <= 0.0001:
		return clip
	var ratio: float = rest / authored
	# Everything sane sits near 1 — the two shipped Mixamo downloads
	# measure 0.94 and 1.15, and must not be touched.
	if ratio > 0.5 and ratio < 2.0:
		return clip
	var fixed := clip.duplicate() as Animation
	for t in fixed.get_track_count():
		if fixed.track_get_type(t) != Animation.TYPE_POSITION_3D:
			continue
		for k in fixed.track_get_key_count(t):
			fixed.track_set_key_value(t, k,
				(fixed.track_get_key_value(t, k) as Vector3) * ratio)
	return fixed


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
