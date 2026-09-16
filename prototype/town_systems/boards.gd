class_name Boards
extends RefCounted
## The two physical boards in the market square (content.md §3).
## Contracts are generated from actual world state — cull contracts on
## real boar pressure, escort contracts for real caravans, harvest labor
## at the real farm. The board never lies: if the contract exists, the
## problem exists. No quest-hub filler, no markers over heads.

static var _open_ui: CanvasLayer = null


## The board's postings, dressed for Thornfield.
##
## The RULE — what work exists and what it pays — now lives in
## rules/contract_board.gd, mirroring sim/Marrowmark.Sim/Town (L88).
## What is left here is the prose, which is where it belongs: a second
## town phrases the same contract differently and should not have to
## re-derive which contracts there are.
static func contracts(state: TownWorldState) -> Array:
	var out: Array = []
	for c in ContractBoardRules.generate(state):
		var row: Dictionary = (c as Dictionary).duplicate()
		match int(c["kind"]):
			ContractBoardRules.Kind.CULL:
				row["kind"] = "cull"
				row["title"] = "Cull the boars — %s" % String(c["subject"])
				row["detail"] = ("Blood-warped boars press at %s (pressure %d of 5). "
					+ "Thin them before they reach the farms.") % [
						String(c["subject"]), int(c["magnitude"])]
			ContractBoardRules.Kind.ESCORT:
				row["kind"] = "escort"
				row["title"] = "Guard the %s wagon" % String(c["subject"])
				row["detail"] = ("A wagon musters at the carter's yard for %s. "
					+ "They want %d guards. Coin, not promises.") % [
						String(c["subject"]), int(c["magnitude"])]
			ContractBoardRules.Kind.HARVEST:
				row["kind"] = "harvest"
				row["title"] = "Harvest hands — Vance farm"
				row["detail"] = ("Drover Vance wants %d hands for the harvest, up the "
					+ "north road past the burnt mill. Coin's honest and the beer's "
					+ "honest.") % int(c["magnitude"])
			_:
				row["kind"] = "smithing"
				row["title"] = "Smithing: %s" % String(c["subject"])
				row["detail"] = "Odo's commission, at the smithy west of the square. He corrects; you learn."
		out.append(row)
	return out


## The market board lists only what's warehoused in Thornfield
## (economy.md §3): grain, cloth, ale, tools.
static func market_goods(state: TownWorldState) -> Array:
	return ContractBoardRules.market(state)


## What a job-giver says about work you have ALREADY taken.
##
## The board and the people have to agree about what you have accepted.
## Reported from play: a contract taken off the board was still offered
## in conversation as though it were free, which makes the town look like
## it is not paying attention — you have the paper in your hand.
##
## Prose lives here for the same reason the postings do: the rule (who
## has taken what) is in rules/contract_board.gd, and a second town
## phrases the same duty differently.
static func duty_line(state: TownWorldState, contract_id: String) -> String:
	for r in contracts(state):
		if String(r.get("id", "")) != contract_id:
			continue
		match String(r.get("kind", "")):
			"cull":
				return ("\"That one's yours already — I've got the paper here with your "
					+ "mark on it. Go when it's light, and come back able to count.\"")
			"escort":
				return ("\"You're on that one. The wagon musters at first light by the "
					+ "carter's yard — be there before the lead pair are harnessed, and "
					+ "walk on the side the road's worst on.\"")
			"harvest":
				return ("\"Vance is expecting you. Up the north road, past the burnt "
					+ "mill. There's beer at the end of it if the weather holds.\"")
			_:
				return ("\"Odo's got that work waiting, west of the square. He "
					+ "corrects; you learn. Don't keep him.\"")
	return "\"That's yours already. See it done.\""


## Take a contract: binding, so the conversation layer confirms first.
static func take(state: TownWorldState, contract_id: String) -> bool:
	return ContractBoardRules.take(state, contract_id)


## The contract board hands out work, so its rows are things you take.
## It was read-only until a player tried to take one off it and found
## there was nothing to press — the only way to accept a job was to ask
## the right person about it in conversation, which the board itself
## gives no hint of.
static func open_contracts_ui(state: TownWorldState) -> void:
	_open_list_ui("— CONTRACT BOARD —",
		contracts(state), state,
		"kind", "title", "detail", "pay", true)


## The market board is a price list. Nothing on it is an offer, so
## nothing on it is pressable — and it says so rather than presenting
## rows that look pressable and are not.
static func open_market_ui(state: TownWorldState) -> void:
	_open_list_ui("— MARKET BOARD — Thornfield warehoused goods —",
		market_goods(state), state,
		"good", "good", "", "price", false)


