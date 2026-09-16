extends Node
## Can a second kind of work actually be finished?
##
## Until now the board offered four kinds of job and honoured one. A cull
## could be taken, done and paid; escort, smithing and harvest refused
## honestly because the world gave you nowhere to do them. The farm was
## already built, so the harvest is the one that could stop refusing.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _town() -> TownWorldState:
	var s := TownWorldState.new()
	s.harvest_demand = 4
	return s


func _ready() -> void:
	# --- the rule ---------------------------------------------------------
	var s := _town()
	_ok("a harvest can be progressed at all",
		ContractWorkRules.required(s, "harvest") > 0,
		"it still refuses, so the board still honours one kind of work")

	var quiet := _town()
	quiet.harvest_demand = 1
	var busy := _town()
	busy.harvest_demand = 9
	_ok("and a day's work does not grow with the hands wanted",
		ContractWorkRules.required(quiet, "harvest")
			== ContractWorkRules.required(busy, "harvest"),
		"%d vs %d — magnitude is how many PEOPLE the farm wants, and "
			% [ContractWorkRules.required(quiet, "harvest"),
			ContractWorkRules.required(busy, "harvest")]
		+ "turning up does not make the field bigger")

	s = _town()
	_ok("cutting wheat you were not hired for is not progress",
		ContractWorkRules.record_harvest(s, 5) == 0
			and s.contract_progress.is_empty(),
		"progress is %s" % str(s.contract_progress))

	s = _town()
	s.contracts_taken.append("harvest")
	ContractWorkRules.record_harvest(s, 3)
	_ok("sheaves count once you are hired",
		ContractWorkRules.done(s, "harvest") == 3,
		"%d counted" % ContractWorkRules.done(s, "harvest"))

	var want: int = ContractWorkRules.required(s, "harvest")
	ContractWorkRules.record_harvest(s, want + 40)
	_ok("and stop at what was asked for",
		ContractWorkRules.done(s, "harvest") == want,
		"%d banked against a want of %d"
			% [ContractWorkRules.done(s, "harvest"), want])

	var coin_before: int = s.coin
	var r: Dictionary = ContractWorkRules.hand_in(s, "harvest")
	_ok("a finished harvest pays and returns the paper",
		int(r["result"]) == ContractWorkRules.HandInResult.PAID
			and s.coin > coin_before
			and not s.contracts_taken.has("harvest"),
		"result %d, coin %d -> %d" % [int(r["result"]), coin_before, s.coin])
	_ok("and the farm wants one pair of hands fewer",
		s.harvest_demand == 3 and int(r["demand_after"]) == 3,
		"demand is %d" % s.harvest_demand)

	s = _town()
	s.harvest_demand = 1
	s.contracts_taken.append("harvest")
	ContractWorkRules.record_harvest(s, 999)
	ContractWorkRules.hand_in(s, "harvest")
	var posted := false
	for c in ContractBoardRules.generate(s):
		if String(c["id"]) == "harvest":
			posted = true
	_ok("a farm with hands enough stops asking",
		s.harvest_demand == 0 and not posted,
		"demand %d, still posted: %s" % [s.harvest_demand, str(posted)])

	# The two kinds must not feed each other.
	s = _town()
	s.contracts_taken.append("harvest")
	s.contracts_taken.append("cull-the-Hedges-west")
	ContractWorkRules.record_harvest(s, 2)
	_ok("cutting wheat is not culling boars",
		ContractWorkRules.done(s, "cull-the-Hedges-west") == 0,
		"the cull advanced on a harvest")
	ContractWorkRules.record_cull(s, "the Hedges west", 2)
	_ok("and killing boars is not cutting wheat",
		ContractWorkRules.done(s, "harvest") == 2,
		"the harvest advanced on a cull")

	# --- and the place --------------------------------------------------
	TownState.reset()
	TownState.current().harvest_demand = 4
	TownState.current().contracts_taken.append("harvest")
	var t: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(t)
	await get_tree().create_timer(2.5).timeout

	var field := t.find_child("Reaping", true, false) as Reaping
	_ok("there is standing wheat at the Vance farm", field != null,
		"no Reaping in the town")
	if field == null:
		_finish()
		return
	_ok("and enough of it to be a day's work",
		field.standing() >= ContractWorkRules.required(TownState.current(), "harvest"),
		"%d sheaves for a want of %d" % [field.standing(),
			ContractWorkRules.required(TownState.current(), "harvest")])

	var walker: TownWalker = null
	for n in t.get_children():
		if n is TownWalker:
			walker = n
	# Stand in the field and swing. THE VERB IS THE SWORD: reaping is the
	# combat the town gained today, not a new interaction nobody has been
	# taught.
	walker.global_position = field.global_position + Vector3(0, 1.0, 1.2)
	walker.look_at(field.global_position + Vector3(0, 1.0, 0), Vector3.UP)
	for f in 5:
		await get_tree().physics_frame

	var standing_before: int = field.standing()
	var done_before: int = ContractWorkRules.done(TownState.current(), "harvest")
	var swings := 0

	# Stand still first: one swing takes ONE sheaf, not the row it sweeps
	# through. Without this a single blade would finish the contract.
	walker.try_attack()
	for f in 60:
		await get_tree().physics_frame
	swings += 1
	_ok("one swing takes one sheaf",
		standing_before - field.standing() == 1,
		"%d fell from a single swing" % (standing_before - field.standing()))

	# Then work down the rows, which is what the spacing asks of a
	# player: the sheaves are further apart than a sword is long, so a
	# day's work is walking as well as swinging.
	var want_all: int = ContractWorkRules.required(TownState.current(), "harvest")
	while ContractWorkRules.done(TownState.current(), "harvest") < want_all \
			and swings < 40 and field.standing() > 0:
		var nearest: Node3D = null
		var best := 1e9
		for sh in field.get_children():
			if not (sh is Node3D) or not (sh as Node3D).visible:
				continue
			var d: float = walker.global_position.distance_to((sh as Node3D).global_position)
			if d < best:
				best = d
				nearest = sh as Node3D
		if nearest == null:
			break
		walker.global_position = nearest.global_position + Vector3(0, 1.0, 1.0)
		walker.look_at(nearest.global_position + Vector3(0, 1.0, 0), Vector3.UP)
		for f in 3:
			await get_tree().physics_frame
		walker.try_attack()
		for f in 45:
			await get_tree().physics_frame
		swings += 1

	var cut: int = ContractWorkRules.done(TownState.current(), "harvest") - done_before
	print("      %d sheaves cut in %d swings, %d counted as work"
		% [standing_before - field.standing(), swings, cut])
	_ok("and the town counts them as work", cut > 0,
		"the wheat fell and nobody was paid for it")
	_ok("a day's work can actually be FINISHED in the world",
		ContractWorkRules.can_hand_in(TownState.current(), "harvest"),
		"%d of %d after %d swings — the contract cannot be completed by "
			% [ContractWorkRules.done(TownState.current(), "harvest"),
			want_all, swings]
		+ "playing the game, only by calling the rule directly")
	_ok("and it took a swing per sheaf rather than one sweep",
		swings >= want_all,
		"%d swings for %d sheaves" % [swings, want_all])

	_finish()


func _finish() -> void:
	TownState.reset()
	print("")
	print("harvest: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
