class_name WorldClock
extends RefCounted
## GDScript mirror of sim/Marrowmark.Sim/World/WorldClock.cs.
##
## L88: sim/ is authoritative and this mirrors it. L89: one clock,
## shared by everyone on a server — which is why it is a rule at all
## rather than something the renderer invents for itself.

enum Phase { NIGHT, DAWN, DAY, DUSK }

var _p: Dictionary
var _seconds := 0.0


func _init(start_at_fraction: float = 0.30) -> void:
	_p = _load()
	set_fraction(start_at_fraction)


static func _load() -> Dictionary:
	var file := FileAccess.open("res://rules/world.json", FileAccess.READ)
	if file == null:
		push_error("world tuning missing")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("day"):
		push_error("world tuning has no 'day' section")
		return {}
	return parsed["day"]


func _day_seconds() -> float:
	return float(_p.get("realSecondsPerDay", 5400.0))


## 0 is midnight, 0.25 sunrise, 0.5 noon, 0.75 sunset.
func fraction() -> float:
	return _seconds / _day_seconds()


## The hour on a 24-hour dial, for anything that has to reason about
## time of day. Nothing in the world DISPLAYS one (L80) — this is for
## routines and rules, not for a clock in the corner of the screen.
func hour() -> float:
	return fraction() * 24.0


func set_fraction(f: float) -> void:
	_seconds = fposmod(f, 1.0) * _day_seconds()


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	_seconds = fposmod(_seconds + delta, _day_seconds())


## How high the sun is, in degrees. Negative is below the horizon.
func sun_elevation_degrees() -> float:
	var t: float = cos(fraction() * TAU)   # +1 at midnight, -1 at noon
	if t <= 0.0:
		return -t * float(_p.get("noonElevationDegrees", 62.0))
	return -t * float(_p.get("midnightDepressionDegrees", 18.0))


## Clockwise from north. THE COMPASS (L89): east at sunrise, south at
## noon, west at sunset, always and everywhere.
func sun_azimuth_degrees() -> float:
	return 90.0 + (fraction() - 0.25) * 360.0


func sun_is_rising() -> bool:
	var f := fraction()
	return f > 0.0 and f < 0.5


func phase() -> int:
	var e := sun_elevation_degrees()
	if e >= float(_p.get("dayAboveDegrees", 6.0)):
		return Phase.DAY
	if e <= float(_p.get("nightBelowDegrees", -4.0)):
		return Phase.NIGHT
	return Phase.DAWN if sun_is_rising() else Phase.DUSK


## 0 in full night, 1 in full day, sliding across twilight. The one
## number the renderer blends everything against, so nothing re-derives
## the hour for itself and drifts.
func daylight() -> float:
	var e := sun_elevation_degrees()
	var hi := float(_p.get("dayAboveDegrees", 6.0))
	var lo := float(_p.get("nightBelowDegrees", -4.0))
	if hi <= lo:
		return 1.0 if e >= hi else 0.0
	return clampf((e - lo) / (hi - lo), 0.0, 1.0)