static func _open_list_ui(header: String, rows: Array, _state: TownWorldState,
		kind_key: String, title_key: String, detail_key: String, pay_key: String,
		takeable: bool = false) -> void:
	_close_ui()
	var tree := Engine.get_main_loop()
	if not (tree is SceneTree):
		return
	# Built from board_panel.gd rather than a bare CanvasLayer: the script
	# has to be on the node BEFORE it enters the tree, or Godot never
	# turns its _unhandled_input callback on and B does nothing.
	var ui: CanvasLayer = load("res://town_systems/board_panel.gd").new()
	(tree as SceneTree).root.add_child(ui)
	_open_ui = ui

	var scale := UI.scale_for(ui)
	var vp: Vector2 = (tree as SceneTree).root.get_visible_rect().size
	var width: float = minf(600.0 * scale, vp.x * 0.92)
	var height: float = minf(520.0 * scale, vp.y * 0.86)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(centre)

	var panel := UI.panel()
	panel.custom_minimum_size = Vector2(width, height)
	centre.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", int(8.0 * scale))
	panel.add_child(vb)
	vb.add_child(UI.heading(header, scale))
	var status := UI.subheading(
		"Pick a job to take it." if takeable else "Prices only. Nothing here is an offer.",
		scale)
	vb.add_child(status)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	ui.set("scroll", scroll)
	scroll.custom_minimum_size = Vector2(width - 60.0 * scale, height - 130.0 * scale)
	vb.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", int(10.0 * scale))
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	if rows.is_empty():
		# content.md §3: the board never lies. An empty board means the
		# town genuinely has no work, which is worth saying out loud
		# rather than leaving a blank rectangle.
		list.add_child(UI.body(
			"Nothing pinned today. The town's quiet — suspiciously quiet.",
			scale, width - 90.0 * scale))

	for r in rows:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", int(2.0 * scale))
		list.add_child(row)

		var line := String(r[title_key])
		var taken: bool = r.has("taken") and bool(r["taken"])
		if taken:
			line += "   — taken"
		elif pay_key != "" and r.has(pay_key):
			line += "   — %d pennies" % int(r[pay_key])
			if r.has("unit"):
				line += " the %s" % String(r["unit"])

		if takeable and not taken and r.has("id"):
			# A row you can actually take. Same choice widget as every
			# other list in the game, so a pad walks it and a thumb hits
			# it, and taking one goes through L49's gate like any other
			# binding thing.
			var pick := UI.choice(line, scale, width - 90.0 * scale)
			var cid := String(r["id"])
			var title := String(r[title_key])
			pick.pressed.connect(_on_pick.bind(_state, cid, title, pick, status))
			row.add_child(pick)
		else:
			var t := UI.body(line, scale, width - 90.0 * scale)
			t.add_theme_font_size_override("font_size", int(20.0 * scale))
			if taken:
				t.add_theme_color_override("font_color", UI.DIM)
			row.add_child(t)

		if detail_key != "" and String(r.get(detail_key, "")) != "":
			var d := UI.body(String(r[detail_key]), scale, width - 90.0 * scale)
			d.add_theme_color_override("font_color", UI.DIM)
			d.add_theme_font_size_override("font_size", int(16.0 * scale))
			row.add_child(d)

	var close_b := UI.choice("Step back", scale, width - 60.0 * scale)
	close_b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_b.pressed.connect(_close_ui)
	vb.add_child(close_b)

	# The first job if there is one, so a pad lands on the work rather
	# than on the way out. Falls through to "Step back" on an empty or
	# read-only board.
	var first: Button = null
	for b in list.find_children("*", "Button", true, false):
		first = b as Button
		break

	# Registered BEFORE anything here takes focus. push_modal remembers
	# where the highlight was on the panel underneath so it can put it
	# back; grabbing focus first meant it remembered "nowhere", and
	# closing the board left the conversation behind it with nothing
	# selected — which on a pad is indistinguishable from a hung menu.
	UI.push_modal(ui)

	if first != null:
		first.grab_focus()
	else:
		close_b.grab_focus()


## Taking a job is binding — L49 — so it goes through the one gate in
## ui.gd rather than happening on the press.
static func _on_pick(state: TownWorldState, contract_id: String, title: String,
		pick: Button, status: Label) -> void:
	if _open_ui == null:
		return
	UI.confirm(_open_ui,
		"%s\n\nSigned for, and the terms are the terms. Take it?" % title,
		"Take it", "Leave it",
		func() -> void:
			var ok: bool = take(state, contract_id)
			if ok:
				pick.text = "%s   — taken" % title
				pick.focus_mode = Control.FOCUS_NONE
				pick.disabled = true
				status.text = "Taken, and witnessed. The terms are the terms."
			else:
				status.text = "That paper's already spoken for.")


static func _close_ui() -> void:
	if _open_ui != null:
		UI.pop_modal(_open_ui)
		_open_ui.queue_free()
		_open_ui = null
