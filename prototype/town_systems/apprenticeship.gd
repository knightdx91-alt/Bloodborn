class_name Apprenticeship
extends RefCounted
## Thornfield's masters, and what they say when they take you on.
##
## The RULE — one master, binding, refused rather than swapped — lives in
## rules/town_rules.gd, mirroring sim/Marrowmark.Sim/Town (L88). The
## errand lines are content and belong here.
##
## Every errand is spoken as a landmark direction. L29 forbids markers
## outright, so "up the north road, past the burnt mill" is not flavour
## on top of a waypoint — it IS the waypoint.

## Who actually hires in Thornfield. Passed to the rule so that a model
## reaching for any master it likes (L49) still cannot invent one.
const MASTERS := ["odo", "pell"]


## Hire via dialogue. Returns the master's first errand line.
static func hire(state: TownWorldState, master: String) -> String:
	match TownRules.hire(state, master, MASTERS):
		TownRules.Hire.ALREADY_HIRED:
			return "You're already hired, and %s has a long memory for second masters." % state.apprentice_master
		TownRules.Hire.NO_SUCH_MASTER:
			return "They look at you blankly. That's not theirs to offer."
	match master:
		"odo":
			return ("Odo looks you up and down like a bad weld. \"You'll do. "
				+ "Take this bundle of horseshoes to the Vance farm — up the north road, "
				+ "past the burnt mill. Don't dawdle, and don't lose them.\"")
		"pell":
			return ("Pell grins, tired. \"Ha! Another pair of hands. The Vellmark wagon "
				+ "musters at first light — you'll walk beside it to the south gate and "
				+ "learn the harness. Mind the lead pair; they're worth more than you.\"")
	return "The handshake's done. Work starts at first light."


static func is_hired(state: TownWorldState) -> bool:
	return state.hired
