class_name Apprenticeship
extends RefCounted
## Onboarding §1: you begin as somebody's hired hand. Odo the smith or
## Pell the carter hires you; the hire is a flag plus the first errand,
## spoken as a landmark direction (L29 — no markers, ever).


## Hire via dialogue. Returns the master's first errand line.
static func hire(state: TownWorldState, master: String) -> String:
	if state.hired:
		return "You're already hired, and %s has a long memory for second masters." % state.apprentice_master
	state.hired = true
	state.apprentice_master = master
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
