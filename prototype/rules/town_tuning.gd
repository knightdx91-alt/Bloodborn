class_name TownTuning
extends RefCounted
## Loads town.json — the numbers shared with the C# rules in
## sim/Marrowmark.Sim/Town.
##
## A copy of shared/tuning/town.json, for the same reason combat.json is
## copied: Godot cannot load anything above res://. The copy is not on
## trust — TownTuningFileTests.cs fails the build if the two differ.
##
## Never edit this copy. Edit shared/tuning/town.json and copy it here.

const PATH := "res://rules/town.json"

static func load_section(section: String) -> Dictionary:
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("town tuning missing at %s" % PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has(section):
		push_error("town tuning has no section '%s'" % section)
		return {}
	return parsed[section]
