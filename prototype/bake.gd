extends Node
## Write the country down, take a chunk out to edit, and put it back.
##
##     godot --path prototype --quit-after 100000 bake.tscn -- --r 8
##     godot --path prototype --quit-after 100000 bake.tscn -- --check
##     godot --path prototype --quit-after 100000 bake.tscn -- --out 42 45
##     godot --path prototype --quit-after 100000 bake.tscn -- --in 42 45
##
## tech.md §1a: draft offline, bake, commit, ship the committed land.
## This is the "bake" in that sentence. It writes to res://baked, which
## is where WorldGen looks before it reaches for the noise.
##
## Deliberately NOT run automatically. A bake is a decision — it fixes
## a particular world as the world — and doing it on every build would
## mean the land quietly changing whenever somebody touched a constant.
##
## **--check is the one that matters most**, and is the reason the rest
## of this is safe to use. A baked chunk is an override cut to fit the
## land around it; when the generator changes, that land moves and the
## override does not, and the seam becomes a step you walk into. This
## session moved it twice in one day — rivers cut 7 m channels, and the
## swell moved whole regions by tens of metres — and until `--check`
## existed nothing in the project would have said a word about it.

var radius := 4
var centre := Vector2i(42, 45)


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var t := WgTerrain.new(20260927)
	for i in args.size():
		var arg: String = args[i]
		if arg == "--r" and i + 1 < args.size():
			radius = int(args[i + 1])
		elif arg == "--check":
			_check(t)
			return
		elif arg == "--out" and i + 2 < args.size():
			_out(Vector2i(int(args[i + 1]), int(args[i + 2])))
			return
		elif arg == "--in" and i + 2 < args.size():
			_in(t, Vector2i(int(args[i + 1]), int(args[i + 2])))
			return
	_bake(t)


func _bake(t: WgTerrain) -> void:
	var side := radius * 2 + 1
	var total := side * side
	print("baking %d chunks (%.0f m across) around %s"
		% [total, float(side) * WgChunk.SIZE, str(centre)])
	print("generator fingerprint %d" % t.fingerprint())

	var t0 := Time.get_ticks_msec()
	var done := 0
	var bytes := 0
	for dx in range(-radius, radius + 1):
		for dz in range(-radius, radius + 1):
			var at := Vector2i(centre.x + dx, centre.y + dz)
			var data := WgBake.gather(t, at)
			# The provenance is stamped HERE rather than in `gather`,
			# because `gather` is also what the streaming worker calls
			# on every chunk in the world and it has no use for it.
			data["fingerprint"] = t.fingerprint()
			if WgBake.write(data):
				done += 1
				var f := FileAccess.open(WgBake.path_for(at), FileAccess.READ)
				if f != null:
					bytes += f.get_length()
					f.close()
			if done % 20 == 0:
				print("  %d / %d" % [done, total])

	var secs := float(Time.get_ticks_msec() - t0) / 1000.0
	print("baked %d chunks in %.1f s — %.1f MB, %.1f kB each"
		% [done, secs, float(bytes) / 1048576.0, float(bytes) / float(maxi(done, 1)) / 1024.0])
	print("%.2f km2 of land" % (float(total) * WgChunk.SIZE * WgChunk.SIZE / 1000000.0))
	get_tree().quit()


## Which committed overrides were cut to fit a generator that is gone.
func _check(t: WgTerrain) -> void:
	var now := t.fingerprint()
	print("generator fingerprint %d" % now)
	var dir := DirAccess.open(WgBake.DIR)
	if dir == null:
		print("no %s — nothing is baked, so nothing can be stale" % WgBake.DIR)
		get_tree().quit()
		return
	var fresh := 0
	var stale: Array[String] = []
	var unknown: Array[String] = []
	for name in dir.get_files():
		if not name.ends_with(".chunk"):
			continue
		var parts := name.trim_suffix(".chunk").split("_")
		if parts.size() != 3:
			continue
		var at := Vector2i(int(parts[1]), int(parts[2]))
		match WgBake.stale(at, t):
			WgBake.FRESH: fresh += 1
			WgBake.STALE: stale.append(name)
			WgBake.UNKNOWN: unknown.append(name)
	print("%d fresh, %d STALE, %d of unknown provenance"
		% [fresh, stale.size(), unknown.size()])
	for name in stale:
		print("  stale: %s" % name)
	for name in unknown:
		print("  no fingerprint: %s" % name)
	if not stale.is_empty():
		print("")
		print("A stale override was cut to fit land that has since moved.")
		print("Re-bake it, or edit it, but do not leave it: its edges no")
		print("longer meet the country around it.")
	get_tree().quit()


## Take a chunk out as text, so a person can move what stands on it.
func _out(at: Vector2i) -> void:
	var data := WgBake.read(at)
	if data.is_empty():
		print("nothing baked at %s — bake it first" % str(at))
		get_tree().quit()
		return
	var path := "%s/c_%d_%d.json" % [WgBake.DIR, at.x, at.y]
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot write %s" % path)
		get_tree().quit()
		return
	f.store_string(WgBake.to_json(data))
	f.close()
	print("wrote %s — %d pieces, %d solids"
		% [path, (data["pieces"] as Array).size(),
			(data["solids"] as Array).size()])
	print("edit the pieces and solids, then put it back with --in %d %d"
		% [at.x, at.y])
	get_tree().quit()


## And put it back.
func _in(t: WgTerrain, at: Vector2i) -> void:
	var path := "%s/c_%d_%d.json" % [WgBake.DIR, at.x, at.y]
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		print("no %s" % path)
		get_tree().quit()
		return
	var data := WgBake.from_json(f.get_as_text())
	f.close()
	if data.is_empty():
		get_tree().quit()
		return
	if data["at"] != at:
		print("%s says it is chunk %s" % [path, str(data["at"])])
		get_tree().quit()
		return
	# THE EDIT KEEPS ITS OWN PROVENANCE, not today's. A hand edit does
	# not make a stale chunk fresh: the land around it has still moved,
	# and stamping it with the current fingerprint would hide exactly
	# the thing `--check` exists to find.
	var was := int(data.get("fingerprint", 0))
	if WgBake.write(data):
		print("put %s back — %d pieces, %d solids, fingerprint %d%s"
			% [str(at), (data["pieces"] as Array).size(),
				(data["solids"] as Array).size(), was,
				"" if was == t.fingerprint() else "  (STALE — see --check)"])
	get_tree().quit()
