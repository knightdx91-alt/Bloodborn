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
var _pending: Dictionary = {}
var _topic_width := 0.0
var _topic_scale := 1.0
## What the world looked like when the topic list was last built.
var _stamp := ""


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
	_topic_width = width - 60.0 * scale
	_topic_scale = scale
	_fill_topics()

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
	if UI.confirm_is_open(self):
		UI.confirm_decline(self)
	else:
		close()


## Build the topic buttons from what the world currently looks like.
func _fill_topics() -> void:
	for c in _topic_box.get_children():
		c.queue_free()
	for t in _npc.topics:
		var shown := _resolve(t)
		# An empty answer means the world does not support saying this at
		# all, and the topic is simply absent. See WITHHOLD below.
		if shown.is_empty():
			continue
		var b := UI.choice(String(shown.get("topic", "...")), _topic_scale, _topic_width)
		b.pressed.connect(_on_topic.bind(shown))
		_topic_box.add_child(b)
	_stamp = _world_stamp()


# --- Topics answer to the world (L92) ----------------------------------
#
# A topic is a CANDIDATE, not a script. Every one is resolved against
# world state at the moment the list is built, and a topic the world
# contradicts is never offered as though nothing had happened.
#
# Reported from play: a contract taken off the board was still offered by
# the man who posted it, with the paper already in the player's hand.
# That is the same failure as a quest-giver repeating a finished quest,
# and it makes the town look like it is not listening.
#
# EVERY effect an NPC can offer must appear in this table. That is the
# whole point of the table: a new effect added without an entry fails the
# harness instead of quietly shipping as a static line. L49's whitelist
# was re-implemented verbatim from a paragraph that did not say it had
# been amended — a rule that lives only in prose gets un-followed by the
# next person to read the prose.
#
# Prefer CHANGING a topic to removing one — for the thing the player
# actually did. "Escort the Vellmark wagon?" becoming "— taken", with
# somewhere to be and a time to be there, is a town that noticed.
#
# WITHHOLD (return {}) is for the opposite case: an offer that was never
# theirs to take right now. Reported from play — "those options probably
# shouldn't appear at all if you've already accepted a job, why would
# it?" — and that is exactly right. Dressing up an offer nobody would
# make is worse than not making it: a greyed "— unavailable" row is the
# game admitting it wrote a line it cannot honour. A man with sense does
# not offer work to somebody already spoken for; he says nothing about
# it and talks about the road instead.
const RESOLVERS := {
	"": "_topic_as_authored",
	"ask_rumor": "_topic_as_authored",
	"open_contracts": "_topic_as_authored",
	"open_market": "_topic_as_authored",
	"hire": "_topic_if_unhired",
	"take_contract": "_topic_if_untaken",
	"buy_drink": "_topic_if_affordable",
}


## Effects used anywhere in the roster that no resolver covers. The
## harness fails on a non-empty answer, which is what makes L92 a rule
## rather than a habit.
static func uncovered_effects() -> Array:
	var missing: Array = []
	for data in Roster.all():
		for t in data.get("topics", []):
			var e := String((t as Dictionary).get("effect", ""))
			if not RESOLVERS.has(e) and not missing.has(e):
				missing.append(e)
	return missing


func _resolve(t: Dictionary) -> Dictionary:
	var state: TownWorldState = _systems.get("state", null)
	if state == null:
		return t
	var effect := String(t.get("effect", ""))
	if not RESOLVERS.has(effect):
		# Unknown effect: say so in the list rather than offering it. An
		# offer the game cannot honour is worse than a visible gap.
		var broken := t.duplicate()
		broken["topic"] = "%s   — unavailable" % String(t.get("topic", ""))
		broken["intent"] = "none"
		broken["effect"] = ""
		broken["line"] = "They start to answer, then think better of it."
		return broken
	return call(String(RESOLVERS[effect]), t, state)


