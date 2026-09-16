class_name Reaping
extends Node3D
## Somewhere to do the harvest, at the Vance farm.
##
## The board offered four kinds of work and honoured one: only a cull
## could be finished, because the Hedges was the only place the world
## gave you to do anything in. Escort and smithing are still honest gaps
## — nowhere to walk a wagon to, no forge to stand at — but a field is a
## place, and the farm was already built.
##
## **The verb is the sword.** The player carries one in the town now, so
## reaping is a swing that lands on standing wheat rather than a new
## interaction nobody has been taught. It reads the same three things a
## blow against a fighter reads — is the blade live, does it reach, has
## this swing already spent its hit — so a sheaf costs a real swing and
## the recovery that follows it, and mashing does not go faster than
## the attack it is made of.
##
## Cutting wheat you were not hired for is allowed and is simply not
## progress; that rule lives in `ContractWorkRules.record_harvest`, not
## here. This reports that a sheaf fell. The town decides whether that
## was work.

## Reach past the blade for a stalk at your feet, in metres. Wheat does
## not dodge, so this is generous on purpose — the swing is the cost,
## not the aim.
const STOOP := 0.45

var systems: Dictionary = {}

var _reaper: Fighter = null
var _sheaves: Array[Node3D] = []
## Cut sheaves, in the order they fell, so the field regrows from the
## oldest rather than popping back where you are standing.
var _cut: Array[Node3D] = []
var _regrow := 0.0

## How long a cut sheaf stays down. The field is a place of work rather
## than a resource to strip: come back tomorrow and there is more.
const REGROW_SECONDS := 45.0


func _ready() -> void:
	_build()


func _build() -> void:
	# Tilled ground under the whole strip.
	#
	# The first version stood the sheaves straight on the farm's lawn and
	# the frame said what the numbers could not: twenty-one yellow posts
	# scattered on grass, reading as dropped timber rather than as a crop.
	# A field has to look worked before anything standing in it looks
	# like wheat.
	var soil := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(16.0, 7.0)
	var earth := StandardMaterial3D.new()
	earth.albedo_color = Color(0.42, 0.34, 0.22)
	earth.roughness = 1.0
	plane.material = earth
	soil.mesh = plane
	soil.position = Vector3(0.0, 0.02, 1.6)
	soil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(soil)

	var tints := [Color(0.83, 0.68, 0.33), Color(0.76, 0.60, 0.28),
		Color(0.87, 0.73, 0.38)]
	var i := 0
	# A worked strip rather than a scatter: rows read as something a
	# person is meant to walk down.
	for row in range(3):
		for col in range(7):
			var sheaf := Node3D.new()
			sheaf.position = Vector3(-6.0 + col * 2.0, 0.0, row * 1.6)
			add_child(sheaf)
			# A BUNDLE, not a handful of posts. Many thin stalks held
			# close and splaying outward at the top is what makes a
			# sheaf read as one object from standing height — the first
			# attempt used five thick boxes at a wide spread and read as
			# five separate planks.
			var tall: float = randf_range(0.78, 0.92)
			for blade in range(14):
				var m := MeshInstance3D.new()
				var b := BoxMesh.new()
				b.size = Vector3(0.035, tall, 0.035)
				var mat := StandardMaterial3D.new()
				mat.albedo_color = tints[(i + blade) % 3]
				mat.roughness = 1.0
				b.material = mat
				m.mesh = b
				m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var a: float = randf_range(0.0, TAU)
				var r: float = randf_range(0.0, 0.085)
				m.position = Vector3(cos(a) * r, tall * 0.5, sin(a) * r)
				# Splayed away from the centre, so the top opens out the
				# way a tied sheaf does.
				m.rotation = Vector3(
					sin(a) * r * 2.2, randf_range(0.0, PI), -cos(a) * r * 2.2)
				sheaf.add_child(m)
			_sheaves.append(sheaf)
			i += 1


## Who is swinging here. Set by the town once the walker exists.
func watch(who: Fighter) -> void:
	_reaper = who


func standing() -> int:
	return _sheaves.size()


func _physics_process(delta: float) -> void:
	_tick_regrow(delta)

	# is_instance_valid, not `== null`. A freed node leaves a DANGLING
	# reference in Godot rather than a null one, so when the town is torn
	# down — which a harness does every run — this kept reading a
	# transform off a body that no longer existed. It cost touchcheck a
	# screenful of errors and nothing in the game, which is the kind of
	# fault that lives a long time.
	if not is_instance_valid(_reaper) or _sheaves.is_empty():
		return
	if not _reaper.attack.is_active():
		return

	var facing: Vector3 = -_reaper.global_transform.basis.z
	for sheaf in _sheaves:
		var to_it: Vector3 = sheaf.global_position - _reaper.global_position
		to_it.y = 0.0
		var angle: float = rad_to_deg(facing.signed_angle_to(to_it, Vector3.UP))
		if not _reaper.attack.reaches(to_it.length() - STOOP, angle):
			continue
		# One sheaf per swing, by the same rule that stops one swing
		# hitting two people. Without it a single blade sweeping a row
		# would take the whole row, and the contract would be a walk
		# rather than a day's work.
		if not _reaper.attack.try_consume_hit():
			return
		_fell(sheaf)
		return


func _fell(sheaf: Node3D) -> void:
	sheaf.visible = false
	_sheaves.erase(sheaf)
	_cut.append(sheaf)

	var state: TownWorldState = systems.get("state", null)
	if state != null:
		ContractWorkRules.record_harvest(state, 1)

	Sound.impact(self, sheaf.global_position + Vector3(0, 0.5, 0), "none")


func _tick_regrow(delta: float) -> void:
	if _cut.is_empty():
		return
	_regrow += delta
	if _regrow < REGROW_SECONDS:
		return
	_regrow = 0.0
	var back: Node3D = _cut.pop_front()
	back.visible = true
	_sheaves.append(back)
