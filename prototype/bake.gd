extends Node
## Write the country down.
##
##     godot --path prototype --quit-after 100000 bake.tscn -- --r 8
##
## tech.md §1a: draft offline, bake, commit, ship the committed land.
## This is the "bake" in that sentence. It writes to res://baked, which
## is where WorldGen looks before it reaches for the noise.
##
## Deliberately NOT run automatically. A bake is a decision — it fixes
## a particular world as the world — and doing it on every build would
## mean the land quietly changing whenever somebody touched a constant.

var radius := 4
var centre := Vector2i(42, 45)


func _ready() -> void:
	for i in OS.get_cmdline_user_args().size():
		var arg: String = OS.get_cmdline_user_args()[i]
		if arg == "--r" and i + 1 < OS.get_cmdline_user_args().size():
			radius = int(OS.get_cmdline_user_args()[i + 1])

	var t := WgTerrain.new(20260927)
	var side := radius * 2 + 1
	var total := side * side
	print("baking %d chunks (%.0f m across) around %s"
		% [total, float(side) * WgChunk.SIZE, str(centre)])

	var t0 := Time.get_ticks_msec()
	var done := 0
	var bytes := 0
	for dx in range(-radius, radius + 1):
		for dz in range(-radius, radius + 1):
			var at := Vector2i(centre.x + dx, centre.y + dz)
			var data := WgBake.gather(t, at)
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
	print("%.2f km² of land" % (float(total) * WgChunk.SIZE * WgChunk.SIZE / 1000000.0))
	get_tree().quit()
