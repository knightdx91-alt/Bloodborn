class_name DrillYard
extends Node3D
## The drill yard, as a REGION rather than a scene.
##
## The same move the Hedges made, and for the same reported reason:
## *"i want the whole thing to just be a big world, where you can go to
## the arena, and where ever else from the main town."* The Hedges went
## first; the yard was the last place still behind a menu button, and a
## menu button is what made it a second world rather than a second
## place — its own ground, its own sky, its own clock, its own copy of
## the player.
##
## So this builds only what is ITS OWN — the enclosure, the blocks to
## fight around, the pell, and the man to spar with — and stands on
## whatever ground it is placed on. The sky, the hour and the light
## belong to the world (L89: one clock), the player and the camera
## belong to the scene, and the blade geometry belongs to `Skirmish`.
##
## Deliberately the opposite of the Hedges. That is open field, hedged
## on three sides, where the practice gets spent. This is walled, flat
## and swept, with a fence and a pell, because it is a place for
## practice — it should read as a lesson.

const YARD := 30.0  # half-extent of the fighting floor

const DUMMY_MODEL := "res://assets/models/dummy.fbx"
const DUMMY_HOME := Vector3(3, 0, -2)
const DUMMY_COLOR := Color(0.55, 0.38, 0.30)
const DUMMY_RADIUS := 0.45
const DUMMY_HALF_HEIGHT := 0.75
const DUMMY_HEALTH := 120.0
const DUMMY_RESET_SECONDS := 3.0

const SWORDSMAN_HOME := Vector3(-4, 1, -5)
const SWORDSMAN_HEALTH := 110.0
const SWORDSMAN_DAMAGE := 22.0
const SWORDSMAN_SPEED := 2.4
const RESPAWN_SECONDS := 4.0

const NIGHTSHADE_HOME := Vector3(9, 0, 7)

## How far past the wall he will follow you. He minds his own yard, the
## way the boar minds its own wood — walk out and the bout is over,
## which is what makes the yard a place you can leave rather than a
## room you are locked in.
const LEASH := 12.0

var swordsman: Fighter = null
var dummy: Node3D = null
var skirmish: Skirmish = null
## Who he is sparring with. Set by the world.
var quarry: Fighter = null

## Which brain he is on. Public for the same reason HedgeWood's is:
## a tuning instrument has to be able to reseed him to get a
## repeatable bout out of him.
var tactics: EnemyTactics = null
## Set non-zero to make respawns repeatable. Zero — the default, and
## what the game runs — takes the clock instead.
@export var respawn_seed := 0
var _down := 0.0
var _dummy_skin: StandardMaterial3D = null
var _dummy_health := 0.0
var _dummy_flash := 0.0
var _dummy_rock := 0.0
var _dummy_down := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 20260914
	_build_walls()
	_build_blocks()
	_scatter()
	_build_dummy()
	_build_display()
	_build_swordsman()


## Three walls and a kerb, open toward the road home.
##
## The scene version boxed the yard on all four sides, which was right
## when the only way out was a menu and wrong the moment the yard had a
## road to it. You should never be able to walk into the void — but the
## void is 250 m away now and the town owns the ground in between, so
## what these are for is reading as an enclosure, not as a cage.
func _build_walls() -> void:
	var body := StaticBody3D.new()
	body.name = "Walls"
	var along := YARD * 2.0 + 2.0
	# 0 south, 1 west, 2 east. North is the way in.
	for side in 3:
		var wall := CollisionShape3D.new()
		var wb := BoxShape3D.new()
		wb.size = Vector3(along, 6.0, 1.0) if side == 0 else Vector3(1.0, 6.0, along)
		wall.shape = wb
		match side:
			0: wall.position = Vector3(0, 3, YARD)
			1: wall.position = Vector3(-YARD, 3, 0)
			_: wall.position = Vector3(YARD, 3, 0)
		body.add_child(wall)

		# A low kerb so the wall is visible, not just felt.
		var kerb := MeshInstance3D.new()
		var km := BoxMesh.new()
		km.size = Vector3(along, 0.6, 0.6) if side == 0 else Vector3(0.6, 0.6, along)
		kerb.mesh = km
		kerb.position = Vector3(wall.position.x, 0.3, wall.position.z)
		kerb.material_override = Look.solid_material(Look.KERB, 6.0)
		body.add_child(kerb)
	add_child(body)


## Blocks to fight around. combat.md §1: terrain is fighting space.
func _build_blocks() -> void:
	var stone := Look.solid_material(Look.STONE, 2.4)
	for spot in [Vector3(6, 0.75, -4), Vector3(-5, 0.75, -7), Vector3(-7, 0.75, 3)]:
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.5, 1.5, 1.5)
		b.mesh = bm
		b.position = spot
		b.material_override = stone
		add_child(b)


