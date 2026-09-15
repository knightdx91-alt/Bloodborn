class_name Rumors
extends RefCounted
## Rumor as search interface (content.md §3): buying Mara a drink is how
## you search. Rumors carry source + age + distortion. Fresh rumors come
## up first; old ones come up bent.

const DRINK_PRICE := 2


## Free rumor from whoever will talk: freshest first.
static func search(state: TownWorldState) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -1.0
	for r in state.rumors:
		var age := float(r["age"])
		var score := 100.0 / (1.0 + age) - float(r["distortion"]) * 10.0
		if score > best_score:
			best_score = score
			best = r
	if best.is_empty():
		return {"text": "Nothing moving. Quiet as a chapel.", "source": "the air"}
	var out := best.duplicate()
	if float(best["distortion"]) >= 0.5:
		out["text"] = String(best["text"]) + " (Or that's how it came to me. Drink bends stories.)"
	return out


## Buying a drink: costs coin, returns the freshest rumor Mara's heard.
static func buy_drink(state: TownWorldState) -> Dictionary:
	if state.coin < DRINK_PRICE:
		return {"ok": false}
	state.coin -= DRINK_PRICE
	var r := search(state)
	return {"ok": true, "text": r["text"], "source": r["source"]}


## Time passes: rumors age, distortions creep up. Cheap epoch pressure.
static func age_all(state: TownWorldState, hours: float) -> void:
	for r in state.rumors:
		r["age"] = float(r["age"]) + hours
		r["distortion"] = minf(0.9, float(r["distortion"]) + hours * 0.002)
