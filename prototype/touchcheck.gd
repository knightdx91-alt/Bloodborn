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

	# --- and the town, which had no combat at all -------------------------
	#
	# town_player.gd said in its own header "never touches combat", and it
	# meant it: TownWalker was a bare CharacterBody3D with a model and a
	# Talk chip, so the town had no attack, no dodge and no guard for ANY
	# input scheme — a pad could not fight here either. Decided from play:
	# no place is excluded.
	_ok("the town's player is a fighter, not a stroller", walker is Fighter,
		"the town would need its own combat, and combat.md §8 promises "
		+ "one ruleset rather than two")
	_ok("and carries the same kit as anywhere else",
		walker.stamina != null and walker.health != null
			and walker.attack != null and walker.harness != null,
		"missing a combat component")
	_ok("and still stands on the ground",
		absf(walker.global_position.y) < 2.0,
		"y=%.2f — inheriting Fighter's capsule moved the body"
			% walker.global_position.y)

	var tw_atk: Button = walker.get("_attack_btn")
	var tw_dge: Button = walker.get("_dodge_btn")
	var tw_grd: Button = walker.get("_guard_btn")
	_ok("the town has attack, dodge and guard on screen",
		tw_atk != null and tw_dge != null and tw_grd != null,
		"attack=%s dodge=%s guard=%s" % [str(tw_atk != null),
			str(tw_dge != null), str(tw_grd != null)])

	if tw_atk != null:
		# Real touches, not `pressed.emit()`. Emitting the signal proves
		# the signal is connected and nothing else; this block passed
		# through the entire life of a bug that left every chip deaf
		# under a second thumb. `thumbcheck.gd` is the thorough version
		# of this — two fingers, both indices. These are the same three
		# questions asked here so the town is never the untested one.
		await _thumb_mode()
		_ok("the attack button swings in the town",
			await _tap_watch(tw_atk, 0, func() -> bool:
				return not walker.attack.can_act()),
			"pressing Attack in Thornfield did nothing")

		for f in 120:
			await get_tree().physics_frame
		_ok("the dodge button dodges in the town",
			await _tap_watch(tw_dge, 0, func() -> bool:
				return not walker.dodge.can_act()),
			"pressing Dodge did nothing")

		for f in 120:
			await get_tree().physics_frame
		_touch(0, tw_grd.get_global_rect().get_center(), true)
		var tw_braced := false
		for f in 6:
			await get_tree().process_frame
			if not walker.parry.can_act(): tw_braced = true
		_touch(0, tw_grd.get_global_rect().get_center(), false)
		await get_tree().process_frame
		_ok("the guard button raises the guard in the town", tw_braced,
			"holding Guard did not brace")

	t.queue_free()
	await _settle()

	# --- and a press must NOT fire a phantom swing ------------------------
	#
	# This loaded main.tscn, because the drill yard was the scene with a
	# mouse attack in it. There is one world now and this is it.
	#
	# The fault it guards is why touch-to-mouse emulation is left ON
	# project-wide: Godot presses a Button only from mouse events, so
	# switching emulation off took every menu in the game down with it,
	# in every scene, for the rest of the run. The synthesised click
	# arrives BEFORE the touch, so anything acting on it swings on press
	# instead of on release.
	var y: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(y)
	await get_tree().create_timer(3.0).timeout
	var yw: Fighter = null
	for n in y.get_children():
		if n is TownWalker: yw = n as Fighter
	_ok("there is a fighter to swing", yw != null, "no walker")

	if yw != null:
		await _thumb_mode()
		await _free(yw)

		# Counted off the FIGHTER, not off a debug tally.
		#
		# The yard kept a `_swing_count` for its debug readout and this
		# read it with `get("_swing_count")` — a string lookup into
		# another script's private field, which holds exactly until
		# somebody renames it and then reports a missing swing rather
		# than a missing field. The town keeps no such tally and should
		# not have to: whether a blow was thrown is something the
		# Fighter can be asked directly.
		var mid := Vector2(500, 300)
		_touch(0, mid, true)
		var swung := false
		for f in 12:
			await get_tree().process_frame
			if not yw.attack.can_act(): swung = true
		_ok("a press alone does not swing", not swung,
			"a touch-down threw a blow — the swing-on-press fault")
		_touch(0, mid, false)
		await get_tree().create_timer(2.0).timeout

		await _free(yw)
		var fake := InputEventMouseButton.new()
		fake.button_index = MOUSE_BUTTON_LEFT
		fake.position = mid
		fake.global_position = mid
		fake.pressed = true
		fake.device = InputEvent.DEVICE_ID_EMULATION
		Input.parse_input_event(fake)
		var swung2 := false
		for f in 12:
			await get_tree().process_frame
			if not yw.attack.can_act(): swung2 = true
		_ok("a click emulated from a touch does not swing", not swung2,
			"the synthesised click reached the blade")

	# WHAT IS NO LONGER ASKED, AND WHY.
	#
	# "A real mouse click still swings" was the third check here, and it
	# guarded world.gd's mouse attack. The town has no mouse attack path
	# at all — it swings on KEY_J/Enter, on the pad, and on the touch
	# chips — so with the yard gone there is no such feature to assert,
	# and a check that asserts one would be inventing it. Noted rather
	# than quietly deleted: removing world.gd removes click-to-attack
	# from the game. That is a real loss on a desk and no loss at all on
	# a phone with a pad, which is how this is played.
	#
	# The block that followed ran the chip checks over BOTH main.tscn and
	# hedges.tscn, on the reasoning that two scenes running the same
	# script should behave the same and play said they did not. One
	# world, one place to check: those chips are the town's chips, the
	# block above at "--- and the town, which had no combat at all ---"
	# already presses them, and thumbcheck.gd is the thorough version of
	# the same question. Kept here would be the same check run twice in
	# the same scene, which is not coverage.

	print("")
	print("touch: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()


## Make it a touch game, the way a player does: by touching it. The
## chips are hidden for any other scheme, and a hidden chip is not under
## anybody's finger.
func _thumb_mode() -> void:
	var at := Vector2(60.0, get_viewport().get_visible_rect().size.y - 60.0)
	_touch(7, at, true)
	await get_tree().process_frame
	_touch(7, at, false)
	for f in 3:
		await get_tree().process_frame


## Wait until this fighter can act, so a refused swing is not mistaken
## for a dead button.
##
## The Hedges is a live fight: the boar charges, and a player mid-swing,
## mid-stagger or mid-roll correctly refuses a new input. A fixed wait of
## 120 frames was a guess that happened to hold in the yard and did not
## in the wood, so this block failed at a different check on each run and
## looked like flake. It was not flake — it was the check reading the
## fight instead of the button.
func _free(who: Fighter) -> void:
	for f in 240:
		await get_tree().physics_frame
		if not who.is_busy() and not who.is_staggered():
			return


func _touch(index: int, at: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = at
	e.pressed = down
	Input.parse_input_event(e)


## Tap a chip with one finger and watch, frame by frame, for `probe` to
## come true at any point while it is down or just after. A swing lasts a
## fraction of a second, so a single reading afterwards catches it only
## by luck.
func _tap_watch(b: Button, index: int, probe: Callable) -> bool:
	var seen := false
	_touch(index, b.get_global_rect().get_center(), true)
	if probe.call(): seen = true
	for f in 10:
		await get_tree().process_frame
		if probe.call(): seen = true
	_touch(index, b.get_global_rect().get_center(), false)
	for f in 6:
		await get_tree().process_frame
		if probe.call(): seen = true
	return seen

