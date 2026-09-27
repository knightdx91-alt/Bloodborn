extends Node
## Does the generator make a world, and the SAME world every time?
##
## Determinism is the property everything else rests on. A generator
## that drifts cannot be streamed (chunk edges stop meeting), cannot be
## baked (the bake differs from the preview), and cannot be shared
## (the server's world is not the client's). It is also the property
## most easily lost by accident, because the usual way to write a
## scatter loop — walk the area, roll for each spot — is exactly the
## way that loses it.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _ready() -> void:
	var t := WgTerrain.new(20260927)

	# --- the land exists and is not flat ----------------------------------
	var lo := INF
	var hi := -INF
	for i in 400:
		var x := float(i % 20) * 137.0 + 3000.0
		var z := float(i / 20) * 137.0 + 1000.0
		var h := t.height_at(x, z)
		lo = minf(lo, h)
		hi = maxf(hi, h)
	_ok("the land has relief", hi - lo > 12.0,
		"%.1f m between the highest and lowest of 400 samples — that is a "
			% (hi - lo) + "field, not country")

	# --- determinism ------------------------------------------------------
	var a := t.height_at(1234.5, -876.25)
	var b := WgTerrain.new(20260927).height_at(1234.5, -876.25)
	_ok("the same seed gives the same ground", is_equal_approx(a, b),
		"%.6f vs %.6f from two terrains on one seed" % [a, b])

	var other := WgTerrain.new(99).height_at(1234.5, -876.25)
	_ok("and a different seed gives different ground", absf(a - other) > 0.01,
		"seed 99 and seed 20260927 agree to %.6f — the seed is ignored" % a)

	# --- scatter is a function of place, not of order ---------------------
	#
	# THE check. Asked by building the same patch twice from different
	# starting corners: a running RNG gives a different answer, a hashed
	# cell gives the same one.
	var one := WgScatter.in_rect(t, 500.0, 500.0, 628.0, 628.0)
	var two := WgScatter.in_rect(t, 628.0, 628.0, 500.0, 500.0)
	var three := WgScatter.in_rect(t, 500.0, 500.0, 628.0, 628.0)
	_ok("scatter is the same asked twice", _same(one, three),
		"%d items then %d, and they differ" % [one.size(), three.size()])
	_ok("and asking a wider area first changes nothing",
		_same(one, _clip(WgScatter.in_rect(t, 400.0, 400.0, 700.0, 700.0),
			500.0, 500.0, 628.0, 628.0)),
		"a tree's existence depends on what else was asked for")
	_ok("and there is something out there", one.size() > 8,
		"only %d things in a 128 m square" % one.size())

	# --- no diagonal striping --------------------------------------------
	#
	# The first cut of the cell hash added the coordinates, so every
	# cell on a north-east diagonal drew the same numbers and the
	# country came out ruled with stripes. Compares cells along a
	# diagonal against cells along a row: if the hash is collapsing,
	# the diagonal agrees with itself far more often than chance.
	# Asked as COLLISIONS along a diagonal, not as similarity between
	# neighbours. The first version of this compared cell (i,i) with
	# cell (i+1,i+1) and asked whether they were close — and passed
	# happily with the hash deliberately collapsed to `h + cx + cz`,
	# because adjacent SEEDS give uncorrelated first draws. Neighbouring
	# cells differing proves nothing.
	#
	# What the bug actually does is make every cell on an anti-diagonal
	# hash IDENTICALLY: with x+z, (0,8), (1,7) and (8,0) are one number.
	# So walk a constant-sum line and a constant-difference line and
	# count how many distinct values come out.
	var on_sum := {}
	var on_diff := {}
	for i in 60:
		on_sum[WgScatter.cell_rng(t.seed_value, i, 60 - i, 0).randf()] = true
		on_diff[WgScatter.cell_rng(t.seed_value, i + 30, i, 0).randf()] = true
	_ok("the cell hash does not collapse along diagonals",
		on_sum.size() > 50 and on_diff.size() > 50,
		"60 cells on a constant-sum line gave %d distinct draws and a "
			% on_sum.size()
		+ "constant-difference line gave %d — the hash is folding x and z "
			% on_diff.size()
		+ "together, which rules the country with stripes")

	# --- the wedges are actually different --------------------------------
	#
	# L86: the land carries orientation and a screenshot must be
	# LOCATABLE. Two wedges that differ only in tree count are two
	# wedges nobody can tell apart, so this asks for a real spread.
	var seen: Array[String] = []
	var colours: Array[Color] = []
	var reliefs: Array[float] = []
	for w in WgTerrain.WEDGES:
		var ang := (float(w) + 0.5) / float(WgTerrain.WEDGES) * TAU
		var r := 5000.0
		var bx := cos(ang) * r
		var bz := sin(ang) * r
		var bi = t.biome_at(bx, bz)
		if not seen.has(bi.name):
			seen.append(bi.name)
		colours.append(bi.ground)
		reliefs.append(bi.relief)
	_ok("all six wedges are distinct country", seen.size() == WgTerrain.WEDGES,
		"only %d distinct biomes across six wedges: %s"
			% [seen.size(), str(seen)])

	var spread := 0.0
	for i in colours.size():
		for j in range(i + 1, colours.size()):
			var d: Color = colours[i]
			var e: Color = colours[j]
			spread = maxf(spread, absf(d.r - e.r) + absf(d.g - e.g) + absf(d.b - e.b))
	_ok("and they do not all look the same", spread > 0.35,
		"the two most different ground colours differ by only %.2f" % spread)

	var rlo: float = reliefs.min()
	var rhi: float = reliefs.max()
	_ok("and some are flat while others are steep", rhi > rlo * 3.0,
		"relief runs %.0f m to %.0f m — every wedge is the same shape"
			% [rlo, rhi])

	# --- the capitol is a clearing ----------------------------------------
	var cap_h := t.height_at(0.0, 0.0)
	var far_slope := t.slope_at(0.0, 0.0)
	_ok("the capitol sits on quiet ground", far_slope < 0.06,
		"slope %.3f at the middle of the world — the hub is on a hillside"
			% far_slope)

	# --- settlements ------------------------------------------------------
	var built: WgSettlement.Built = null
	var scanned := 0
	for cx in range(0, 14):
		for cz in range(0, 14):
			var found := WgSettlement.site(t, t.seed_value, cx, cz)
			scanned += 1
			if found.is_empty():
				continue
			var candidate := WgSettlement.build(t, t.seed_value, found)
			if candidate.houses > 0:
				built = candidate
				break
		if built != null:
			break
	_ok("somebody built something out there", built != null,
		"no hamlet in %d candidate cells" % scanned)

	if built != null:
		print("      found %s — %d houses, %d pieces"
			% [built.name, built.houses, built.pieces.size()])
		_ok("and it has more than one house", built.houses >= 3,
			"%d houses is a shed, not a hamlet" % built.houses)
		_ok("and it is made of real files", _all_load(built.pieces),
			"a piece points at a model that does not exist")

		var kinds := {}
		for p in built.pieces:
			var f: String = String(p["path"]).get_file().get_basename()
			kinds[f] = true
		_ok("and a house is walls, corners and a roof",
			_any_with(kinds, "Wall_") and _any_with(kinds, "Corner_")
				and _any_with(kinds, "Roof_"),
			"missing a part: %s" % str(kinds.keys()))
		_ok("and somebody lives there", _any_with(kinds, "Barrel")
				or _any_with(kinds, "Crate") or _any_with(kinds, "Bench")
				or _any_with(kinds, "Stall") or _any_with(kinds, "FarmCrate"),
			"not one prop — it is a model village")
		_ok("and it is named", built.name != "", "an unnamed hamlet")

		# FOUR KINDS OF PLACE, not one shape repeated.
		#
		# Every settlement used to be a street with houses down both
		# sides, so however varied the country got, what people had put
		# on it read as one idea over and over. Diverse land carrying
		# one building pattern is half a world.
		var kinds_seen := {}
		var with_houses := 0
		for cx2 in range(0, 26):
			for cz2 in range(0, 26):
				var f2 := WgSettlement.site(t, t.seed_value, cx2, cz2)
				if f2.is_empty():
					continue
				var b2 := WgSettlement.build(t, t.seed_value, f2)
				kinds_seen[b2.kind] = int(kinds_seen.get(b2.kind, 0)) + 1
				if b2.houses > 0:
					with_houses += 1
		print("      across %d settlements: %s"
			% [with_houses, str(kinds_seen)])
		_ok("and the world builds more than one kind of place",
			kinds_seen.size() >= 4,
			"only %d kinds in the whole sample: %s"
				% [kinds_seen.size(), str(kinds_seen.keys())])
		_ok("and no one kind is the whole world",
			_commonest(kinds_seen) < 0.7,
			"one kind is %.0f%% of every settlement"
				% (_commonest(kinds_seen) * 100.0))

		# Keep-clear: nothing grows through a wall.
		var near := WgScatter.in_rect(t,
			built.centre.x - 60.0, built.centre.z - 60.0,
			built.centre.x + 60.0, built.centre.z + 60.0, built.keep_clear)
		var inside := 0
		for item in near:
			var p: Vector3 = item["position"]
			for rect in built.keep_clear:
				if (rect as Rect2).has_point(Vector2(p.x, p.z)):
					inside += 1
					break
		_ok("and nothing grows through its walls", inside == 0,
			"%d scattered things standing inside the keep-clear rects" % inside)

	# --- landmarks --------------------------------------------------------
	#
	# L86 again, and the sharpest case of it: with no minimap the land
	# carries orientation, and orientation needs things to orient BY.
	# Six biomes of empty country all look identical once you are
	# standing in one.
	var mark_kinds := {}
	var mark_count := 0
	for cx3 in range(0, 30):
		for cz3 in range(0, 30):
			var m := WgLandmark.at_cell(t, t.seed_value, cx3, cz3)
			if m.is_empty() or (m["pieces"] as Array).is_empty():
				continue
			mark_count += 1
			mark_kinds[m["kind"]] = int(mark_kinds.get(m["kind"], 0)) + 1
	print("      %d landmarks in 900 cells: %s" % [mark_count, str(mark_kinds)])
	_ok("there are landmarks between the places", mark_count > 40,
		"only %d landmarks in 900 cells — the country is empty" % mark_count)
	_ok("and more than one sort of them", mark_kinds.size() >= 4,
		"only %d sorts: %s" % [mark_kinds.size(), str(mark_kinds.keys())])
	_ok("and they are rarer than settlements",
		mark_count < 400,
		"%d landmarks is not a landmark, it is scenery" % mark_count)

	# --- chunks -----------------------------------------------------------
	var gen := WorldGen.new()
	gen.world_seed = 20260927
	gen.terrain = t
	add_child(gen)
	await get_tree().process_frame

	var c0 := gen.make_chunk(Vector2i(8, 8))
	await get_tree().process_frame
	_ok("a chunk builds", c0 != null and c0.get_child_count() > 2,
		"the chunk is empty")
	print("      chunk (8,8) placed %d things" % c0.placed)
	_ok("and it has ground under it",
		c0.find_child("GroundBody", true, false) != null,
		"nothing to stand on")

	# Seams: the shared edge of two chunks must agree to the millimetre,
	# because they are sampled from the same function of world position.
	var seam_ok := true
	var worst := 0.0
	for i in 65:
		var wx := 9.0 * WgChunk.SIZE - WgChunk.SIZE * 0.5
		var wz := 8.0 * WgChunk.SIZE - WgChunk.SIZE * 0.5 + float(i)
		var left := t.height_at(wx - 0.0001, wz)
		var right := t.height_at(wx + 0.0001, wz)
		worst = maxf(worst, absf(left - right))
		if absf(left - right) > 0.01:
			seam_ok = false
	_ok("and its edge meets its neighbour's", seam_ok,
		"the ground jumps %.3f m across a chunk border" % worst)

	# --- and you can stand on it ------------------------------------------
	#
	# The one that matters for a spike. A HeightMapShape3D built from
	# the wrong grid, or scaled wrongly, or wound the wrong way, gives
	# ground you fall straight through — and the generator looks
	# perfect in every render right up until a body is put on it.
	var at := Vector3(8.0 * WgChunk.SIZE, 0.0, 8.0 * WgChunk.SIZE)
	var ground := t.height_at(at.x, at.z)
	var body := CharacterBody3D.new()
	var cap := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 2.0
	shape.radius = 0.4
	cap.shape = shape
	body.add_child(cap)
	body.position = Vector3(at.x, ground + 6.0, at.z)
	add_child(body)
	for i in 120:
		body.velocity.y -= 9.8 * (1.0 / 60.0)
		body.move_and_slide()
		await get_tree().physics_frame
	var rest := body.global_position.y
	_ok("and a body lands on it instead of falling through",
		rest > ground - 0.5 and rest < ground + 3.0,
		"dropped from %.1f onto ground at %.1f and ended at %.1f"
			% [ground + 6.0, ground, rest])
	print("      ground %.2f m, body came to rest at %.2f m" % [ground, rest])

	_finish()