## A handful of posts and stones. Nothing here is a feature — it exists
## because an empty plane gives the eye nothing to measure speed or
## distance against, and because a drill yard with nothing in it does
## not read as a place.
func _scatter() -> void:
	var stone := Look.solid_material(Look.STONE, 2.4)
	var timber := Look.solid_material(Look.TIMBER, 5.0, 0.9)

	# A fence along the two closed long sides, just inside the kerb.
	for i in 22:
		var t := i / 21.0
		for corner in [Vector3(-26.0 + t * 52.0, 0, 27.0), Vector3(-27.0, 0, -26.0 + t * 52.0)]:
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
	for i in 34:
		var angle := _rng.randf() * TAU
		var radius: float = lerp(9.0, 27.0, _rng.randf())
		var rock := MeshInstance3D.new()
		var rm := SphereMesh.new()
		# Small and rounded. The first pass made them big and flat, which
		# reads as puddles rather than stone.
		var size: float = lerp(0.16, 0.42, radius / 27.0) * _rng.randf_range(0.7, 1.4)
		rm.radius = size
		rm.height = size * 1.7
		rock.mesh = rm
		rock.position = Vector3(cos(angle) * radius, size * 0.45, sin(angle) * radius)
		rock.scale = Vector3(1.0, _rng.randf_range(0.7, 1.0), _rng.randf_range(0.85, 1.15))
		rock.rotation.y = _rng.randf() * TAU
		rock.material_override = stone
		add_child(rock)


func _build_dummy() -> void:
	dummy = Node3D.new()
	dummy.name = "Pell"
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


## INACTIVE DISPLAY MODEL — not a fighter. The nightshade stands at the
## yard's edge so its silhouette can be judged, but it has no AI, no
## health and no collision. Enemy variety is a later build-plan step.
func _build_display() -> void:
	var shade := (load(Fighter.NIGHTSHADE_MODEL) as PackedScene).instantiate()
	shade.position = NIGHTSHADE_HOME
	shade.rotation_degrees = Vector3(0, 140, 0)
	add_child(shade)


func _build_swordsman() -> void:
	swordsman = Fighter.new()
	swordsman.name = "Swordsman"
	swordsman.position = SWORDSMAN_HOME
	add_child(swordsman)
	# Darker and colder, so the two are told apart by value rather than
	# by a marker over anyone's head (interface.md §2): the difference
	# has to be in the silhouette and the value.
	swordsman.setup(SWORDSMAN_HEALTH, Color(0.40, 0.62, 0.62), true,
		Fighter.ENEMY_CHARACTER, Color(0.26, 0.27, 0.30),
		Color(0.16, 0.13, 0.10), "light")
	swordsman.weapon_damage = SWORDSMAN_DAMAGE
	tactics = EnemyTactics.new(20260914)


func _find(node: Node, cls: String) -> Node:
	if node.get_class() == cls:
		return node
	for child in node.get_children():
		var hit := _find(child, cls)
		if hit != null:
			return hit
	return null


## Put the yard into the world's fight.
##
## The scene version owned the player, the opponent and the blade
## geometry together, which is exactly why the town had no combat. The
## yard now hands its own fighter and its own pell to the one `Skirmish`
## the world already runs, and gets out of the way.
func sparred_by(who: Fighter, field: Skirmish) -> void:
	quarry = who
	skirmish = field
	if field == null:
		return
	field.enlist(swordsman)
	# The pell is a post: struck, never striking. Its position is read
	# through a Callable rather than copied, because it rocks when hit
	# and a stale position would let you miss a dummy you are standing
	# in front of.
	field.add_post(func() -> Vector3: return dummy.global_position, DUMMY_RADIUS)
	field.landed_on_post.connect(_hit_dummy)


func _physics_process(delta: float) -> void:
	if swordsman == null or not is_instance_valid(swordsman):
		return
	swordsman.tick(delta)
	_tick_dummy(delta)
	_tick_down(delta)

	if _down > 0.0 or quarry == null or not is_instance_valid(quarry):
		swordsman.move(Vector3.ZERO, 0.0, delta)
		return
	if quarry.health.is_dead():
		swordsman.move(Vector3.ZERO, 0.0, delta)
		return

	# He minds his own yard. Walk out and he does not follow you into
	# Thornfield — the same leash the boar has, for the same reason.
	if quarry.global_position.distance_to(global_position) > YARD + LEASH:
		swordsman.move(Vector3.ZERO, 0.0, delta)
		return

	var to_you: Vector3 = quarry.global_position - swordsman.global_position
	to_you.y = 0.0
	_run(delta, to_you.normalized(), to_you.length())


