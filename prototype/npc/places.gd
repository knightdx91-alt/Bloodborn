class_name Places
extends RefCounted
## Where Thornfield's named places actually are on the ground.
##
## The RULE layer (rules/routine.gd, sim/Town/Routine.cs) deals only in
## place NAMES — "forge", "inn", "board". It has no idea where the forge
## is, and should not: a second town has its own forge somewhere else and
## reuses every line of the rule.
##
## This is the other half, and it is content. The anchors are the same
## positions the roster already uses, so the smith's forge is where the
## smith was standing.

const ANCHORS := {
	"inn": Vector3(-14.5, 0, 2),        # The Sheaf
	"forge": Vector3(-5.5, 0, -27.5),   # Odo's smithy
	"yard": Vector3(12.5, 0, -30),      # the carter's yard
	"chapel": Vector3(-22, 0, 31.5),    # the hedge-chapel
	"board": Vector3(9.5, 0, 11),       # the market boards
	"square": Vector3(0, 0, 0),         # the market square
	"farm": Vector3(-5.5, 0, -27.5),    # the Vance farm road
}


## Where to stand for a named place. `spread` fans people out around the
## anchor so a full inn is a crowd rather than one body inside another.
static func spot(place: String, spread: int = 0) -> Vector3:
	var base: Vector3 = ANCHORS.get(place, ANCHORS["square"])
	if spread == 0:
		return base
	# Deterministic ring, so the same person stands in the same spot
	# every evening rather than shuffling each time the scene loads.
	var angle: float = float(spread) * 2.399963  # golden angle, in radians
	var radius: float = 1.1 + 0.42 * float(spread % 4)
	return base + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


static func known(place: String) -> bool:
	return ANCHORS.has(place)
