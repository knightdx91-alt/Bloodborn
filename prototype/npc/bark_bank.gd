class_name BarkBank
extends RefCounted
## Authored bark lines for Thornfield's crowd — the ~95% of NPC speech
## volume that brainstorm.md §9.1 gives NO MODEL AT ALL, because 3,000
## concurrent players at one turn per 90s is ~33 inferences a second
## forever, on a game with no subscription (L27).
## Epoch-filtered: each line carries the epoch range where it
## is true. Epoch 0 is the first harvest; epoch-1 lines exist to prove
## the filter, not because the prototype advances epochs.

## role -> Array of {text, e0, e1}
const LINES := {
	"market": [
		{"text": "Grain's two pennies the stone and that's fair, whatever Fenwick's face says.", "e0": 0, "e1": 99},
		{"text": "Cloth up again. Thornfield feeds the looms and the looms know it.", "e0": 0, "e1": 99},
		{"text": "You want ale, Tammas is your man. You want the price, ask Fenwick twice.", "e0": 0, "e1": 99},
		{"text": "Fair day's next week. Mara's already watering the ale — don't tell her I said.", "e0": 0, "e1": 99},
		{"text": "Rain before noon and the road to Greywater turns to soup. Buy your grain today.", "e0": 0, "e1": 99},
	],
	"farmer": [
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
static func lines(role: String, epoch: int) -> Array:
	var out: Array = []
	if not LINES.has(role):
		return out
	for ln in LINES[role]:
		if epoch >= int(ln["e0"]) and epoch <= int(ln["e1"]):
			out.append(String(ln["text"]))
	return out
