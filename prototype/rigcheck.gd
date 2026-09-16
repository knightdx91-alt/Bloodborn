extends Node
## Will a Mixamo clip drive this character, or fold it up?
##
## SPEC-character-v3.md's rule exists because v2 passed a character
## through Blender and the FBX exporter baked a Z-up→Y-up rotation into
## the skeleton's REST POSE. All 65 bone names matched and it still
## exploded. The lesson generalises past that one symptom: **a rig and
## the clips that drive it have to agree about more than names.**
##
## This checks the agreement that actually broke, on every humanoid the
## game might use. Two of them are known-good direct Mixamo downloads
## and are in the shipped prototype — they are here as CONTROLS, because
## a check that has never passed on something known good is not a check,
## it is a guess. An earlier version of this file asserted a rest-pose
## match within 5° and "no bone beyond 3m"; the working player model
## fails the first (16°) and a centimetre rig fails the second for
## reasons of unit rather than correctness. Both thresholds were
## measuring the harness.

var _fails: Array[String] = []


func _ok(n: String, c: bool, d: String) -> void:
	if c: print("  ok    %s" % n)
	else: _fails.append(n); print("  FAIL  %s — %s" % [n, d])


func _find(node: Node, cls: String) -> Node:
	if node.get_class() == cls: return node
	for c in node.get_children():
		var hit := _find(c, cls)
		if hit != null: return hit
	return null


func _ready() -> void:
	var clip_src := (load("res://assets/animations/anim_Walking.fbx") as PackedScene).instantiate()
	var sa := _find(clip_src, "AnimationPlayer") as AnimationPlayer
	var clip: Animation = sa.get_animation(sa.get_animation_list()[0])

	# What height the clip expects the pelvis to sit at.
	var clip_hips := 0.0
	for t in clip.get_track_count():
		if clip.track_get_type(t) == Animation.TYPE_POSITION_3D \
				and str(clip.track_get_path(t)).findn("Hips") != -1:
			clip_hips = (clip.track_get_key_value(t, 0) as Vector3).length()
	print("  the walk clip puts the hips at %.3f" % clip_hips)

	for who in [["paladin", true], ["skeleton_zombie", true],
			["brute", false], ["raider", false]]:
		var name := String(who[0])
		var known_good := bool(who[1])
		var n := (load("res://assets/models/%s.fbx" % name) as PackedScene).instantiate() as Node3D
		add_child(n)
		var skel := _find(n, "Skeleton3D") as Skeleton3D
		var hips := skel.find_bone("mixamorig_Hips")
		if skel == null or hips == -1:
			_ok("%s has a Mixamo pelvis" % name, false, "no mixamorig_Hips")
			continue

		var rest_hips: float = skel.get_bone_rest(hips).origin.length()
		# THE CHECK. The clip's pelvis track and the rig's pelvis rest
		# have to be in the same units, or the clip drives the hips to a
		# hundredth of their height and the body folds up around them.
		# That is what brute.fbx and raider.fbx do: their armatures are
		# authored in centimetres (hips rest ~104) with the parent node
		# scaled 0.01 to compensate, which looks right standing still and
		# collapses the moment a metre-authored clip touches it.
		var ratio: float = rest_hips / maxf(clip_hips, 0.0001)
		var agrees: bool = ratio > 0.5 and ratio < 2.0
		_ok("%s speaks the clip's units" % name, agrees,
			"pelvis rests at %.2f but the clip says %.2f — %.0fx out"
				% [rest_hips, clip_hips, ratio])
		print("      %s: hips rest %.3f, ratio %.2f%s"
			% [name, rest_hips, ratio, "  (known good)" if known_good else ""])

	print("")
	print("rigs: all clear" if _fails.is_empty() else "FAILED: %s" % ", ".join(_fails))
	get_tree().quit()
