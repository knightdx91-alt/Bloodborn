class_name Armour
extends RefCounted
## Grey-box armour, built from primitives and hung on the skeleton.
##
## This is a placeholder for the geometry and **not** a placeholder for
## the structure. `pillars.md` **L63** tracks armour across head, torso,
## arms and legs, each with its own condition, and says a piece that
## breaks "does not merely stop protecting — **it comes off**, and that
## slot is bare for the rest of the fight... a fighter who started the
## day in plate finishes it half bare and increasingly desperate."
##
## A character with its armour baked into one mesh cannot do that, which
## is most bought characters and all of Mixamo's — so the slots are worth
## building before the meshes are worth buying. When real pieces arrive
## they replace the boxes below and nothing else changes.

enum Slot { HEAD, TORSO, ARMS, LEGS }

## Which Mixamo bone carries each piece, and where along it.
##
## Limb bones point their local +Y down the limb — measured off the rest
## pose, not assumed — so an offset in +Y slides a piece toward the hand
## or the foot.
##
## `size` is the piece's FULL EXTENT, not a radius. Both primitives below
## are built at diameter 1 so that scale and size are the same number;
## reading it as a radius once put a bucket on the character's head.
const PIECES := {
	Slot.HEAD: [
		{"bone": "Head", "shape": "dome", "size": Vector3(0.195, 0.25, 0.215),
		 "at": Vector3(0.0, 0.075, 0.005), "metal": true},
		{"bone": "Head", "shape": "box", "size": Vector3(0.03, 0.10, 0.035),
		 "at": Vector3(0.0, 0.055, 0.095), "metal": true},
	],
	Slot.TORSO: [
		{"bone": "Spine2", "shape": "dome", "size": Vector3(0.36, 0.40, 0.26),
		 "at": Vector3(0.0, 0.04, 0.0), "metal": true},
		{"bone": "Hips", "shape": "dome", "size": Vector3(0.32, 0.20, 0.25),
		 "at": Vector3(0.0, 0.03, 0.0), "metal": false},
	],
	Slot.ARMS: [
		{"bone": "LeftArm", "shape": "dome", "size": Vector3(0.175, 0.16, 0.175),
		 "at": Vector3(0.0, 0.025, 0.0), "metal": true},
		{"bone": "RightArm", "shape": "dome", "size": Vector3(0.175, 0.16, 0.175),
		 "at": Vector3(0.0, 0.025, 0.0), "metal": true},
		{"bone": "LeftForeArm", "shape": "tube", "size": Vector3(0.115, 0.18, 0.115),
		 "at": Vector3(0.0, 0.12, 0.0), "metal": true},
		{"bone": "RightForeArm", "shape": "tube", "size": Vector3(0.115, 0.18, 0.115),
		 "at": Vector3(0.0, 0.12, 0.0), "metal": true},
	],
	Slot.LEGS: [
		{"bone": "LeftLeg", "shape": "tube", "size": Vector3(0.135, 0.26, 0.135),
		 "at": Vector3(0.0, 0.15, 0.0), "metal": true},
		{"bone": "RightLeg", "shape": "tube", "size": Vector3(0.135, 0.26, 0.135),
		 "at": Vector3(0.0, 0.15, 0.0), "metal": true},
		{"bone": "LeftUpLeg", "shape": "tube", "size": Vector3(0.175, 0.26, 0.175),
		 "at": Vector3(0.0, 0.15, 0.0), "metal": false},
		{"bone": "RightUpLeg", "shape": "tube", "size": Vector3(0.175, 0.26, 0.175),
		 "at": Vector3(0.0, 0.15, 0.0), "metal": false},
	],
}

## Hang a harness on `skel`. Returns slot -> the nodes wearing it, so the
## caller can take a slot off later.
static func fit(skel: Skeleton3D, iron: Color, leather: Color) -> Dictionary:
	var metal := Look.metal_material(iron)
	var hide := Look.solid_material(leather, 8.0, 0.92)
	var worn := {}

	for slot in PIECES:
		var nodes: Array[Node3D] = []
		for piece in PIECES[slot]:
			var bone := skel.find_bone("mixamorig_" + piece["bone"])
			if bone < 0:
				push_warning("no bone %s; that piece goes unworn" % piece["bone"])
				continue

			var mount := BoneAttachment3D.new()
			mount.bone_idx = bone
			skel.add_child(mount)

			var mesh := MeshInstance3D.new()
			var size: Vector3 = piece["size"]
			match piece["shape"]:
				"dome":
					var sphere := SphereMesh.new()
					sphere.radius = 0.5
					sphere.height = 1.0
					mesh.mesh = sphere
				"tube":
					var tube := CylinderMesh.new()
					tube.top_radius = 0.42
					tube.bottom_radius = 0.5
					tube.height = 1.0
					mesh.mesh = tube
				_:
					var box := BoxMesh.new()
					box.size = Vector3.ONE
					mesh.mesh = box
			mesh.scale = size
			mesh.position = piece["at"]
			mesh.material_override = metal if piece["metal"] else hide
			mount.add_child(mesh)
			nodes.append(mount)
		worn[slot] = nodes
	return worn
