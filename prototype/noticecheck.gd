extends Node
## Does the town notice what you did?

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	TownState.reset()
	var state: TownWorldState = TownState.current()
	var clock := WorldClock.new(0.5)   # noon
	TownState.set_clock(clock)

	print("--- barks answer to the world ---")
	var day_market := BarkBank.lines("market", 0, state, 12.0)
	var night_market := BarkBank.lines("market", 0, state, 2.0)
	_ok("the market has something to say by day", day_market.size() > 0, "silent at noon")
	_ok("and says something different at 2am",
		night_market != day_market, "the same lines at 2am as at noon")
	var packed_down := false
	for l in night_market:
		if l.findn("stalls are down") != -1:
			packed_down = true
	_ok("the stalls are down at night", packed_down,
		"no night line in the 2am pool")
	var stalls_at_noon := false
	for l in day_market:
		if l.findn("stalls are down") != -1:
			stalls_at_noon = true
	_ok("and not at noon", not stalls_at_noon, "the night line leaked into daylight")

	print("--- and to what you did ---")
	var before := BarkBank.lines("farmer", 0, state, 12.0)
	var thanked := false
	for l in before:
		if l.findn("thinning") != -1:
			thanked = true
	_ok("nobody thanks you before you have done anything", not thanked,
		"the crowd is grateful for work that was never done")

	state.culls_completed = 1
	var after := BarkBank.lines("farmer", 0, state, 12.0)
	var now_thanked := false
	for l in after:
		if l.findn("thinning") != -1:
			now_thanked = true
	_ok("and they do once you have", now_thanked,
		"a finished cull went unremarked")
	_ok("the pool actually grew", after.size() > before.size(),
		"%d lines before, %d after" % [before.size(), after.size()])

	print("--- an unknown condition silences a line, it does not pass ---")
	var bad := BarkBank._holds(["not_a_real_condition"], state, 12.0)
	_ok("a typo fails closed", not bad,
		"an unknown condition passed, which would put a lie in somebody's mouth")

	print("--- greetings ---")
	TownState.reset()
	var fresh: TownWorldState = TownState.current()
	TownState.set_clock(clock)
	var t: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(t)
	await get_tree().create_timer(2.5).timeout
	var who: TownNPC = null
	for n in t.get_node("Population").get_children():
		if n is TownNPC and (n as TownNPC).npc_id == "mara":
			who = n
	var stranger := who.greeting()
	TownState.current().culls_completed = 2
	var known := who.greeting()
	_ok("a stranger is greeted as one", stranger.findn("Hedges") == -1,
		"got '%s'" % stranger)
	_ok("and somebody who thinned the Hedges is not",
		known.findn("Hedges") != -1 and known != stranger,
		"got '%s'" % known)
	print("      stranger: %s" % stranger)
	print("      known:    %s" % known)

	# The TOWN's clock, not the one this test made: town.gd registers its
	# own on load and replaces it, which is correct — the town owns its
	# clock — and quietly made an earlier version of this check compare a
	# greeting against an hour nobody was reading.
	TownState.clock().set_fraction(2.0 / 24.0)
	var late := who.greeting()
	_ok("and the hour is noticed", late != known, "same greeting at 2am")
	print("      at 2am:   %s" % late)

	TownState.reset()
	print("")
	print("notice: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
