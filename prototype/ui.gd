class_name UI
extends RefCounted
## The one place a panel, a heading and a choice are defined.
##
## `interface.md` §1 (L80) puts the world first and allows a real
## interface only where nothing else will do — the pack, the boards, a
## conversation. Those few are therefore worth building properly rather
## than leaving as default grey boxes, and they should all look like the
## same game.
##
## Two rules this exists to enforce, both learnt from bugs:
##
##  1. **Nothing is sized in fixed pixels.** The launcher shipped a menu
##     that fit the developer's window and clipped "Thornfield" off the
##     bottom of a short one, and the conversation panel is a hardcoded
##     520×300 that would do the same on a phone. Everything here scales
##     to the viewport, on BOTH axes.
##  2. **Everything focusable is visibly focused.** L15 ships to three
##     consoles and `interface.md` §7 makes controller navigation a
##     requirement; Godot's default focus ring is a thin dark outline on
##     a dark button, which is invisible at arm's length.
##
## The palette is the world's own (look.gd): timber, iron, parchment.
## art-audio.md §5 puts the look in the treatment rather than in bought
## assets, and that applies to a dialogue box as much as to a field.

## Designed against this, and scaled from it.
const DESIGN_WIDTH := 640.0
const DESIGN_HEIGHT := 720.0
const MIN_SCALE := 0.55
const MAX_SCALE := 1.6
## Below this a touch target is a miss waiting to happen.
const MIN_TAP := 48.0

const PARCHMENT := Color(0.84, 0.79, 0.68)
const INK := Color(0.13, 0.11, 0.09)
const PANEL_DARK := Color(0.13, 0.11, 0.10, 0.96)
const PANEL_EDGE := Color(0.42, 0.34, 0.24)
const CHOICE_IDLE := Color(0.18, 0.16, 0.14, 0.95)
const CHOICE_HOVER := Color(0.25, 0.22, 0.18, 0.98)
const FOCUS_EDGE := Color(0.72, 0.62, 0.38)
const DIM := Color(0.62, 0.58, 0.50)


## One number everything else is multiplied by. Both axes constrain: a
## scale taken from height alone blew a title out to 858px inside a
## 720px-wide phone and dragged its buttons off both edges.
## Takes any Node, deliberately: these panels hang off a CanvasLayer,
## which is NOT a CanvasItem, so a CanvasItem parameter made every real
## call site a compile error — and the one workaround written around it
## fell back to a scale of 1.0 in silence.
static func scale_for(node: Node) -> float:
	var view: Viewport = node.get_viewport()
	if view == null:
		return 1.0
	var vp: Vector2 = view.get_visible_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		return 1.0
	return clampf(minf(vp.y / DESIGN_HEIGHT, vp.x / DESIGN_WIDTH),
		MIN_SCALE, MAX_SCALE)


static func _box(fill: Color, edge: Color, width: int, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = edge
	b.border_width_left = width
	b.border_width_right = width
	b.border_width_top = width
	b.border_width_bottom = width
	b.corner_radius_top_left = radius
	b.corner_radius_top_right = radius
	b.corner_radius_bottom_left = radius
	b.corner_radius_bottom_right = radius
	b.content_margin_left = 18
	b.content_margin_right = 18
	b.content_margin_top = 14
	b.content_margin_bottom = 14
	return b


## A panel to put things in: dark timber with a lit edge.
static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(PANEL_DARK, PANEL_EDGE, 2, 3))
	return p


static func heading(text: String, scale: float) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", PARCHMENT)
	l.add_theme_font_size_override("font_size", int(26.0 * scale))
	return l


static func subheading(text: String, scale: float) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", DIM)
	l.add_theme_font_size_override("font_size", int(17.0 * scale))
	return l


