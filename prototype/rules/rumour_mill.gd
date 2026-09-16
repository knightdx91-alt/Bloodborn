class_name RumourMill
extends RefCounted
## GDScript mirror of sim/Marrowmark.Sim/Town/RumourMill.cs.
##
## L88: sim/ is authoritative and this mirrors it.
##
## Rumour as a search interface (content.md §3) — buying a drink runs the
## query. Freshest first, with bent rumours pushed down, so a fresh lie
## still loses to a slightly older truth.

static func _p() -> Dictionary:
	return TownTuning.load_section("rumour")


## { found, rumour, hedged, paid }
static func search(state: TownWorldState) -> Dictionary:
	var p := _p()
	var best: Variant = null
	var best_score := -INF

	for r in state.rumors:
		var score: float = float(p.get("freshnessWeight", 100.0)) / (1.0 + float(r["age"])) \
			- float(r["distortion"]) * float(p.get("distortionPenalty", 10.0))
		if score > best_score:
			best_score = score
			best = r

	if best == null:
		return {"found": false, "rumour": null, "hedged": false, "paid": true}

	return {
		"found": true,
		"rumour": best,
		"hedged": float(best["distortion"]) >= float(p.get("hedgeAbove", 0.5)),
		"paid": true,
	}


## Spends coin, so it is binding and the conversation layer confirms
## first (L49).
## What a drink costs. Exposed because L92 makes the conversation ask
## before it offers, rather than offering and then refusing.
static func drink_price() -> int:
	return int(_p().get("drinkPrice", 2))


static func buy_drink(state: TownWorldState) -> Dictionary:
	var price := drink_price()
	if state.coin < price:
		return {"found": false, "rumour": null, "hedged": false, "paid": false}
	state.coin -= price
	return search(state)


## Time passes; stories bend. Capped below 1 on purpose — a rumour that
## is pure noise is not a rumour, it is a lie, and the teller would know.
static func age_all(state: TownWorldState, hours: float) -> void:
	if hours <= 0.0:
		return
	var p := _p()
	var ceiling := float(p.get("maxDistortion", 0.9))
	var creep := float(p.get("distortionPerHour", 0.002))
	for r in state.rumors:
		r["age"] = float(r["age"]) + hours
		r["distortion"] = minf(ceiling, float(r["distortion"]) + hours * creep)
