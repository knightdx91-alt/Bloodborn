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
	# AROUND THE CAPITOL, not around the game's origin. Thornfield sits
	# at (0,0) now, so sampling six angles from there lands six points
	# in Thornfield's own corner and reports three biomes for six
	# wedges — which is what it did.
	var hub2 := t.capitol_site()
	for w in WgTerrain.WEDGES:
		var ang := (float(w) + 0.5) / float(WgTerrain.WEDGES) * TAU
		var r := WgTerrain.TOWN_RING * 0.83
		var bx := hub2.x + cos(ang) * r
		var bz := hub2.z + sin(ang) * r
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

		# THE WEDGE LEANS THE ODDS.
		#
		# The Wistwood is "old forest with older ruins" in lore.md §5,
		# so it has to actually have more of them than the horse
		# plains do — otherwise the description is a caption on a
		# picture of the same thing.
		var wist_ruins := 0
		var wist_all := 0
		var reach_ruins := 0
		var reach_all := 0
		for w2 in WgTerrain.WEDGES:
			var bname: String = t.biomes()[w2].name
			if bname != "the Wistwood" and bname != "the Reaches":
				continue
			var ang2 := (float(w2) + 0.5) / float(WgTerrain.WEDGES) * TAU
			# DISTINCT CELLS. The first cut walked outward in 34 m
			# steps through 900 m cells, so it counted the same two or
			# three hamlets twenty times each and reported "80% of 59"
			# about a sample of three.
			var seen_cells := {}
			for k in 400:
				var rr := WgTerrain.TOWN_RING * 0.45 + float(k % 40) * 600.0
				var fan := (float(k / 40) - 4.5) * 0.06
				var sx := hub2.x + cos(ang2 + fan) * rr
				var sz := hub2.z + sin(ang2 + fan) * rr
				var sc3 := int(floor(sx / WgSettlement.CELL))
				var sz3 := int(floor(sz / WgSettlement.CELL))
				var ckey := "%d:%d" % [sc3, sz3]
				if seen_cells.has(ckey):
					continue
				seen_cells[ckey] = true
				# And only cells whose settlement really is in this
				# wedge — a cell near the border belongs to whichever
				# country it actually fell in.
				var b4 := WgSettlement.cached(t, t.seed_value, sc3, sz3)
				if b4.kind == "":
					continue
				if t.biome_at(b4.centre.x, b4.centre.z).name != bname:
					continue
				if bname == "the Wistwood":
					wist_all += 1
					if b4.kind == "ruin": wist_ruins += 1
				else:
					reach_all += 1
					if b4.kind == "ruin": reach_ruins += 1
		var wist_rate := float(wist_ruins) / maxf(1.0, float(wist_all))
		var reach_rate := float(reach_ruins) / maxf(1.0, float(reach_all))
		print("      ruins: Wistwood %.0f%% of %d, Reaches %.0f%% of %d"
			% [wist_rate * 100.0, wist_all, reach_rate * 100.0, reach_all])
		_ok("the Wistwood has older ruins in it than the horse plains",
			wist_rate > reach_rate,
			"Wistwood %.0f%% vs Reaches %.0f%% — the wedge's own "
				% [wist_rate * 100.0, reach_rate * 100.0]
			+ "description is not reaching the generator")

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

	# --- the Wheel ---------------------------------------------------------
	#
	# lore.md §5 names six towns and the country each one sits in. The
	# generator makes country; this asks whether it makes THIS country.
	var towns_ok := true
	var wrong_wedge: Array[String] = []
	var hub3 := t.capitol_site()
	for w in WgTerrain.WEDGES:
		var site := t.town_site(w)
		# Distance from the CAPITOL. It used to be distance from the
		# origin, which was the same thing only while the capitol was
		# the origin.
		var r := Vector2(site.x - hub3.x, site.z - hub3.z).length()
		if absf(r - WgTerrain.TOWN_RING) > 1.0:
			towns_ok = false
		# THE ONE AT RISK. The wedge borders are chewed by noise so
		# they are not drawn lines, and a town sits at its arc's
		# middle — but a big enough chew could push the middle over a
		# border, and a town would then stand in its neighbour's
		# country wearing its own name.
		var bi = t.biome_at(site.x, site.z)
		if t.wedge_at(site.x, site.z) != w:
			wrong_wedge.append("%s in %s" % [t.biomes()[w].town, bi.name])
	_ok("the six towns stand on the ring", towns_ok,
		"a town is not at %.0f m from the capitol" % WgTerrain.TOWN_RING)
	_ok("and each in its own country", wrong_wedge.is_empty(),
		"border noise pushed a town out of its wedge: %s" % str(wrong_wedge))

	# THE GROUND IS READY FOR A TOWN. People build on the flat, and
	# 750 m of town on a hillside is 750 m of houses floating at one
	# corner and buried at the other.
	var worst_town_slope := 0.0
	var worst_town := ""
	for w in WgTerrain.WEDGES:
		var site := t.town_site(w)
		for probe in [Vector2(0, 0), Vector2(160, 0), Vector2(0, -160),
				Vector2(-110, 110)]:
			var sl := t.slope_at(site.x + probe.x, site.z + probe.y, 6.0)
			if sl > worst_town_slope:
				worst_town_slope = sl
				worst_town = t.biomes()[w].town
	_ok("the ground at every town site is level", worst_town_slope < 0.02,
		"worst slope %.3f, at %s" % [worst_town_slope, worst_town])
	print("      worst slope across the six town sites: %.4f" % worst_town_slope)

	# And the country beyond the skirt is still country — a platform
	# that flattened the whole wedge would be worse than none.
	var out_slope := 0.0
	for w in WgTerrain.WEDGES:
		var site := t.town_site(w)
		out_slope = maxf(out_slope, t.slope_at(site.x + 1400.0, site.z, 6.0))
	_ok("and the country past it is not flattened too", out_slope > 0.02,
		"slope %.4f a kilometre out — the platform is swallowing the wedge"
			% out_slope)

	# Nothing procedural is squatting where a town goes.
	var squatters: Array[String] = []
	for w in WgTerrain.WEDGES:
		var site := t.town_site(w)
		var scx2 := int(floor(site.x / WgSettlement.CELL))
		var scz2 := int(floor(site.z / WgSettlement.CELL))
		for dx4 in range(-1, 2):
			for dz4 in range(-1, 2):
				var b5 := WgSettlement.cached(t, t.seed_value, scx2 + dx4, scz2 + dz4)
				if b5.kind == "":
					continue
				var d5 := Vector2(b5.centre.x, b5.centre.z).distance_to(
					Vector2(site.x, site.z))
				if d5 < WgTerrain.TOWN_FLAT + WgTerrain.TOWN_SKIRT:
					squatters.append("%s at %.0f m from %s"
						% [b5.name, d5, t.biomes()[w].town])
	_ok("and no hamlet is squatting on a town site", squatters.is_empty(),
		"%s — a procedural village standing where a named town goes is a "
			% str(squatters)
		+ "collision nobody finds until they try to put the town there")

	var named := {}
	for b3 in t.biomes():
		named[b3.town] = b3.name
	_ok("and every wedge is somebody's",
		named.size() == WgTerrain.WEDGES and not named.has(""),
		"towns and wedges do not pair up: %s" % str(named))
	print("      %s" % str(named))

	var wheel := WgRoads.wheel(t)
	var spokes := 0
	var rim := 0
	for seg in wheel:
		if seg.get("kind", "") == "spoke": spokes += 1
		elif seg.get("kind", "") == "rim": rim += 1
	_ok("six spokes run to the capitol", spokes == WgTerrain.WEDGES,
		"%d spokes" % spokes)
	_ok("and the rim road closes the ring", rim == WgTerrain.WEDGES,
		"%d rim segments for %d towns" % [rim, WgTerrain.WEDGES])

	# The spoke is the design's own twenty minutes.
	var spoke_len := 0.0
	for seg in wheel:
		if seg.get("kind", "") == "spoke":
			spoke_len = (seg["a"] as Vector2).distance_to(seg["b"] as Vector2)
			break
	_ok("and a spoke is the journey it was designed to be",
		absf(spoke_len - WgTerrain.TOWN_RING) < 1.0,
		"a spoke is %.0f m, not %.0f" % [spoke_len, WgTerrain.TOWN_RING])
	# 4.5 m/s is WALK_SPEED_MAX, which is now what a full stick gives
	# and is below SPRINT_THRESHOLD, so it is the fastest pace that can
	# be held indefinitely. It used to read 5.0, which was the speed at
	# 80% stick — full stick overshot into sprint and drained, so the
	# "sustainable pace" was one nobody would naturally hold.
	print("      spoke %.0f m — %.0f minutes at %.1f m/s"
		% [spoke_len, spoke_len / Fighter.WALK_SPEED_MAX / 60.0,
			Fighter.WALK_SPEED_MAX])

	# THE WORLD IS THE SIZE IT WAS ASKED TO BE.
	#
	# "3x how long it would take you to cross Skyrim walking." Skyrim
	# is ~6 km across at ~1.5 m/s, so ~65 minutes; three times that is
	# ~200. Asserted as a TIME rather than a distance, because the
	# distance is meaningless without the walk speed — and the walk
	# speed has already been wrong once, which is how the old "5 m/s
	# sustainable pace" got into the design and stayed there.
	# TWO SEPARATE FACTS, because the size and the walk are now two
	# decisions. The world was sized so that SIZED_AT_SPEED gives
	# SIZED_CROSSING_MIN; the walk was then slowed deliberately, which
	# makes the real crossing longer. Checking them together would let
	# a feel tweak to the walk drag the map around behind it.
	var across := WgTerrain.WORLD_R * 2.0
	var sized_min := across / WgTerrain.SIZED_AT_SPEED / 60.0
	var real_min := across / Fighter.WALK_SPEED_MAX / 60.0
	print("      world %.1f km across, %.0f km2"
		% [across / 1000.0,
			PI * (WgTerrain.WORLD_R / 1000.0) * (WgTerrain.WORLD_R / 1000.0)])
	print("      sized for %.0f min at %.1f m/s; the walk is %.1f m/s, so %.0f min"
		% [sized_min, WgTerrain.SIZED_AT_SPEED, Fighter.WALK_SPEED_MAX, real_min])
	print("      a mount at 2.5x crosses in %.0f min" % (real_min / 2.5))
	_ok("the world is the size it was sized to be",
		absf(sized_min - WgTerrain.SIZED_CROSSING_MIN) < 5.0,
		"%.0f min at the sizing speed, not %.0f"
			% [sized_min, WgTerrain.SIZED_CROSSING_MIN])
	_ok("and the walk is slower than the speed it was sized at",
		Fighter.WALK_SPEED_MAX < WgTerrain.SIZED_AT_SPEED,
		"the walk is %.1f m/s — it was meant to be slowed below %.1f"
			% [Fighter.WALK_SPEED_MAX, WgTerrain.SIZED_AT_SPEED])
	_ok("and walking is still free at a full stick",
		Fighter.WALK_SPEED_MAX < Fighter.SPRINT_THRESHOLD,
		"a full stick at %.1f m/s is above SPRINT_THRESHOLD %.1f, so the "
			% [Fighter.WALK_SPEED_MAX, Fighter.SPRINT_THRESHOLD]
		+ "sprint bug is back")

	# --- roads ------------------------------------------------------------
	var segs := WgRoads.near(t, t.seed_value,
		hub2.x - 24000.0, hub2.z - 24000.0, hub2.x + 24000.0, hub2.z + 24000.0)
	_ok("the places are joined up", segs.size() > 5,
		"only %d road segments across 36 km of country" % segs.size())
	print("      %d road segments" % segs.size())

	# EACH LINK OWNED ONCE. A cell links east and south only, so no
	# pair can be produced twice — if it could, a road would be drawn
	# over itself and the ownership rule would be a lie that a chunk at
	# a border could contradict.
	var road_pairs := {}
	var road_dupes := 0
	for seg in segs:
		var sa: Vector2 = seg["a"]
		var sb: Vector2 = seg["b"]
		var r_lo := sa if (sa.x < sb.x or (sa.x == sb.x and sa.y < sb.y)) else sb
		var r_hi := sb if r_lo == sa else sa
		var r_key := "%.1f,%.1f-%.1f,%.1f" % [r_lo.x, r_lo.y, r_hi.x, r_hi.y]
		if road_pairs.has(r_key):
			road_dupes += 1
		road_pairs[r_key] = true
	_ok("and no road is laid twice", road_dupes == 0,
		"%d duplicate segments — the east/south ownership rule is leaking"
			% road_dupes)

	_ok("and asking twice gives the same roads",
		WgRoads.near(t, t.seed_value, hub2.x - 24000.0, hub2.z - 24000.0,
			hub2.x + 24000.0, hub2.z + 24000.0).size() == segs.size(),
		"the road network is not deterministic")

	if not segs.is_empty():
		var seg0: Dictionary = segs[0]
		var r_mid: Vector2 = (seg0["a"] as Vector2).lerp(seg0["b"] as Vector2, 0.5)
		var wear_on := WgRoads.wear(segs, r_mid.x, r_mid.y)
		var r_perp := ((seg0["b"] as Vector2) - (seg0["a"] as Vector2)).orthogonal().normalized()
		var r_off := r_mid + r_perp * 30.0
		var wear_off := WgRoads.wear(segs, r_off.x, r_off.y)
		_ok("the track is worn where it runs", wear_on > 0.9,
			"wear %.2f in the middle of a road" % wear_on)
		_ok("and the field beside it is not", wear_off < 0.01,
			"wear %.2f thirty metres off the road" % wear_off)

		var road_area := WgScatter.in_rect(t, r_mid.x - 40.0, r_mid.y - 40.0,
			r_mid.x + 40.0, r_mid.y + 40.0, [], segs)
		var in_ruts := 0
		for item in road_area:
			var rp: Vector3 = item["position"]
			if WgRoads.wear(segs, rp.x, rp.z) > 0.3:
				in_ruts += 1
		_ok("and nothing grows in the ruts", in_ruts == 0,
			"%d things standing in the road" % in_ruts)

	# --- water ------------------------------------------------------------
	#
	# A RIVER THAT RUNS UPHILL is the classic generator bug, and the one
	# thing about rivers that arithmetic CAN settle. Everything else here
	# was settled by rendering a map and looking at it.
	var rivers: Array = []
	for rcx in range(-9, 10):
		for rcz in range(-9, 10):
			var rp := WgRivers.trace(t, t.seed_value, rcx, rcz)
			if not rp.is_empty():
				rivers.append(rp)
	_ok("there is water in the world", rivers.size() > 20,
		"%d rivers traced over %.0f km2" % [rivers.size(),
			pow(19.0 * WgRivers.SOURCE_CELL / 1000.0, 2.0)])

	# Against BARE height — the land before the cut. Judging a river
	# against the ground it dug would be judging it against itself.
	var worst_climb := 0.0
	var worst_at := ""
	var total_drop := 0.0
	for path in rivers:
		var pts: PackedVector2Array = path
		var src := t.bare_height(pts[0].x, pts[0].y)
		total_drop += src - t.bare_height(
			pts[pts.size() - 1].x, pts[pts.size() - 1].y)
		for i in range(1, pts.size()):
			var rise := t.bare_height(pts[i].x, pts[i].y) - src
			if rise > worst_climb:
				worst_climb = rise
				worst_at = "%.0f,%.0f" % [pts[i].x, pts[i].y]
	_ok("and none of it runs uphill", worst_climb <= 0.0,
		"a river reaches %.1f m ABOVE its own source at %s"
			% [worst_climb, worst_at])
	print("      %d rivers, mean source-to-mouth drop %.1f m"
		% [rivers.size(), total_drop / float(maxi(rivers.size(), 1))])

	# A CELL THAT ACTUALLY SPRINGS. Asking about a fixed (3,-2) compared
	# two empty paths and called them different, which is a check that
	# fails for a reason that has nothing to do with determinism.
	var fresh := WgTerrain.new(20260927)
	var drifted := 0
	var compared := 0
	for rcx in range(-9, 10):
		for rcz in range(-9, 10):
			var one_p := WgRivers.trace(t, t.seed_value, rcx, rcz)
			if one_p.is_empty():
				continue
			compared += 1
			if not _same_path(one_p,
					WgRivers.trace(fresh, t.seed_value, rcx, rcz)):
				drifted += 1
	_ok("and it is the same water every time", compared > 0 and drifted == 0,
		"%d of %d courses differ between two terrains on one seed"
			% [drifted, compared])

	# The cut is what makes water legible from a ridge (L86). A channel
	# that is not actually lower than its banks is a blue stripe.
	#
	# 2.5 METRES, A NUMBER OF ITS OWN. The first version of this asked
	# for `DEPTH * 0.4`, so setting DEPTH to zero — the exact bug it is
	# here to catch — also set the bar to zero and the check sailed
	# through the mutation. A threshold derived from the thing under
	# test cannot test it.
	#
	# BOTH banks, at the valley's edge and perpendicular to the flow: a
	# river running along a hillside has high ground on one side anyway,
	# and asking only that side would credit it for a valley it does not
	# have.
	var carved := 0
	for path in rivers:
		var pts2: PackedVector2Array = path
		var mid := pts2.size() / 2
		var m: Vector2 = pts2[mid]
		var flow: Vector2 = (pts2[mid + 1] - pts2[mid - 1]).normalized()
		var perp := Vector2(-flow.y, flow.x) * (WgRivers.VALLEY + 60.0)
		var bed := t.height_at(m.x, m.y)
		var banks: float = minf(
			t.height_at(m.x + perp.x, m.y + perp.y),
			t.height_at(m.x - perp.x, m.y - perp.y))
		if banks - bed > 2.5:
			carved += 1
	_ok("and it lies in a valley it cut",
		float(carved) / float(maxi(rivers.size(), 1)) > 0.6,
		"only %d of %d channels sit below their own banks"
			% [carved, rivers.size()])

	# WATER DOES NOT CUT THROUGH A TOWN. A 7 m channel through the
	# market would put the smithy in a ravine, and the town platforms
	# are the one part of this world that is not the generator's to
	# reshape.
	var flooded := 0
	var scarred := 0.0
	for w3 in WgTerrain.WEDGES:
		var site := t.town_site(w3)
		for k in 48:
			var ang3 := float(k) / 48.0 * TAU
			var rr := WgTerrain.TOWN_FLAT * 0.8
			var px := site.x + cos(ang3) * rr
			var pz := site.z + sin(ang3) * rr
			if t.water_at(px, pz) > WgTerrain.NO_WATER:
				flooded += 1
			scarred = maxf(scarred,
				t.bare_height(px, pz) - t.height_at(px, pz))
	_ok("and none of it runs through a town", flooded == 0,
		"%d samples on town ground have water on them" % flooded)
	_ok("and no town platform is cut by it", scarred < 1.0,
		"a town's levelled ground is dug %.1f m deeper than it was levelled to"
			% scarred)

	# AND NOTHING STANDS IN IT. A tree in open water is as old a tell as
	# a river running uphill, and the scatter had no idea water existed
	# until this went in.
	var in_water := 0
	var looked := 0
	for k2 in mini(rivers.size(), 6):
		var pts3: PackedVector2Array = rivers[k2]
		var m3: Vector2 = pts3[pts3.size() / 2]
		for item in WgScatter.in_rect(t, m3.x - 100.0, m3.y - 100.0,
				m3.x + 100.0, m3.y + 100.0):
			looked += 1
			var ip: Vector3 = item["position"]
			if t.river_distance(ip.x, ip.z) <= WgRivers.SHEET:
				in_water += 1
	_ok("and nothing grows in it", looked > 50 and in_water == 0,
		"%d of %d things within 100 m of six rivers are standing in the water"
			% [in_water, looked])

	# CULLING THE ROADS CHANGES NOTHING.
	#
	# A chunk's vertex loop tests wear against only the segments that
	# can reach its own square, because testing all of them was 13.2 ms
	# of a 54 ms chunk. That is only safe if it is EXACT — one dropped
	# segment is a stripe of road that stops at a chunk border — so this
	# asks the same question both ways at every vertex of several
	# chunks and requires the same answer to the bit.
	# ON CHUNKS THAT ACTUALLY HAVE A ROAD ON THEM. The first version of
	# this probed four chunks by eye, none of which a road crossed —
	# both sides answered nought at every vertex and the mutation that
	# shrank the cull could not fail. So the chunks are FOUND, by
	# looking for wear, and the count of worn vertices is asserted
	# before the comparison is believed.
	var cull_diff := 0
	var cull_worn := 0
	var cull_chunks := 0
	var probe_half := WgChunk.SIZE * 0.5
	var probe_step := WgChunk.SIZE / float(WgChunk.VERTS - 1)
	for k in 220:
		if cull_chunks >= 4:
			break
		var pcx := -6 + (k % 22)
		var pcz := -5 + (k / 22)
		var ox := float(pcx) * WgChunk.SIZE
		var oz := float(pcz) * WgChunk.SIZE
		var all_roads := WgRoads.near(t, t.seed_value,
			ox - WgChunk.SIZE, oz - WgChunk.SIZE,
			ox + WgChunk.SIZE, oz + WgChunk.SIZE)
		var some := WgRoads.touching(all_roads,
			Rect2(ox - probe_half, oz - probe_half,
				WgChunk.SIZE, WgChunk.SIZE))
		var worn_here := 0
		var diff_here := 0
		for iz in WgChunk.VERTS:
			for ix in WgChunk.VERTS:
				var wx := ox - probe_half + float(ix) * probe_step
				var wz := oz - probe_half + float(iz) * probe_step
				var full := WgRoads.wear(all_roads, wx, wz)
				if full > 0.0:
					worn_here += 1
				if full != WgRoads.wear(some, wx, wz):
					diff_here += 1
		if worn_here == 0:
			continue
		cull_chunks += 1
		cull_worn += worn_here
		cull_diff += diff_here
	_ok("there is road on the chunks this was asked about",
		cull_chunks >= 3 and cull_worn > 200,
		"only %d chunks with %d worn vertices between them — comparing "
			% [cull_chunks, cull_worn] + "unworn ground proves nothing")
	_ok("and culling the roads changes none of them", cull_diff == 0,
		"%d vertices are worn differently once the far roads are dropped"
			% cull_diff)
	print("      %d worn vertices across %d chunks, %d changed by the cull"
		% [cull_worn, cull_chunks, cull_diff])

	# --- bridges ----------------------------------------------------------
	#
	# ROADS WERE LAID BEFORE RIVERS EXISTED and nothing told them. This
	# found ten of 215 segments running through open water, the deepest
	# with the full 7 m channel under it — a cart track diving into a
	# river and out the far side.
	var road_wet := 0
	var road_bridged := 0
	var seg_count := 0
	var spans: Array[float] = []
	var all_decks: Array = []
	for patch in [Vector2(0, 0), Vector2(9000, -12000), Vector2(-15000, 4000),
			Vector2(6000, 14000), Vector2(-8000, -9000)]:
		var here := WgRoads.near(t, t.seed_value,
			patch.x, patch.y, patch.x + 5000.0, patch.y + 5000.0)
		seg_count += here.size()
		var decks := WgCrossing.near(t, here, patch.x, patch.y,
			patch.x + 5000.0, patch.y + 5000.0)
		for deck in decks:
			spans.append(deck["span"])
			all_decks.append(deck)
		# INSIDE THE SAME BOX THE BRIDGES WERE ASKED FOR.
		#
		# The first version of this walked whole segments and compared
		# them against the bridges near one patch — and the Wheel's
		# spokes are 23 km long, so it was counting water a spoke
		# crosses in another wedge entirely and calling it unbridged.
		# 262 of 359 samples "failed" and the generator was right every
		# time. A chunk only ever asks about the ground it is on, so
		# that is what this asks about too.
		var patch_box := Rect2(patch.x, patch.y, 5000.0, 5000.0)
		for seg in here:
			var a3: Vector2 = seg["a"]
			var b3: Vector2 = seg["b"]
			var steps := maxi(int(a3.distance_to(b3) / 4.0), 2)
			for k in steps + 1:
				var p3 := a3.lerp(b3, float(k) / float(steps))
				if not patch_box.has_point(p3):
					continue
				if t.river_distance(p3.x, p3.y) > WgRivers.CHANNEL:
					continue
				road_wet += 1
				for deck2 in decks:
					if WgCrossing.covers(deck2, p3.x, p3.y):
						road_bridged += 1
						break
	_ok("roads meet the rivers somewhere", road_wet > 0,
		"no road in %d segments touches water, so this proves nothing"
			% seg_count)
	_ok("and every one of those crossings has a deck over it",
		road_wet > 0 and road_bridged == road_wet,
		"%d of %d road samples in open water have no bridge above them"
			% [road_wet - road_bridged, road_wet])
	spans.sort()
	if not spans.is_empty():
		print("      %d bridges over %d road segments; span %.0f..%.0f m"
			% [spans.size(), seg_count, spans[0], spans[spans.size() - 1]])

	# And the same crossing every time, which is what lets two chunks
	# each build their half of one deck without conferring.
	#
	# OVER THE PATCHES THAT ACTUALLY HAVE BRIDGES. The first version of
	# this asked about a 4 km box at the origin, which holds none — so
	# it compared two empty lists, found them identical, and passed.
	# The mutation that made the walk step wander proved it: nothing
	# failed. A check that cannot fail is not a check, and the count is
	# now asserted first.
	var fresh_t := WgTerrain.new(20260927)
	var compared_decks := 0
	var drift := 0
	for patch2 in [Vector2(0, 0), Vector2(9000, -12000), Vector2(-15000, 4000),
			Vector2(6000, 14000), Vector2(-8000, -9000)]:
		var r_two := WgRoads.near(fresh_t, t.seed_value,
			patch2.x, patch2.y, patch2.x + 5000.0, patch2.y + 5000.0)
		var d_two := WgCrossing.near(fresh_t, r_two, patch2.x, patch2.y,
			patch2.x + 5000.0, patch2.y + 5000.0)
		var d_one: Array = []
		for deck5 in all_decks:
			var q: Vector2 = deck5["at"]
			if q.x >= patch2.x - 64.0 and q.x <= patch2.x + 5064.0 \
					and q.y >= patch2.y - 64.0 and q.y <= patch2.y + 5064.0:
				d_one.append(deck5)
		if d_one.size() != d_two.size():
			drift += absi(d_one.size() - d_two.size())
			continue
		for i in d_one.size():
			compared_decks += 1
			if not (d_one[i]["at"] as Vector2).is_equal_approx(
					d_two[i]["at"] as Vector2):
				drift += 1
	_ok("and a crossing is in the same place every time",
		compared_decks > 5 and drift == 0,
		"%d of %d bridges moved between two terrains on one seed"
			% [drift, compared_decks])

	# A DECK IS ABOVE THE WATER, which is the whole point of it. Ten
	# centimetres of clearance is a stepping stone, not a bridge.
	var low := 999.0
	for deck3 in all_decks:
		var m4: Vector2 = deck3["at"]
		var w4 := t.water_at(m4.x, m4.y)
		if w4 <= WgTerrain.NO_WATER:
			continue
		low = minf(low, minf(deck3["h0"], deck3["h1"]) - w4)
	_ok("and it stands clear of the water",
		not all_decks.is_empty() and low >= WgCrossing.CLEARANCE - 0.01,
		"a deck sits only %.2f m above the river" % low)

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
	# WHICH CHUNK A POINT IS ON. Asked of the chunk's own footprint,
	# because that is the thing `chunk_of` has to agree with — and for
	# half a year it did not: it assumed a chunk starts at its
	# coordinate when a chunk is centred on it.
	var off := 0
	var worst_off := ""
	for k in 40:
		var px := -900.0 + float(k) * 47.0
		var pz := 620.0 - float(k) * 31.0
		var said := WorldGen.chunk_of(Vector3(px, 0.0, pz))
		var cen := Vector2(float(said.x), float(said.y)) * WgChunk.SIZE
		if absf(px - cen.x) > WgChunk.SIZE * 0.5 + 0.001 \
				or absf(pz - cen.y) > WgChunk.SIZE * 0.5 + 0.001:
			off += 1
			worst_off = "%.0f,%.0f was put on the chunk centred %.0f,%.0f" \
				% [px, pz, cen.x, cen.y]
	_ok("a point is on the chunk that actually covers it", off == 0,
		"%d of 40 points land outside their own chunk — %s" % [off, worst_off])

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

	# --- and you can walk over the water -----------------------------
	#
	# THE ONE THAT MATTERS. Every check above is about geometry a render
	# already showed; this is the one that says whether the bridge is a
	# bridge or a picture of one. A deck with no collision under it
	# looks perfect from the air and drops you in the river.
	var walked := false
	for deck4 in all_decks:
		var m5: Vector2 = deck4["at"]
		var deck_y: float = (deck4["h0"] + deck4["h1"]) * 0.5
		var span_c := gen.make_chunk(WorldGen.chunk_of(
			Vector3(m5.x, deck_y, m5.y)))
		if span_c == null:
			continue
		await get_tree().process_frame
		var walker := CharacterBody3D.new()
		var wcap := CollisionShape3D.new()
		var wshape := CapsuleShape3D.new()
		wshape.height = 2.0
		wshape.radius = 0.4
		wcap.shape = wshape
		walker.add_child(wcap)
		walker.position = Vector3(m5.x, deck_y + 4.0, m5.y)
		add_child(walker)
		for i in 120:
			walker.velocity.y -= 9.8 * (1.0 / 60.0)
			walker.move_and_slide()
			await get_tree().physics_frame
		var landed := walker.global_position.y
		var river := t.water_at(m5.x, m5.y)
		_ok("and a body stays on the bridge instead of in the river",
			landed > deck_y - 0.6,
			"dropped onto a deck at %.1f over water at %.1f and ended at %.1f"
				% [deck_y, river, landed])
		print("      deck %.2f m, water %.2f m, body came to rest at %.2f m"
			% [deck_y, river, landed])
		walker.queue_free()
		walked = true
		break
	_ok("there was a bridge to stand on at all", walked,
		"none of the %d decks found could be built, so the check above "
			% all_decks.size() + "proved nothing")

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


func _same_path(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	if a.size() != b.size() or a.is_empty():
		return false
	for i in a.size():
		if not a[i].is_equal_approx(b[i]):
			return false
	return true


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