static func body(text: String, scale: float, wrap_to: float = 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", PARCHMENT)
	l.add_theme_font_size_override("font_size", int(19.0 * scale))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if wrap_to > 0.0:
		l.custom_minimum_size = Vector2(wrap_to, 0)
	return l


## Something you pick. Sized for a thumb, and unmistakably focused when
## a controller is on it.
static func choice(text: String, scale: float, width: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", int(19.0 * scale))
	b.add_theme_color_override("font_color", PARCHMENT)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _box(CHOICE_IDLE, PANEL_EDGE, 1, 2))
	b.add_theme_stylebox_override("hover", _box(CHOICE_HOVER, PANEL_EDGE, 1, 2))
	b.add_theme_stylebox_override("pressed", _box(CHOICE_HOVER, FOCUS_EDGE, 2, 2))
	# The focused box is filled AND edged, not merely outlined: an outline
	# alone disappears against dark timber on a phone held at arm's
	# length, and then a pad looks broken rather than unfocused.
	b.add_theme_stylebox_override("focus", _box(CHOICE_HOVER, FOCUS_EDGE, 3, 2))
	b.custom_minimum_size = Vector2(width, maxf(52.0 * scale, MIN_TAP))
	return b


# --- Modals ------------------------------------------------------------
#
# A conversation can open the contract board on top of itself, and the
# player can walk away from either. Three things follow, and none of them
# happen by default:
#
#   1. B must back out of whatever is on top, and ONLY what is on top.
#   2. The panel underneath must stop taking focus, or the d-pad walks the
#      highlight out of the front panel into buttons hidden behind it.
#   3. The world must stop listening. Without this you stroll off
#      mid-sentence with the stick, and the right stick swings the camera
#      round behind the dialogue box.
#
# Every panel in the kit registers here, so `modal_open()` answers all
# three with one call.

static var _modals: Array[CanvasLayer] = []


## True while any panel in the kit is on screen. The town player asks
## this before reading a stick.
static func modal_open() -> bool:
	_prune()
	return not _modals.is_empty()


## The panel that owns the buttons right now. Only this one should act on
## a cancel press.
static func top_modal() -> CanvasLayer:
	_prune()
	return _modals[-1] if not _modals.is_empty() else null


static func push_modal(layer: CanvasLayer) -> void:
	_prune()
	var below := top_modal()
	if below != null:
		_set_branch_focusable(below, false)
		# And out of sight. Leaving it drawn put the contract board on top
		# of the conversation that opened it, with the dialogue panel
		# still poking out underneath — two panels, one of which does
		# nothing when pressed. It comes back when the board closes.
		below.visible = false
	_modals.append(layer)


static func pop_modal(layer: CanvasLayer) -> void:
	_modals.erase(layer)
	_prune()
	var below := top_modal()
	if below != null:
		below.visible = true
		_set_branch_focusable(below, true)


static func _prune() -> void:
	var live: Array[CanvasLayer] = []
	for m in _modals:
		if is_instance_valid(m) and not m.is_queued_for_deletion():
			live.append(m)
	_modals = live


## Turn a whole panel's focus off, and back on again with the highlight
## where it was. Godot has no notion of a modal branch, so this is done
## by hand rather than by a flag we could have set.
static func _set_branch_focusable(layer: CanvasLayer, on: bool) -> void:
	if on:
		var was: Control = layer.get_meta("ui_focus_was", null) as Control
		for c in layer.find_children("*", "Control", true, false):
			var ctl := c as Control
			if ctl.has_meta("ui_focus_mode"):
				ctl.focus_mode = int(ctl.get_meta("ui_focus_mode")) as Control.FocusMode
				ctl.remove_meta("ui_focus_mode")
		if is_instance_valid(was) and was.focus_mode != Control.FOCUS_NONE:
			was.grab_focus()
			return
		# Nothing remembered — take the first thing that can hold the
		# highlight rather than leaving the panel with none. A menu with
		# nothing selected reads as a broken pad.
		for c in layer.find_children("*", "Control", true, false):
			var first := c as Control
			if first.focus_mode != Control.FOCUS_NONE and first.is_visible_in_tree():
				first.grab_focus()
				return
		return
	layer.set_meta("ui_focus_was", null)
	for c in layer.find_children("*", "Control", true, false):
		var ctl := c as Control
		if ctl.focus_mode == Control.FOCUS_NONE:
			continue
		if ctl.has_focus():
			layer.set_meta("ui_focus_was", ctl)
		ctl.set_meta("ui_focus_mode", int(ctl.focus_mode))
		ctl.focus_mode = Control.FOCUS_NONE


# --- Touch ------------------------------------------------------------
#
# Touch is not a shipping platform (L15 is PC and three consoles), but it
# is the only way to play this on the machine that is to hand, and a
# thumb control that is half a thumb wide is not a control. These are
# sized from the viewport like everything else here, and inset out of
# the notch.


## Usable screen inset in VIEWPORT pixels: left, top, right, bottom.
##
## DisplayServer reports the safe area in screen pixels, which on a phone
## is not the same number — the old code multiplied a screen height by
## 0.02 and called it a margin, which is a coincidence rather than an
## inset. Mapped properly here, and zero everywhere without a cutout.
static func safe_inset(node: Node) -> Vector4:
	var view: Viewport = node.get_viewport()
	if view == null:
		return Vector4.ZERO
	var vp: Vector2 = view.get_visible_rect().size
	var screen := Vector2(DisplayServer.screen_get_size())
	var safe := DisplayServer.get_display_safe_area()
	if screen.x <= 0.0 or screen.y <= 0.0 or safe.size.x <= 0 or safe.size.y <= 0:
		return Vector4.ZERO
	var sx: float = vp.x / screen.x
	var sy: float = vp.y / screen.y
	return Vector4(
		maxf(0.0, float(safe.position.x) * sx),
		maxf(0.0, float(safe.position.y) * sy),
		maxf(0.0, float(screen.x - safe.end.x) * sx),
		maxf(0.0, float(screen.y - safe.end.y) * sy))


## A thumb target: short label, dark timber, big enough to hit blind.
static func chip(text: String, scale: float) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", int(20.0 * scale))
	b.add_theme_color_override("font_color", PARCHMENT)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _box(PANEL_DARK, PANEL_EDGE, 2, 4))
	b.add_theme_stylebox_override("hover", _box(PANEL_DARK, PANEL_EDGE, 2, 4))
	b.add_theme_stylebox_override("pressed", _box(CHOICE_HOVER, FOCUS_EDGE, 2, 4))
	b.custom_minimum_size = Vector2(maxf(120.0 * scale, 96.0),
		maxf(64.0 * scale, MIN_TAP + 8.0))
	return b



