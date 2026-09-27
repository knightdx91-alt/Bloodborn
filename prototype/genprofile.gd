extends Node
## Where a chunk's time actually goes.
##
## Six guesses about this generator's cost have been wrong and one
## measurement was right, so this exists to make measuring the cheap
## thing to do. It builds real chunks through `WgChunk.build` with
## `WgChunk.profile` on, so the numbers are the real path rather than a
## reconstruction of it that can drift.
##
##     godot --headless --path prototype genprofile.tscn -- <cx> <cz> <n>
##
## Defaults to the chunks just outside Thornfield's own ground, which
## is where the town's streaming works and where a 67 ms chunk was
## first noticed.

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var cx0 := int(args[0]) if args.size() > 0 else 5
	var cz0 := int(args[1]) if args.size() > 1 else 5
	var side := int(args[2]) if args.size() > 2 else 3

	var t := WgTerrain.new(20260927)
	# One chunk first, unprofiled, so the caches everything shares are
	# warm and this measures a steady-state chunk rather than the first
	# one in an empty world.
	var warm := WgChunk.new()
	add_child(warm)
	warm.build(t, cx0 - 1, cz0 - 1)
	warm.queue_free()

	WgChunk.profile_reset()
	WgChunk.profile = true
	var n := 0
	var total := 0
	for dx in side:
		for dz in side:
			var c := WgChunk.new()
			add_child(c)
			var t0 := Time.get_ticks_usec()
			c.build(t, cx0 + dx, cz0 + dz)
			total += Time.get_ticks_usec() - t0
			c.queue_free()
			n += 1
	WgChunk.profile = false

	print("%d chunks from (%d,%d), %.1f ms each" % [n, cx0, cz0,
		float(total) / float(n) / 1000.0])
	var rows: Array = []
	for phase in WgChunk.spent:
		rows.append([phase, int(WgChunk.spent[phase])])
	rows.sort_custom(func(a, b): return a[1] > b[1])
	# Sub-phases are indented and are INSIDE their parent, so counting
	# them again would make the remainder negative — which it did, by
	# exactly the parent's share.
	var named := 0
	for row in rows:
		if not String(row[0]).begins_with(" "):
			named += int(row[1])
		print("  %-16s %7.2f ms  %5.1f%%" % [row[0],
			float(row[1]) / float(n) / 1000.0,
			100.0 * float(row[1]) / float(maxi(total, 1))])
	print("  %-16s %7.2f ms  %5.1f%%" % ["(unaccounted)",
		float(total - named) / float(n) / 1000.0,
		100.0 * float(total - named) / float(maxi(total, 1))])
	get_tree().quit()
