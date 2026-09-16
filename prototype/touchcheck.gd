extends Node
## Can a finger press things, and does it still not fire a phantom swing?
##
## This exists because the answer to the first question was NO for every
## button in the game — the launcher, a conversation, the contract board
## — and nothing noticed, because the pad was doing all the pressing.

var _fails: Array[String] = []
var _hits := 0


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _settle() -> void:
	for i in 8: await get_tree().process_frame


func _tap(at: Vector2) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = at
	t.pressed = true
	Input.parse_input_event(t)
	await _settle()
	var u := InputEventScreenTouch.new()
	u.index = 0
	u.position = at
	u.pressed = false
	Input.parse_input_event(u)
	await _settle()


func _press_button(b: Button) -> int:
	_hits = 0
	await _tap(b.get_global_rect().get_center())
	return _hits


func _ready() -> void:
	_ok("touch-to-mouse emulation is on", Input.is_emulating_mouse_from_touch(),
		"off — no Button in the game can be pressed with a finger")

	# --- the launcher ---
	var l: Node = load("res://launcher.tscn").instantiate()
	add_child(l)
	await _settle()
	await _settle()
	var lb := (l.find_children("*", "Button", true, false)[0]) as Button
	# Unhook the real handler first: it changes scene, which frees this
	# harness mid-test. (That it did so is itself the proof the tap
	# landed, but a test that deletes itself reports nothing.)
	for c in lb.pressed.get_connections():
		lb.pressed.disconnect(c["callable"])
	lb.pressed.connect(func() -> void: _hits += 1)
	_ok("a finger presses a launcher button", await _press_button(lb) == 1,
		"tapping '%s' did nothing" % lb.text)
	l.queue_free()
	await _settle()

	# --- a conversation and the board ---
	var t: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(t)
	await get_tree().create_timer(2.5).timeout
	var npc: TownNPC = null
	for n in t.get_node("Population").get_children():
		if n is TownNPC and (n as TownNPC).topics.size() > 0 and npc == null:
			npc = n
	ConversationUI.open(npc, {"state": TownWorldState.new()})
	await _settle()
	var leave: Button = null
	for b in ConversationUI.current.find_children("*", "Button", true, false):
		if (b as Button).text == "Leave":
			leave = b as Button
	_ok("the conversation has a Leave button", leave != null, "none found")
	if leave != null:
		await _tap(leave.get_global_rect().get_center())
		_ok("a finger leaves a conversation", ConversationUI.current == null,
			"tapping Leave did nothing")

	Boards.open_contracts_ui(TownWorldState.new())
	await _settle()
	var step: Button = null
	for b in UI.top_modal().find_children("*", "Button", true, false):
		if (b as Button).text == "Step back":
			step = b as Button
	_ok("the board has a Step back button", step != null, "none found")
	if step != null:
		await _tap(step.get_global_rect().get_center())
		_ok("a finger steps back from the board", not UI.modal_open(),
			"tapping Step back did nothing")

	# --- the walker's own chips ---
	var walker: TownWalker = null
	for n in t.get_children():
		if n is TownWalker:
			walker = n
	var back: Button = null
	for b in walker.find_children("*", "Button", true, false):
		if (b as Button).text == "Back":
			back = b as Button
	_ok("the Back chip is there on touch", back != null and back.visible,
		"no visible Back chip")
	t.queue_free()
	await _settle()

	# --- and the drill yard must NOT swing on press ---
	var y: Node3D = load("res://main.tscn").instantiate() as Node3D
	add_child(y)
	await get_tree().create_timer(2.0).timeout
	# Let the yard actually settle. A click in the first seconds, or one
	# sent while a swing is already running, is refused by the fighter —
	# which an earlier version of this check happily reported as "mouse
	# attack is broken". Each probe below starts from rest.
	await get_tree().create_timer(3.0).timeout

	# A touch DOWN alone must not swing. This is the exact fault that had
	# emulation switched off project-wide: the synthesised click arrives
	# BEFORE the touch, so acting on it fires a swing on press.
	var swings_before: int = y.get("_swing_count")
	var d := InputEventScreenTouch.new()
	d.index = 0
	d.position = Vector2(500, 300)
	d.pressed = true
	Input.parse_input_event(d)
	await _settle()
	_ok("a press alone does not swing in the yard",
		int(y.get("_swing_count")) == swings_before,
		"swings went %d -> %d on touch-down"
			% [swings_before, int(y.get("_swing_count"))])
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = Vector2(500, 300)
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().create_timer(3.0).timeout

	# The mechanism itself: a click MARKED emulated is dropped, a real
	# one is not. That is the whole of the change.
	#
	# NOTE: the touch tap->swing path is deliberately NOT asserted here.
	# A synthetic tap produces no swing on this build OR on the one
	# before the change, so the harness cannot drive it and an assertion
	# would only be measuring the harness. That one is checked on a phone.
	var base: int = y.get("_swing_count")
	var fake := InputEventMouseButton.new()
	fake.button_index = MOUSE_BUTTON_LEFT
	fake.position = Vector2(500, 300)
	fake.global_position = Vector2(500, 300)
	fake.pressed = true
	fake.device = InputEvent.DEVICE_ID_EMULATION
	Input.parse_input_event(fake)
	await _settle()
	_ok("a click emulated from a touch does not swing",
		int(y.get("_swing_count")) == base,
		"swings went %d -> %d on an emulated click"
			% [base, int(y.get("_swing_count"))])

	await get_tree().create_timer(3.0).timeout
	var base2: int = y.get("_swing_count")
	var real := InputEventMouseButton.new()
	real.button_index = MOUSE_BUTTON_LEFT
	real.position = Vector2(500, 300)
	real.global_position = Vector2(500, 300)
	real.pressed = true
	real.device = 0
	Input.parse_input_event(real)
	await _settle()
	_ok("a real mouse click still swings",
		int(y.get("_swing_count")) > base2,
		"mouse attack is broken: swings stayed at %d" % base2)

	# --- Combat you can reach with a thumb --------------------------------
	#
	# Reported from play: "there isn't a way to do combat without a
	# controller when I'm in the hedges or the town." The gestures were
	# never the whole problem — nothing on screen said they existed, and
	# an input you cannot discover is not an input.
	#
	# Checked in BOTH scenes on purpose. They run the same script, so
	# there should be no difference; play says there is one, and a check
	# that only ever looked at the yard is how that difference stayed
	# invisible.
	for scene in ["res://main.tscn", "res://hedges.tscn"]:
		var w: Node3D = load(scene).instantiate() as Node3D
		add_child(w)
		await get_tree().create_timer(1.2).timeout
		var where := "the yard" if scene.ends_with("main.tscn") else "the Hedges"

		var atk: Button = w.get("_attack_btn")
		var dge: Button = w.get("_dodge_btn")
		var grd: Button = w.get("_guard_btn")
		_ok("%s has an attack, a dodge and a guard on screen" % where,
			atk != null and dge != null and grd != null,
			"attack=%s dodge=%s guard=%s" % [str(atk != null),
				str(dge != null), str(grd != null)])

		if atk == null:
			w.queue_free()
			await get_tree().process_frame
			continue

		_ok("and in %s they are only there for a thumb" % where,
			atk.visible == InputMode.is_touch(),
			"visible=%s while is_touch=%s"
				% [str(atk.visible), str(InputMode.is_touch())])

		var fighter: Fighter = w.get("player")
		var hits_before: int = int(w.get("_swing_count"))
		atk.pressed.emit()
		await get_tree().process_frame
		_ok("the attack button swings in %s" % where,
			int(w.get("_swing_count")) > hits_before,
			"swings %d -> %d — the button is decoration"
				% [hits_before, int(w.get("_swing_count"))])

		# Let the swing finish before asking for anything else: a fighter
		# is committed to its own attack, so a dodge during one is
		# correctly refused and would measure the wrong thing.
		for f in 120:
			await get_tree().physics_frame
		dge.pressed.emit()
		await get_tree().process_frame
		_ok("the dodge button dodges in %s" % where,
			not fighter.dodge.can_act(), "pressing Dodge did nothing")

		for f in 120:
			await get_tree().physics_frame
		grd.button_down.emit()
		await get_tree().process_frame
		var braced: bool = not fighter.parry.can_act()
		grd.button_up.emit()
		await get_tree().process_frame
		_ok("the guard button raises the guard in %s" % where, braced,
			"holding Guard did not brace")

		w.queue_free()
		await get_tree().process_frame

	print("")
	print("touch: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()

