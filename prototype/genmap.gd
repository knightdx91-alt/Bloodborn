extends Node
## A hillshaded map of the country, straight from the heightfield.
##
## Rendering the land to look at it means building chunks, and a chunk
## is 64 m: seeing a 3.6 km river needs 3,200 of them. So this asks the
## heightfield directly and shades the result, which costs one height
## sample per pixel and shows shapes — river networks, the wheel of
## wedges, the town platforms — that no ground-level shot can.
##
## It is NOT a substitute for looking at a frame. A map cannot tell you
## whether country is worth walking across. It can tell you whether the
## rivers join up, which a frame cannot.
##
##     godot --headless --path prototype genmap.tscn -- <span_m> <px> [x z]
##
## Without x and z it centres on Godsgrave. With them it centres on
## that point in Thornfield's frame, which is the frame everything else
## in the generator uses.

var out_path := "/tmp/gen/map.png"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var span := float(args[0]) if args.size() > 0 else 12000.0
	var px := int(args[1]) if args.size() > 1 else 900

	var t := WgTerrain.new(20260927)
	var hub := t.capitol_site()
	if args.size() > 3:
		hub = Vector3(float(args[2]), 0.0, float(args[3]))
	var step := span / float(px)
	var h := PackedFloat32Array()
	h.resize(px * px)
	# Water, kept separately: ridged country is full of dark creases that
	# look exactly like rivers in a hillshade, so a map that only shades
	# relief cannot answer "is that a river or a fold". Painting the
	# channel is the only way to tell them apart.
	var wet := PackedByteArray()
	wet.resize(px * px)
	for j in px:
		for i in px:
			var x := hub.x + (float(i) / float(px) - 0.5) * span
			var z := hub.z + (float(j) / float(px) - 0.5) * span
			h[j * px + i] = t.height_at(x, z)
			wet[j * px + i] = 1 if t.river_distance(x, z) <= WgRivers.CHANNEL else 0
		if j % 100 == 0:
			print("  row %d/%d" % [j, px])

	var img := Image.create(px, px, false, Image.FORMAT_RGB8)
	for j in px:
		for i in px:
			var c := _shade(h, px, i, j, step)
			if wet[j * px + i] == 1:
				c = c.lerp(Color(0.24, 0.34, 0.40), 0.85)
			img.set_pixel(i, j, c)
	DirAccess.make_dir_recursive_absolute("/tmp/gen")
	if args.size() > 4:
		out_path = "/tmp/gen/%s.png" % args[4]
	img.save_png(out_path)
	print("wrote %s  (%.0f m across, %.1f m/px, centred %.0f,%.0f)"
		% [out_path, span, step, hub.x, hub.z])
	get_tree().quit()


## Lambert against a light from the north-west, times a height ramp, so
## both the relief and the levels read at once.
func _shade(h: PackedFloat32Array, px: int, i: int, j: int, step: float) -> Color:
	var i0: int = maxi(i - 1, 0)
	var i1: int = mini(i + 1, px - 1)
	var j0: int = maxi(j - 1, 0)
	var j1: int = mini(j + 1, px - 1)
	var dx := (h[j * px + i1] - h[j * px + i0]) / (float(i1 - i0) * step)
	var dz := (h[j1 * px + i] - h[j0 * px + i]) / (float(j1 - j0) * step)
	var n := Vector3(-dx, 1.0, -dz).normalized()
	var lit: float = clampf(n.dot(Vector3(-0.55, 0.62, -0.55).normalized()),
		0.0, 1.0)
	var v: float = h[j * px + i]
	var lift: float = clampf((v + 40.0) / 120.0, 0.0, 1.0)
	var base := Color(0.32, 0.36, 0.28).lerp(Color(0.80, 0.78, 0.66), lift)
	return base * (0.30 + 0.85 * lit)