## The swordsman's side of the fight. Geometry here, rules in sim/.
##
## The difference from the boar is the whole point. He turns to face you
## every tick, because his telegraph is the wind-up (combat.md §6) and a
## wind-up aimed elsewhere teaches nothing. A boar aims once and cannot
## correct. Reading a man is a different skill from reading an animal,
## and the yard is where you learn the first one.
func _run(delta: float, heading: Vector3, distance: float) -> void:
	var decision := tactics.decide(distance, swordsman.stamina, swordsman.is_busy())
	match decision["intent"]:
		EnemyTactics.Intent.ATTACK:
			# Face you before committing.
			swordsman.rotation.y = atan2(-heading.x, -heading.z)
			if swordsman.try_attack(EnemyTactics.section_for(decision["shape"])):
				# He aims as well. A heavy comes down overhead, a quick
				# goes for the body, and the whole-body swing takes the
				# legs — so a harness wears unevenly and which piece
				# fails says something about the fight.
				swordsman.attack.arc = [Attack.Arc.UPPER_RIGHT,
					Attack.Arc.OVERHEAD, Attack.Arc.LOWER_LEFT][decision["shape"]]
				tactics.threw(decision["shape"])
			swordsman.move(Vector3.ZERO, 0.0, delta)
		EnemyTactics.Intent.CLOSE:
			swordsman.move(heading, SWORDSMAN_SPEED, delta)
		_:
			# Circling, or busy. Keep facing you so the next wind-up is
			# readable from the start.
			if not swordsman.is_busy():
				swordsman.rotation.y = lerp_angle(
					swordsman.rotation.y, atan2(-heading.x, -heading.z), 6.0 * delta)
			swordsman.move(Vector3.ZERO, 0.0, delta)


func _tick_down(delta: float) -> void:
	if swordsman.health.is_dead() and _down <= 0.0:
		_down = RESPAWN_SECONDS
		return
	if _down <= 0.0:
		return
	_down = maxf(0.0, _down - delta)
	if _down > 0.0:
		return
	# Another one steps up. A drill yard is not a boss room, and
	# crucially it is not a contract either — nothing here is recorded
	# against the board. Killing the sparring partner is practice, and
	# practice does not pay.
	swordsman.revive()
	swordsman.global_position = global_position + SWORDSMAN_HOME
	# A fresh brain, so the next man is not the last man continued.
	#
	# From the CLOCK in play, which is what makes him unpredictable, but
	# from `respawn_seed` when one is set — because a tuning instrument
	# measuring five plans against "the same enemy behaviour each time"
	# gets a different enemy the moment one of them kills him, and then
	# reports the difference as though it were the plan.
	tactics = EnemyTactics.new(
		respawn_seed if respawn_seed != 0 else Time.get_ticks_msec())


## Is the pell up? False while it lies knocked over waiting to reset.
##
## Public because anything aiming at it needs to know — swinging at a
## pell that is not there is a swing thrown at nothing, and the capture
## harness did exactly that until it could ask.
func pell_standing() -> bool:
	return _dummy_down <= 0.0


## Struck. Wired to `Skirmish.landed_on_post` — which carries no identity
## because the yard's pell is the only post in the world. A second one
## anywhere would need the signal to say which, and this would be the
## line that broke.
func _hit_dummy(amount: float) -> void:
	if _dummy_down > 0.0:
		return
	_dummy_health = maxf(0.0, _dummy_health - amount)
	_dummy_flash = 1.0
	_dummy_rock = 1.0
	if _dummy_health <= 0.0:
		_dummy_down = DUMMY_RESET_SECONDS


func _tick_dummy(delta: float) -> void:
	if dummy == null:
		return
	_dummy_flash = maxf(0.0, _dummy_flash - delta * 4.0)
	_dummy_rock = maxf(0.0, _dummy_rock - delta * 3.0)

	if _dummy_down > 0.0:
		_dummy_down -= delta
		dummy.visible = false
		if _dummy_down <= 0.0:
			_dummy_health = DUMMY_HEALTH
			dummy.visible = true
	else:
		# It rocks when hit, and that is the only feedback of its kind
		# there should be: interface.md §2 gives an opponent no bars.
		dummy.rotation.x = -_dummy_rock * 0.28
		dummy.rotation.z = _dummy_rock * 0.10

	if _dummy_skin != null:
		_dummy_skin.albedo_color = DUMMY_COLOR.lerp(Color(1, 0.92, 0.85), _dummy_flash)
