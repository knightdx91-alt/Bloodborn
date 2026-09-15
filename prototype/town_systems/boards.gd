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
	var ui := CanvasLayer.new()
	var root := Engine.get_main_loop()
	if root is SceneTree:
		(root as SceneTree).root.add_child(ui)
	else:
		return
	_open_ui = ui
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-280, -220)
	panel.custom_minimum_size = Vector2(560, 440)
	ui.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)
	var h := Label.new()
	h.text = header
	vb.add_child(h)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(540, 330)
	vb.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	if rows.is_empty():
		var e := Label.new()
		e.text = "Nothing pinned today. The town's quiet — suspiciously quiet."
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(e)
	for r in rows:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		list.add_child(box)
		var t := Label.new()
		var line := String(r[title_key])
		if r.has("taken") and bool(r["taken"]):
			line += "  [taken]"
		elif r.has(pay_key) and pay_key != "":
			line += "  — %d pennies" % int(r[pay_key])
		elif pay_key != "":
			line += "  — %d pennies the %s" % [int(r[pay_key]), String(r.get("unit", ""))]
		t.text = line
		box.add_child(t)
		if detail_key != "" and String(r.get(detail_key, "")) != "":
			var d := Label.new()
			d.text = String(r[detail_key])
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			d.custom_minimum_size = Vector2(520, 0)
			box.add_child(d)
		if r.has("kind"):
			var k := Label.new()
			k.text = "  [%s]" % String(r[kind_key])
			box.add_child(k)
	var close_b := Button.new()
	close_b.text = "Step back"
	close_b.pressed.connect(_close_ui)
	vb.add_child(close_b)
	# The board is read-only, so the only thing to press is the way out —
	# and a pad needs it focused to press it at all.
	close_b.grab_focus()


static func _close_ui() -> void:
	if _open_ui != null:
		_open_ui.queue_free()
		_open_ui = null
