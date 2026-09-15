class_name TownRules
extends RefCounted
## GDScript mirrors of sim/Marrowmark.Sim/Town's apprenticeship and
## shrine rules. L88: sim/ is authoritative and this mirrors it.

enum Hire { HIRED, ALREADY_HIRED, NO_SUCH_MASTER }


## onboarding.md §1 — you begin as somebody's hired hand. One master:
## a second is refused rather than silently swapped, because §1 makes
## the first one a relationship and not a menu.
static func hire(state: TownWorldState, master: String,
		masters_who_hire: Array = []) -> int:
	if state.hired:
		return Hire.ALREADY_HIRED
	if master == "":
		return Hire.NO_SUCH_MASTER
	if not masters_who_hire.is_empty() and not masters_who_hire.has(master):
		return Hire.NO_SUCH_MASTER
	state.hired = true
	state.apprentice_master = master
	return Hire.HIRED


## The shrine takes what it can rather than refusing or lending: a player
## who cannot pay still gets up, and the unpaid part is remembered in the
## respawn count. L17's ordinary death is a cost, never a wall.
static func shrine_toll(state: TownWorldState) -> int:
	var p := TownTuning.load_section("shrine")
	var toll := int(p.get("shrineToll", 4))
	var paid: int = mini(state.coin, toll)
	state.coin -= paid
	state.respawns += 1
	return paid
