class_name BarkBank
extends RefCounted
## Authored bark lines for Thornfield's crowd — the ~95% of NPC speech
## volume that brainstorm.md §9.1 gives NO MODEL AT ALL, because 3,000
## concurrent players at one turn per 90s is ~33 inferences a second
## forever, on a game with no subscription (L27).
## Epoch-filtered: each line carries the epoch range where it
## is true. Epoch 0 is the first harvest; epoch-1 lines exist to prove
## the filter, not because the prototype advances epochs.

## **A bark answers to the world, the same way a topic does (L92).**
##
## A line may carry `when`: a list of named conditions, all of which must
## hold for it to be in the pool. A crowd that says "boars in the west
## Hedges again" after you spent a morning clearing them is a crowd that
## was not listening, and it undoes the work the board does silently.
##
## The conditions are deliberately few and named rather than arbitrary
## expressions. Content should be able to reach for "night" without
## being able to reach for anything at all.
const CONDITIONS := ["day", "night", "boars_pressing", "boars_quiet",
	"work_done", "you_took_work", "you_are_hired", "you_gave_work_back"]


## role -> Array of {text, e0, e1, when}
const LINES := {
	"market": [
		{"text": "Heard you put a paper back. No shame in it — knowing what you can't carry is worth learning early.",
			"e0": 0, "e1": 99, "when": ["you_gave_work_back"]},
		{"text": "Stalls are down. Come back when it's light and I'll not overcharge you. Much.",
			"e0": 0, "e1": 99, "when": ["night"]},
		{"text": "Road's safer than it was. That's worth something to a man with a cart.",
			"e0": 0, "e1": 99, "when": ["work_done"]},
		{"text": "Grain's two pennies the stone and that's fair, whatever Fenwick's face says.", "e0": 0, "e1": 99},
		{"text": "Cloth up again. Thornfield feeds the looms and the looms know it.", "e0": 0, "e1": 99},
		{"text": "You want ale, Tammas is your man. You want the price, ask Fenwick twice.", "e0": 0, "e1": 99},
		{"text": "Fair day's next week. Mara's already watering the ale — don't tell her I said.", "e0": 0, "e1": 99},
		{"text": "Rain before noon and the road to Greywater turns to soup. Buy your grain today.", "e0": 0, "e1": 99},
	],
	"farmer": [
		{"text": "Somebody took the west paper and brought it back. Hedge doesn't care who tries, only who finishes.",
			"e0": 0, "e1": 99, "when": ["you_gave_work_back"]},
		{"text": "Somebody's been thinning the west Hedges. First quiet week we've had.",
			"e0": 0, "e1": 99, "when": ["work_done"]},
		{"text": "Whoever took that cull paper earned it. The far field's still standing.",
			"e0": 0, "e1": 99, "when": ["work_done", "day"]},
		{"text": "Gate's barred and I'm not opening it. Boars don't knock.",
			"e0": 0, "e1": 99, "when": ["night", "boars_pressing"]},
		{"text": "Wheat's coming in heavy. My back knows it before the scales do.", "e0": 0, "e1": 99},
		{"text": "Boars in the west Hedges again. We cull or we lose the far field — there's no third way.", "e0": 0, "e1": 99},
		{"text": "Scarecrow's doing his best. The crows respect him. The boars don't.", "e0": 0, "e1": 99},
		{"text": "Vance is hiring hands for harvest. Coin's honest and the beer's honest.", "e0": 0, "e1": 99},
		{"text": "They say the Hollow Sow broke these hedges in my gran's time. Hedges grew back. So did the sows.", "e0": 0, "e1": 99},
	],
	"child": [
		{"text": "Bet you can't run to the granaries and back before the bell!", "e0": 0, "e1": 99},
		{"text": "The burnt mill's haunted. My brother heard the wheel. He's a liar but still.", "e0": 0, "e1": 99},
		{"text": "Mara gives me the foam off the ale. Don't tell my mam.", "e0": 0, "e1": 99},
		{"text": "When I'm grown I'm driving a wagon to Vellmark. Horses and everything.", "e0": 0, "e1": 99},
	],
	"warden": [
		{"text": "You gave one back. Better that than us finding you in the wood a week later.",
			"e0": 0, "e1": 99, "when": ["you_gave_work_back"]},
		{"text": "Hedge holds. Walk it twice a day and it keeps holding.", "e0": 0, "e1": 99},
		{"text": "North road's clear to the mill. Past that, keep your eyes up.", "e0": 0, "e1": 99},
		{"text": "The Hollow Sow broke these hedges once. We remember so it doesn't happen twice.", "e0": 0, "e1": 99},
		{"text": "South gate sees the caravans. North gate sees everything else.", "e0": 0, "e1": 99},
	],
	"drover": [
		{"text": "Vellmark run's three days if the road's kind. It hasn't been kind.", "e0": 0, "e1": 99},
		{"text": "Easy with the lead pair, they're worth more than you. Present company included.", "e0": 0, "e1": 99},
		{"text": "Pell's looking for guards for the Grey water wagon. Coin, not promises.", "e0": 0, "e1": 99},
		{"text": "Horses know the road better than I do. I just hold the reins and take the credit.", "e0": 0, "e1": 99},
	],
	"granary": [
		{"text": "Three granaries and every one full. That's a good year, whatever the priests say.", "e0": 0, "e1": 99},
		{"text": "Rats get the spill, we get the rest. Fair trade.", "e0": 0, "e1": 99},
		{"text": "You can see the silos from the north road. That's the point. Thornfield feeds people.", "e0": 0, "e1": 99},
	],
	"brewery": [
		{"text": "Vats are singing today. Good mash, good ale.", "e0": 0, "e1": 99},
		{"text": "Tammas tastes every barrel. Somebody has to. He volunteers.", "e0": 0, "e1": 99},
	],
	"chapel": [
		{"text": "Left my first-fruits at the altar. Sarella nodded. That's a good sign. Probably.", "e0": 0, "e1": 99},
		{"text": "In Gleaner country a small wonder's just Tuesday. You get used to it. Mostly.", "e0": 0, "e1": 99},
	],
	"smithy": [
		{"text": "Odo corrected my hammer grip four times today. Four. He's right every time, worse luck.", "e0": 0, "e1": 99},
		{"text": "Blunt steel for the drill yard, sharp steel for the hedges. Don't mix them up.", "e0": 0, "e1": 99},
	],
	"vigil": [
		{"text": "The Vigil works the rim roads. Culling's holy work. I'll water the horse and ride.", "e0": 0, "e1": 99},
		{"text": "Thornfield's hedges held this year. Pray they hold the next.", "e0": 0, "e1": 99},
	],
	"later_epoch": [
		{"text": "Stories get specific, don't they? Ask me again when the year's turned.", "e0": 1, "e1": 99},
	],
}