## Nothing in the world can contradict this one.
func _topic_as_authored(t: Dictionary, _state: TownWorldState) -> Dictionary:
	return t


func _topic_if_untaken(t: Dictionary, state: TownWorldState) -> Dictionary:
	var arg := _arg(t)
	if arg == "" or not state.contracts_taken.has(arg):
		# Carrying somebody else's work already: this is not an offer
		# anyone would make, so it is not made.
		if _committed(state):
			return {}
		return t
	var done := t.duplicate()
	done["topic"] = "%s   — taken" % String(t.get("topic", ""))
	done["intent"] = "none"
	done["effect"] = ""
	done["line"] = Boards.duty_line(state, arg)
	return done


func _topic_if_unhired(t: Dictionary, state: TownWorldState) -> Dictionary:
	var arg := _arg(t)
	if arg == "" or not state.hired:
		# Taking somebody on is a bigger commitment than a contract, and
		# no master offers it to somebody already carrying work.
		if _committed(state):
			return {}
		return t
	var spoken := t.duplicate()
	var mine: bool = state.apprentice_master == arg
	spoken["topic"] = "%s   — %s" % [String(t.get("topic", "")),
		"done" if mine else "spoken for"]
	spoken["intent"] = "none"
	spoken["effect"] = ""
	spoken["line"] = Apprenticeship.duty_line(state, arg)
	return spoken


## An empty purse is the world contradicting an offer just as much as a
## contract already signed is.
func _topic_if_affordable(t: Dictionary, state: TownWorldState) -> Dictionary:
	if state.coin >= RumourMill.drink_price():
		return t
	var broke := t.duplicate()
	broke["topic"] = "%s   — no coin" % String(t.get("topic", ""))
	broke["intent"] = "none"
	broke["effect"] = ""
	broke["line"] = "Mara eyes your purse. \"Coin first, thirsty.\""
	return broke


## Is the player already carrying accepted work?
##
## One piece at a time. Reported from play, and it is the honest reading
## of the fiction: you have the paper in your hand, and the next person
## you speak to can see that.
func _committed(state: TownWorldState) -> bool:
	return not state.contracts_taken.is_empty()


func _arg(t: Dictionary) -> String:
	var raw: Variant = t.get("effect_arg", null)
	return String(raw) if raw is String else ""


## Cheap description of the parts of the world the topics depend on.
func _world_stamp() -> String:
	var state: TownWorldState = _systems.get("state", null)
	if state == null:
		return ""
	return "%d|%s|%s" % [state.contracts_taken.size(), str(state.hired),
		state.apprentice_master]


## The list is rebuilt when that world changes underneath it — including
## while this conversation is still open, which is what happens when the
## contract board is opened from it and a job taken there.
func _process(_delta: float) -> void:
	if _topic_box == null or UI.confirm_is_open(self):
		return
	if _world_stamp() == _stamp:
		return
	var had := -1
	for i in _topic_box.get_child_count():
		if (_topic_box.get_child(i) as Button).has_focus():
			had = i
	_fill_topics()
	if had >= 0:
		await get_tree().process_frame
		if had < _topic_box.get_child_count():
			(_topic_box.get_child(had) as Button).grab_focus()


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


## Anything binding goes through the one gate in ui.gd — the same panel,
## the same rules, whether the job came from a person or off the board.
func _show_confirm(line: String) -> void:
	_say(line + "\n\n[This binds you, or costs you coin.]")
	# The terms go INSIDE the gate. It used to ask "Go through with it?"
	# over the top of the dialogue box that held the actual offer, so the
	# one thing you needed to read was the one thing it covered.
	UI.confirm(self,
		"%s\n\nThis binds you, or costs you coin. Go through with it?" % line,
		"Do it", "Think it over", _on_sign, _on_decline)


func _on_sign() -> void:
	var t := _pending
	_pending = {}
	_apply_effect(t)


func _on_decline() -> void:
	_pending = {}
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
