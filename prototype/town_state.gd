extends Node
## Thornfield, between visits.
##
## Autoloaded as `TownState`. Until this existed, `TownWorldState` was
## built fresh every time the town scene loaded — so a contract you took,
## the coin you spent and the master who hired you all vanished the
## moment you walked to the drill yard and back. Nothing in the work loop
## can mean anything while the world forgets it.
##
## The state itself stays a plain `TownWorldState` (the systems and the
## L88 rule mirrors all take one), so nothing else has to know this is
## here. This owns the single live copy and its trips to disk.

const PATH := "user://thornfield.cfg"
const SECTION := "town"

var _state: TownWorldState = null


## The live town. Loaded from disk the first time anything asks.
func current() -> TownWorldState:
	if _state == null:
		_state = TownWorldState.new()
		_read()
	return _state


## Wipe it and start the town over. Used by the harness, which must not
## inherit whatever the last play session left lying about, and by any
## future "new game".
func reset() -> void:
	_state = TownWorldState.new()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


## The town's clock, so anything that needs the hour asks one place.
##
## Held here rather than on the town scene because the Hedges has a clock
## too and they must not drift apart: L89 is one clock shared by
## everybody, and two scenes each keeping their own is exactly the thing
## it rules out.
var _clock: WorldClock = null


func clock() -> WorldClock:
	return _clock


func set_clock(c: WorldClock) -> void:
	_clock = c


func save() -> void:
	if _state == null:
		return
	var cfg := ConfigFile.new()
	for f in _fields():
		cfg.set_value(SECTION, f, _state.get(f))
	cfg.save(PATH)


## Every script variable on TownWorldState, by name.
##
## Enumerated rather than listed by hand on purpose: a field added to the
## state later is persisted automatically instead of being silently
## forgotten, which is the usual way save systems rot.
func _fields() -> Array:
	var out: Array = []
	for p in _state.get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out.append(String(p["name"]))
	return out


func _read() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	var fresh := TownWorldState.new()
	for f in _fields():
		if not cfg.has_section_key(SECTION, f):
			continue
		var stored: Variant = cfg.get_value(SECTION, f)
		# A field whose type has changed since the file was written is
		# dropped rather than forced in. A save that crashes the town is
		# worse than a save that forgets one thing.
		if typeof(stored) != typeof(fresh.get(f)):
			push_warning("TownState: dropping '%s', stored %s, expected %s"
				% [f, type_string(typeof(stored)), type_string(typeof(fresh.get(f)))])
			continue
		_state.set(f, stored)


## Android does not promise to call _exit_tree when the app goes away, so
## the pause notification is the one that actually fires when a player
## switches out of the game.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, \
		NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_EXIT_TREE:
			save()
