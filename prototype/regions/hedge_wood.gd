class_name HedgeWood
extends Node3D
## The Hedges, as a REGION rather than a scene.
##
## It used to be half of `world.gd`: a builder that made its own ground,
## its own sky and its own clock, because it was a separate scene reached
## from a menu. Reported from play: *"i want the whole thing to just be a
## big world, where you can go to the arena, and where ever else from the
## main town."*
##
## So it builds only what is ITS OWN — the hedge on three sides, the
## scrub, and the boar — and stands on whatever ground it is placed on.
## The sky, the hour and the light belong to the world now, and a region
## that brought its own would be a second answer to a question L89
## already settled with one shared clock.
##
## Deliberately NOT the drill yard with different props. The yard is
## walled, flat and swept because it is a place for practice; this is
## where the practice is spent, and it should not feel like a lesson.

const FIELD := 34.0
const BOAR_HEALTH := 110.0
const BOAR_DAMAGE := 22.0
## A charging boar is faster than a man can walk and faster than it can
## turn — both on purpose. Outrunning it is not the answer.
const CHARGE_SPEED := 6.2
const STALK_SPEED := 1.6
const GORE_REACH := 1.5
const RESPAWN_SECONDS := 4.0

var boar: Fighter = null
var skirmish: Skirmish = null
## Who the boar is coming for. Set by the world.
var quarry: Fighter = null

var _beast: BeastTactics = null
var _charge_dir := Vector3.FORWARD
var _down := 0.0
var _rng := RandomNumberGenerator.new()
## The open side faces the road home, so the way you came in is the way
## you can leave.
@export var open_toward := 0.0


func _ready() -> void:
	_rng.seed = 20260916
	_build_hedge()
	_build_scrub()
	_build_boar()


func _build_hedge() -> void:
	for side in 3:
		var along := FIELD * 2.0
		var n := 26
		for i in n:
			var t := (float(i) / float(n - 1) - 0.5) * along
			var bush := MeshInstance3D.new()
			var bm := BoxMesh.new()
			var w: float = _rng.randf_range(1.9, 2.6)
			var h: float = _rng.randf_range(1.6, 2.3)
			bm.size = Vector3(w, h, 1.4)
			bush.mesh = bm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.13, 0.21, 0.10).lerp(
				Color(0.18, 0.27, 0.12), _rng.randf())
			mat.roughness = 1.0
			bush.material_override = mat
			var body := StaticBody3D.new()
			var col := CollisionShape3D.new()
			var cb := BoxShape3D.new()
			cb.size = bm.size
			col.shape = cb
			body.add_child(col)
			body.add_child(bush)
			match side:
				0: body.position = Vector3(t, h * 0.5, -FIELD)
				1: body.position = Vector3(-FIELD, h * 0.5, t)
				_: body.position = Vector3(FIELD, h * 0.5, t)
			if side > 0:
				body.rotation.y = PI / 2.0
			add_child(body)


func _build_scrub() -> void:
	# Something to break sight-lines on. Nothing to collide with — a
	# field you keep snagging on is a worse field.
	for i in 40:
		var tuft := MeshInstance3D.new()
		var tm := BoxMesh.new()
		var th: float = _rng.randf_range(0.5, 1.2)
		tm.size = Vector3(_rng.randf_range(0.5, 1.1), th, _rng.randf_range(0.5, 1.1))
		tuft.mesh = tm
		var tmat := StandardMaterial3D.new()
		tmat.albedo_color = Color(0.20, 0.25, 0.12).lerp(
			Color(0.32, 0.29, 0.16), _rng.randf())
		tmat.roughness = 1.0
		tuft.material_override = tmat
		tuft.position = Vector3(
			_rng.randf_range(-FIELD + 4.0, FIELD - 4.0), th * 0.5,
			_rng.randf_range(-FIELD + 4.0, FIELD - 4.0))
		tuft.rotation.y = _rng.randf_range(0.0, PI)
		add_child(tuft)


func _build_boar() -> void:
	boar = Fighter.new()
	boar.position = Vector3(-4, 1, -5)
	add_child(boar)
	boar.setup_beast(BOAR_HEALTH, "boar")
	boar.weapon_damage = BOAR_DAMAGE
	_beast = BeastTactics.new(20260916)


