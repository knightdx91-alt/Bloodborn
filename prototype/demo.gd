extends Node3D
## A capture harness: plays a scripted run of the prototype and writes
## every frame to disk, for stitching into a video. Not part of the game,
## and not loaded by it — `main.tscn` is the game.
##
## It exists because the only way anyone sees this project move is a
## video: the developer has no PC, the verification browser renders at
## three or four frames a second, and a screenshot cannot show a 0.28s
## parry window mattering.
##
## Run it, and stitch the result:
##
##     godot --path prototype --resolution 800x450 --fixed-fps 24 demo.tscn
##     cat $(ls /tmp/demo/f*.jpg | sort) | ffmpeg -f image2pipe \
##         -vcodec mjpeg -framerate 24 -i pipe: -c:v libvpx -b:v 2200k \
##         -auto-alt-ref 0 -pix_fmt yuv420p file:out.webm
##
## `--fixed-fps` is what makes this work: game time advances a fixed step
## per rendered frame, so the capture is smooth no matter how slowly the
## software rasteriser actually draws it.

const FPS := 24
const OUT := "/tmp/demo/f%04d.jpg"

var w: Node3D
var _caption: Label
var _sub: Label
var _frame := 0

func _say(title: String, sub: String = "") -> void:
	_caption.text = title
	_sub.text = sub

func _steer(v: Vector2) -> void:
	if v == Vector2.ZERO:
		w._touch_id = -1
		w._touch_vec = Vector2.ZERO
		return
	w._touch_id = 0
	w._touch_vec = v
	# Tell the hold-to-guard check this is a steer, not a brace.
	w._touch_max_drag = 999.0

## One rendered frame, captured.
func _tick() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_jpg(OUT % _frame, 0.88)
	_frame += 1

func _ready() -> void:
	w = (load("res://main.tscn") as PackedScene).instantiate()
	add_child(w)

	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	_caption = Label.new()
	_caption.add_theme_font_size_override("font_size", 30)
	_caption.add_theme_color_override("font_color", Color(0.97, 0.95, 0.90))
	_caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_caption.add_theme_constant_override("shadow_offset_y", 2)
	_caption.add_theme_constant_override("shadow_offset_x", 2)
	_caption.position = Vector2(28, 330)
	layer.add_child(_caption)

	_sub = Label.new()
	_sub.add_theme_font_size_override("font_size", 19)
	_sub.add_theme_color_override("font_color", Color(0.78, 0.76, 0.72))
	_sub.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_sub.add_theme_constant_override("shadow_offset_y", 2)
	_sub.position = Vector2(28, 372)
	layer.add_child(_sub)

	await get_tree().process_frame
	await get_tree().process_frame

	# Park the enemy out of the way for the first two beats.
	w.enemy.position = Vector3(0, 1, -45)

	await _beat_move()
	await _beat_attack()
	await _beat_enemy()
	await _beat_dodge()
	await _beat_parry()

	print("rendered %d frames" % _frame)
	get_tree().quit()

func _beat_move() -> void:
	_say("Stage 1 — move and look", "Drag to steer. How far you drag is how fast you go.")
	_steer(Vector2(0.28, -0.28))     # a walk
	for i in 34: await _tick()
	_steer(Vector2(0.75, 0.55))      # a run
	for i in 34: await _tick()
	_steer(Vector2.ZERO)
	for i in 10: await _tick()

func _beat_attack() -> void:
	_say("Attack — a committed swing", "0.30s wind-up, 0.12s of live blade, 0.45s recovering.")
	# Walk to the dummy.
	for i in 70:
		var to: Vector3 = w.dummy.global_position - w.player.global_position
		to.y = 0.0
		if to.length() > 1.5:
			_steer(Vector2(to.normalized().x, to.normalized().z) * 0.55)
		else:
			_steer(Vector2.ZERO)
			w.player.rotation.y = atan2(-to.normalized().x, -to.normalized().z)
			w._try_attack()
		await _tick()
	_say("...until it falls over", "It rocks back from each blow. No health bar — you read the body.")
	for i in 60:
		var to2: Vector3 = w.dummy.global_position - w.player.global_position
		to2.y = 0.0
		_steer(Vector2.ZERO)
		if w._dummy_down <= 0.0:
			w.player.rotation.y = atan2(-to2.normalized().x, -to2.normalized().z)
			w._try_attack()
		await _tick()

