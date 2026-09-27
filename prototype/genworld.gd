extends Node3D
## THE SPIKE: walk the generated world, and watch the numbers.
##
## `tech.md` §1a says to build no land until one question is answered —
## can the target device hold a world of this order at all? Streaming is
## a bigger engineering job than drafting the country, and if it will
## not hold on the phone that changes the world's SHAPE and not merely
## its size. So this is the thing that can still say no, the way the
## L39 latency spike was.
##
## It is a SPIKE, not a place. Thornfield is the game; this is an
## instrument you can stand inside. It comes out of the launcher the
## day the generated land is baked and the real world is built on it.
##
## What to watch, on a real phone rather than here:
##   fps      — the number that decides it
##   chunks   — how much world is resident
##   built    — should settle once you stop; climbing while standing
##              still means the hysteresis is not holding

const START := Vector3(2720.0, 0.0, 2930.0)

var gen: WorldGen
var walker: TownWalker
var _read: Label
var _worst := 999.0
var _samples := 0
var _sum := 0.0


func _ready() -> void:
	Look.build(self)
	var clock := WorldClock.new(0.42)
	TownState.set_clock(clock)
	Look.set_time(self, clock)
	for c in get_children():
		if c is DirectionalLight3D and (c as DirectionalLight3D).shadow_enabled:
			(c as DirectionalLight3D).directional_shadow_max_distance = 260.0

	gen = WorldGen.new()
	gen.world_seed = 20260927
	gen.radius = 3
	gen.per_frame = 1
	add_child(gen)

	# THE GROUND FIRST, then the body.
	#
	# A CharacterBody3D spawned over a chunk that has not been built yet
	# has nothing to stand on and is in free fall by the time it does —
	# it ends up under the world, which reads as the generator having
	# made a hole.
	var here := WorldGen.chunk_of(START)
	gen.build_block(here, 1)

	walker = TownWalker.new()
	walker.position = Vector3(START.x, gen.height_at(START.x, START.z) + 1.2, START.z)
	add_child(walker)
	gen.follow(walker)

	var layer := CanvasLayer.new()
	add_child(layer)
	_read = Label.new()
	_read.add_theme_font_size_override("font_size", 18)
	_read.add_theme_color_override("font_color", Color(0.95, 0.94, 0.90))
	_read.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_read.add_theme_constant_override("shadow_offset_y", 2)
	_read.position = Vector2(14, 14)
	_read.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_read)


func _process(_delta: float) -> void:
	if walker == null or _read == null:
		return
	var fps := Performance.get_monitor(Performance.TIME_FPS)
	# The first seconds are the scene standing up, not the game running,
	# so they are kept out of the average and out of the worst case.
	if _samples > 90:
		_worst = minf(_worst, fps)
	_samples += 1
	_sum += fps

	var p := walker.global_position
	var b = gen.terrain.biome_at(p.x, p.z)
	_read.text = ("fps %d   worst %d   mean %d\n"
		+ "chunks %d   built %d   freed %d\n"
		+ "%s\n%.0f, %.0f") % [
			int(fps), int(_worst if _worst < 999.0 else fps),
			int(_sum / maxf(1.0, float(_samples))),
			gen.live.size(), gen.built_total, gen.freed_total,
			b.name, p.x, p.z]
