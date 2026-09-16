extends Node3D
## Does the NPC interface actually work on a pad?
##
## Run it:
##     godot --path prototype --rendering-driver opengl3 qacheck.tscn
##
## Kept in the repo rather than thrown away, because it checks things the
## eye checks badly and a screenshot cannot check at all: that every
## button is on screen and thumb-sized at three very different viewport
## shapes, that focus is where it should be — and ONLY where it should
## be — when the L49 confirm gate is up, and that B backs out one layer
## at a time with the board open on top of a conversation.
##
## It found four real faults the first time it ran, including a script
## that did not compile.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _settle() -> void:
	for i in 6: await get_tree().process_frame


func _press_cancel() -> void:
	var e := InputEventAction.new()
	e.action = "ui_cancel"
	e.pressed = true
	Input.parse_input_event(e)
	await _settle()
	var up := InputEventAction.new()
	up.action = "ui_cancel"
	up.pressed = false
	Input.parse_input_event(up)
	await _settle()


func _buttons(root: Node) -> Array:
	var out: Array = []
	for b in root.find_children("*", "Button", true, false):
		out.append(b as Button)
	return out


## On screen, thumb-sized, and something holding the highlight.
func _fit_check(root: Node, vp: Vector2, label: String) -> void:
	var bad := ""
	var focused := false
	for bb in _buttons(root):
		var b := bb as Button
		if not b.is_visible_in_tree():
			continue
		var r := b.get_global_rect()
		if r.end.y > vp.y + 1 or r.position.y < -1 or r.end.x > vp.x + 1 or r.position.x < -1:
			bad = "'%s' off screen %s in %s" % [b.text, str(r), str(vp)]
		if r.size.y < 44.0:
			bad = "'%s' only %dpx tall" % [b.text, int(r.size.y)]
		if b.has_focus():
			focused = true
	if not focused:
		bad = "nothing focused"
	_ok(label, bad == "", bad)


