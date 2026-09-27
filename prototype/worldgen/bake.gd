class_name WgBake
extends RefCounted
## Writing the country down, and reading it back.
##
## `tech.md` §1a settles the shape of this: **generation is a content
## tool, not a runtime system.** Draft the land offline, bake it, commit
## the result, and ship the committed land. A world rebuilt from a seed
## on arrival cannot hold the clock, the territory, the contracts or the
## war — and beyond that, a baked world is one somebody can go and
## CHANGE. A hill that is wrong stops being a tuning argument about
## noise and becomes a file you edit.
##
## The format is deliberately dull: a header, the heightfield, the
## vertex colours, and a list of what stands on it. No compression and
## no cleverness, because the thing that matters about a bake is that
## it reads back EXACTLY — `bakecheck` asserts a baked chunk is
## identical to the generated one, and that property is worth more than
## any number of saved bytes.

const MAGIC := 0x4D524B31  # "MRK1"
const VERSION := 1
const DIR := "res://baked"


static func path_for(at: Vector2i, dir: String = DIR) -> String:
	return "%s/c_%d_%d.chunk" % [dir, at.x, at.y]


## Everything a chunk is, as plain data.
##
## Gathered by asking the same generator a chunk asks, so there is one
## description of what is in a square of world rather than two that can
## drift apart.
static func gather(terrain: WgTerrain, at: Vector2i) -> Dictionary:
	var size := WgChunk.SIZE
	var verts := WgChunk.VERTS
	var origin := Vector3(float(at.x) * size, 0.0, float(at.y) * size)
	var half := size * 0.5
	var step := size / float(verts - 1)

	var wide := verts + 2
	var grid := PackedFloat32Array()
	grid.resize(wide * wide)
	for iz in wide:
		for ix in wide:
			grid[iz * wide + ix] = terrain.height_at(
				origin.x - half + float(ix - 1) * step,
				origin.z - half + float(iz - 1) * step)

	var heights := PackedFloat32Array()
	heights.resize(verts * verts)
	var colours := PackedByteArray()
	colours.resize(verts * verts * 3)

	var roads := WgRoads.near(terrain, terrain.seed_value,
		origin.x - size, origin.z - size, origin.x + size, origin.z + size)

	for iz in verts:
		for ix in verts:
			var gi := (iz + 1) * wide + (ix + 1)
			var h: float = grid[gi]
			var vi := iz * verts + ix
			heights[vi] = h
			var dx: float = grid[gi + 1] - grid[gi - 1]
			var dz: float = grid[gi + wide] - grid[gi - wide]
			var slope: float = Vector2(dx, dz).length() / (2.0 * step)
			var wx := origin.x - half + float(ix) * step
			var wz := origin.z - half + float(iz) * step
			var col := terrain.shade(wx, wz, h, slope)
			var worn := WgRoads.wear(roads, wx, wz)
			if worn > 0.0:
				col = col.lerp(WgRoads.surface(), worn)
			colours[vi * 3 + 0] = int(clampf(col.r, 0.0, 1.0) * 255.0)
			colours[vi * 3 + 1] = int(clampf(col.g, 0.0, 1.0) * 255.0)
			colours[vi * 3 + 2] = int(clampf(col.b, 0.0, 1.0) * 255.0)

	# What stands on it, gathered exactly as WgChunk gathers it.
	var keep_clear: Array = []
	var pieces: Array = []
	var solids: Array = []

	var scx := int(floor(origin.x / WgSettlement.CELL))
	var scz := int(floor(origin.z / WgSettlement.CELL))
	var hamlets: Array = []
	for dx2 in range(-1, 2):
		for dz2 in range(-1, 2):
			var built := WgSettlement.cached(terrain, terrain.seed_value,
				scx + dx2, scz + dz2)
			if built.houses == 0 and built.pieces.is_empty():
				continue
			hamlets.append(built)
			keep_clear.append_array(built.keep_clear)

	var lcx := int(floor(origin.x / WgLandmark.CELL))
	var lcz := int(floor(origin.z / WgLandmark.CELL))
	var marks: Array = []
	for dx3 in range(-1, 2):
		for dz3 in range(-1, 2):
			var mark := WgLandmark.cached(terrain, terrain.seed_value,
				lcx + dx3, lcz + dz3)
			if mark.is_empty() or (mark["pieces"] as Array).is_empty():
				continue
			marks.append(mark)
			keep_clear.append_array(mark["keep_clear"])

	var mine := Rect2(origin.x - half, origin.z - half, size, size)
	for item in WgScatter.in_rect(terrain, origin.x - half, origin.z - half,
			origin.x + half, origin.z + half, keep_clear, roads):
		pieces.append(item)
	for built in hamlets:
		for piece in built.pieces:
			var p: Vector3 = piece["position"]
			if mine.has_point(Vector2(p.x, p.z)):
				pieces.append(piece)
		for solid in built.solids:
			var sp: Vector3 = solid["position"]
			if mine.has_point(Vector2(sp.x, sp.z)):
				solids.append(solid)
	for mark in marks:
		for piece in mark["pieces"]:
			var mp: Vector3 = piece["position"]
			if mine.has_point(Vector2(mp.x, mp.z)):
				pieces.append(piece)

	return {
		"at": at, "heights": heights, "colours": colours,
		"pieces": pieces, "solids": solids,
	}


