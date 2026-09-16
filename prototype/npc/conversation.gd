class_name ConversationUI
extends CanvasLayer
## Text conversation: walk up, hold to talk, choose a topic.
## The model emits an intent; the game validates and executes it.
## Anything binding ends in a confirm panel — L49, moderation.md §5.
## No LLM in the prototype: voice cards are carried by the authored
## lines, which proves the gate without the risk.
##
## NOTE: the INTENTS list below is a whitelist, and L49 deliberately
## REMOVED that ceiling — "no ceiling on what the model may propose; a
## hard gate on what executes". Harmless while every intent comes from
## an authored card; wrong the moment a model is put behind it. See
## TOWN.md.

## Intent whitelist. Anything else is refused, never executed.
const INTENTS := ["offer_contract", "share_rumor", "refuse",
	"set_disposition", "none"]

## Intents that bind the player and always get a confirm panel.
const BINDING := ["offer_contract"]

static var current: ConversationUI = null

var _npc: TownNPC
var _systems: Dictionary
var _dialog: RichTextLabel
var _topic_box: VBoxContainer
var _confirm: PanelContainer
var _pending: Dictionary = {}


static func open(npc: TownNPC, systems: Dictionary) -> void:
	if current != null:
		current.close()
	var ui := ConversationUI.new()
	ui._npc = npc
	ui._systems = systems
	# CanvasLayer isn't in the tree yet; build after adding.
	var root := npc.get_tree().current_scene
	if root == null:
		root = npc.get_tree().root
	root.add_child(ui)
	# Registered before _build() grabs focus, for the same reason the
	# board is: the stack has to see where the highlight was underneath.
	UI.push_modal(ui)
	ui._build()
	current = ui


