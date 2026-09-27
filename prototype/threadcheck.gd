extends Node
## Is a threaded chunk the same chunk?
##
## Threading the generator buys nothing if it changes what the
## generator produces, and a race here would not look like a race: it
## would look like a seam, a missing hamlet, or a road drawn twice, and
## it would appear on one device in one run out of ten.
##
## So this does not ask whether threading is fast. It asks whether the
## answer is identical, under concurrency, with the caches warm and
## cold.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	var at := Vector2i(42, 45)

	# The truth: one thread, caches cold.
	WgSettlement._cache.clear()
	WgLandmark._cache.clear()
	WgRoads._wheel.clear()
	var truth := WgBake.gather(WgTerrain.new(20260927), at)

	# --- the same chunk, from eight workers at once ----------------------
	#
	# Eight threads on ONE cell is the sharpest test of the caches:
	# every one of them misses, computes, and writes back at the same
	# moment.
	WgSettlement._cache.clear()
	WgLandmark._cache.clear()
	WgRoads._wheel.clear()
	var results: Array = []
	results.resize(8)
	var tasks: Array = []
	for i in 8:
		var slot := i
		tasks.append(WorkerThreadPool.add_task(func() -> void:
			results[slot] = WgBake.gather(WgTerrain.new(20260927), at)))
	for task in tasks:
		WorkerThreadPool.wait_for_task_completion(task)

	var same := 0
	var why: Array[String] = []
	for i in 8:
		var got = results[i]
		if got == null or (got as Dictionary).is_empty():
			why.append("worker %d returned nothing" % i)
			continue
		var d := _differs(truth, got)
		if d == "":
			same += 1
		else:
			why.append("worker %d: %s" % [i, d])
	_ok("eight workers on one chunk all agree with one thread", same == 8,
		"%d of 8 matched — %s" % [same, str(why)])

	# --- different chunks at once, which is what streaming does ----------
	WgSettlement._cache.clear()
	WgLandmark._cache.clear()
	WgRoads._wheel.clear()
	var spread: Array[Vector2i] = [Vector2i(42, 45), Vector2i(43, 45),
		Vector2i(42, 46), Vector2i(90, 12), Vector2i(-31, 77), Vector2i(8, 8)]
	var got_many: Array = []
	got_many.resize(spread.size())
	var tasks2: Array = []
	for i in spread.size():
		var slot2 := i
		tasks2.append(WorkerThreadPool.add_task(func() -> void:
			got_many[slot2] = WgBake.gather(WgTerrain.new(20260927), spread[slot2])))
	for task in tasks2:
		WorkerThreadPool.wait_for_task_completion(task)

	# Against single-threaded truth for each, caches cold each time.
	var mismatched: Array[String] = []
	for i in spread.size():
		WgSettlement._cache.clear()
		WgLandmark._cache.clear()
		WgRoads._wheel.clear()
		var alone := WgBake.gather(WgTerrain.new(20260927), spread[i])
		var d2 := _differs(alone, got_many[i])
		if d2 != "":
			mismatched.append("%s: %s" % [str(spread[i]), d2])
	_ok("six chunks built concurrently match six built alone",
		mismatched.is_empty(), str(mismatched))

	# --- the roads, which are the likeliest thing to double up -----------
	#
	# WgRoads.wheel appends twelve segments into a shared array. Two
	# threads racing its first call would append into the same one and
	# produce twenty-four — every road drawn twice, and gencheck would
	# blame the east/south ownership rule.
	WgRoads._wheel.clear()
	var wheels: Array = []
	wheels.resize(8)
	var tasks3: Array = []
	for i in 8:
		var slot3 := i
		tasks3.append(WorkerThreadPool.add_task(func() -> void:
			wheels[slot3] = WgRoads.wheel(WgTerrain.new(20260927)).size()))
	for task in tasks3:
		WorkerThreadPool.wait_for_task_completion(task)
	var sizes := {}
	for w in wheels:
		sizes[w] = true
	_ok("the Wheel's roads are built once, not once per thread",
		sizes.size() == 1 and wheels[0] == WgTerrain.WEDGES * 2,
		"workers saw these segment counts: %s — expected all %d"
			% [str(sizes.keys()), WgTerrain.WEDGES * 2])

	# --- and the streamed world actually fills in -------------------------
	var gen := WorldGen.new()
	gen.world_seed = 20260927
	gen.threaded = true
	gen.radius = 2
	gen.per_frame = 2
	add_child(gen)
	var marker := Node3D.new()
	marker.position = Vector3(42.0 * WgChunk.SIZE, 0.0, 45.0 * WgChunk.SIZE)
	add_child(marker)
	gen.follow(marker)
	for i in 400:
		await get_tree().process_frame
	var want := (gen.radius * 2 + 1) * (gen.radius * 2 + 1)
	_ok("threaded streaming fills the whole block",
		gen.live.size() == want,
		"%d of %d chunks resident after 400 frames" % [gen.live.size(), want])
	_ok("and builds each of them exactly once",
		gen.built_total == want,
		"built %d chunks for %d positions — a coordinate was built twice"
			% [gen.built_total, want])
	print("      %d chunks, %d built, %d freed"
		% [gen.live.size(), gen.built_total, gen.freed_total])

	_finish()


## "" if the two gathers are the same chunk, else what differs.
func _differs(a: Dictionary, b: Dictionary) -> String:
	var ha: PackedFloat32Array = a["heights"]
	var hb: PackedFloat32Array = b["heights"]
	if ha.size() != hb.size():
		return "%d heights vs %d" % [ha.size(), hb.size()]
	for i in ha.size():
		if ha[i] != hb[i]:
			return "height %d: %.6f vs %.6f" % [i, ha[i], hb[i]]
	var ca: PackedByteArray = a["colours"]
	var cb: PackedByteArray = b["colours"]
	if ca != cb:
		return "colours differ"
	var pa: Array = a["pieces"]
	var pb: Array = b["pieces"]
	if pa.size() != pb.size():
		return "%d pieces vs %d" % [pa.size(), pb.size()]
	for i in pa.size():
		if String(pa[i]["path"]) != String(pb[i]["path"]):
			return "piece %d is a different model" % i
		if (pa[i]["position"] as Vector3) != (pb[i]["position"] as Vector3):
			return "piece %d moved" % i
	if (a["solids"] as Array).size() != (b["solids"] as Array).size():
		return "solid count differs"
	return ""


func _finish() -> void:
	print("")
	print("threads: all clear" if _fails.is_empty()
		else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
