class_name Waypost
extends Node3D
## A signpost on the road out, and the road actually going somewhere.
##
## The Hedges was reachable only from the launcher — a scene menu. The
## first answer to that was a signpost that CHANGED SCENES: better, but
## still a door. Then: *"i want the whole thing to just be a big world."*
##
## So the wood stands in the same scene as the town now, and this is
## what it always should have been — **a sign**. It tells you what is
## down the road and points at it. There is nothing to press, because
## there is nothing to load: you walk.
##
## It keeps a `destination` for roads that do still lead somewhere else,
## and leaves it empty when the place is simply over there.

## How close you have to be for the road to be an option.
const REACH := 4.0

## Where this road goes.
@export var destination := ""
## What the chip says.
@export var label := "Take the road"
## What the sign reads, for anyone close enough to read it.
@export var reads := ""
## Where the player stands when they come BACK through here.
@export var returns_to := Vector3.ZERO
## And which way they are facing when they do. Set explicitly rather
## than borrowed from the post's own rotation: the post is turned so its
## board can be READ by somebody walking out, and a player walking back
## in wants to be looking the other way.
@export var returns_facing := 0.0


func _ready() -> void:
	_build()


func _build() -> void:
	var post := MeshInstance3D.new()
	var beam := BoxMesh.new()
	beam.size = Vector3(0.16, 2.3, 0.16)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.36, 0.27, 0.18)
	wood.roughness = 1.0
	beam.material = wood
	post.mesh = beam
	post.position = Vector3(0, 1.15, 0)
	add_child(post)

	# The arm points WEST, which is where the Hedges are — "the Hedges
	# west" is what the board calls the wood. A sign that does not point
	# is furniture.
	var arm := MeshInstance3D.new()
	var plank := BoxMesh.new()
	plank.size = Vector3(1.5, 0.34, 0.07)
	var board := StandardMaterial3D.new()
	board.albedo_color = Color(0.52, 0.41, 0.27)
	board.roughness = 1.0
	plank.material = board
	arm.mesh = plank
	arm.position = Vector3(-0.62, 1.95, 0)
	add_child(arm)

	if reads != "":
		var text := Label3D.new()
		text.text = reads
		text.font_size = 96
		text.pixel_size = 0.0022
		text.position = Vector3(-0.62, 1.95, 0.05)
		text.modulate = Color(0.16, 0.12, 0.08)
		text.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		text.no_depth_test = false
		add_child(text)


func in_reach(who: Node3D) -> bool:
	return who != null \
		and who.global_position.distance_to(global_position) < REACH


## Tell the town where to put you when you come back.
##
## Split from `travel` so it can be checked: travel changes the scene,
## which tears down whatever is asking the question — a harness that
## called it simply died mid-run. The two things a journey does are
## remembering the way home and going, and only the second one is
## untestable.
func remember_way_home() -> void:
	TownState.set_arrival(returns_to, returns_facing)
	TownState.save()


## Set off. Returning puts you on this road rather than in the middle of
## the square you last spawned in.
func travel(tree: SceneTree) -> void:
	if destination == "":
		return
	remember_way_home()
	tree.change_scene_to_file(destination)
