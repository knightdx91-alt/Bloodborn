extends Node3D
## Does the game notice what the player is holding?
##
## Run it:
##     godot --path prototype --rendering-driver opengl3 inputcheck.tscn
##
## InputMode is a claim about behaviour — "plug a pad in and the thumb
## controls leave; unplug it and they come back" — so it is checked by
## feeding it events and looking at what is actually on screen, not by
## reading the switch statement.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _settle() -> void:
	for i in 6: await get_tree().process_frame


func _send(e: InputEvent) -> void:
	Input.parse_input_event(e)
	await _settle()


func _touch(at: Vector2) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 7
	t.position = at
	t.pressed = true
	await _send(t)
	var u := InputEventScreenTouch.new()
	u.index = 7
	u.position = at
	u.pressed = false
	await _send(u)


func _pad_button() -> void:
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_A
	b.pressed = true
	await _send(b)
	var r := InputEventJoypadButton.new()
	r.button_index = JOY_BUTTON_A
	r.pressed = false
	await _send(r)


func _key() -> void:
	var k := InputEventKey.new()
	k.keycode = KEY_W
	k.pressed = true
	await _send(k)
	var u := InputEventKey.new()
	u.keycode = KEY_W
	u.pressed = false
	await _send(u)


func _ready() -> void:
	print("--- the scheme follows the last thing used ---")
	await _key()
	_ok("a keypress means keyboard", InputMode.is_keyboard(),
		"scheme is %s" % InputMode.scheme_name())
	await _touch(Vector2(100, 300))
	_ok("a touch means touch", InputMode.is_touch(),
		"scheme is %s" % InputMode.scheme_name())
	await _pad_button()
	_ok("a pad button means pad", InputMode.is_pad(),
		"scheme is %s" % InputMode.scheme_name())

	# A stick barely off centre must NOT count: it would flip the
	# interface back and forth under a worn controller resting on a desk.
	await _key()
	var drift := InputEventJoypadMotion.new()
	drift.axis = JOY_AXIS_LEFT_X
	drift.axis_value = 0.20
	await _send(drift)
	_ok("a resting stick does not count as a pad", InputMode.is_keyboard(),
		"0.20 of drift flipped the scheme")
	var push := InputEventJoypadMotion.new()
	push.axis = JOY_AXIS_LEFT_X
	push.axis_value = 0.90
	await _send(push)
	_ok("a real push does", InputMode.is_pad(),
		"scheme is %s" % InputMode.scheme_name())

	# A mouse event right after a touch is the browser's echo of that
	# touch, not a hand on a mouse.
	await _touch(Vector2(120, 320))
	var m := InputEventMouseMotion.new()
	m.relative = Vector2(40, 40)
	await _send(m)
	_ok("mouse motion just after a touch is ignored", InputMode.is_touch(),
		"the touch echo was taken for a mouse")

	print("--- the town's thumb controls come and go ---")
	var t: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(t)
	await get_tree().create_timer(2.5).timeout

	var walker: TownWalker = null
	for n in t.get_children():
		if n is TownWalker:
			walker = n
	_ok("the town has a walker", walker != null, "no TownWalker in the scene")
	if walker == null:
		print("FAILED: no walker")
		get_tree().quit()
		return

	await _touch(Vector2(200, 400))
	await _settle()
	var back: Button = null
	for b in walker.find_children("*", "Button", true, false):
		if (b as Button).text == "Back":
			back = b as Button
	_ok("touch gets a way out of Thornfield", back != null and back.visible,
		"no visible Back chip on touch")
	if back != null:
		var vp: Vector2 = get_viewport().get_visible_rect().size
		var r := back.get_global_rect()
		_ok("and it is on screen", r.end.x <= vp.x + 1 and r.position.y >= -1,
			"Back is at %s in %s" % [str(r), str(vp)])
		_ok("and it is thumb-sized", r.size.y >= 48.0 and r.size.x >= 96.0,
			"Back is %dx%d" % [int(r.size.x), int(r.size.y)])

	await _pad_button()
	await _settle()
	_ok("a pad takes the thumb controls off the screen",
		back == null or not back.visible, "Back chip still showing on a pad")

	await _touch(Vector2(200, 400))
	await _settle()
	_ok("and putting the pad down brings them back",
		back != null and back.visible, "Back chip did not return")

	print("")
	print("input: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
