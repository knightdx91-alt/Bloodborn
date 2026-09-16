extends Node
## Is anything moving when nothing is happening?

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	TownState.reset()
	var t: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(t)
	await get_tree().create_timer(3.0).timeout

	var smokes: Array = t.get("_smokes")
	var forge: OmniLight3D = t.get("_forge")
	var birds: Node3D = t.get("_birds")

	_ok("chimneys smoke", smokes.size() >= 4,
		"only %d emitters — no chimney positions were recorded" % smokes.size())
	_ok("and they are emitting",
		smokes.size() > 0 and (smokes[0] as CPUParticles3D).emitting, "not emitting")
	_ok("the forge glows", forge != null and forge.light_energy > 0.0, "no forge light")
	_ok("there are birds", birds != null and birds.get_child_count() == 3,
		"no flock")

	var clock: WorldClock = TownState.clock()

	# Noon: thin smoke, dim forge.
	clock.set_fraction(12.0 / 24.0)
	Atmosphere.set_time(smokes, forge, birds, clock)
	await get_tree().process_frame
	var noon_smoke: float = ((smokes[0] as CPUParticles3D).material_override as StandardMaterial3D).albedo_color.a
	var noon_forge: float = forge.light_energy

	# Midnight: thicker smoke, brighter forge.
	clock.set_fraction(0.0)
	Atmosphere.set_time(smokes, forge, birds, clock)
	await get_tree().process_frame
	var night_smoke: float = ((smokes[0] as CPUParticles3D).material_override as StandardMaterial3D).albedo_color.a
	var night_forge: float = forge.light_energy

	_ok("smoke thickens after dark", night_smoke > noon_smoke,
		"%.3f at noon, %.3f at midnight" % [noon_smoke, night_smoke])
	_ok("and the forge burns brighter", night_forge > noon_forge,
		"%.2f at noon, %.2f at midnight" % [noon_forge, night_forge])
	_ok("and the forge is never off", night_forge > 0.0 and noon_forge > 0.0,
		"a banked forge still glows, and L20 wants a source for every light")
	print("      smoke %.3f -> %.3f, forge %.2f -> %.2f"
		% [noon_smoke, night_smoke, noon_forge, night_forge])

	# Birds are a dawn and dusk thing.
	clock.set_fraction(12.0 / 24.0)
	Atmosphere.set_time(smokes, forge, birds, clock)
	var at_noon: bool = birds.visible
	clock.set_fraction(18.0 / 24.0)
	Atmosphere.set_time(smokes, forge, birds, clock)
	var at_dusk: bool = birds.visible
	_ok("birds are out at dusk and not at noon", at_dusk and not at_noon,
		"noon=%s dusk=%s" % [str(at_noon), str(at_dusk)])
	_ok("and not at midnight either", not Atmosphere.flying_hour(0.5),
		"a flock at midnight")
	_ok("and out at dawn", Atmosphere.flying_hour(6.0), "nothing at dawn")

	# And they actually fly.
	var was: Vector3 = (birds.get_child(0) as Node3D).position
	Atmosphere.fly(birds, 40.0)
	var now: Vector3 = (birds.get_child(0) as Node3D).position
	_ok("and they move", was.distance_to(now) > 1.0,
		"the flock is nailed to the sky")

	TownState.reset()
	print("")
	print("atmosphere: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
