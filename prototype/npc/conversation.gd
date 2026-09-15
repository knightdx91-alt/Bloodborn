class_name ConversationUI
extends CanvasLayer
## Text conversation: walk up, hold to talk, choose a topic.
## The model emits an intent from a whitelist; the game validates it
## (plan §4). Anything binding ends in a confirm panel. No LLM in the
## prototype — voice cards are carried by the authored lines.

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
	ui._build()
	current = ui


func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.position = Vector2(-260, -330)
	panel.size = Vector2(520, 300)
	panel.custom_minimum_size = Vector2(520, 300)
	add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	var head := Label.new()
	head.text = "%s — %s" % [_npc.display_name, _npc.role]
	vb.add_child(head)
	_dialog = RichTextLabel.new()
	_dialog.bbcode_enabled = false
	_dialog.scroll_following = true
	_dialog.custom_minimum_size = Vector2(500, 110)
	_dialog.text = _npc.greeting()
	vb.add_child(_dialog)
	_topic_box = VBoxContainer.new()
	_topic_box.add_theme_constant_override("separation", 4)
	vb.add_child(_topic_box)
	for t in _npc.topics:
		var b := Button.new()
		b.text = String(t.get("topic", "..."))
		b.pressed.connect(_on_topic.bind(t))
		_topic_box.add_child(b)
	var leave := Button.new()
	leave.text = "Leave"
	leave.pressed.connect(close)
	vb.add_child(leave)


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
	_say(line + "\n\n[This binds you, or costs you coin. Go through with it?]")
	_confirm = PanelContainer.new()
	_confirm.set_anchors_preset(Control.PRESET_CENTER)
	_confirm.position = Vector2(-160, -60)
	_confirm.custom_minimum_size = Vector2(320, 120)
	add_child(_confirm)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_confirm.add_child(vb)
	var q := Label.new()
	q.text = "Go through with it?"
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(q)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	var sign := Button.new()
	sign.text = "Do it"
	sign.pressed.connect(_on_sign)
	hb.add_child(sign)
	var no := Button.new()
	no.text = "Think it over"
	no.pressed.connect(_on_decline)
	hb.add_child(no)


func _on_sign() -> void:
	var t := _pending
	_pending = {}
	if _confirm != null:
		_confirm.queue_free()
		_confirm = null
	_apply_effect(t)


func _on_decline() -> void:
	_pending = {}
	if _confirm != null:
		_confirm.queue_free()
		_confirm = null
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
	queue_free()