## `version` exists for one reader: the check that a stale bake is
## REFUSED rather than silently used. The file is compressed, so a test
## cannot reach in and poke the header byte, and a rejection path that
## has never once been exercised is not a rejection path.
static func write(data: Dictionary, dir: String = DIR,
		version: int = VERSION) -> bool:
	DirAccess.make_dir_recursive_absolute(dir)
	var at: Vector2i = data["at"]
	# COMPRESSED. The heightfield is smooth and the colour field is
	# smoother, so a general-purpose compressor does very well on both —
	# and at 255 km2 the difference between 33 kB and 8 kB a chunk is
	# the difference between a bake that can ship and one that cannot.
	var f := FileAccess.open_compressed(path_for(at, dir), FileAccess.WRITE,
		FileAccess.COMPRESSION_ZSTD)
	if f == null:
		push_error("cannot write %s" % path_for(at, dir))
		return false
	f.store_32(MAGIC)
	f.store_32(version)
	f.store_32(at.x)
	f.store_32(at.y)

	var heights: PackedFloat32Array = data["heights"]
	f.store_32(heights.size())
	for h in heights:
		f.store_float(h)

	var colours: PackedByteArray = data["colours"]
	f.store_32(colours.size())
	f.store_buffer(colours)

	# A string table, because the same model path repeats a hundred
	# times in a chunk and storing it a hundred times is the one piece
	# of thrift worth having here.
	var paths: Array[String] = []
	var index := {}
	var pieces: Array = data["pieces"]
	for piece in pieces:
		var path: String = piece["path"]
		if not index.has(path):
			index[path] = paths.size()
			paths.append(path)
	f.store_32(paths.size())
	for path in paths:
		f.store_pascal_string(path)

	f.store_32(pieces.size())
	for piece in pieces:
		f.store_32(int(index[piece["path"]]))
		var p: Vector3 = piece["position"]
		f.store_float(p.x); f.store_float(p.y); f.store_float(p.z)
		f.store_float(float(piece.get("yaw", 0.0)))
		var raw = piece.get("scale", 1.0)
		var sc: Vector3 = raw if raw is Vector3 else Vector3(raw, raw, raw)
		f.store_float(sc.x); f.store_float(sc.y); f.store_float(sc.z)

	var solids: Array = data["solids"]
	f.store_32(solids.size())
	for solid in solids:
		var sp: Vector3 = solid["position"]
		var ss: Vector3 = solid["size"]
		f.store_float(sp.x); f.store_float(sp.y); f.store_float(sp.z)
		f.store_float(ss.x); f.store_float(ss.y); f.store_float(ss.z)
		f.store_float(float(solid.get("yaw", 0.0)))
	f.close()
	return true


## Read a baked chunk. Empty dictionary if there is not one.
static func read(at: Vector2i, dir: String = DIR) -> Dictionary:
	var path := path_for(at, dir)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open_compressed(path, FileAccess.READ,
		FileAccess.COMPRESSION_ZSTD)
	if f == null:
		return {}
	if f.get_32() != MAGIC:
		push_error("%s is not a chunk" % path)
		return {}
	var version := f.get_32()
	if version != VERSION:
		# Loudly, because silently generating instead of loading is how
		# a stale bake hides for a week.
		push_error("%s is version %d, this build reads %d" % [path, version, VERSION])
		return {}
	var cx := f.get_32()
	var cz := f.get_32()

	var hn := f.get_32()
	var heights := PackedFloat32Array()
	heights.resize(hn)
	for i in hn:
		heights[i] = f.get_float()

	var cn := f.get_32()
	var colours := f.get_buffer(cn)

	var pn := f.get_32()
	var paths: Array[String] = []
	for i in pn:
		paths.append(f.get_pascal_string())

	var count := f.get_32()
	var pieces: Array = []
	for i in count:
		var pi := f.get_32()
		var px := f.get_float(); var py := f.get_float(); var pz := f.get_float()
		var yaw := f.get_float()
		var sx := f.get_float(); var sy := f.get_float(); var sz := f.get_float()
		pieces.append({
			"path": paths[pi] if pi < paths.size() else "",
			"position": Vector3(px, py, pz),
			"yaw": yaw,
			"scale": Vector3(sx, sy, sz),
		})

	var sn := f.get_32()
	var solids: Array = []
	for i in sn:
		var ax := f.get_float(); var ay := f.get_float(); var az := f.get_float()
		var bx := f.get_float(); var by := f.get_float(); var bz := f.get_float()
		var syaw := f.get_float()
		solids.append({
			"position": Vector3(ax, ay, az),
			"size": Vector3(bx, by, bz),
			"yaw": syaw,
		})
	f.close()
	return {
		"at": Vector2i(cx, cz), "heights": heights, "colours": colours,
		"pieces": pieces, "solids": solids,
	}
