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


## Take a contract: binding, so the conversation layer confirms first.
static func take(state: TownWorldState, contract_id: String) -> bool:
	return ContractBoardRules.take(state, contract_id)


static func open_contracts_ui(state: TownWorldState) -> void:
	_open_list_ui("— CONTRACT BOARD —",
		contracts(state), state,
		"kind", "title", "detail", "pay")


static func open_market_ui(state: TownWorldState) -> void:
	_open_list_ui("— MARKET BOARD — Thornfield warehoused goods —",
		market_goods(state), state,
		"good", "good", "", "price")


static func _open_list_ui(header: String, rows: Array, _state: TownWorldState,
		kind_key: String, title_key: String, detail_key: String, pay_key: String) -> void:
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
		if r.has("taken") and bool(r["taken"]):
			line += "   — taken"
		elif pay_key != "" and r.has(pay_key):
			line += "   — %d pennies" % int(r[pay_key])
			if r.has("unit"):
				line += " the %s" % String(r["unit"])
		var t := UI.body(line, scale, width - 90.0 * scale)
		t.add_theme_font_size_override("font_size", int(20.0 * scale))
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

	# Registered BEFORE anything here takes focus. push_modal remembers
	# where the highlight was on the panel underneath so it can put it
	# back; grabbing focus first meant it remembered "nowhere", and
	# closing the board left the conversation behind it with nothing
	# selected — which on a pad is indistinguishable from a hung menu.
	UI.push_modal(ui)

	# The board is read-only, so the only thing to press is the way out —
	# and a pad needs it focused to press it at all.
	close_b.grab_focus()


static func _close_ui() -> void:
	if _open_ui != null:
		UI.pop_modal(_open_ui)
		_open_ui.queue_free()
		_open_ui = null
