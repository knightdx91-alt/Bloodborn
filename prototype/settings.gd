class_name Settings
extends RefCounted
## Player settings that persist between runs.
##
## This exists because the camera's pitch direction was flipped twice
## from here and reported inverted both times — which is the point at
## which guessing at a sign you cannot see is the wrong tool. Whether a
## stick feels inverted is not a fact to be derived; it is a preference,
## and it belongs to whoever is holding the pad.
##
## `interface.md` §7 required this anyway: remappable controls are
## listed beside subtitles and colourblind-safe cues as accessibility
## that is "never traded away for minimalism". This is the first of
## them.

const PATH := "user://settings.cfg"
const SECTION := "camera"

static var _loaded := false
static var _invert_y := false
static var _invert_x := false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	_invert_y = bool(cfg.get_value(SECTION, "invert_y", false))
	_invert_x = bool(cfg.get_value(SECTION, "invert_x", false))


static func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "invert_y", _invert_y)
	cfg.set_value(SECTION, "invert_x", _invert_x)
	cfg.save(PATH)


## +1 or -1, ready to multiply a stick axis by.
static func pitch_sign() -> float:
	_load()
	return -1.0 if _invert_y else 1.0


static func yaw_sign() -> float:
	_load()
	return -1.0 if _invert_x else 1.0


static func invert_y() -> bool:
	_load()
	return _invert_y


static func invert_x() -> bool:
	_load()
	return _invert_x


static func set_invert_y(on: bool) -> void:
	_load()
	_invert_y = on
	_save()


static func set_invert_x(on: bool) -> void:
	_load()
	_invert_x = on
	_save()
