class_name ContractWorkRules
extends RefCounted
## GDScript mirror of sim/Marrowmark.Sim/Town/ContractWork.cs.
##
## L88: sim/ is authoritative and this mirrors it. The C# is the copy
## that is tested (12 tests) and the copy the server will run; this
## exists only because Godot's web export cannot run C#.
##
## Doing the work, and being paid for it — the half of the board that
## did not exist. **Finishing a cull changes the world, and the world is
## what the board is generated from**: thin the boars and the region's
## pressure drops, so the next posting for that wood is smaller and pays
## less, and at zero it is not posted at all. Nothing announces it. The
## board says something different because something different is true.

enum HandInResult {
	PAID,
	NOT_TAKEN,
	NOT_FINISHED,
	NO_SUCH_CONTRACT,
	## Taken, but this KIND of work has nowhere to be done yet. An
	## honest refusal beats a contract that pays for nothing.
	NOT_YET_POSSIBLE,
}

enum AbandonResult { RELEASED, NOT_TAKEN }


static func _p() -> Dictionary:
	return TownTuning.load_section("board")


## How much work a contract wants. Zero means this kind cannot yet be
## progressed at all.
static func required_for(contract: Dictionary) -> int:
	if int(contract.get("kind", -1)) != ContractBoardRules.Kind.CULL:
		return 0
	var per := int(_p().get("cullKillsPerPressure", 1))
	return maxi(1, int(contract.get("magnitude", 1)) * per)


static func required(state: TownWorldState, contract_id: String) -> int:
	for c in ContractBoardRules.generate(state):
		if String(c["id"]) == contract_id:
			return required_for(c)
	return 0


static func done(state: TownWorldState, contract_id: String) -> int:
	return int(state.contract_progress.get(contract_id, 0))


## Record boars killed in a named region, against whichever cull the
## player is actually carrying for it.
##
## Keyed on the REGION rather than a contract id because that is what the
## world can report: something died in a place. The town works out
## whether that was work.
static func record_cull(state: TownWorldState, region: String, killed: int) -> int:
	if killed <= 0:
		return 0
	for c in ContractBoardRules.generate(state):
		if int(c["kind"]) != ContractBoardRules.Kind.CULL:
			continue
		if String(c.get("subject", "")) != region or not bool(c.get("taken", false)):
			continue
		var id := String(c["id"])
		var want := required_for(c)
		# Capped, so a long hunt does not bank credit against the NEXT
		# contract for the same wood.
		state.contract_progress[id] = mini(want, done(state, id) + killed)
		return int(state.contract_progress[id])
	# Killing boars nobody paid you for is allowed. It is not progress.
	return 0


static func can_hand_in(state: TownWorldState, contract_id: String) -> bool:
	if not state.contracts_taken.has(contract_id):
		return false
	var want := required(state, contract_id)
	return want > 0 and done(state, contract_id) >= want


## Returns {"result": HandInResult, "paid": int, "pressure_after": int}.
## pressure_after is -1 where the contract had no such consequence.
static func hand_in(state: TownWorldState, contract_id: String) -> Dictionary:
	if not state.contracts_taken.has(contract_id):
		return {"result": HandInResult.NOT_TAKEN, "paid": 0, "pressure_after": -1}

	var contract := {}
	for c in ContractBoardRules.generate(state):
		if String(c["id"]) == contract_id:
			contract = c
	if contract.is_empty():
		return {"result": HandInResult.NO_SUCH_CONTRACT, "paid": 0, "pressure_after": -1}

	var want := required_for(contract)
	if want <= 0:
		return {"result": HandInResult.NOT_YET_POSSIBLE, "paid": 0, "pressure_after": -1}
	if done(state, contract_id) < want:
		return {"result": HandInResult.NOT_FINISHED, "paid": 0, "pressure_after": -1}

	var pay := int(contract.get("pay", 0))
	state.coin += pay
	# The paper goes back. Whether it is posted again is decided by the
	# consequence below, not by this line — the board is generated from
	# the world, not from a list of postings.
	state.contracts_taken.erase(contract_id)
	state.contract_progress.erase(contract_id)

	var after := -1
	if int(contract["kind"]) == ContractBoardRules.Kind.CULL:
		state.culls_completed += 1
		var region := String(contract.get("subject", ""))
		if state.boar_pressure.has(region):
			var relief := int(_p().get("cullPressureRelief", 1))
			state.boar_pressure[region] = maxi(0, int(state.boar_pressure[region]) - relief)
			after = int(state.boar_pressure[region])

	return {"result": HandInResult.PAID, "paid": pay, "pressure_after": after}


## Give the paper back, unfinished. Returns { result, forfeited }.
##
## Taking work was a one-way door: a contract taken by mistake — or one
## whose wood turned out to be further than it looked — stayed on your
## name for good. That is not difficulty, it is a dead end, and the fix
## is not to make abandoning free but to make it POSSIBLE and REMEMBERED.
##
## The progress goes with it. Whatever was killed toward this contract is
## not banked for a later attempt, because the paper you hand back is the
## paper the work was done against. Retaking it starts again, which is
## what stops abandoning being a way to pause a job you are losing.
##
## No coin changes hands. The cost is that the town watched, and
## `contracts_abandoned` is what it remembers by.
##
## Deliberately does NOT check the posting still exists: if the board
## withdrew it while you held it, you can still stop holding it. Refusing
## to let go of work nobody is offering is the same dead end in a smaller
## room.
static func abandon(state: TownWorldState, contract_id: String) -> Dictionary:
	if state == null or not state.contracts_taken.has(contract_id):
		return {"result": AbandonResult.NOT_TAKEN, "forfeited": 0}

	var forfeited := done(state, contract_id)
	state.contracts_taken.erase(contract_id)
	state.contract_progress.erase(contract_id)
	state.contracts_abandoned += 1
	return {"result": AbandonResult.RELEASED, "forfeited": forfeited}
