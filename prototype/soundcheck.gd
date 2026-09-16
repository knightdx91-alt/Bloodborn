extends Node
## Does the audio channel actually carry what L87 says it carries?
##
## `art-audio.md` §4 makes sound the *primary* channel for one thing: a
## cut biting flesh, a cut skipping off plate and a mace finding mail are
## how the damage triangle reaches a player who is never shown a number.
## That is a claim about the files, not about the code that plays them,
## so this measures the files.
##
## Thresholds are ratios between the three, never absolute numbers. The
## point is to survive the placeholders being replaced by real samples:
## a recorded plate hit that rings longer than a recorded flesh hit still
## passes, and a swap that makes two of them interchangeable still fails.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


## Everything the ear gets from one impact, measured off the samples.
##
## `ring_ms` is how long it stays above a twentieth of its own peak —
## how long it takes to die. `brightness` is mean sample-to-sample
## change over mean level, which rises with high-frequency content: it
## is a cheap spectral centroid and needs no FFT.
func _measure(file: String) -> Dictionary:
	var s := load("res://assets/audio/%s" % file) as AudioStreamWAV
	if s == null:
		return {}
	var bytes: PackedByteArray = s.data
	var n: int = bytes.size() / 2
	if n < 2:
		return {}

	var peak := 0.0
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var v: float = float(bytes.decode_s16(i * 2)) / 32768.0
		samples[i] = v
		peak = maxf(peak, absf(v))
	if peak <= 0.0:
		return {}

	var last_loud := 0
	var sum_level := 0.0
	var sum_delta := 0.0
	for i in n:
		var a: float = absf(samples[i])
		if a > peak * 0.05:
			last_loud = i
		sum_level += a
		if i > 0:
			sum_delta += absf(samples[i] - samples[i - 1])

	return {
		"peak": peak,
		"ring_ms": float(last_loud) * 1000.0 / float(s.mix_rate),
		"brightness": sum_delta / maxf(sum_level, 0.0001),
	}


