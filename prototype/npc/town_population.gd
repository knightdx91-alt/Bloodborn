class_name TownPopulation
extends RefCounted
## Thornfield's people and systems, in one call.
##
## Integration (one line, when the town build is ready for it):
##     TownPopulation.populate(self)
## at the end of town.gd's _ready(). Kept separate so the NPC/systems
## pass never touches town.gd or the combat files.
##
## Returns {"state": TownWorldState} — the systems dict handed to every
## conversation. Boards, Shrine, Rumors and Apprenticeship are static.


static func populate(town_root: Node3D) -> Dictionary:
	var state := TownWorldState.new()
	var systems := {"state": state}
	var pop := Node3D.new()
	pop.name = "Population"
	town_root.add_child(pop)
	for data in Roster.all():
		var npc := TownNPC.new()
		npc.name = "NPC_%s" % String(data["id"])
		npc.setup(data)
		pop.add_child(npc)
	return systems


## Headcount check for the verification harness.
static func expected_count() -> int:
	return Roster.all().size()
