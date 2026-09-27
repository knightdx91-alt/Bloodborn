#!/usr/bin/env bash
# Does the generator's fingerprint actually see the generator?
#
# `WgTerrain.fingerprint()` is what stops a baked override outliving the
# land it was cut to fit: bake.tscn --check compares it, and a chunk
# whose stored fingerprint no longer matches is named as stale. That
# protection is worth exactly as much as the fingerprint's coverage,
# and a hash that misses the change you just made is worse than none,
# because it says "fresh" with authority.
#
# So this changes one constant at a time and asserts the number moves.
# It is not a harness — it edits source files, which is why it lives
# here and not beside the *check.tscn scenes — and it is how four real
# blind spots were found:
#
#   - river depth and shape (the spiral samples are a kilometre and a
#     half from the nearest channel, where the cut does nothing)
#   - road wear (blended into a chunk's vertex colours, never into
#     ground_at, so no height or colour sample sees it)
#   - the six town platforms (no blind sample in 3,870 km2 lands on one)
#   - a wedge's own tree list (the scatter rects were all in other
#     wedges)
#
# and why the probability samples are four hundred cells rather than
# forty: moving a chance by a point in a hundred flips a cell in a
# hundred.
#
#     ci/fingerprint-coverage.sh
#
# Run it after changing anything about how the land is made. Every line
# must say "caught".
set -u
cd "$(dirname "$0")/../prototype" || exit 1
G=${GODOT:-/tmp/godot/Godot_v4.3-stable_linux.x86_64}

fp() {
	stdbuf -o0 timeout 600 "$G" --headless --path . --quit-after 100000 \
		bake.tscn -- --check 2>&1 | grep -oP 'fingerprint \K\d+' | head -1
}

base=$(fp)
echo "base $base"
bad=0

try() {  # name file sed-expression
	cp "$2" /tmp/fp.bak
	sed -i "$3" "$2"
	local n
	n=$(fp)
	cp /tmp/fp.bak "$2"
	if [ "$n" = "$base" ]; then
		echo "MISSED  $1"
		bad=$((bad + 1))
	else
		echo "caught  $1"
	fi
}

try "the swell, by 10 cm"          worldgen/terrain.gd 's/^const SWELL := 30.0$/const SWELL := 30.1/'
try "a wedge's relief, by 10 cm"   worldgen/terrain.gd 's/^\tfens.relief = 5.0$/\tfens.relief = 5.1/'
try "a wedge's ground colour"      worldgen/terrain.gd 's/^\tfens.ground = Color(0.26, 0.31, 0.21)$/\tfens.ground = Color(0.27, 0.31, 0.21)/'
try "the detail noise frequency"   worldgen/terrain.gd 's|^\t_detail.frequency = 1.0 / 70.0$|\t_detail.frequency = 1.0 / 71.0|'
try "the town platform width"      worldgen/terrain.gd 's/^const TOWN_FLAT := 420.0$/const TOWN_FLAT := 421.0/'
try "which trees grow in the Fens" worldgen/terrain.gd 's/^\tfens.trees = \["DeadTree_1", "CommonTree_3", "CommonTree_5"\]$/\tfens.trees = ["DeadTree_1", "CommonTree_3", "CommonTree_4"]/'
try "tree density in the Hedges"   worldgen/terrain.gd 's/^\thedges.tree_density = 0.22$/\thedges.tree_density = 0.23/'
try "river depth, by 10 cm"        worldgen/rivers.gd  's/^const DEPTH := 7.0$/const DEPTH := 6.9/'
try "river valley width, by 1 m"   worldgen/rivers.gd  's/^const VALLEY := 150.0$/const VALLEY := 151.0/'
try "the water surface height"     worldgen/rivers.gd  's/^const RISE := 1.6$/const RISE := 1.7/'
try "how often a river springs"    worldgen/rivers.gd  's/^const SOURCE_CHANCE := 0.55$/const SOURCE_CHANCE := 0.56/'
try "how far a river may turn"     worldgen/rivers.gd  's/^\tconst TURN := 0.72.*$/\tconst TURN := 0.74/'
try "how wide a road is worn"      worldgen/roads.gd   's/^const WIDTH := \([0-9.]*\)$/const WIDTH := 9.5/'
try "how often a hamlet appears"   worldgen/settlement.gd 's/^const CHANCE := \([0-9.]*\)$/const CHANCE := 0.41/'
try "how often a landmark does"    worldgen/landmark.gd   's/^const CHANCE := 0.30$/const CHANCE := 0.31/'

echo ""
if [ "$bad" -eq 0 ]; then
	echo "fingerprint: all clear"
else
	echo "FAILED: $bad generator changes the fingerprint cannot see"
	exit 1
fi
