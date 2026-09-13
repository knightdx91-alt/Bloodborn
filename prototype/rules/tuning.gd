class_name Tuning
extends RefCounted
## Loads combat.json — the numbers shared with the C# rules in sim/.
##
## This file is a copy of shared/tuning/combat.json, because Godot cannot
## load anything above res:// and the canonical copy must not live inside
## a prototype that may yet be thrown away (L54 is not settled). The copy
## is not on trust: TuningFileTests.cs fails the build if the two differ.
##
## Never edit this copy. Edit shared/tuning/combat.json and copy it here.

const PATH := "res://rules/combat.json"

static func load_section(section: String) -> Dictionary:
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		push_error("combat tuning missing at %s" % PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has(section):
		push_error("combat tuning has no section '%s'" % section)
		return {}
	return parsed[section]
