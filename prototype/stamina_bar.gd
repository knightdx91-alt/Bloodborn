class_name StaminaBar
extends Control
## The stamina bar, for whoever is holding it.
##
## `interface.md` §2: there is no persistent HUD. It fades in the moment
## the bar MOVES and fades out once you are full and rested — so in a
## fight it is effectively always there, and walking down a road it never
## is. Nothing here knows what combat is; the trigger is the number
## changing.
##
## Lifted out of `world.gd`, where it was the drill yard's private
## property. Reported from play: *"the stamina bar isn't showing."* It
## was not — Thornfield never had one, and since the Hedges moved into
## the town's scene, the town is everywhere the game is actually played.
## The same fault, and the same fix, as `Skirmish` and `Feel` before it:
## a thing every region needs cannot live inside one of them.

const FADE_IN := 12.0
const FADE_OUT := 2.2
const LINGER := 0.9

const FULL := Color(0.85, 0.83, 0.72)
const SPENT := Color(0.78, 0.35, 0.28)

var _watching: Fighter
var _back: ColorRect
var _fill: ColorRect
var _alpha := 0.0
var _linger := 0.0
var _last := 0.0


## Hang a bar on `layer` and point it at `who`.
static func add_to(layer: CanvasLayer, who: Fighter) -> StaminaBar:
	var bar := StaminaBar.new()
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	# It is a readout, not a control. Without this it eats the touches
	# meant for the world underneath it.
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar._watching = who
	layer.add_child(bar)
	bar._build()
	return bar


func _build() -> void:
	_back = ColorRect.new()
	_back.color = Color(0, 0, 0, 0.45)
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_back)

	_fill = ColorRect.new()
	_fill.color = FULL
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fill)

	modulate.a = 0.0
	if _watching != null:
		_last = _watching.stamina.current()


## Called every frame by whoever owns the region.
func tick(delta: float) -> void:
	if _watching == null or not is_instance_valid(_watching):
		return

	var vp := get_viewport().get_visible_rect().size
	# Low and centred, under the character rather than pinned to a
	# corner — the eye is already there and does not have to travel.
	var width: float = minf(vp.x * 0.46, 320.0)
	var height := 5.0
	var left := (vp.x - width) * 0.5
	var top: float = vp.y - maxf(vp.y * 0.10, 46.0)

	var fraction: float = clampf(_watching.stamina.fraction(), 0.0, 1.0)
	_back.position = Vector2(left, top)
	_back.size = Vector2(width, height)
	_fill.position = Vector2(left, top)
	_fill.size = Vector2(width * fraction, height)
	_fill.color = SPENT if _watching.stamina.is_exhausted() else FULL

	var moving: bool = absf(_watching.stamina.current() - _last) > 0.01
	_last = _watching.stamina.current()
	var rested: bool = fraction >= 0.999 and not _watching.stamina.is_exhausted()

	if moving and not rested:
		_linger = LINGER
	else:
		_linger = maxf(0.0, _linger - delta)

	var target: float = 1.0 if _linger > 0.0 else 0.0
	var rate: float = FADE_IN if target > _alpha else FADE_OUT
	_alpha = move_toward(_alpha, target, rate * delta)
	modulate.a = _alpha


## For a harness: is the bar actually on screen right now?
func showing() -> float:
	return _alpha