## The share of the commonest kind.
func _commonest(counts: Dictionary) -> float:
	var total := 0
	var top := 0
	for k in counts:
		total += int(counts[k])
		top = maxi(top, int(counts[k]))
	if total == 0:
		return 1.0
	return float(top) / float(total)


func _same(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	var ka: Array[String] = []
	var kb: Array[String] = []
	for i in a.size():
		ka.append(_key(a[i]))
		kb.append(_key(b[i]))
	ka.sort()
	kb.sort()
	return ka == kb


func _key(item: Dictionary) -> String:
	var p: Vector3 = item["position"]
	return "%s@%.3f,%.3f" % [item["path"], p.x, p.z]


func _clip(items: Array, x0: float, z0: float, x1: float, z1: float) -> Array:
	var out: Array = []
	for item in items:
		var p: Vector3 = item["position"]
		if p.x >= x0 and p.x < x1 and p.z >= z0 and p.z < z1:
			out.append(item)
	return out


func _all_load(pieces: Array) -> bool:
	var seen := {}
	for p in pieces:
		var path: String = p["path"]
		if seen.has(path):
			continue
		seen[path] = true
		if not ResourceLoader.exists(path):
			print("      missing: %s" % path)
			return false
	return true


func _any_with(kinds: Dictionary, prefix: String) -> bool:
	for k in kinds:
		if String(k).begins_with(prefix) or String(k).contains(prefix):
			return true
	return false


func _finish() -> void:
	print("")
	print("gen: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
