extends Node
## Does the GDScript mirror behave like the C# it mirrors?
##
## The 12 xUnit tests in ContractWorkTests.cs are the specification. These
## are the same scenarios run against the mirror, because L88's split is
## only worth having if the two halves agree — a mirror that drifts is
## worse than no mirror, since the tested copy says everything is fine.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _town() -> TownWorldState:
	var s := TownWorldState.new()
	s.boar_pressure = {"the Hedges west": 3, "the north road": 1}
	s.caravans = [{"id": "velmark-1", "dest": "Vellmark",
		"status": "mustering", "guards": 2}]
	s.smithing_jobs = []
	s.harvest_demand = 0
	s.coin = 12
	return s


const WEST := "cull-the-Hedges-west"
const ROAD := "cull-the-north-road"


func _ready() -> void:
	# Required scales with the problem.
	var s := _town()
	var west := {}
	var road := {}
	for c in ContractBoardRules.generate(s):
		if String(c["id"]) == WEST: west = c
		elif String(c["id"]) == ROAD: road = c
	_ok("a cull wants work in proportion to the problem",
		ContractWorkRules.required_for(west) > ContractWorkRules.required_for(road),
		"west %d vs road %d" % [ContractWorkRules.required_for(west),
			ContractWorkRules.required_for(road)])

	# Unpaid kills are not progress.
	s = _town()
	_ok("killing boars you were not paid for is not progress",
		ContractWorkRules.record_cull(s, "the Hedges west", 5) == 0
			and s.contract_progress.is_empty(),
		"progress is %s" % str(s.contract_progress))

	# Progress caps.
	s = _town()
	ContractBoardRules.take(s, WEST)
	var want := ContractWorkRules.required(s, WEST)
	ContractWorkRules.record_cull(s, "the Hedges west", want + 10)
	_ok("progress is capped at what was asked for",
		ContractWorkRules.done(s, WEST) == want,
		"done %d, wanted %d" % [ContractWorkRules.done(s, WEST), want])

	# Unfinished pays nothing.
	s = _town()
	ContractBoardRules.take(s, WEST)
	ContractWorkRules.record_cull(s, "the Hedges west", 1)
	var coin_before: int = s.coin
	var r := ContractWorkRules.hand_in(s, WEST)
	_ok("an unfinished contract pays nothing",
		int(r["result"]) == ContractWorkRules.HandInResult.NOT_FINISHED
			and s.coin == coin_before and s.contracts_taken.has(WEST),
		"result %d, coin %d" % [int(r["result"]), s.coin])

	# Never taken.
	s = _town()
	_ok("work you never took cannot be handed in",
		int(ContractWorkRules.hand_in(s, WEST)["result"])
			== ContractWorkRules.HandInResult.NOT_TAKEN, "wrong result")

	# Escort refuses honestly.
	s = _town()
	ContractBoardRules.take(s, "escort-velmark-1")
	coin_before = s.coin
	r = ContractWorkRules.hand_in(s, "escort-velmark-1")
	_ok("an escort refuses honestly rather than paying for nothing",
		int(r["result"]) == ContractWorkRules.HandInResult.NOT_YET_POSSIBLE
			and s.coin == coin_before,
		"result %d, coin %d" % [int(r["result"]), s.coin])

	# Paid, paper returned.
	s = _town()
	var pay := 0
	for c in ContractBoardRules.generate(s):
		if String(c["id"]) == WEST: pay = int(c["pay"])
	ContractBoardRules.take(s, WEST)
	ContractWorkRules.record_cull(s, "the Hedges west", ContractWorkRules.required(s, WEST))
	coin_before = s.coin
	r = ContractWorkRules.hand_in(s, WEST)
	_ok("finishing a cull pays and returns the paper",
		int(r["result"]) == ContractWorkRules.HandInResult.PAID
			and int(r["paid"]) == pay and s.coin == coin_before + pay
			and not s.contracts_taken.has(WEST)
			and not s.contract_progress.has(WEST),
		"result %d paid %d coin %d" % [int(r["result"]), int(r["paid"]), s.coin])
	_ok("finishing a cull thins the boars",
		int(r["pressure_after"]) == 2 and int(s.boar_pressure["the Hedges west"]) == 2,
		"pressure after %d" % int(r["pressure_after"]))

	# Smaller and cheaper next time.
	var after := {}
	for c in ContractBoardRules.generate(s):
		if String(c["id"]) == WEST: after = c
	_ok("the next posting for that wood is smaller and pays less",
		not after.is_empty() and not bool(after["taken"]) and int(after["pay"]) < pay,
		"pay was %d, now %s" % [pay, str(after.get("pay", "gone"))])

	# A quiet wood leaves the board.
	s = _town()
	ContractBoardRules.take(s, ROAD)
	ContractWorkRules.record_cull(s, "the north road", 99)
	r = ContractWorkRules.hand_in(s, ROAD)
	var still_posted := false
	for c in ContractBoardRules.generate(s):
		if String(c["id"]) == ROAD: still_posted = true
	_ok("culling a wood quiet takes it off the board entirely",
		int(r["result"]) == ContractWorkRules.HandInResult.PAID
			and int(r["pressure_after"]) == 0 and not still_posted,
		"pressure %d, posted %s" % [int(r["pressure_after"]), str(still_posted)])

	# And comes back with the boars.
	s.boar_pressure["the north road"] = 2
	var again := {}
	for c in ContractBoardRules.generate(s):
		if String(c["id"]) == ROAD: again = c
	_ok("a quiet wood can be worked again when the boars return",
		not again.is_empty() and not bool(again["taken"])
			and ContractWorkRules.done(s, ROAD) == 0,
		"contract is %s" % str(again))

	# Independent progress.
	s = _town()
	ContractBoardRules.take(s, WEST)
	ContractBoardRules.take(s, ROAD)
	ContractWorkRules.record_cull(s, "the north road", 1)
	_ok("two contracts are progressed independently",
		ContractWorkRules.done(s, WEST) == 0 and ContractWorkRules.done(s, ROAD) == 1,
		"west %d road %d" % [ContractWorkRules.done(s, WEST),
			ContractWorkRules.done(s, ROAD)])

	# --- Giving the paper back -------------------------------------------
	#
	# Taking work used to be a one-way door: a contract taken by mistake
	# stayed on your name for good. These are about the door opening both
	# ways WITHOUT abandoning becoming a free pause on a job you are
	# losing.
	s = _town()
	s.contracts_taken.append(WEST)
	ContractWorkRules.record_cull(s, "the Hedges west", 3)
	var before_coin: int = s.coin
	var before_pressure: int = int(s.boar_pressure["the Hedges west"])
	var give: Dictionary = ContractWorkRules.abandon(s, WEST)

	_ok("a taken contract can be given back",
		int(give["result"]) == ContractWorkRules.AbandonResult.RELEASED
			and not s.contracts_taken.has(WEST),
		"result %d, still taken: %s"
			% [int(give["result"]), str(s.contracts_taken.has(WEST))])
	_ok("and it says what the work cost", int(give["forfeited"]) == 3,
		"reported %d forfeited, 3 were done" % int(give["forfeited"]))
	_ok("the work goes back with the paper",
		ContractWorkRules.done(s, WEST) == 0,
		"%d still banked — abandoning would be a free pause"
			% ContractWorkRules.done(s, WEST))
	_ok("no coin changes hands", s.coin == before_coin,
		"%d -> %d" % [before_coin, s.coin])
	_ok("and the boars are not thinned by giving up",
		int(s.boar_pressure["the Hedges west"]) == before_pressure
			and s.culls_completed == 0,
		"pressure %d -> %d, culls %d" % [before_pressure,
			int(s.boar_pressure["the Hedges west"]), s.culls_completed])
	_ok("but the town counts it", s.contracts_abandoned == 1,
		"counted %d" % s.contracts_abandoned)

	# Retaking starts from nothing.
	s.contracts_taken.append(WEST)
	_ok("retaking it starts again", ContractWorkRules.done(s, WEST) == 0,
		"%d carried over" % ContractWorkRules.done(s, WEST))

	# One you never took.
	s = _town()
	_ok("one you never took cannot be given back",
		int(ContractWorkRules.abandon(s, WEST)["result"])
			== ContractWorkRules.AbandonResult.NOT_TAKEN
			and s.contracts_abandoned == 0,
		"it let go of a paper it never held")

	# A withdrawn posting you still hold.
	s = _town()
	s.contracts_taken.append("cull-nowhere-at-all")
	_ok("a paper for a withdrawn posting can still be dropped",
		int(ContractWorkRules.abandon(s, "cull-nowhere-at-all")["result"])
			== ContractWorkRules.AbandonResult.RELEASED,
		"refusing to let go of work nobody is offering is the same dead "
		+ "end in a smaller room")

	# And the town has something to say about it.
	s = _town()
	var said_before := BarkBank.lines("farmer", 0, s, 12.0)
	s.contracts_abandoned = 1
	var said_after := BarkBank.lines("farmer", 0, s, 12.0)
	_ok("and the town has something new to say once you have",
		said_after.size() > said_before.size(),
		"%d lines before, %d after — nothing in the town noticed"
			% [said_before.size(), said_after.size()])

	print("")
	print("contract work: all clear" if _fails.is_empty()
		else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