## The world hands the region its player and its combat field.
func hunted_by(who: Fighter, field: Skirmish) -> void:
	quarry = who
	skirmish = field
	if field != null and boar != null:
		field.enlist(boar)


func _physics_process(delta: float) -> void:
	if boar == null or not is_instance_valid(boar):
		return
	boar.tick(delta)
	_beast.tick(delta)
	_tick_down(delta)

	if _down > 0.0 or quarry == null or not is_instance_valid(quarry):
		boar.move(Vector3.ZERO, 0.0, delta)
		return

	# A boar minds its own wood. Walk out of it and it does not follow
	# you to Thornfield — which is the whole reason the wood is a place
	# in the world rather than a room you are locked in.
	var to_you: Vector3 = quarry.global_position - boar.global_position
	to_you.y = 0.0
	if quarry.global_position.distance_to(global_position) > FIELD + 12.0:
		boar.move(Vector3.ZERO, 0.0, delta)
		return

	_run(delta, to_you.normalized(), to_you.length())


## The boar's side of the fight. Geometry here, rules in sim/.
##
## The difference from a swordsman is the whole point. A swordsman turns
## to face you every tick, because his telegraph is the wind-up and a
## wind-up aimed elsewhere teaches nothing. A boar aims ONCE, at the
## moment it commits, and then cannot correct — so the heading is
## captured at the start of the run and the body driven along it whatever
## you do next. Stepping aside is the answer, and it only is one because
## of this.
func _run(delta: float, heading: Vector3, distance: float) -> void:
	var was_charging := _beast.is_charging()
	var decision := _beast.decide(distance, boar.stamina, boar.is_busy())

	match decision["intent"]:
		BeastTactics.Intent.CHARGE:
			if not was_charging:
				# Commit. This is the last moment it gets to aim.
				_charge_dir = heading
				boar.rotation.y = atan2(-heading.x, -heading.z)
				_beast.charged(boar.stamina)
				Sound.swing(self, boar.global_position + Vector3(0, 0.7, 0))
			boar.move(_charge_dir, CHARGE_SPEED, delta)
			if distance <= GORE_REACH and not boar.is_busy():
				if boar.try_attack("enemyHeavy"):
					boar.attack.arc = Attack.Arc.LOWER_LEFT
					_beast.spent()

		BeastTactics.Intent.GORE:
			boar.rotation.y = atan2(-heading.x, -heading.z)
			if boar.try_attack("enemyQuick"):
				boar.attack.arc = Attack.Arc.LOWER_RIGHT
				_beast.gored()
			boar.move(Vector3.ZERO, 0.0, delta)

		BeastTactics.Intent.WHEEL:
			# Turning round. Slower than it can run, which is what makes
			# this the window worth taking.
			boar.rotation.y = lerp_angle(
				boar.rotation.y, atan2(-heading.x, -heading.z), 3.0 * delta)
			boar.move(Vector3.ZERO, 0.0, delta)

		BeastTactics.Intent.STALK:
			boar.rotation.y = lerp_angle(
				boar.rotation.y, atan2(-heading.x, -heading.z), 5.0 * delta)
			boar.move(heading, STALK_SPEED, delta)

		_:
			boar.move(Vector3.ZERO, 0.0, delta)


func _tick_down(delta: float) -> void:
	if boar.health.is_dead() and _down <= 0.0:
		_down = RESPAWN_SECONDS
		ContractWorkRules.record_cull(TownState.current(), region_name(), 1)
		TownState.save()
		return
	if _down <= 0.0:
		return
	_down = maxf(0.0, _down - delta)
	if _down > 0.0:
		return
	# Another one comes out of the wood. The Hedges is not a boss room.
	boar.revive()
	boar.global_position = global_position + Vector3(
		_rng.randf_range(-FIELD + 6.0, FIELD - 6.0), 1.0,
		_rng.randf_range(-FIELD + 6.0, FIELD - 6.0))
	_beast = BeastTactics.new(Time.get_ticks_msec())


## Which wood this is, for the contract board.
@export var region := "the Hedges west"


func region_name() -> String:
	return region