func _ready() -> void:
	# --- The three impacts, as heard -------------------------------------
	var flesh := _measure("hit_flesh.wav")
	var mail := _measure("hit_mail.wav")
	var plate := _measure("hit_plate.wav")

	_ok("the three impacts exist and have samples in them",
		not flesh.is_empty() and not mail.is_empty() and not plate.is_empty(),
		"one of hit_flesh/hit_mail/hit_plate is missing, empty or silent")
	if _fails.size() > 0:
		print("")
		print("FAILED: %s" % ", ".join(_fails))
		get_tree().quit()
		return

	print("      flesh  peak %.2f  ring %4.0fms  bright %.4f"
		% [flesh["peak"], flesh["ring_ms"], flesh["brightness"]])
	print("      mail   peak %.2f  ring %4.0fms  bright %.4f"
		% [mail["peak"], mail["ring_ms"], mail["brightness"]])
	print("      plate  peak %.2f  ring %4.0fms  bright %.4f"
		% [plate["peak"], plate["ring_ms"], plate["brightness"]])

	# Meat does not ring. Steel does. That is the whole tell.
	_ok("flesh dies fastest", flesh["ring_ms"] < mail["ring_ms"]
		and flesh["ring_ms"] < plate["ring_ms"],
		"flesh rings %.0fms, mail %.0fms, plate %.0fms"
			% [flesh["ring_ms"], mail["ring_ms"], plate["ring_ms"]])
	_ok("plate rings on, and not by a hair",
		plate["ring_ms"] > flesh["ring_ms"] * 2.0,
		"plate %.0fms against flesh %.0fms — not a difference you would hear"
			% [plate["ring_ms"], flesh["ring_ms"]])
	_ok("mail is the bright one",
		mail["brightness"] > flesh["brightness"] * 3.0
		and mail["brightness"] > plate["brightness"] * 2.0,
		"brightness flesh %.4f, mail %.4f, plate %.4f — mail is small links "
		% [flesh["brightness"], mail["brightness"], plate["brightness"]]
		+ "moving against each other and should be the brightest by far")
	_ok("and plate is brighter than flesh too",
		plate["brightness"] > flesh["brightness"],
		"%.4f vs %.4f" % [plate["brightness"], flesh["brightness"]])
	_ok("none of them clips to nothing or blows the ceiling",
		flesh["peak"] > 0.2 and mail["peak"] <= 1.0 and plate["peak"] <= 1.0,
		"peaks %.2f / %.2f / %.2f" % [flesh["peak"], mail["peak"], plate["peak"]])

	# --- Every armour class reaches a sound -------------------------------
	var classes := ["none", "light", "mail", "plate"]
	var missing := []
	for c in classes:
		if not Sound.IMPACTS.has(c):
			missing.append(c)
	_ok("every armour class the damage table knows has a sound",
		missing.is_empty(), "no impact for %s" % ", ".join(missing))
	_ok("mail and plate are not the same file",
		Sound.IMPACTS["mail"] != Sound.IMPACTS["plate"],
		"the two armours a player has to tell apart play the same clip")
	_ok("an unknown class still makes a noise",
		Sound.IMPACTS.get("brigandine", "hit_flesh.wav") != "",
		"impact() falls back rather than going silent")

	# --- What the blow MET, not what is left of it ------------------------
	#
	# resolve() wears the piece down as it computes, so a blow that breaks
	# the last of the mail leaves the slot reading "none" immediately
	# afterwards. Asked at that moment, the loudest ring in the fight
	# would be played as a bare hit on meat. hurt() therefore reports the
	# class itself, read before the wear is applied — this walks a real
	# fighter's harness down to its last hit and listens to the one that
	# breaks it.
	var him := Fighter.new()
	add_child(him)
	him.setup(100.0, Color.WHITE, true, Fighter.CHARACTER,
		Look.IRON, Look.LEATHER, "mail")
	await get_tree().process_frame
	var slot: int = ArmourSet.Slot.TORSO
	var arc: int = -1
	for a in [Attack.Arc.OVERHEAD, Attack.Arc.UPPER_LEFT,
			Attack.Arc.UPPER_RIGHT, Attack.Arc.LOWER_LEFT,
			Attack.Arc.LOWER_RIGHT, Attack.Arc.THRUST]:
		if ArmourSet.slot_for(a) == slot:
			arc = a
			break

	var mail_blows := 0
	var breaking := {}
	for i in 40:
		var got: Dictionary = him.hurt(1.0, arc, "cut")
		if String(got["class"]) == "mail":
			mail_blows += 1
		if bool(got["broke"]):
			breaking = got
			break

	_ok("a harness can actually be worn through", not breaking.is_empty(),
		"40 blows to the torso and the mail is still whole — the setup is "
		+ "wrong, not the rule")
	if not breaking.is_empty():
		_ok("the blow that BREAKS the mail is still reported as mail",
			String(breaking["class"]) == "mail",
			"reported '%s' — asked a moment too late, and the ring that "
				% String(breaking["class"])
			+ "tells you the armour just failed plays as a hit on bare meat")
		_ok("and it plays the mail impact, not the flesh one",
			Sound.IMPACTS.get(String(breaking["class"]), "") == "hit_mail.wav",
			"a broken-mail blow would play %s"
				% Sound.IMPACTS.get(String(breaking["class"]), "nothing"))
		_ok("the blows before it were mail too", mail_blows > 1,
			"only %d mail blows before the break" % mail_blows)

	# And once it is gone, it really is gone: the NEXT blow is bare.
	var after: Dictionary = him.hurt(1.0, arc, "cut")
	_ok("the blow after that one is bare", String(after["class"]) == "none",
		"still reporting '%s' after the piece came off" % String(after["class"]))
	him.queue_free()

	# --- Room tone crossfades on the clock --------------------------------
	var host := Node3D.new()
	add_child(host)
	var room := Sound.ambience(host)
	_ok("there are two ambience layers, not one swapped stream",
		room.has("day") and room.has("night")
		and room["day"] != room["night"], "a single player cannot crossfade")

	Sound.set_time(room, 1.0)
	var noon_day: float = (room["day"] as AudioStreamPlayer).volume_db
	var noon_night: float = (room["night"] as AudioStreamPlayer).volume_db
	Sound.set_time(room, 0.0)
	var dark_day: float = (room["day"] as AudioStreamPlayer).volume_db
	var dark_night: float = (room["night"] as AudioStreamPlayer).volume_db
	Sound.set_time(room, 0.5)
	var mid_day: float = (room["day"] as AudioStreamPlayer).volume_db
	var mid_night: float = (room["night"] as AudioStreamPlayer).volume_db

	_ok("day is on top at noon", noon_day > noon_night + 20.0,
		"day %.1fdB, night %.1fdB" % [noon_day, noon_night])
	_ok("night is on top at midnight", dark_night > dark_day + 20.0,
		"day %.1fdB, night %.1fdB" % [dark_day, dark_night])
	_ok("and both are audible through the handover",
		absf(mid_day - mid_night) < 1.0 and mid_day > -40.0,
		"day %.1fdB, night %.1fdB at half light — a crossfade, not a cut"
			% [mid_day, mid_night])
	_ok("the town is never louder than a floor", noon_day < -10.0,
		"%.1fdB is a soundtrack, not room tone" % noon_day)

	# --- A one-shot lands where the thing happened ------------------------
	#
	# `position` is local. Every impact so far is parented to World, which
	# sits at the origin, so a local/global mix-up would have been silent
	# for as long as that stayed true.
	host.global_position = Vector3(30.0, 0.0, -12.0)
	var target := Vector3(4.0, 1.1, 5.0)
	Sound.impact(host, target, "plate")
	var placed: AudioStreamPlayer3D = null
	for c in host.get_children():
		if c is AudioStreamPlayer3D:
			placed = c
	_ok("an impact spawns a positional player", placed != null,
		"nothing was added under a parent that is in the tree")
	if placed != null:
		_ok("and it plays from where the blow landed, not the parent's origin",
			placed.global_position.distance_to(target) < 0.01,
			"asked for %s, sits at %s — %.1fm out"
				% [str(target), str(placed.global_position),
				placed.global_position.distance_to(target)])
		_ok("and it is audible across a fight but not across the town",
			placed.max_distance > 10.0 and placed.max_distance < 100.0,
			"max_distance %.0fm" % placed.max_distance)

	# --- Footsteps come from walking ---------------------------------------
	var h: Node3D = load("res://hedges.tscn").instantiate() as Node3D
	add_child(h)
	await get_tree().create_timer(1.0).timeout
	var you: Fighter = h.get("player")
	_ok("there is somebody to walk", you != null, "no player in the Hedges")

	if you != null:
		# Counted as they SPAWN, not by looking at the children afterwards.
		# A step clip is about a tenth of a second and frees itself the
		# moment it finishes, so a fighter who has walked for a second and
		# a half has no step players left to find. That mistake reported
		# "3.4m covered in silence" for a walk that was working.
		you.child_entered_tree.connect(_saw_child)

		# Walked by HOLDING A KEY, not by calling move() by hand. The scene
		# drives the player itself every physics frame, so a harness that
		# also calls move() gets two calls a frame — its own, then the
		# scene's move(ZERO, 0.0) — and the stride accumulator is reset by
		# the second one before it can ever reach a full step. That is
		# what "3.4m covered in silence" was: the test walking against the
		# game rather than through it.
		_steps = 0
		for i in 30:
			await get_tree().physics_frame
		_ok("standing still makes no footsteps", _steps == 0,
			"%d steps from a fighter who did not move" % _steps)

		_steps = 0
		var from: Vector3 = you.global_position
		_hold(KEY_W, true)
		for i in 90:
			await get_tree().physics_frame
		_hold(KEY_W, false)
		var covered: float = Vector2(you.global_position.x - from.x,
			you.global_position.z - from.z).length()
		print("      walked %.1fm and took %d steps" % [covered, _steps])
		_ok("walking does", _steps > 0,
			"%.1fm covered in silence" % covered)
		_ok("and it is a stride, not a frame",
			_steps > 0 and _steps <= int(covered) + 1,
			"%d steps in %.1fm is a sprint on gravel, not a walk"
				% [_steps, covered])

	print("")
	print("sound: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()


var _steps := 0

func _hold(key: Key, down: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = key
	e.physical_keycode = key
	e.pressed = down
	Input.parse_input_event(e)

func _saw_child(c: Node) -> void:
	if c is AudioStreamPlayer3D:
		_steps += 1
