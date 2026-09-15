extends Control
## Boot menu: pick the drill yard (combat) or Thornfield (town).
## Keeps combat files untouched — the yard still boots straight into
## main.tscn when chosen here.
##
## Sized to the VIEWPORT rather than to fixed pixels. The first version
## used 72px of title and two 110px buttons, which came to more than
## 450px of content and clipped "Thornfield" clean off the bottom of a
## short window. A menu that only fits on the developer's screen is not
## a menu.

## The layout is designed against this size and scaled from it. BOTH
## axes constrain, because the title is the widest thing on screen and
## scaling on height alone blew "MARROWMARK" out to 858px inside a
## 720px-wide phone — the buttons stretched to match it and hung off
## both edges.
const DESIGN_HEIGHT := 720.0
const DESIGN_WIDTH := 640.0
## Never shrink past legibility, never grow into a billboard.
const MIN_SCALE := 0.55
const MAX_SCALE := 1.6
## A touch target below this is a miss waiting to happen.
const MIN_BUTTON_HEIGHT := 48.0

var _vb: VBoxContainer
var _title: Label
var _sub: Label
var _buttons: Array[Button] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# Margins keep the menu clear of rounded corners and notches; the
	# safe-area insets are what make that true on a real phone rather
	# than only on a rectangle.
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(center)

	_vb = VBoxContainer.new()
	_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(_vb)

	_title = Label.new()
	_title.text = "MARROWMARK"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(_title)

	_sub = Label.new()
	_sub.text = "prototype"
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.modulate = Color(0.7, 0.7, 0.75)
	_vb.add_child(_sub)

	_buttons.append(_big_button("Drill Yard", "res://main.tscn"))
	_buttons.append(_big_button("Thornfield", "res://town.tscn"))
	for b in _buttons:
		_vb.add_child(b)

	_margin = margin
	_relayout()
	get_viewport().size_changed.connect(_relayout)


var _margin: MarginContainer


func _big_button(text: String, scene: String) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(_go.bind(scene))
	return b


## Re-sized on every viewport change, so rotating the phone cannot leave
## a button off the edge.
func _relayout() -> void:
	var vp := get_viewport_rect().size
	var scale: float = clampf(
		minf(vp.y / DESIGN_HEIGHT, vp.x / DESIGN_WIDTH),
		MIN_SCALE, MAX_SCALE)

	_title.add_theme_font_size_override("font_size", int(72.0 * scale))
	_sub.add_theme_font_size_override("font_size", int(32.0 * scale))
	_vb.add_theme_constant_override("separation", int(28.0 * scale))

	var button_h: float = maxf(110.0 * scale, MIN_BUTTON_HEIGHT)
	var button_w: float = minf(420.0 * scale, vp.x * 0.86)
	for b in _buttons:
		b.custom_minimum_size = Vector2(button_w, button_h)
		b.add_theme_font_size_override("font_size", int(44.0 * scale))

	var side: int = int(maxf(16.0, vp.x * 0.04))
	_margin.add_theme_constant_override("margin_left", side)
	_margin.add_theme_constant_override("margin_right", side)
	_margin.add_theme_constant_override("margin_top",
		int(maxf(12.0, DisplayServer.get_display_safe_area().position.y)))
	_margin.add_theme_constant_override("margin_bottom", 12)


func _go(scene: String) -> void:
	get_tree().change_scene_to_file(scene)
