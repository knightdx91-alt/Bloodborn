class_name WorldGen
extends Node3D
## The generated world, streamed in squares around whoever is walking.
##
## This is the piece `tech.md` §1a called the real engineering: not the
## generator, which is the cheap half, but the thing that decides what
## is in memory. 255 km² is about a thousand times the ground the game
## stood on before, on a phone, so a world that loads whole is not a
## world that loads.
##
## Chunks are built when they come within `radius` and freed when they
## fall outside `radius + HYSTERESIS`. The gap is deliberate: with a
## single threshold, a player standing exactly on a boundary builds and
## frees the same chunk on alternate frames for as long as they stand
## there, which costs more than either loading or unloading.
##
## **Budgeted per frame.** Building a chunk means thousands of noise
## samples, a mesh, a collision field and a few hundred instantiated
## scenes; doing several in one frame is a visible stall. `per_frame`
## caps it, and the queue is sorted so the nearest missing chunk is
## always the next one built.

const HYSTERESIS := 1

@export var radius := 3
@export var per_frame := 1
@export var world_seed := 20260927

var terrain: WgTerrain = null
## Vector2i -> WgChunk
var live: Dictionary = {}
var _wanted: Array[Vector2i] = []
var _follow: Node3D = null

## Counters a harness can read without walking the tree.
var built_total := 0
var freed_total := 0
## How many came off disk rather than out of the noise.
var loaded_baked := 0
## Off, and a chunk is always generated. A harness comparing the two
## needs to be able to say so.
@export var use_baked := true

signal chunk_built(at: Vector2i, chunk: WgChunk)


func _ready() -> void:
	if terrain == null:
		terrain = WgTerrain.new(world_seed)


## Stream around this node. Null stops streaming without freeing.
func follow(who: Node3D) -> void:
	_follow = who


## The chunk coordinates a world position falls in.
static func chunk_of(at: Vector3) -> Vector2i:
	return Vector2i(int(floor(at.x / WgChunk.SIZE)),
		int(floor(at.z / WgChunk.SIZE)))


func _process(_delta: float) -> void:
	if _follow == null or not is_instance_valid(_follow):
		return
	_refresh(chunk_of(_follow.global_position))
	_work()


## Decide what should exist, and drop what should not.
func _refresh(centre: Vector2i) -> void:
	_wanted.clear()
	for dx in range(-radius, radius + 1):
		for dz in range(-radius, radius + 1):
			var at := Vector2i(centre.x + dx, centre.y + dz)
			if not live.has(at):
				_wanted.append(at)

	# Nearest first, so walking forward loads the ground ahead rather
	# than a corner behind.
	_wanted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a - centre).length_squared() < (b - centre).length_squared())

	var drop: Array[Vector2i] = []
	for at in live:
		var d: Vector2i = at - centre
		if maxi(absi(d.x), absi(d.y)) > radius + HYSTERESIS:
			drop.append(at)
	for at in drop:
		var c: WgChunk = live[at]
		live.erase(at)
		c.queue_free()
		freed_total += 1


func _work() -> void:
	var made := 0
	while made < per_frame and not _wanted.is_empty():
		var at: Vector2i = _wanted.pop_front()
		if live.has(at):
			continue
		make_chunk(at)
		made += 1


## Build one chunk now, outside the budget. Used by the bakery and by
## harnesses that cannot wait for a frame each.
func make_chunk(at: Vector2i) -> WgChunk:
	if live.has(at):
		return live[at]
	if terrain == null:
		terrain = WgTerrain.new(world_seed)
	var c := WgChunk.new()
	c.name = "Chunk_%d_%d" % [at.x, at.y]
	add_child(c)
	# BAKED IF THERE IS ONE, generated if there is not.
	#
	# tech.md §1a: the generator is a content tool and the committed
	# land is what ships. Preferring the bake here is what makes that
	# true in the build rather than only in the document — and falling
	# back keeps the generator usable while the land is still being
	# drafted, which is where it is now.
	var baked := WgBake.read(at) if use_baked else {}
	if not baked.is_empty():
		c.build_baked(baked, at.x, at.y)
		loaded_baked += 1
	else:
		c.build(terrain, at.x, at.y)
	live[at] = c
	built_total += 1
	chunk_built.emit(at, c)
	return c


## Everything within radius of a point, built at once. For a spike or a
## bake, where there is no player and no frame budget to respect.
func build_block(centre: Vector2i, r: int) -> void:
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			make_chunk(Vector2i(centre.x + dx, centre.y + dz))


## The ground height anywhere, without needing the chunk to exist —
## which is how a body gets placed before the world under it is built.
func height_at(x: float, z: float) -> float:
	if terrain == null:
		terrain = WgTerrain.new(world_seed)
	return terrain.height_at(x, z)