func _beat_enemy() -> void:
	_say("The enemy — three attack shapes", "Quick, heavy, committed. Told apart by the wind-up alone.")
	# Move the fight to open ground — the toppled dummy sits between them
	# otherwise, and the point of this beat is to see the wind-ups.
	w.player.position = Vector3(2, 1, 9)
	w.player.rotation.y = 0.0
	w.enemy.position = Vector3(2, 1, 3)
	w.enemy.revive()
	_steer(Vector2.ZERO)
	for i in 120:
		# Circle him rather than standing square on. The camera sits
		# behind the player, so head-on the two overlap — and circling is
		# what L56 wants from the mobility anyway.
		var to_e: Vector3 = w.enemy.global_position - w.player.global_position
		to_e.y = 0.0
		if to_e.length() > 0.1 and not w.player.is_busy():
			var side: Vector3 = to_e.normalized().cross(Vector3.UP)
			_steer(Vector2(side.x, side.z) * 0.34)
		if w.enemy.attack.phase() == 1:
			_steer(Vector2.ZERO)
			var shape: int = w.enemy.attack.shape()
			_say("The enemy — three attack shapes",
				["QUICK — 0.22s wind-up. Answer: dodge.",
				 "HEAVY — 0.62s wind-up. Answer: parry.",
				 "COMMITTED — 1.00s wind-up. Cannot be parried."][shape])
		await _tick()

func _beat_dodge() -> void:
	_say("Dodge — 0.30s of invulnerability", "Tap with a second finger. Blows pass straight through.")
	for i in 130:
		if w.enemy.attack.phase() == 1 and w.player.dodge.can_act() and not w.player.is_busy():
			var left: float = w.enemy.attack.windup_seconds() - w.enemy.attack.elapsed()
			if left < 0.12:
				var away: Vector3 = w.player.global_position - w.enemy.global_position
				away.y = 0.0
				if w.player.try_dodge(away.cross(Vector3.UP).normalized()):
					w._dodge_count += 1
		await _tick()

func _beat_parry() -> void:
	_say("Parry — the heart of it", "Hold still to guard. Time it against a heavy.")
	var punished := false
	for i in 170:
		if not w.player.is_busy() and w.enemy.attack.phase() == 1:
			var shape: int = w.enemy.attack.shape()
			var left: float = w.enemy.attack.windup_seconds() - w.enemy.attack.elapsed()
			if shape == 1 and left < 0.18 and w.player.parry.can_act():
				if w.player.try_parry():
					w._parry_attempts += 1
			elif shape == 0 and left < 0.12 and w.player.dodge.can_act():
				if w.player.try_dodge(Vector3(1, 0, 0)):
					w._dodge_count += 1
		if w.enemy.is_staggered():
			_say("Parried — he is staggered", "0.9s opened up, and you are free again in 0.12s.")
			punished = false
			var to: Vector3 = w.enemy.global_position - w.player.global_position
			to.y = 0.0
			if not w.player.is_busy():
				w.player.rotation.y = atan2(-to.normalized().x, -to.normalized().z)
				if to.length() < 1.7:
					if w.player.try_attack():
						punished = true
						w._swing_count += 1
				else:
					_steer(Vector2(to.normalized().x, to.normalized().z) * 0.5)
		else:
			_steer(Vector2.ZERO)
		await _tick()
	_say("Stage 1, built headless", "No editor, no GPU, nothing on the developer's machine.")
	for i in 36: await _tick()
