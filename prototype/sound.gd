class_name Sound
extends RefCounted
## The first audio in this project.
##
## `art-audio.md` §4 (**L87**) makes audio the second information
## channel, and in one case the primary one: *"a cut biting flesh, a cut
## skipping off plate, a mace finding mail are different sounds, and that
## is how the damage triangle reaches a player who is never shown a
## number."* That is a testable claim, and it is tested with
## placeholders rather than waited on.
##
## Everything here is synthesised by `assets/tools/build_audio.py` — pure
## stdlib Python, no samples, no dependencies. They are placeholders and
## are meant to be replaced; what they are for is proving the channel
## carries the information. Measured: flesh is dull and done in 196 ms,
## plate rings for 950 ms, mail is 28x brighter than flesh.

const DIR := "res://assets/audio/%s"

## Which impact an armour class makes. The names are `ArmourSet`'s.
const IMPACTS := {
	"none": "hit_flesh.wav",
	"light": "hit_flesh.wav",
	"mail": "hit_mail.wav",
	"plate": "hit_plate.wav",
}


static func _stream(file: String, looping: bool = false) -> AudioStream:
	var path: String = DIR % file
	if not ResourceLoader.exists(path):
		return null
	var s := load(path) as AudioStream
	if s is AudioStreamWAV and looping:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = w.data.size() / 2  # 16-bit mono
	return s


## Room tone, crossfading between day and night on the shared clock.
##
## Two players rather than one, because a crossfade needs both audible at
## once — swapping a single stream at dawn would cut the crickets off
## mid-chirp.
static func ambience(parent: Node) -> Dictionary:
	var day := AudioStreamPlayer.new()
	day.stream = _stream("ambience_day.wav", true)
	day.bus = "Master"
	day.volume_db = -80.0
	parent.add_child(day)

	var night := AudioStreamPlayer.new()
	night.stream = _stream("ambience_night.wav", true)
	night.bus = "Master"
	night.volume_db = -80.0
	parent.add_child(night)

	if day.stream != null:
		day.play()
	if night.stream != null:
		night.play()
	return {"day": day, "night": night}


## Push the hour into the room tone. `lit` is the clock's daylight, 0–1.
static func set_time(players: Dictionary, lit: float) -> void:
	var day: AudioStreamPlayer = players.get("day", null)
	var night: AudioStreamPlayer = players.get("night", null)
	# Quiet on purpose: this is the floor a town sits on, not a track.
	# -14 dB full, and silence rather than a hum when a layer is out.
	if is_instance_valid(day):
		day.volume_db = linear_to_db(maxf(lit, 0.0001)) - 14.0
	if is_instance_valid(night):
		night.volume_db = linear_to_db(maxf(1.0 - lit, 0.0001)) - 14.0


## One blow landing, positioned in the world so it comes from where the
## fight is rather than from everywhere.
static func impact(parent: Node3D, at: Vector3, armour_class: String) -> void:
	var file: String = IMPACTS.get(armour_class, "hit_flesh.wav")
	_one_shot(parent, at, file, randf_range(-1.5, 1.5))


static func swing(parent: Node3D, at: Vector3) -> void:
	_one_shot(parent, at, "swing.wav", randf_range(-2.0, 2.0), -6.0)


static func step(parent: Node3D, at: Vector3) -> void:
	_one_shot(parent, at, "step_%d.wav" % (randi() % 3 + 1),
		randf_range(-2.5, 2.5), -10.0)


## Played from a node that frees itself. A pool would be better under
## load; this is a prototype and the garbage is measured in bytes.
static func _one_shot(parent: Node3D, at: Vector3, file: String,
		pitch_semitones: float = 0.0, gain_db: float = 0.0) -> void:
	var s := _stream(file)
	if s == null or parent == null or not parent.is_inside_tree():
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.unit_size = 6.0
	p.max_distance = 45.0
	p.pitch_scale = pow(2.0, pitch_semitones / 12.0)
	p.volume_db = gain_db
	parent.add_child(p)
	# Placed in WORLD space, after the node is in the tree. `position` is
	# local, which is the same thing only while the parent sits at the
	# origin — true of World, not true of a fighter who is the one doing
	# the swinging.
	p.global_position = at
	p.finished.connect(p.queue_free)
	p.play()
