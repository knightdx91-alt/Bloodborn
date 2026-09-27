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

## Chunks the SCENE supplies itself, as a half-width in chunks.
##
## Thornfield builds its own ground — a flat plane it has stood on
## since before there was a generator — and it sits on the levelled
## platform at its town site, which is flat at exactly the same height.
## So the two meet without a seam, and the generator simply leaves that
## square alone rather than drawing a second floor inside it.
##
## Chunk-aligned on purpose: a hole measured in metres would cut chunks
## in half and leave the town's plane fighting a generated one along
## the join.
@export var hole_chunks := 0

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
			if in_hole(at):
				continue
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


## OFF THE MAIN THREAD.
##
## This is the one optimisation on the generator that is structural
## rather than a guess about where time goes — and five of those
## guesses were wrong, so the distinction matters. A chunk costs ~48 ms
## and that is a three-frame stall no matter how cheap the work gets;
## moving it to a worker does not make it cheaper, it makes it
## invisible.
##
## Only the DATA is threaded. `WgBake.gather` is a pure function of the
## seed and the coordinates — no nodes, no scene tree — and it already
## exists, because baking needed exactly this split. Assembly stays on
## the main thread, where it must: `add_child`, resource loading and
## MultiMesh construction are not safe off it.
##
## Each worker gets its OWN WgTerrain. That looks wasteful and is the
## cheapest correct answer: FastNoiseLite is not documented as
## thread-safe, and because the generator is deterministic a second
## terrain on the same seed is the same terrain. No sharing, no lock,
## no doubt.
@export var threaded := true
## How many may be in flight at once.
@export var in_flight_max := 2

var _jobs: Dictionary = {}          # Vector2i -> { task, terrain, data }
var _thread_terrain: Array = []


## Is this chunk the scene's own ground rather than the generator's?
func in_hole(at: Vector2i) -> bool:
	return hole_chunks > 0 \
		and absi(at.x) <= hole_chunks and absi(at.y) <= hole_chunks


func _work() -> void:
	if not threaded:
		var made := 0
		while made < per_frame and not _wanted.is_empty():
			var at: Vector2i = _wanted.pop_front()
			if live.has(at):
				continue
			make_chunk(at)
			made += 1
		return

	# Anything finished gets assembled, within the frame budget.
	var done := 0
	for at in _jobs.keys():
		if done >= per_frame:
			break
		var job: Dictionary = _jobs[at]
		if not WorkerThreadPool.is_task_completed(job["task"]):
			continue
		WorkerThreadPool.wait_for_task_completion(job["task"])
		_jobs.erase(at)
		_thread_terrain.append(job["terrain"])
		if live.has(at):
			continue
		var c := WgChunk.new()
		c.name = "Chunk_%d_%d" % [at.x, at.y]
		add_child(c)
		c.build_baked(job["data"], at.x, at.y)
		live[at] = c
		built_total += 1
		chunk_built.emit(at, c)
		done += 1

	# And start more, up to the limit.
	while _jobs.size() < in_flight_max and not _wanted.is_empty():
		var at2: Vector2i = _wanted.pop_front()
		if live.has(at2) or _jobs.has(at2):
			continue
		_start(at2)


func _start(at: Vector2i) -> void:
	var mine: WgTerrain = _thread_terrain.pop_back() if not _thread_terrain.is_empty() \
		else WgTerrain.new(world_seed)
	var job := {"task": -1, "terrain": mine, "data": {}}
	_jobs[at] = job
	job["task"] = WorkerThreadPool.add_task(func() -> void:
		job["data"] = WgBake.gather(mine, at))


## Wait for every worker and drop what they were building.
##
## Godot will not let the scene tree go while a task is still running,
## and a chunk half-assembled into a freed node is a crash rather than
## a glitch.
func _exit_tree() -> void:
	for at in _jobs:
		WorkerThreadPool.wait_for_task_completion(_jobs[at]["task"])
	_jobs.clear()


## Build one chunk now, outside the budget. Used by the bakery and by
## harnesses that cannot wait for a frame each.
func make_chunk(at: Vector2i) -> WgChunk:
	if live.has(at):
		return live[at]
	if in_hole(at):
		return null
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
