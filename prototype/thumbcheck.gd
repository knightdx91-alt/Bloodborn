extends Node
## Can two thumbs fight?
##
## Reported from play: *"the attack, and dodge buttons dont work while i
## am moving. and the guard button does nothing at all."*
##
## The chips are `Button`s, and a Button hears a touch only because Godot
## synthesises a mouse click from it. That synthesis happens for touch
## index 0 and no other — so the moment your left thumb is on the stick,
## the right thumb is index 1 and every chip on screen is deaf.
##
## Everything here goes through `Input.parse_input_event` with real
## `InputEventScreenTouch`, at the indices two thumbs actually produce.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	get_window().size = Vector2i(1100, 620)
	TownState.reset()
	var town: Node3D = load("res://town.tscn").instantiate() as Node3D
	add_child(town)
	await get_tree().create_timer(3.0).timeout

	var walker: TownWalker = null
	for n in town.get_children():
		if n is TownWalker: walker = n as TownWalker
	_ok("there is somebody to fight with", walker != null, "no TownWalker")
	if walker == null:
		_finish()
		return

	# Chips are only on screen for a thumb, so tell the game a thumb is
	# what it has. One real touch does that honestly.
	_touch(0, Vector2(120.0, 500.0), true)
	await _settle()
	_touch(0, Vector2(120.0, 500.0), false)
	await _settle()
	_ok("touching the screen makes it a touch game", InputMode.is_touch(),
		"the scheme is still %d" % InputMode.scheme())

	var attack_btn: Button = walker.get("_attack_btn")
	var dodge_btn: Button = walker.get("_dodge_btn")
	var guard_btn: Button = walker.get("_guard_btn")
	_ok("the chips exist and are on screen",
		attack_btn != null and attack_btn.visible
			and dodge_btn != null and dodge_btn.visible
			and guard_btn != null and guard_btn.visible,
		"attack=%s dodge=%s guard=%s" % [str(attack_btn), str(dodge_btn),
			str(guard_btn)])
	if attack_btn == null or dodge_btn == null or guard_btn == null:
		_finish()
		return

	# --- one thumb, standing still ----------------------------------------
	#
	# A swing is WATCHED rather than looked at afterwards. The first
	# version of this check read `attack.can_act()` once, several frames
	# after the tap, and a swing is shorter than that — so moving the
	# dispatch from the release to the press was enough to make a working
	# build look broken. What is being asked is "did a swing happen at
	# all", and that is a question about a window, not an instant.
	walker.revive()
	await _settle()
	_ok("one thumb, standing still: Attack swings",
		await _tap_watch(attack_btn, 0, func() -> bool:
			return not walker.attack.can_act()),
		"nothing came out of the scabbard")

	walker.revive()
	await _settle()
	_ok("one thumb, standing still: Dodge rolls",
		await _tap_watch(dodge_btn, 0, func() -> bool:
			return not walker.dodge.can_act()),
		"the body did not move")

	# --- the guard ---------------------------------------------------------
	#
	# Held, not tapped: holding it is what makes it a block, so what this
	# asks is whether the guard is UP while the finger is DOWN.
	walker.revive()
	await _settle()
	_touch(0, _centre(guard_btn), true)
	await _settle()
	_ok("holding Guard raises the guard", walker.get("_guard_held") == true,
		"the finger is on the chip and the guard is down")
	_touch(0, _centre(guard_btn), false)
	await _settle()
	_ok("and letting go lowers it", walker.get("_guard_held") == false,
		"the guard stayed up after the finger left")

	# --- two thumbs, which is how it is actually played --------------------
	#
	# Left thumb on the stick, right thumb on a chip. This is the
	# reported bug, and it is the whole point of the file.
	walker.revive()
	await _settle()
	_touch(0, Vector2(140.0, 480.0), true)
	await _settle()
	_ok("the left thumb is steering", walker.get("_stick_id") == 0,
		"the stick did not take the first finger")

	_ok("while moving: Attack still swings",
		await _tap_watch(attack_btn, 1, func() -> bool:
			return not walker.attack.can_act()),
		"the second finger pressed Attack and the sword stayed put — "
			+ "this is the reported bug")

	walker.revive()
	await _settle()
	_ok("while moving: Dodge still rolls",
		await _tap_watch(dodge_btn, 1, func() -> bool:
			return not walker.dodge.can_act()),
		"the second finger pressed Dodge and nothing happened")

	walker.revive()
	await _settle()
	_touch(1, _centre(guard_btn), true)
	await _settle()
	_ok("while moving: Guard still guards", walker.get("_guard_held") == true,
		"the second finger is holding Guard and the guard is down")
	_touch(1, _centre(guard_btn), false)
	await _settle()
	_ok("and still lowers", walker.get("_guard_held") == false,
		"the guard stayed up")

	_touch(0, Vector2(140.0, 480.0), false)
	await _settle()

	# --- and the guard has to be VISIBLE -----------------------------------
	#
	# Everything above can pass while the player sees nothing at all, and
	# for a while it did. `try_parry` holds the heavy swing's wind-up as
	# a stand-in brace, and it asked for a 0.12s blend into it and then
	# froze the clip on the very next line — but a blend is advanced by
	# the same clock `speed_scale` scales, so the cross-fade stopped at
	# nought per cent. The AnimationPlayer reported `swing_heavy` at 0.72
	# while the body rendered, pixel for pixel, the idle it was meant to
	# be fading out of.
	#
	# So this asks the skeleton where the sword hand actually is, rather
	# than asking the AnimationPlayer what it believes.
	walker.revive()
	await _settle()
	var skel: Skeleton3D = _skeleton(walker)
	_ok("the body has a skeleton to read", skel != null, "no Skeleton3D")
	if skel != null:
		var hand: int = skel.find_bone("mixamorig_RightHand")
		_ok("and a sword hand on it", hand != -1, "no mixamorig_RightHand")
		if hand != -1:
			for f in 20:
				await get_tree().physics_frame
			var at_ease: Vector3 = skel.get_bone_global_pose(hand).origin
			walker.try_parry()
			for f in 20:
				await get_tree().physics_frame
			var braced: Vector3 = skel.get_bone_global_pose(hand).origin
			var moved: float = at_ease.distance_to(braced)
			print("      the sword hand moved %.3fm into the brace" % moved)
			_ok("raising the guard moves the body", moved > 0.10,
				"the hand is within %.3fm of where it rests — the guard "
					% moved + "is up and the fighter is standing there "
					+ "as if nothing happened, which is what L65 forbids")
			walker.lower_guard()

	_finish()


func _skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n as Skeleton3D
	for c in n.get_children():
		var hit := _skeleton(c)
		if hit != null:
			return hit
	return null


func _centre(b: Button) -> Vector2:
	return b.get_global_rect().get_center()


## Tap a chip and watch, frame by frame, for `probe` to come true at any
## point. A swing lasts a fraction of a second and a single reading
## afterwards catches it only by luck.
func _tap_watch(b: Button, index: int, probe: Callable) -> bool:
	var seen := false
	_touch(index, _centre(b), true)
	if probe.call(): seen = true
	for f in 10:
		await get_tree().process_frame
		if probe.call(): seen = true
	_touch(index, _centre(b), false)
	for f in 6:
		await get_tree().process_frame
		if probe.call(): seen = true
	return seen


func _touch(index: int, at: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = at
	e.pressed = down
	Input.parse_input_event(e)


func _settle() -> void:
	for f in 4:
		await get_tree().process_frame


func _finish() -> void:
	TownState.reset()
	print("")
	print("thumbs: all clear" if _fails.is_empty()
		else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
