class_name Rumors
extends RefCounted
## Thornfield's voice on top of the rumour rules.
##
## The RULE — ranking, ageing, what a drink costs — now lives in
## rules/rumour_mill.gd, mirroring sim/Marrowmark.Sim/Town (L88). What
## is left here is how a hedged rumour sounds when somebody says it out
## loud, which is content and belongs with the town.

## How a teller signals they are not vouching for this one. content.md
## §3 wants old rumours to come up *bent* rather than absent — a story
## you cannot quite trust is still a lead.
const HEDGE := " (Or that's how it came to me. Drink bends stories.)"

const NOTHING := {
	"text": "Nothing moving. Quiet as a chapel.",
	"source": "the air",
}


## Free rumour from whoever will talk: freshest first.
static func search(state: TownWorldState) -> Dictionary:
	return _dress(RumourMill.search(state))


## Buying a drink: costs coin, returns the freshest thing Mara's heard.
static func buy_drink(state: TownWorldState) -> Dictionary:
	var r := RumourMill.buy_drink(state)
	if not bool(r["paid"]):
		return {"ok": false}
	# Coin left the purse, so the purse has to be written down.
	Boards._persist()
	var said := _dress(r)
	return {"ok": true, "text": said["text"], "source": said["source"]}


## Time passes: rumours age, distortions creep up.
static func age_all(state: TownWorldState, hours: float) -> void:
	RumourMill.age_all(state, hours)


static func _dress(r: Dictionary) -> Dictionary:
	if not bool(r["found"]):
		return NOTHING.duplicate()
	var out: Dictionary = (r["rumour"] as Dictionary).duplicate()
	if bool(r["hedged"]):
		out["text"] = String(out["text"]) + HEDGE
	return out
