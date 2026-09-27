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

## Where the spike opens.
##
## Thornfield's own site on the ring, rather than the arbitrary
## coordinate this used before the Wheel existed — the starting town
## is where a player would start, and opening anywhere else made the
## spike feel like a sample of country rather than a place in a world.
## Resolved at startup because it depends on the terrain.
var start := Vector3.ZERO

var gen: WorldGen
var walker: TownWalker
var _read: Label
var _worst := 999.0
var _samples := 0
var _sum := 0.0
## Somewhere worth standing, found once at startup.
var _stops: Array = []
var _stop := 0


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

	# The ground first, then the body — but NOT for the reason this
	# comment used to give.
	#
	# It claimed a body spawned over an unbuilt chunk falls through the
	# world. Mutation-tested by deleting this call: it does not. What
	# actually saves you is WorldGen's nearest-first queue — after a
	# spawn or a jump the chunk underfoot is the nearest missing one,
	# so it is built on the very next frame and the body falls for one
	# frame, which on any device is centimetres.
	#
	# Kept because one frame of grey where the ground should be is
	# still one frame of grey, and on a phone a chunk is not free.
	# Insurance, not a load-bearing wall, and the difference is worth
	# writing down so nobody later "optimises" the queue on the
	# assumption that this call is what holds the player up.
	start = gen.terrain.town_site(0)   # Thornfield's wedge
	var here := WorldGen.chunk_of(start)
	gen.build_block(here, 1)

	walker = TownWalker.new()
	walker.position = Vector3(start.x, gen.height_at(start.x, start.z) + 1.2, start.z)
	add_child(walker)
	gen.follow(walker)

	_find_stops()

	var layer := CanvasLayer.new()
	add_child(layer)

	# A WAY TO SEE IT WITHOUT WALKING FIVE KILOMETRES.
	#
	# The point of the spike is to judge whether the country is varied
	# and whether the device can hold it, and the biomes are six
	# wedges of a nine-kilometre world. Walking between them is the
	# game; walking between them to EVALUATE them is a waste of an
	# evening. This jumps to the next thing worth looking at.
	# Built as a CHIP and registered with the walker, not added as a
	# plain Button. A plain one is deaf under a second thumb — Godot
	# synthesises the click from touch index 0 only — and pressing it
	# would start a camera drag as well, because the walker reads raw
	# touch before the GUI sees it. `extra_chips` puts it through the
	# same dispatch the attack and dodge chips go through.
	var jump := UI.chip("Jump", 1.0)
	jump.anchor_left = 1.0
	jump.anchor_right = 1.0
	jump.offset_left = -150.0
	jump.offset_top = 24.0
	jump.offset_right = -24.0
	jump.offset_bottom = 96.0
	jump.pressed.connect(_next_stop)
	layer.add_child(jump)
	walker.extra_chips.append(jump)

	_read = Label.new()
	_read.add_theme_font_size_override("font_size", 18)
	_read.add_theme_color_override("font_color", Color(0.95, 0.94, 0.90))
	_read.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_read.add_theme_constant_override("shadow_offset_y", 2)
	_read.position = Vector2(14, 14)
	_read.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_read)


## One place in each wedge, plus a settlement and a landmark.
##
## Found by asking the generator rather than by hardcoding
## coordinates, so this keeps working when the seed or the biome
## layout changes — a list of magic numbers would silently start
## pointing at the wrong country.
func _find_stops() -> void:
	var t := gen.terrain
	# THE SIX TOWN SITES, and the capitol. Not six points at an
	# arbitrary radius: the whole shape of the world is six towns on a
	# ring around Godsgrave, and standing where each one will be is
	# what makes that shape legible from inside rather than on paper.
	for w in WgTerrain.WEDGES:
		var site := t.town_site(w)
		var b := t.biome_at(site.x, site.z)
		_stops.append({"at": site, "what": "%s — %s" % [b.town, b.name]})
	var hub := t.capitol_site()
	_stops.append({"at": hub, "what": "Godsgrave — the capitol"})

	var want := ["street", "ring", "farmstead", "ruin"]
	var got: Dictionary = {}
	for cx in range(0, 24):
		for cz in range(0, 24):
			var b := WgSettlement.cached(t, t.seed_value, cx, cz)
			if b.houses == 0 and b.pieces.is_empty():
				continue
			if want.has(b.kind) and not got.has(b.kind):
				got[b.kind] = true
				_stops.append({"at": b.centre, "what": "%s — %s" % [b.name, b.kind]})
		if got.size() == want.size():
			break

	var marks := ["stones", "tower", "shrine", "camp"]
	var seen: Dictionary = {}
	for cx in range(0, 24):
		for cz in range(0, 24):
			var m := WgLandmark.cached(t, t.seed_value, cx, cz)
			if m.is_empty() or (m["pieces"] as Array).is_empty():
				continue
			if marks.has(m["kind"]) and not seen.has(m["kind"]):
				seen[m["kind"]] = true
				_stops.append({"at": m["at"], "what": m["kind"]})
		if seen.size() == marks.size():
			break


func _next_stop() -> void:
	if _stops.is_empty() or walker == null:
		return
	_stop = (_stop + 1) % _stops.size()
	var to: Vector3 = _stops[_stop]["at"]
	# Ground first, as at spawn, and with the same caveat: the
	# nearest-first queue is what keeps you out of the void, and this
	# only spares you the frame of grey. See `_ready`.
	gen.build_block(WorldGen.chunk_of(to), 1)
	walker.global_position = Vector3(to.x, gen.height_at(to.x, to.z) + 1.2, to.z)
	walker.velocity = Vector3.ZERO


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
	var label: String = ""
	if not _stops.is_empty():
		label = str(_stops[_stop]["what"])
	_read.text = ("fps %d   worst %d   mean %d\n"
		+ "chunks %d   built %d   freed %d\n"
		+ "%s\n%s\n%.0f, %.0f") % [
			int(fps), int(_worst if _worst < 999.0 else fps),
			int(_sum / maxf(1.0, float(_samples))),
			gen.live.size(), gen.built_total, gen.freed_total,
			b.name, label, p.x, p.z]