func _build() -> void:
	# Sized to the viewport, never in fixed pixels — the previous panel
	# was a hardcoded 520x300, which is the same fault that clipped the
	# launcher's second button off a short window.
	var scale := UI.scale_for(self)
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var width: float = minf(560.0 * scale, vp.x * 0.92)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", int(maxf(12.0, vp.x * 0.03)))
	root.add_theme_constant_override("margin_right", int(maxf(12.0, vp.x * 0.03)))
	root.add_theme_constant_override("margin_bottom",
		int(maxf(12.0, DisplayServer.get_display_safe_area().size.y * 0.02)))
	add_child(root)

	# Bottom of the screen, so the world above it stays visible. L80's
	# order of preference puts the world first; a dialogue box that fills
	# the screen stops you seeing the person you are talking to.
	var bottom := VBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(bottom)

	var panel := UI.panel()
	panel.custom_minimum_size = Vector2(width, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bottom.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", int(8.0 * scale))
	panel.add_child(vb)

	vb.add_child(UI.heading(_npc.display_name, scale))
	vb.add_child(UI.subheading(_npc.role, scale))

	_dialog = RichTextLabel.new()
	_dialog.bbcode_enabled = false
	_dialog.scroll_following = true
	_dialog.fit_content = true
	_dialog.custom_minimum_size = Vector2(width - 60.0 * scale, 96.0 * scale)
	_dialog.add_theme_color_override("default_color", UI.PARCHMENT)
	_dialog.add_theme_font_size_override("normal_font_size", int(19.0 * scale))
	_dialog.text = _npc.greeting()
	vb.add_child(_dialog)

	_topic_box = VBoxContainer.new()
	_topic_box.add_theme_constant_override("separation", int(5.0 * scale))
	vb.add_child(_topic_box)
	for t in _npc.topics:
		var b := UI.choice(String(t.get("topic", "...")), scale, width - 60.0 * scale)
		b.pressed.connect(_on_topic.bind(t))
		_topic_box.add_child(b)

	var leave := UI.choice("Leave", scale, width - 60.0 * scale)
	leave.pressed.connect(close)
	vb.add_child(leave)

	# A pad needs something focused to press. Prefer the first topic so
	# that A talks rather than walking away.
	if _topic_box.get_child_count() > 0:
		(_topic_box.get_child(0) as Button).grab_focus()
	else:
		leave.grab_focus()


## B backs out of one layer at a time: out of the confirm panel if it is
## up, out of the conversation otherwise. Only the panel on top acts, so
## opening the board from here and pressing B returns you to the
## conversation rather than dumping you into the street.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if UI.top_modal() != self:
		return
	get_viewport().set_input_as_handled()
	if _confirm != null:
		_on_decline()
	else:
		close()


func _on_topic(t: Dictionary) -> void:
	var intent := String(t.get("intent", "none"))
	if not INTENTS.has(intent):
		_say(String(t.get("line", "")) + "\n[The words don't land. They wave you off.]")
		return
	var line := String(t.get("line", ""))
	match intent:
		"none":
			_say(line)
			if String(t.get("effect", "")) != "":
				_apply_effect(t)
		"refuse":
			_say(line)
		"set_disposition":
			_apply_disposition(t.get("effect_arg", {}))
			_say(line)
		"share_rumor":
			var r: Dictionary = Rumors.search(_systems["state"])
			_say(line + "\n\n\"" + String(r["text"]) + "\"\n— " + String(r["source"]))
		"offer_contract":
			_pending = t
			_show_confirm(line)


func _apply_disposition(arg: Variant) -> void:
	if arg is Dictionary:
		if arg.has("warm"):
			_npc.greeting_warm = bool(arg["warm"])
		if arg.has("uses_name"):
			_npc.uses_name = bool(arg["uses_name"])
		if arg.has("stays") and not bool(arg["stays"]):
			_npc.stays = false
			close()


func _show_confirm(line: String) -> void:
	_say(line + "\n\n[This binds you, or costs you coin.]")
	var scale := UI.scale_for(self)
	var vp: Vector2 = get_viewport().get_visible_rect().size

	# Nothing behind the gate may take focus while it is up. Otherwise
	# the d-pad walks the highlight down out of "Think it over" and into
	# the topic list behind it, and A then presses a button the player
	# cannot see. L49 makes this panel the gate; a gate you can step
	# around is not one.
	_freeze_base(true)

	_confirm = UI.panel()
	_confirm.set_anchors_preset(Control.PRESET_CENTER)
	var width: float = minf(360.0 * scale, vp.x * 0.86)
	_confirm.custom_minimum_size = Vector2(width, 0)
	_confirm.position = Vector2(-width * 0.5, -70.0 * scale)
	add_child(_confirm)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", int(10.0 * scale))
	_confirm.add_child(vb)

	var q := UI.heading("Go through with it?", scale)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(q)

	var sign := UI.choice("Do it", scale, width - 60.0 * scale)
	sign.alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign.pressed.connect(_on_sign)
	vb.add_child(sign)

	var no := UI.choice("Think it over", scale, width - 60.0 * scale)
	no.alignment = HORIZONTAL_ALIGNMENT_CENTER
	no.pressed.connect(_on_decline)
	vb.add_child(no)

	# Focus the REFUSAL, not the commitment. L49 makes this panel the
	# gate on anything binding, and a gate whose default answer is "yes"
	# is not a gate — a stray A press must not sign anything.
	no.grab_focus()


## Focus off (and back on) for everything that is not the confirm panel.
func _freeze_base(frozen: bool) -> void:
	for c in find_children("*", "Button", true, false):
		var b := c as Button
		if _confirm != null and _confirm.is_ancestor_of(b):
			continue
		b.focus_mode = Control.FOCUS_NONE if frozen else Control.FOCUS_ALL


func _dismiss_confirm() -> void:
	if _confirm != null:
		_confirm.queue_free()
		_confirm = null
	_freeze_base(false)
	# Put the highlight back on the conversation, or a pad is left with
	# nothing selected and the menu reads as dead.
	if _topic_box != null and _topic_box.get_child_count() > 0:
		(_topic_box.get_child(0) as Button).grab_focus()


func _on_sign() -> void:
	var t := _pending
	_pending = {}
	_dismiss_confirm()
	_apply_effect(t)


func _on_decline() -> void:
	_pending = {}
	_dismiss_confirm()
	_say("They nod, and the paper goes back in the drawer.")


## Non-binding effects apply at once; binding ones only after Sign.
func _apply_effect(t: Dictionary) -> void:
	var effect := String(t.get("effect", ""))
	var arg: Variant = t.get("effect_arg", null)
	var state: TownWorldState = _systems["state"]
	match effect:
		"hire":
			var line := Apprenticeship.hire(state, String(arg))
			_npc.say_line("You're hired.")
			_say(line)
		"take_contract":
			var ok: bool = Boards.take(state, String(arg))
			_say("Done, and witnessed. The terms are the terms — don't make anyone repeat them." if ok
				else "That paper's already spoken for.")
		"buy_drink":
			var r: Dictionary = Rumors.buy_drink(state)
			if bool(r.get("ok", false)):
				_say("Mara slides the ale over. \"" + String(r["text"]) + "\"\n— " + String(r["source"]))
			else:
				_say("Mara laughs. \"Coin first, thirsty.\"")
		"ask_rumor":
			var r2: Dictionary = Rumors.search(state)
			_say("\"" + String(r2["text"]) + "\"\n— " + String(r2["source"]))
		"open_contracts":
			Boards.open_contracts_ui(state)
		"open_market":
			Boards.open_market_ui(state)
		"":
			_say("They shrug, and the moment passes.")
		_:
			_say("That isn't something they can do for you.")


func _say(text: String) -> void:
	_dialog.text = text


func close() -> void:
	if current == self:
		current = null
	UI.pop_modal(self)
	queue_free()