func _ready() -> void:
	var t: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(t)
	await get_tree().create_timer(2.5).timeout

	var pop: Node = t.get_node_or_null("Population")
	_ok("the town has a population", pop != null, "no Population node")
	if pop == null:
		print("FAILED: no population")
		get_tree().quit()
		return

	var npc: TownNPC = null
	var binder: TownNPC = null
	for n in pop.get_children():
		if not (n is TownNPC):
			continue
		var c := n as TownNPC
		if npc == null and c.topics.size() > 0:
			npc = c
		for tp in c.topics:
			if String(tp.get("intent", "")) == "offer_contract":
				binder = c
	_ok("someone has something to say", npc != null, "no NPC has topics")
	_ok("someone offers a contract", binder != null, "no offer_contract topic anywhere")
	if npc == null:
		print("FAILED: nobody to talk to")
		get_tree().quit()
		return

	var state := TownWorldState.new()

	print("--- the conversation, at three shapes ---")
	for size in [Vector2i(900, 600), Vector2i(1080, 2400), Vector2i(640, 360)]:
		get_window().size = size
		await _settle()
		ConversationUI.open(npc, {"state": state})
		await _settle()
		_fit_check(ConversationUI.current, Vector2(size),
			"fits and focuses at %dx%d" % [size.x, size.y])
		if size == Vector2i(900, 600):
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/qa/ui_convo.png")
		ConversationUI.current.close()
		await _settle()

	print("--- the walker is frozen while a menu is up ---")
	_ok("no menu, no freeze", not UI.modal_open(), "modal_open() true with nothing open")
	get_window().size = Vector2i(900, 600)
	await _settle()
	ConversationUI.open(npc, {"state": state})
	await _settle()
	_ok("talking counts as a menu", UI.modal_open(), "modal_open() false mid-conversation")

	print("--- B backs out ---")
	await _press_cancel()
	_ok("B leaves the conversation", ConversationUI.current == null, "still open after cancel")
	_ok("and the walker is free again", not UI.modal_open(), "modal_open() stuck true")

	print("--- the confirm gate ---")
	if binder != null:
		ConversationUI.open(binder, {"state": state})
		await _settle()
		var ui: ConversationUI = ConversationUI.current
		var offer: Button = null
		for bb in _buttons(ui):
			for tp in binder.topics:
				if String(tp.get("intent", "")) == "offer_contract" \
						and (bb as Button).text == String(tp.get("topic", "")):
					offer = bb as Button
		_ok("the offer is on the list", offer != null, "no button for the offer")
		if offer != null:
			offer.pressed.emit()
			await _settle()
			var focus_on := ""
			var loose: Array[String] = []
			for bb in _buttons(ui):
				var b := bb as Button
				if b.has_focus():
					focus_on = b.text
				if b.focus_mode != Control.FOCUS_NONE \
						and b.text != "Do it" and b.text != "Think it over":
					loose.append(b.text)
			_ok("the gate opens on the refusal", focus_on == "Think it over",
				"focus was on '%s'" % focus_on)
			_ok("nothing behind the gate can be reached", loose.is_empty(),
				"still focusable: %s" % ", ".join(loose))

			await _press_cancel()
			_ok("B declines rather than leaving", ConversationUI.current != null,
				"cancel closed the whole conversation")
			if ConversationUI.current != null:
				var back := ""
				for bb in _buttons(ConversationUI.current):
					if (bb as Button).has_focus():
						back = (bb as Button).text
				_ok("the highlight comes back", back != "", "nothing focused after declining")
				ConversationUI.current.close()
				await _settle()

	print("--- the board ---")
	for size in [Vector2i(900, 600), Vector2i(640, 360)]:
		get_window().size = size
		await _settle()
		Boards.open_contracts_ui(state)
		await _settle()
		var layer := UI.top_modal()
		_ok("the board is the top menu at %dx%d" % [size.x, size.y],
			layer != null, "nothing on the modal stack")
		if layer != null:
			_fit_check(layer, Vector2(size), "board fits and focuses at %dx%d" % [size.x, size.y])
		if size == Vector2i(900, 600):
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/tmp/qa/ui_board.png")
		# The list is longer than the panel and the only focusable thing
		# on it is the way out, so down has to scroll rather than move a
		# highlight — otherwise a pad reads five contracts and stops.
		if layer != null:
			var sc: ScrollContainer = layer.get("scroll")
			_ok("the board has a list to scroll at %dx%d" % [size.x, size.y],
				sc != null, "no ScrollContainer handed to the panel")
			if sc != null and sc.get_v_scroll_bar().max_value > sc.size.y:
				var before := sc.scroll_vertical
				Input.action_press("ui_down")
				await _settle()
				await _settle()
				Input.action_release("ui_down")
				await _settle()
				_ok("down scrolls the board at %dx%d" % [size.x, size.y],
					sc.scroll_vertical > before,
					"stuck at %d" % sc.scroll_vertical)
		await _press_cancel()
		_ok("B steps back from the board at %dx%d" % [size.x, size.y],
			not UI.modal_open(), "board still up after cancel")

	print("--- the board on top of a conversation ---")
	get_window().size = Vector2i(900, 600)
	await _settle()
	ConversationUI.open(npc, {"state": state})
	await _settle()
	Boards.open_contracts_ui(state)
	await _settle()
	var still_reachable: Array[String] = []
	for bb in _buttons(ConversationUI.current):
		if (bb as Button).focus_mode != Control.FOCUS_NONE:
			still_reachable.append((bb as Button).text)
	_ok("the conversation underneath stops taking focus", still_reachable.is_empty(),
		"still focusable: %s" % ", ".join(still_reachable))
	await _press_cancel()
	_ok("B closes the board, not the conversation",
		ConversationUI.current != null and UI.modal_open(),
		"cancel took out the conversation too")
	if ConversationUI.current != null:
		var regained := false
		for bb in _buttons(ConversationUI.current):
			if (bb as Button).has_focus():
				regained = true
		_ok("and the conversation gets the highlight back", regained, "nothing focused")
		await _press_cancel()
	_ok("B again leaves the conversation", not UI.modal_open(), "something still open")

	print("")
	print("npc UI: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