# --- The gate ---------------------------------------------------------
#
# L49 puts a hard confirm in front of anything binding, and there is one
# of these rather than one per screen — a conversation and the contract
# board both hand out work, and a gate that behaves differently
# depending on where you found the job is not a gate, it is two.
#
# The rules it enforces, all of them learnt the hard way:
#
#  * It opens on the REFUSAL. A stray press must cost nothing.
#  * Nothing behind it can take focus, or the d-pad walks the highlight
#    off the gate and A presses a button hidden underneath — which here
#    means signing by accident.
#  * B declines it rather than closing the screen behind it.


## Put a gate up on `layer`. `on_yes` runs only if the player says yes.
static func confirm(layer: CanvasLayer, question: String, yes_text: String,
		no_text: String, on_yes: Callable, on_no: Callable = Callable()) -> void:
	if confirm_is_open(layer):
		return
	var scale := scale_for(layer)
	var view: Viewport = layer.get_viewport()
	var vp: Vector2 = view.get_visible_rect().size if view != null \
		else Vector2(DESIGN_WIDTH, DESIGN_HEIGHT)

	var frozen: Array[Control] = []
	for c in layer.find_children("*", "Control", true, false):
		var ctl := c as Control
		if ctl.focus_mode != Control.FOCUS_NONE:
			if ctl.has_focus():
				layer.set_meta("ui_gate_focus_was", ctl)
			ctl.focus_mode = Control.FOCUS_NONE
			frozen.append(ctl)

	# And the screen it belongs to goes away while it is up. A gate laid
	# over a dialogue box covers the very terms it is asking about —
	# reported as "another small screen pops up, so you can't read the
	# one below it" — so the gate has to carry the terms itself and be
	# the only thing on screen. Both halves, or neither works.
	var hidden: Array[CanvasItem] = []
	for c in layer.get_children():
		if c is CanvasItem and (c as CanvasItem).visible:
			hidden.append(c as CanvasItem)
			(c as CanvasItem).visible = false
	layer.set_meta("ui_gate_hid", hidden)

	# Centred by a container rather than by an offset, so a long set of
	# terms grows the panel without walking it off the top of the screen.
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(centre)
	layer.set_meta("ui_confirm", centre)

	var panel := UI.panel()
	var width: float = minf(420.0 * scale, vp.x * 0.88)
	panel.custom_minimum_size = Vector2(width, 0)
	centre.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", int(10.0 * scale))
	panel.add_child(vb)

	var q := body(question, scale, width - 60.0 * scale)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(q)

	var yes := choice(yes_text, scale, width - 60.0 * scale)
	yes.alignment = HORIZONTAL_ALIGNMENT_CENTER
	yes.pressed.connect(func() -> void:
		_close_confirm(layer, frozen)
		if on_yes.is_valid():
			on_yes.call())
	vb.add_child(yes)

	var no := choice(no_text, scale, width - 60.0 * scale)
	no.alignment = HORIZONTAL_ALIGNMENT_CENTER
	no.pressed.connect(func() -> void:
		_close_confirm(layer, frozen)
		if on_no.is_valid():
			on_no.call())
	vb.add_child(no)

	no.grab_focus()


static func confirm_is_open(layer: CanvasLayer) -> bool:
	if layer == null or not layer.has_meta("ui_confirm"):
		return false
	var p: Node = layer.get_meta("ui_confirm") as Node
	return is_instance_valid(p) and not p.is_queued_for_deletion()


## What B does while a gate is up.
static func confirm_decline(layer: CanvasLayer) -> void:
	if not confirm_is_open(layer):
		return
	var p := layer.get_meta("ui_confirm") as Node
	for b in p.find_children("*", "Button", true, false):
		var btn := b as Button
		if btn.has_focus() or btn.get_index() == 1:
			btn.pressed.emit()
			return


static func _close_confirm(layer: CanvasLayer, frozen: Array[Control]) -> void:
	if layer.has_meta("ui_confirm"):
		var p := layer.get_meta("ui_confirm") as Node
		if is_instance_valid(p):
			p.queue_free()
		layer.remove_meta("ui_confirm")
	if layer.has_meta("ui_gate_hid"):
		for c in layer.get_meta("ui_gate_hid"):
			if is_instance_valid(c):
				(c as CanvasItem).visible = true
		layer.remove_meta("ui_gate_hid")
	for c in frozen:
		if is_instance_valid(c):
			c.focus_mode = Control.FOCUS_ALL
	# Hand the highlight back, or a pad is left with nothing selected and
	# the screen reads as hung.
	var was: Control = layer.get_meta("ui_gate_focus_was", null) as Control
	if is_instance_valid(was) and was.focus_mode != Control.FOCUS_NONE:
		was.grab_focus()
		return
	for c in frozen:
		if is_instance_valid(c) and c.is_visible_in_tree():
			c.grab_focus()
			return
