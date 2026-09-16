class_name TownWorldState
extends RefCounted
## Minimal data model for Thornfield's T5 systems. Everything the boards,
## the shrine, rumors and apprenticeship read is here, seeded once.
## The board never lists what doesn't exist: contract generation reads
## these fields directly (see boards.gd).

## Epoch 0 = the first harvest. Bark lines and rumors filter on this.
var epoch: int = 0

## Blood-warped boar pressure per region, 0-5. Grows if unculled;
## cull contracts are real maintenance (content.md §2).
var boar_pressure := {
	"the Hedges west": 3,
	"the Hedges east": 2,
	"the north road": 1,
}

## Caravans mustering at the carter's yard. Escort contracts come from
## real caravans (content.md §3).
var caravans := [
	{"id": "velmark-1", "dest": "Vellmark", "status": "mustering", "guards": 2},
	{"id": "greywater-1", "dest": "Greywater", "status": "mustering", "guards": 1},
]

## Hands wanted for the harvest at the Vance farm.
var harvest_demand: int = 4

## Smithing commissions Odo will offer.
var smithing_jobs := [
	{"id": "smith-1", "work": "Re-shoe the carter's lead pair", "pay": 6},
	{"id": "smith-2", "work": "Blunt a dozen drill-yard swords", "pay": 9},
]

## What's warehoused in Thornfield. The market board lists only this
## (economy.md §3). pay/prices in copper pennies.
var warehoused := {
	"grain": {"qty": 120, "price": 2, "unit": "stone"},
	"cloth": {"qty": 45, "price": 9, "unit": "bolt"},
	"ale": {"qty": 60, "price": 3, "unit": "cask"},
	"tools": {"qty": 18, "price": 14, "unit": "set"},
}

## Rumors: text, who said it, how old (hours), how bent in the telling.
## Buying drinks is the search interface (content.md §3).
var rumors := [
	{"text": "Boars out of the west Hedges took two of Vance's sheep last week. He's counting the rest twice a day now.",
		"source": "a drover", "age": 30.0, "distortion": 0.1},
	{"text": "They say the Hollow Sow's kin den down by the old orchard-wood. Nobody's checked. Nobody wants to.",
		"source": "Mara Kettle", "age": 60.0, "distortion": 0.3},
	{"text": "A Grey water wagon's mustering for the south road and short two guards. Pell's paying in coin, not promises.",
		"source": "Carter Pell", "age": 12.0, "distortion": 0.05},
	{"text": "The mill on the north road? Burnt in my gran's time. She swore she heard the wheel turn the winter after.",
		"source": "a market-goer", "age": 200.0, "distortion": 0.6},
	{"text": "Sarella read the first-fruits and went quiet for a long minute. That's never nothing.",
		"source": "a chapel-goer", "age": 20.0, "distortion": 0.25},
]

var contracts_taken: Array = []

## Work done toward each taken contract, by contract id. Separate from
## contracts_taken because taking work and doing it are different facts,
## and only the second one can be lost.
var contract_progress: Dictionary = {}

## Prototype stand-in for the player's purse.
var coin: int = 12

## Apprenticeship (onboarding.md §1): "" until Odo or Pell hires you.
var apprentice_master: String = ""
var hired: bool = false

var last_respawn: String = ""
var respawns: int = 0
