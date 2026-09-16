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


## The ScrollContainer a control lives in, if any.
func _scroller(node: Node) -> ScrollContainer:
	var n: Node = node.get_parent()
	while n != null:
		if n is ScrollContainer:
			return n as ScrollContainer
		n = n.get_parent()
	return null


## On screen, thumb-sized, and something holding the highlight.
##
## A row inside a scrolling list is allowed to be below the fold — that
## is what scrolling is. It still has to fit HORIZONTALLY and still has
## to be thumb-sized; only the vertical bound is the scroller's problem,
## and the scroller itself is checked instead. Without the distinction
## this fails the moment a list is longer than its panel, which is most
## of the time.
func _fit_check(root: Node, vp: Vector2, label: String) -> void:
	var bad := ""
	var focused := false
	for bb in _buttons(root):
		var b := bb as Button
		if not b.is_visible_in_tree():
			continue
		var r := b.get_global_rect()
		var sc := _scroller(b)
		if r.end.x > vp.x + 1 or r.position.x < -1:
			bad = "'%s' off the side %s in %s" % [b.text, str(r), str(vp)]
		if sc == null:
			if r.end.y > vp.y + 1 or r.position.y < -1:
				bad = "'%s' off screen %s in %s" % [b.text, str(r), str(vp)]
		else:
			var sr := sc.get_global_rect()
			if sr.end.y > vp.y + 1 or sr.position.y < -1:
				bad = "the list itself is off screen %s in %s" % [str(sr), str(vp)]
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

	print("--- everybody is standing on the ground ---")
	# Measured off the rendered mesh, not off the numbers that produced
	# it. This exact fault has now hit three bodies — the player's spawn,
	# the townsfolk — because Fighter's model offset of -1.0 is correct
	# for a capsule CENTRED on the origin and catastrophic for a node
	# whose origin is at the feet, and the line gets copied with its
	# reassuring comment attached.
	var sunk: Array[String] = []
	var floating: Array[String] = []
	var measured := 0
	for n in pop.get_children():
		if not (n is TownNPC):
			continue
		var who := n as TownNPC
		var low := INF
		for m in who.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			if mi.mesh == null:
				continue
			var box := mi.get_aabb()
			# Every corner, because the mesh may be rotated.
			for i in 8:
				var corner: Vector3 = mi.global_transform * box.get_endpoint(i)
				low = minf(low, corner.y)
		if low == INF:
			continue
		measured += 1
		var ground: float = who.global_position.y
		if low < ground - 0.25:
			sunk.append("%s %.2fm under" % [who.display_name, ground - low])
		elif low > ground + 0.35:
			floating.append("%s %.2fm above" % [who.display_name, low - ground])
	_ok("every NPC's body was measurable", measured > 0, "no meshes found to measure")
	_ok("nobody is buried", sunk.is_empty(), ", ".join(sunk))
	_ok("and nobody is hovering", floating.is_empty(), ", ".join(floating))

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
	# Reported from play: "the other menu doesn't close". It was still
	# drawn behind the board, so two panels were on screen and only one
	# of them did anything.
	_ok("and is out of sight while the board is up",
		not ConversationUI.current.visible,
		"the dialogue panel is still drawn behind the board")
	await _press_cancel()
	_ok("B closes the board, not the conversation",
		ConversationUI.current != null and UI.modal_open(),
		"cancel took out the conversation too")
	_ok("and the conversation is visible again",
		ConversationUI.current != null and ConversationUI.current.visible,
		"the dialogue panel stayed hidden after the board closed")
	if ConversationUI.current != null:
		var regained := false
		for bb in _buttons(ConversationUI.current):
			if (bb as Button).has_focus():
				regained = true
		_ok("and the conversation gets the highlight back", regained, "nothing focused")
		await _press_cancel()
	_ok("B again leaves the conversation", not UI.modal_open(), "something still open")

	print("--- taking a job off the board ---")
	# Reported from play: "I can't click on any job to accept it." The
	# rows were labels.
	var fresh := TownWorldState.new()
	Boards.open_contracts_ui(fresh)
	await _settle()
	var board := UI.top_modal()
	var job: Button = null
	for bb in _buttons(board):
		var b := bb as Button
		if b.text != "Step back":
			job = b
			break
	_ok("a job on the board is pressable", job != null,
		"every row is a label — nothing to accept")
	if job != null:
		_ok("and the board opens with a job selected, not the exit",
			job.has_focus(), "focus was elsewhere")
		var before := fresh.contracts_taken.size()
		job.pressed.emit()
		await _settle()
		_ok("taking one puts the gate up first", UI.confirm_is_open(board),
			"it took the job with no confirm — L49")
		_ok("and nothing is taken yet", fresh.contracts_taken.size() == before,
			"the contract was taken before the gate was answered")

		var take_btn: Button = null
		var leave_btn: Button = null
		for bb in _buttons(board):
			var b := bb as Button
			if b.text == "Take it":
				take_btn = b
			elif b.text == "Leave it":
				leave_btn = b
		_ok("the gate offers both answers", take_btn != null and leave_btn != null,
			"missing a button")
		if leave_btn != null:
			_ok("and opens on the refusal", leave_btn.has_focus(),
				"focus was not on 'Leave it'")
		if take_btn != null:
			take_btn.pressed.emit()
			await _settle()
			_ok("saying yes takes the job",
				fresh.contracts_taken.size() == before + 1,
				"contracts taken went %d -> %d"
					% [before, fresh.contracts_taken.size()])
			_ok("and the row says so", job.text.ends_with("taken"),
				"the row still reads '%s'" % job.text)
			_ok("and cannot be taken twice", job.focus_mode == Control.FOCUS_NONE,
				"the taken row is still selectable")
	Boards._close_ui()
	await _settle()

	print("--- the gate does not cover what it is asking about ---")
	# Reported from play: "there is another small screen that pops up, so
	# you can't read the other one below it."
	var gstate := TownWorldState.new()
	ConversationUI.open(binder, {"state": gstate})
	await _settle()
	var gui: ConversationUI = ConversationUI.current
	var goffer: Button = null
	for bb in _buttons(gui):
		for tp in binder.topics:
			if String(tp.get("intent", "")) == "offer_contract" \
					and (bb as Button).text == String(tp.get("topic", "")):
				goffer = bb as Button
	if goffer != null:
		var offer_text := goffer.text
		goffer.pressed.emit()
		await _settle()
		var gate: Control = gui.get_meta("ui_confirm", null) as Control
		_ok("the gate is up", gate != null and UI.confirm_is_open(gui), "no gate")
		if gate != null:
			# Nothing from the conversation may still be drawn behind it.
			var behind: Array[String] = []
			for c in gui.get_children():
				if c is CanvasItem and c != gate and (c as CanvasItem).visible:
					behind.append(c.name)
			_ok("nothing is left drawn behind it", behind.is_empty(),
				"still visible: %s" % ", ".join(behind))
			# And it has to say what it is asking about, or hiding the
			# panel behind it just loses the terms instead of covering
			# them.
			var said := ""
			for l in gate.find_children("*", "Label", true, false):
				said += (l as Label).text
			_ok("and states the terms itself", said.length() > 40,
				"the gate reads '%s'" % said)
			var vp2: Vector2 = get_viewport().get_visible_rect().size
			for bb in _buttons(gate):
				var gb := bb as Button
				var gr := gb.get_global_rect()
				_ok("'%s' is on screen" % gb.text,
					gr.end.y <= vp2.y + 1 and gr.position.y >= -1
						and gr.end.x <= vp2.x + 1 and gr.position.x >= -1,
					"at %s in %s" % [str(gr), str(vp2)])
		UI.confirm_decline(gui)
		await _settle()
		_ok("declining brings the conversation back",
			gui.get_node_or_null(".") != null and _buttons(gui).size() > 0,
			"the conversation did not come back")
		var back_visible := false
		for c in gui.get_children():
			if c is CanvasItem and (c as CanvasItem).visible:
				back_visible = true
		_ok("and it is visible again", back_visible, "still hidden after declining")
		_ok("and the offer is still on the list",
			offer_text != "", "lost track of the offer")
	if ConversationUI.current != null:
		ConversationUI.current.close()
		await _settle()

	print("--- L92: every topic answers to the world ---")
	# The rule is only a rule if a new effect cannot be added without
	# deciding what the world says about it. This is what stops L92
	# decaying into a habit, the way L49's whitelist did.
	var uncovered := ConversationUI.uncovered_effects()
	_ok("every effect in the roster has a resolver", uncovered.is_empty(),
		"no world-check for: %s" % ", ".join(uncovered))

	# And a case that is neither a contract nor a hire, to show the
	# mechanism is general rather than two special cases wearing a table.
	var broke := TownWorldState.new()
	broke.coin = 0
	var drinker: TownNPC = null
	var drink_topic := ""
	for n in pop.get_children():
		if not (n is TownNPC):
			continue
		for tp in (n as TownNPC).topics:
			if String(tp.get("effect", "")) == "buy_drink" and drinker == null:
				drinker = n as TownNPC
				drink_topic = String(tp.get("topic", ""))
	_ok("somebody sells a drink", drinker != null, "nobody does")
	if drinker != null:
		ConversationUI.open(drinker, {"state": broke})
		await _settle()
		var offered_free := false
		var says_broke := false
		for bb in _buttons(ConversationUI.current):
			var bt := (bb as Button).text
			if bt == drink_topic:
				offered_free = true
			elif bt.begins_with(drink_topic) and bt.ends_with("no coin"):
				says_broke = true
		_ok("an empty purse is the world contradicting an offer too",
			not offered_free, "'%s' offered with no coin" % drink_topic)
		_ok("and the topic says so", says_broke, "no '— no coin' topic appeared")
		ConversationUI.current.close()
		await _settle()

	print("--- you can carry more than one job ---")
	# "One piece of work at a time" was implemented here and was WRONG:
	# you can take as much work as you can find. The only thing that
	# makes no sense is taking THE SAME job twice. This checks the
	# distinction, in the direction the mistake went.
	var busy := TownWorldState.new()
	var master: TownNPC = null
	var hire_topic := ""
	var other_job := ""
	for n in pop.get_children():
		if not (n is TownNPC):
			continue
		for tp in (n as TownNPC).topics:
			if String(tp.get("effect", "")) == "hire" and master == null:
				master = n as TownNPC
				hire_topic = String(tp.get("topic", ""))
	_ok("somebody offers an apprenticeship", master != null, "nobody does")
	if master != null:
		for tp in master.topics:
			if String(tp.get("effect", "")) == "take_contract":
				other_job = String(tp.get("topic", ""))
		# Take a job somewhere else entirely, then come back.
		Boards.take(busy, String(Boards.contracts(busy)[0]["id"]))
		ConversationUI.open(master, {"state": busy})
		await _settle()
		var offers_hire := false
		var offers_other := false
		for bb in _buttons(ConversationUI.current):
			var bt := (bb as Button).text
			if bt == hire_topic:
				offers_hire = true
			if other_job != "" and bt == other_job:
				offers_other = true
		_ok("carrying work does not stop an apprenticeship being offered",
			offers_hire, "'%s' was withheld while carrying work" % hire_topic)
		if other_job != "":
			_ok("nor another job", offers_other,
				"'%s' was withheld while carrying work" % other_job)
		ConversationUI.current.close()
		await _settle()

		# And the board still hands out second jobs — just not the same one.
		Boards.open_contracts_ui(busy)
		await _settle()
		var board2 := UI.top_modal()
		var pressable := 0
		for bb in _buttons(board2):
			if (bb as Button).text != "Step back":
				pressable += 1
		_ok("the board still offers other jobs", pressable > 0,
			"nothing pressable while carrying work")
		# A taken row is deliberately NOT a button any more — it is a dim
		# label, so it cannot be pressed and the board still does not lie
		# about what work exists. So look for the text, not for a button:
		# an earlier version of this check searched buttons only and
		# reported the row missing when it was right there.
		var taken_rows := 0
		for l in board2.find_children("*", "Label", true, false):
			if (l as Label).text.ends_with("taken"):
				taken_rows += 1
		_ok("and marks the one already taken", taken_rows >= 1,
			"no '— taken' row on the board")
		Boards._close_ui()
		await _settle()

	print("--- the town knows what you have already taken ---")
	# Reported from play: Carter Pell went on offering a job that had
	# already been taken off the board.
	var pstate := TownWorldState.new()
	var giver: TownNPC = null
	var job_id := ""
	var job_topic := ""
	for n in pop.get_children():
		if not (n is TownNPC):
			continue
		for tp in (n as TownNPC).topics:
			if String(tp.get("effect", "")) == "take_contract" and giver == null:
				giver = n as TownNPC
				job_id = String(tp.get("effect_arg", ""))
				job_topic = String(tp.get("topic", ""))
	_ok("somebody offers a contract by name", giver != null, "nobody does")
	if giver != null:
		ConversationUI.open(giver, {"state": pstate})
		await _settle()
		var offers_it := false
		for bb in _buttons(ConversationUI.current):
			if (bb as Button).text == job_topic:
				offers_it = true
		_ok("and offers it while it is free", offers_it,
			"'%s' was not on the list to begin with" % job_topic)
		ConversationUI.current.close()
		await _settle()

		# Take it elsewhere — off the board — then come back.
		Boards.take(pstate, job_id)
		ConversationUI.open(giver, {"state": pstate})
		await _settle()
		var still_offered := false
		var reports := false
		for bb in _buttons(ConversationUI.current):
			var bt := (bb as Button).text
			if bt == job_topic:
				still_offered = true
			elif bt.begins_with(job_topic) and bt.ends_with("taken"):
				reports = true
		_ok("then stops offering it once it is taken", not still_offered,
			"'%s' is still offered as though it were free" % job_topic)
		_ok("and offers to report for duty instead", reports,
			"no '— taken' topic appeared")
		ConversationUI.current.close()
		await _settle()

	print("")
	print("npc UI: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