## All lines valid for `role` at `epoch`.
## Every line valid for this role, at this epoch, in this world, at this
## hour. `state` and `hour` are optional so anything that only wants the
## epoch filter still works.
static func lines(role: String, epoch: int, state: TownWorldState = null,
		hour: float = -1.0) -> Array:
	var out: Array = []
	if not LINES.has(role):
		return out
	for ln in LINES[role]:
		if epoch < int(ln["e0"]) or epoch > int(ln["e1"]):
			continue
		if not _holds(ln.get("when", []), state, hour):
			continue
		out.append(String(ln["text"]))
	return out


## Do all of a line's conditions hold? An unknown condition FAILS rather
## than passing, so a typo silences one line instead of putting a lie in
## somebody's mouth.
static func _holds(conditions: Array, state: TownWorldState, hour: float) -> bool:
	for c in conditions:
		var name := String(c)
		if not CONDITIONS.has(name):
			push_warning("BarkBank: unknown condition '%s'" % name)
			return false
		if not _one(name, state, hour):
			return false
	return true


static func _one(condition: String, state: TownWorldState, hour: float) -> bool:
	match condition:
		"day":
			return hour < 0.0 or RoutineRules.waking(hour)
		"night":
			return hour >= 0.0 and not RoutineRules.waking(hour)
		"boars_pressing":
			if state == null: return false
			for region in state.boar_pressure:
				if int(state.boar_pressure[region]) >= 3:
					return true
			return false
		"boars_quiet":
			if state == null: return false
			for region in state.boar_pressure:
				if int(state.boar_pressure[region]) <= 0:
					return true
			return false
		"work_done":
			return state != null and int(state.culls_completed) > 0
		"you_took_work":
			return state != null and not state.contracts_taken.is_empty()
		"you_are_hired":
			return state != null and bool(state.hired)
		"you_gave_work_back":
			# The only cost of abandoning a contract. There is no
			# reputation number and no penalty at the board — the town
			# simply has something else to say to you, which is where
			# this world keeps its opinions.
			return state != null and int(state.contracts_abandoned) > 0
	return false
