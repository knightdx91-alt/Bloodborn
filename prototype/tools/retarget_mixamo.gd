extends SceneTree

const MAP := {
	"mixamorig_Hips": "Hips",
	"mixamorig_Spine": "Spine",
	"mixamorig_Spine2": "Chest",
	"mixamorig_Neck": "Neck",
	"mixamorig_Head": "Head",
	"mixamorig_LeftShoulder": "Shoulder.L",
	"mixamorig_LeftArm": "UpperArm.L",
	"mixamorig_LeftForeArm": "LowerArm.L",
	"mixamorig_LeftHand": "Hand.L",
	"mixamorig_RightShoulder": "Shoulder.R",
	"mixamorig_RightArm": "UpperArm.R",
	"mixamorig_RightForeArm": "LowerArm.R",
	"mixamorig_RightHand": "Hand.R",
	"mixamorig_LeftUpLeg": "UpperLeg.L",
	"mixamorig_LeftLeg": "LowerLeg.L",
	"mixamorig_LeftFoot": "Foot.L",
	"mixamorig_LeftToeBase": "Toes.L",
	"mixamorig_RightUpLeg": "UpperLeg.R",
	"mixamorig_RightLeg": "LowerLeg.R",
	"mixamorig_RightFoot": "Foot.R",
	"mixamorig_RightToeBase": "Toes.R",
}

func _find(n: Node, t: String) -> Node:
	if n.get_class() == t: return n
	for c in n.get_children():
		var r := _find(c, t)
		if r != null: return r
	return null

func _init() -> void:
	var anim_scene := load("res://assets/animations/anim_Idle.fbx") as PackedScene
	var a := anim_scene.instantiate()
	var ap := _find(a, "AnimationPlayer") as AnimationPlayer
	var src: Animation = ap.get_animation("mixamo_com")
	var src_skel := _find(a, "Skeleton3D") as Skeleton3D

	var tgt_scene := load("res://assets/models/humanoid.fbx") as PackedScene
	var tgt := tgt_scene.instantiate()
	var tgt_skel := _find(tgt, "Skeleton3D") as Skeleton3D

	var out := Animation.new()
	out.length = src.length
	out.loop_mode = Animation.LOOP_LINEAR

	var kept := 0
	var dropped := 0
	var skipped_kind := 0
	for t in src.get_track_count():
		var path := String(src.track_get_path(t))          # e.g. "Skeleton3D:mixamorig_Hips"
		var parts := path.split(":")
		var bone := parts[parts.size() - 1]
		if not MAP.has(bone):
			dropped += 1
			continue

		# ROTATION ONLY. Bone *positions* belong to the source rig's
		# proportions — copying them onto a different skeleton collapses
		# it. This is the single most common way retargeting silently
		# fails, and it looks like success until you render it.
		var kind := src.track_get_type(t)
		if kind != Animation.TYPE_ROTATION_3D:
			skipped_kind += 1
			continue

		# Rest-pose correction. The two rigs hold their bones at
		# different resting angles, so a raw rotation from one lands
		# wrong on the other — the character ends up on its side. Take
		# the *change from the source's rest pose* and apply that same
		# change to the target's rest pose instead.
		var si := src_skel.find_bone(bone)
		var ti := tgt_skel.find_bone(MAP[bone])
		var s_rest := src_skel.get_bone_rest(si).basis.get_rotation_quaternion()
		var t_rest := tgt_skel.get_bone_rest(ti).basis.get_rotation_quaternion()

		var nt := out.add_track(kind)
		out.track_set_path(nt, NodePath("Skeleton3D:" + MAP[bone]))
		out.track_set_interpolation_type(nt, src.track_get_interpolation_type(t))
		for k in src.track_get_key_count(t):
			var q: Quaternion = src.track_get_key_value(t, k)
			var delta := s_rest.inverse() * q
			out.track_insert_key(nt, src.track_get_key_time(t, k), t_rest * delta)
		kept += 1

	print("RETARGET: kept ", kept, " rotation tracks; dropped ", dropped,
		" unmapped bones; skipped ", skipped_kind, " position/scale tracks")
	print("  out length: ", out.length, "  tracks: ", out.get_track_count())

	# Which humanoid bones ended up with no animation at all?
	var hs := load("res://assets/models/humanoid.fbx") as PackedScene
	var h := hs.instantiate()
	var skel := _find(h, "Skeleton3D") as Skeleton3D
	var animated := {}
	for t in out.get_track_count():
		animated[String(out.track_get_path(t)).split(":")[-1]] = true
	var missing: Array[String] = []
	for i in skel.get_bone_count():
		var bn := skel.get_bone_name(i)
		if not animated.has(bn):
			missing.append(bn)
	print("  humanoid bones with no track: ", missing)

	var err := ResourceSaver.save(out, "res://idle_retargeted.tres")
	print("  saved: ", error_string(err))
	quit()
