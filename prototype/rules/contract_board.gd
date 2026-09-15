class_name ContractBoardRules
extends RefCounted
## GDScript mirror of sim/Marrowmark.Sim/Town/ContractBoard.cs.
##
## L88: sim/ is authoritative and this mirrors it. The C# is the copy
## that is tested and the copy the server will run; this exists only
## because Godot's web export cannot run C#.
##
## Facts only — no prose. What work exists and what it pays is a rule;
## how a Thornfield carter phrases it is content, and lives in
## town_systems/boards.gd. Keeping the line there is what lets a second
## town reuse any of this.

enum Kind { CULL, ESCORT, HARVEST, SMITHING }

static func _p() -> Dictionary:
	return TownTuning.load_section("board")


## Every posting, generated from state that is actually true. Set a boar
## pressure to zero and its contract is simply not on the board
## (content.md §3 — "the board never lies about the world").
static func generate(state: TownWorldState) -> Array:
	var p := _p()
	var out: Array = []

	for region in state.boar_pressure:
		var pressure := int(state.boar_pressure[region])
		if pressure <= 0:
			continue
		var cid := "cull-" + String(region).replace(" ", "-")
		out.append({
			"id": cid,
			"kind": Kind.CULL,
			"subject": String(region),
			"magnitude": pressure,
			"pay": int(p.get("cullBasePay", 4))
				+ pressure * int(p.get("cullPayPerPressure", 3)),
			"taken": state.contracts_taken.has(cid),
		})

	for c in state.caravans:
		if String(c["status"]) != "mustering":
			continue
		var cid2 := "escort-" + String(c["id"])
		out.append({
			"id": cid2,
			"kind": Kind.ESCORT,
			"subject": String(c["dest"]),
			"magnitude": int(c["guards"]),
			"pay": int(p.get("escortBasePay", 10))
				+ int(c["guards"]) * int(p.get("escortPayPerGuard", 4)),
			"taken": state.contracts_taken.has(cid2),
		})

	if state.harvest_demand > 0:
		out.append({
			"id": "harvest",
			"kind": Kind.HARVEST,
			"subject": "",
			"magnitude": state.harvest_demand,
			"pay": int(p.get("harvestPay", 5)),
			"taken": state.contracts_taken.has("harvest"),
		})

	for j in state.smithing_jobs:
		var cid3 := String(j["id"])
		out.append({
			"id": cid3,
			"kind": Kind.SMITHING,
			"subject": String(j.get("work", "")),
			"magnitude": 0,
			"pay": int(j["pay"]),
			"taken": state.contracts_taken.has(cid3),
		})

	return out


## Binding, so the conversation layer confirms first (L49). Refuses
## anything not actually posted: a mistyped id, or a model reaching for
## work that was withdrawn, must not quietly book a job nobody offers.
static func take(state: TownWorldState, contract_id: String) -> bool:
	if state.contracts_taken.has(contract_id):
		return false
	var posted := false
	for c in generate(state):
		if String(c["id"]) == contract_id:
			posted = true
			break
	if not posted:
		return false
	state.contracts_taken.append(contract_id)
	return true


## Only what is actually warehoused here (economy.md §3).
static func market(state: TownWorldState) -> Array:
	var out: Array = []
	for good in state.warehoused:
		var g: Dictionary = state.warehoused[good]
		if int(g["qty"]) <= 0:
			continue
		out.append({
			"good": String(good),
			"qty": int(g["qty"]),
			"price": int(g["price"]),
			"unit": String(g["unit"]),
		})
	return out
