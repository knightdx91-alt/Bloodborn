extends Node
## Does the spike stand up?
##
## genworld.tscn is the one scene in the project a harness had never
## touched, which is backwards: it is the scene the person evaluating
## this actually runs, on a phone, where nothing can be checked
## afterwards. Everything else was covered and the thing being judged
## was not.
##
## It does not measure frame rate. That is the spike's whole question
## and it cannot be answered in a container — this only asks whether
## what arrives on the phone is a working instrument rather than a
## black screen.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	var spike: Node3D = load("res://genworld.tscn").instantiate() as Node3D
	add_child(spike)
	# Long enough for the opening block to build and the body to settle.
	await get_tree().create_timer(6.0).timeout

	var gen = spike.get("gen")
	var walker = spike.get("walker")
	_ok("the spike builds a world", gen != null, "no WorldGen")
	_ok("and puts somebody in it", walker != null, "no walker")
	if gen == null or walker == null:
		_finish()
		return

	_ok("and some of it is resident", gen.live.size() > 0,
		"no chunks built at all")
	print("      %d chunks, %d built" % [gen.live.size(), gen.built_total])

	# THE ONE THAT MATTERS ON A PHONE: does the player end up standing
	# on the world rather than under it?
	#
	# What this does NOT prove, said because it was mutation-tested
	# and found not to: that `genworld`'s explicit build-before-spawn
	# is what achieves it. Deleting that call leaves this check green,
	# because WorldGen's nearest-first queue builds the chunk underfoot
	# on the next frame either way. This asserts the OUTCOME, which is
	# the thing worth asserting; the mechanism is the queue's, and
	# genworld.gd now says so rather than taking the credit.
	var p: Vector3 = walker.global_position
	var ground: float = gen.height_at(p.x, p.z)
	_ok("and they are standing on it, not falling through it",
		p.y > ground - 1.0 and p.y < ground + 4.0,
		"walker at y=%.1f, ground at %.1f" % [p.y, ground])
	print("      walker y=%.2f, ground y=%.2f" % [p.y, ground])

	# It opens at Thornfield, in Thornfield's country.
	var here = gen.terrain.biome_at(p.x, p.z)
	_ok("the spike opens in the starting town's country",
		String(here.town) == "Thornfield",
		"opened in %s, which is %s's" % [str(here.name), str(here.town)])

	# Jump has somewhere to go, and it is the Wheel.
	var stops: Array = spike.get("_stops")
	_ok("Jump has places to go", stops.size() >= 10,
		"only %d stops" % stops.size())
	var towns := 0
	for stop in stops:
		if String(stop["what"]).contains("—"):
			towns += 1
	_ok("and the six towns and the capitol are among them", towns >= 7,
		"only %d named places in the Jump list" % towns)

	# And jumping actually moves you somewhere built.
	if stops.size() > 1:
		var before: Vector3 = walker.global_position
		spike.call("_next_stop")
		await get_tree().create_timer(1.5).timeout
		var after: Vector3 = walker.global_position
		_ok("and jumping moves you", before.distance_to(after) > 100.0,
			"Jump moved the walker %.0f m" % before.distance_to(after))
		var g2: float = gen.height_at(after.x, after.z)
		_ok("and lands you on ground that exists",
			after.y > g2 - 1.0 and after.y < g2 + 4.0,
			"landed at y=%.1f with ground at %.1f — arriving in free fall"
				% [after.y, g2])

	_finish()


func _finish() -> void:
	print("")
	print("spike: all clear" if _fails.is_empty()
		else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
