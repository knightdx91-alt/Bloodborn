class_name Shrine
extends RefCounted
## The shrine stone beside the Gleaner chapel: where the dying are
## knitted back (lore.md §3) — i.e. the respawn point. Mechanically and
## spiritually the same stone. You come back poorer; that teaches the
## death ladder from its bottom rung (onboarding.md §3).

const RESPAWN_AT := Vector3(28, 0, -25)
const TOLL := 4


## Return the dead to the shrine. The toll is coin; what coin can't cover
## is remembered in the respawn count.
static func respawn(state: TownWorldState, player: Node3D) -> String:
	player.global_position = RESPAWN_AT + Vector3(1.5, 0, 1.5)
	var paid := mini(state.coin, TOLL)
	state.coin -= paid
	state.respawns += 1
	state.last_respawn = "knitted back at the shrine, %d pennies lighter" % paid
	return ("Cold stone under your back, and Sarella's voice, soft as seasons: "
		+ "\"Up you come. The shrine keeps what it's owed — " + str(paid) + " pennies, this time. "
		+ "The dying are knitted back, never whole.\"")
