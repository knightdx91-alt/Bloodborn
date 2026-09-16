# tools/build_quadrupeds.py — build models/wolf.fbx + models/boar.fbx and
# their four animation clips each (Idle/Walk/Run/Attack), all procedural.
#
# Each species gets its own ~20-bone armature (spine chain, 4x 3-segment
# legs, neck/head/jaw, 2-segment tail) built fresh in Blender — no Mixamo
# round-trip. Animations are authored procedurally by sampling pose
# functions and keyframing every bone each frame (Blender 4.5 auto-creates
# the action slot on first keyframe_insert).
#
# Convention (matches the repo's one-clip-per-file layout):
#   models/wolf.fbx          armature + mesh, no animation
#   animations/wolf_Idle.fbx  armature + Idle action only
#   .../wolf_Walk.fbx, wolf_Run.fbx, wolf_Attack.fbx (same for boar_*)
#
# Run from this directory: blender --background --python build_quadrupeds.py

import bpy
import os
import math
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUTM = os.path.join(HERE, "..", "models")
OUTA = os.path.join(HERE, "..", "animations")
os.makedirs(OUTM, exist_ok=True)
os.makedirs(OUTA, exist_ok=True)

# ---------------------------------------------------------------- rigs
# (name, parent, head, tail) — Blender Z-up, character faces -Y (matches the
# Mixamo convention used by the humanoid enemies, so exports face +Z in FBX).
WOLF_BONES = [
    ("Root", None, (0, 0, 0.62), (0, -0.06, 0.62)),
    ("Spine", "Root", (0, 0, 0.62), (0, -0.25, 0.66)),
    ("Chest", "Spine", (0, -0.25, 0.66), (0, -0.50, 0.64)),
    ("Neck", "Chest", (0, -0.50, 0.64), (0, -0.68, 0.78)),
    ("Head", "Neck", (0, -0.68, 0.78), (0, -0.88, 0.74)),
    ("Jaw", "Head", (0, -0.80, 0.70), (0, -0.94, 0.66)),
    ("Tail1", "Root", (0, 0.04, 0.62), (0, 0.24, 0.57)),
    ("Tail2", "Tail1", (0, 0.24, 0.57), (0, 0.44, 0.50)),
    ("FL_Upper", "Root", (0.15, -0.42, 0.60), (0.15, -0.42, 0.32)),
    ("FL_Lower", "FL_Upper", (0.15, -0.42, 0.32), (0.15, -0.44, 0.10)),
    ("FL_Paw", "FL_Lower", (0.15, -0.44, 0.10), (0.15, -0.52, 0.02)),
    ("FR_Upper", "Root", (-0.15, -0.42, 0.60), (-0.15, -0.42, 0.32)),
    ("FR_Lower", "FR_Upper", (-0.15, -0.42, 0.32), (-0.15, -0.44, 0.10)),
    ("FR_Paw", "FR_Lower", (-0.15, -0.44, 0.10), (-0.15, -0.52, 0.02)),
    ("HL_Upper", "Root", (0.15, 0.14, 0.60), (0.17, 0.20, 0.34)),
    ("HL_Lower", "HL_Upper", (0.17, 0.20, 0.34), (0.16, 0.12, 0.12)),
    ("HL_Paw", "HL_Lower", (0.16, 0.12, 0.12), (0.16, 0.02, 0.02)),
    ("HR_Upper", "Root", (-0.15, 0.14, 0.60), (-0.17, 0.20, 0.34)),
    ("HR_Lower", "HR_Upper", (-0.17, 0.20, 0.34), (-0.16, 0.12, 0.12)),
    ("HR_Paw", "HR_Lower", (-0.16, 0.12, 0.12), (-0.16, 0.02, 0.02)),
]

BOAR_BONES = [
    ("Root", None, (0, 0, 0.55), (0, -0.06, 0.55)),
    ("Spine", "Root", (0, 0, 0.55), (0, -0.22, 0.60)),
    ("Chest", "Spine", (0, -0.22, 0.60), (0, -0.44, 0.58)),
    ("Neck", "Chest", (0, -0.44, 0.58), (0, -0.58, 0.68)),
    ("Head", "Neck", (0, -0.58, 0.68), (0, -0.76, 0.64)),
    ("Jaw", "Head", (0, -0.68, 0.60), (0, -0.80, 0.56)),
    ("Tail1", "Root", (0, 0.04, 0.55), (0, 0.18, 0.50)),
    ("Tail2", "Tail1", (0, 0.18, 0.50), (0, 0.30, 0.44)),
    ("FL_Upper", "Root", (0.16, -0.38, 0.52), (0.16, -0.38, 0.28)),
    ("FL_Lower", "FL_Upper", (0.16, -0.38, 0.28), (0.16, -0.40, 0.10)),
    ("FL_Paw", "FL_Lower", (0.16, -0.40, 0.10), (0.16, -0.46, 0.02)),
    ("FR_Upper", "Root", (-0.16, -0.38, 0.52), (-0.16, -0.38, 0.28)),
    ("FR_Lower", "FR_Upper", (-0.16, -0.38, 0.28), (-0.16, -0.40, 0.10)),
    ("FR_Paw", "FR_Lower", (-0.16, -0.40, 0.10), (-0.16, -0.46, 0.02)),
    ("HL_Upper", "Root", (0.16, 0.12, 0.52), (0.18, 0.17, 0.30)),
    ("HL_Lower", "HL_Upper", (0.18, 0.17, 0.30), (0.17, 0.10, 0.10)),
    ("HL_Paw", "HL_Lower", (0.17, 0.10, 0.10), (0.17, 0.02, 0.02)),
    ("HR_Upper", "Root", (-0.16, 0.12, 0.52), (-0.18, 0.17, 0.30)),
    ("HR_Lower", "HR_Upper", (-0.18, 0.17, 0.30), (-0.17, 0.10, 0.10)),
    ("HR_Paw", "HR_Lower", (-0.17, 0.10, 0.10), (-0.17, 0.02, 0.02)),
]

# ---------------------------------------------------------------- helpers
def deselect():
    bpy.ops.object.select_all(action="DESELECT")

def make_mat(name, rgb, roughness=0.95, emission=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 3.0
    return m

def limb(p1, p2, r1, r2, mat, seg=10):
    a, b = Vector(p1), Vector(p2)
    d = b - a
    deselect()
    bpy.ops.mesh.primitive_cylinder_add(vertices=seg, radius=r1,
                                        depth=d.length, location=(a + b) / 2)
    o = bpy.context.active_object
    o.rotation_euler = Vector((0, 0, 1)).rotation_difference(d.normalized()).to_euler()
    if abs(r2 - r1) > 1e-9:
        for v in o.data.vertices:
            if v.co.z > 0:
                v.co.x *= r2 / r1
                v.co.y *= r2 / r1
        o.data.update()
    o.data.materials.append(mat)
    for p in o.data.polygons:
        p.use_smooth = True
    return o

def ball(p, r, mat, seg=12, scale=None):
    deselect()
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=max(8, seg // 2),
                                         radius=r, location=p)
    o = bpy.context.active_object
    if scale:
        o.scale = scale
        deselect(); o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(mat)
    for pg in o.data.polygons:
        pg.use_smooth = True
    return o

def box(p, dims, mat):
    deselect()
    bpy.ops.mesh.primitive_cube_add(location=p)
    o = bpy.context.active_object
    o.scale = (dims[0] / 2, dims[1] / 2, dims[2] / 2)
    deselect(); o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(mat)
    return o

def cone(p, r, h, mat, rot=(0, 0, 0)):
    deselect()
    bpy.ops.mesh.primitive_cone_add(radius1=r, radius2=0.0, depth=h,
                                    location=p, rotation=rot)
    o = bpy.context.active_object
    o.data.materials.append(mat)
    for pg in o.data.polygons:
        pg.use_smooth = True
    return o

def disc_y(p, r, h, mat):
    """Cylinder with its axis along Y (a disc facing forward/back)."""
    deselect()
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, location=p,
                                        rotation=(math.pi / 2, 0, 0))
    o = bpy.context.active_object
    o.data.materials.append(mat)
    for pg in o.data.polygons:
        pg.use_smooth = True
    return o

def clear_scene():
    if bpy.context.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for coll in (bpy.data.meshes, bpy.data.armatures, bpy.data.actions,
                 bpy.data.materials):
        for x in list(coll):
            coll.remove(x)

def make_armature(bone_table, name):
    data = bpy.data.armatures.new(name + "Data")
    arm = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    for bn, parent, head, tail in bone_table:
        b = eb.new(bn)
        b.head = head
        b.tail = tail
        if parent:
            b.parent = eb[parent]
    for b in eb:
        b.use_deform = True
    bpy.ops.object.mode_set(mode="OBJECT")
    return arm

def J(arm, name):
    b = arm.data.bones[name]
    return Vector(b.head_local), Vector(b.tail_local)

# ---------------------------------------------------------------- meshes
def build_wolf_mesh(arm):
    FUR = make_mat("WolfFur", (0.26, 0.26, 0.30))
    DARK = make_mat("WolfDark", (0.16, 0.16, 0.19))
    EYE = make_mat("WolfEye", (0.1, 0.04, 0.02), emission=(1.0, 0.25, 0.08))
    parts = []
    parts.append(ball((0, -0.13, 0.62), 1.0, FUR, scale=(0.30, 0.45, 0.32)))
    parts.append(ball((0, -0.44, 0.60), 0.24, FUR, scale=(1.0, 1.0, 1.05)))
    nh, hh = J(arm, "Neck")[0], J(arm, "Head")[0]
    parts.append(limb(nh, hh, 0.15, 0.11, FUR))
    parts.append(box((0, -0.78, 0.76), (0.22, 0.26, 0.22), FUR))   # skull
    parts.append(box((0, -0.93, 0.71), (0.12, 0.18, 0.12), DARK))   # snout
    parts.append(box((0, -0.87, 0.665), (0.10, 0.16, 0.07), DARK)) # jaw
    parts.append(cone((0.08, -0.72, 0.90), 0.045, 0.12, DARK))     # ears
    parts.append(cone((-0.08, -0.72, 0.90), 0.045, 0.12, DARK))
    parts.append(box((0.07, -0.895, 0.78), (0.035, 0.02, 0.03), EYE))
    parts.append(box((-0.07, -0.895, 0.78), (0.035, 0.02, 0.03), EYE))
    for leg in ("FL", "FR", "HL", "HR"):
        uh, ut = J(arm, leg + "_Upper")
        lh, lt = J(arm, leg + "_Lower")
        ph, pt = J(arm, leg + "_Paw")
        parts.append(limb(uh, ut, 0.075, 0.055, FUR))
        parts.append(limb(lh, lt, 0.055, 0.040, DARK))
        parts.append(box(((ph + pt) / 2 + Vector((0, -0.02, 0))), (0.10, 0.16, 0.09), DARK))
    t1h, t1t = J(arm, "Tail1")
    t2h, t2t = J(arm, "Tail2")
    parts.append(limb(t1h, t1t, 0.050, 0.035, DARK))
    parts.append(limb(t2h, t2t, 0.035, 0.015, DARK))
    return parts

def build_boar_mesh(arm):
    HIDE = make_mat("BoarHide", (0.25, 0.17, 0.12))
    SNOUT = make_mat("BoarSnout", (0.15, 0.10, 0.08))
    TUSK = make_mat("BoarTusk", (0.75, 0.70, 0.60), roughness=0.6)
    EYE = make_mat("BoarEye", (0.1, 0.03, 0.02), emission=(1.0, 0.20, 0.05))
    parts = []
    parts.append(ball((0, -0.11, 0.56), 1.0, HIDE, scale=(0.38, 0.48, 0.40)))  # barrel
    parts.append(ball((0, -0.35, 0.66), 1.0, HIDE, scale=(0.30, 0.25, 0.28)))  # shoulder hump
    nh, hh = J(arm, "Neck")[0], J(arm, "Head")[0]
    parts.append(limb(nh, hh, 0.17, 0.14, HIDE))
    parts.append(box((0, -0.67, 0.66), (0.30, 0.28, 0.30), HIDE))  # big head
    parts.append(disc_y((0, -0.84, 0.62), 0.11, 0.10, SNOUT))       # snout disc
    parts.append(box((0, -0.74, 0.585), (0.16, 0.14, 0.08), SNOUT)) # jaw
    # tusks: up, forward, outward
    parts.append(cone((0.10, -0.82, 0.62), 0.035, 0.16, TUSK, rot=(0.6, 0.4, 0)))
    parts.append(cone((-0.10, -0.82, 0.62), 0.035, 0.16, TUSK, rot=(0.6, -0.4, 0)))
    parts.append(cone((0.11, -0.58, 0.84), 0.05, 0.12, HIDE))       # ears
    parts.append(cone((-0.11, -0.58, 0.84), 0.05, 0.12, HIDE))
    parts.append(box((0.09, -0.815, 0.70), (0.035, 0.02, 0.03), EYE))
    parts.append(box((-0.09, -0.815, 0.70), (0.035, 0.02, 0.03), EYE))
    # bristle ridge along the back
    for i in range(5):
        y = 0.15 - i * 0.125
        z = 0.80 + 0.06 * math.sin(i * 0.9)
        parts.append(cone((0, y, z), 0.030, 0.10, SNOUT, rot=(-0.2, 0, 0)))
    for leg in ("FL", "FR", "HL", "HR"):
        uh, ut = J(arm, leg + "_Upper")
        lh, lt = J(arm, leg + "_Lower")
        ph, pt = J(arm, leg + "_Paw")
        parts.append(limb(uh, ut, 0.095, 0.070, HIDE))
        parts.append(limb(lh, lt, 0.070, 0.050, HIDE))
        parts.append(box(((ph + pt) / 2 + Vector((0, -0.02, 0))), (0.12, 0.18, 0.10), SNOUT))
    t1h, t1t = J(arm, "Tail1")
    t2h, t2t = J(arm, "Tail2")
    parts.append(limb(t1h, t1t, 0.030, 0.022, HIDE))
    parts.append(limb(t2h, t2t, 0.022, 0.012, HIDE))
    return parts

# ---------------------------------------------------------------- animation authoring
def sstep(a, b, x):
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)

def bake_action(arm, name, n_frames, fn, loop):
    """Sample fn(t01, pose_bones) and keyframe every bone each frame.

    Rotations are keyed as QUATERNION: the Blender 4.5 FBX exporter fails
    to bake rotation_euler fcurves on slotted actions (writes identity),
    while rotation_quaternion bakes correctly.
    """
    act = bpy.data.actions.new(name)
    arm.animation_data_create()
    arm.animation_data.action = act
    bones = arm.pose.bones
    last = n_frames + 1 if loop else n_frames
    for f in range(1, last + 1):
        t = (f - 1) / n_frames
        if loop and f == last:
            t = 0.0
        bpy.context.scene.frame_set(f)
        for pb in bones:  # reset in euler space; fn assigns euler components
            pb.rotation_mode = "XYZ"
            pb.rotation_euler = (0, 0, 0)
        bones["Root"].location = (0, 0, 0)
        fn(t, bones)
        bpy.context.view_layer.update()
        for pb in bones:
            e = pb.rotation_euler
            pb.rotation_mode = "QUATERNION"
            pb.rotation_quaternion = e.to_quaternion()
            pb.keyframe_insert(data_path="rotation_quaternion", frame=f)
        bones["Root"].keyframe_insert(data_path="location", frame=f)
    try:
        act.frame_range = (1, last)
    except Exception:
        pass
    return act, last

def gait_fn(amp_u, amp_l, amp_p, bob, roll, tail_up):
    def fn(t, B):
        for leg, phase in (("FL", 0.0), ("HR", 0.0), ("FR", math.pi), ("HL", math.pi)):
            ph = 2 * math.pi * t + phase
            B[leg + "_Upper"].rotation_euler.x = amp_u * math.sin(ph)
            B[leg + "_Lower"].rotation_euler.x = amp_l * math.sin(ph - 0.9) - 0.12
            B[leg + "_Paw"].rotation_euler.x = amp_p * math.sin(ph - 0.5)
        B["Root"].location = (0, 0, bob * math.sin(4 * math.pi * t))
        B["Root"].rotation_euler = (0, roll * math.sin(2 * math.pi * t), 0)
        B["Spine"].rotation_euler.x = 0.03 * math.sin(4 * math.pi * t + 1)
        B["Head"].rotation_euler.x = -0.05 * math.sin(4 * math.pi * t)
        B["Tail1"].rotation_euler.x = tail_up
        B["Tail1"].rotation_euler.z = 0.10 * math.sin(2 * math.pi * t + 0.5)
        B["Tail2"].rotation_euler.z = 0.12 * math.sin(2 * math.pi * t + 1.2)
    return fn

def idle_fn(t, B):
    B["Chest"].rotation_euler.x = 0.05 * math.sin(2 * math.pi * t)   # breathe
    B["Neck"].rotation_euler.x = 0.02 * math.sin(2 * math.pi * t + 0.5)
    B["Head"].rotation_euler.z = 0.07 * math.sin(2 * math.pi * t + 1.0)
    B["Head"].rotation_euler.x = 0.03 * math.sin(4 * math.pi * t)
    B["Tail1"].rotation_euler.z = 0.18 * math.sin(2 * math.pi * t)
    B["Tail2"].rotation_euler.z = 0.22 * math.sin(2 * math.pi * t + 0.8)
    B["Root"].location = (0, 0, 0.008 * math.sin(2 * math.pi * t))

def boar_idle_fn(t, B):
    B["Chest"].rotation_euler.x = 0.04 * math.sin(2 * math.pi * t)
    B["Head"].rotation_euler.x = 0.10 * math.sin(2 * math.pi * t) + 0.05  # sniffing dips
    B["Head"].rotation_euler.z = 0.05 * math.sin(2 * math.pi * t + 2.0)
    B["Tail1"].rotation_euler.z = 0.15 * math.sin(2 * math.pi * t)
    B["Tail2"].rotation_euler.z = 0.30 * math.sin(6 * math.pi * t)        # tail flicks
    B["Root"].location = (0, 0, 0.010 * math.sin(2 * math.pi * t))

def wolf_attack_fn(t, B):
    crouch = sstep(0.00, 0.25, t) * (1 - sstep(0.35, 0.50, t))
    strike = sstep(0.30, 0.45, t) * (1 - sstep(0.55, 0.70, t))
    bite = sstep(0.45, 0.52, t) * (1 - sstep(0.60, 0.72, t))
    B["Root"].location = (0, -0.30 * strike, -0.08 * crouch + 0.03 * strike)
    B["Chest"].rotation_euler.x = 0.20 * crouch - 0.15 * strike
    B["Neck"].rotation_euler.x = 0.15 * crouch - 0.35 * strike
    B["Head"].rotation_euler.x = 0.25 * crouch - 0.60 * strike
    B["Jaw"].rotation_euler.x = 0.65 * strike - 0.55 * bite
    B["FL_Upper"].rotation_euler.x = -0.30 * strike
    B["FR_Upper"].rotation_euler.x = -0.30 * strike
    B["Tail1"].rotation_euler.x = -0.35 * strike

def boar_attack_fn(t, B):  # charge + tusk swipe
    paw = sstep(0.00, 0.20, t) * (1 - sstep(0.25, 0.35, t))
    charge = sstep(0.25, 0.38, t) * (1 - sstep(0.55, 0.70, t))
    swipe_l = sstep(0.40, 0.50, t) * (1 - sstep(0.52, 0.60, t))
    swipe_r = sstep(0.52, 0.60, t) * (1 - sstep(0.64, 0.72, t))
    B["Root"].location = (0, -0.38 * charge, -0.05 * paw + 0.02 * charge)
    B["FL_Upper"].rotation_euler.x = -0.45 * paw - 0.25 * charge
    B["FR_Upper"].rotation_euler.x = -0.25 * charge
    B["Chest"].rotation_euler.x = -0.12 * charge
    B["Head"].rotation_euler.x = -0.20 * paw - 0.45 * charge
    B["Head"].rotation_euler.z = 0.45 * swipe_l - 0.45 * swipe_r
    B["Jaw"].rotation_euler.x = 0.50 * (swipe_l + swipe_r)
    B["Tail1"].rotation_euler.x = -0.30 * charge

# ---------------------------------------------------------------- bind + export
def bind(arm, parts, mesh_name):
    deselect()
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.join()
    mesh_obj = bpy.context.active_object
    mesh_obj.name = mesh_name
    bpy.context.view_layer.update()
    segs = [(b.name, Vector(b.head_local), Vector(b.tail_local))
            for b in arm.data.bones]
    for b in arm.data.bones:
        mesh_obj.vertex_groups.new(name=b.name)
    grp_index = {vg.name: vg.index for vg in mesh_obj.vertex_groups}
    mw = mesh_obj.matrix_world
    for v in mesh_obj.data.vertices:
        p = mw @ v.co
        best, best_d = None, 1e18
        for name, h, tt in segs:
            d = p - h
            tv = tt - h
            L2 = tv.dot(tv)
            proj = h + tv * max(0.0, min(1.0, d.dot(tv) / L2)) if L2 > 1e-12 else h
            dist = (p - proj).length
            if dist < best_d:
                best_d, best = dist, name
        mesh_obj.vertex_groups[grp_index[best]].add([v.index], 1.0, "REPLACE")
    mod = mesh_obj.modifiers.new(name="Armature", type="ARMATURE")
    mod.object = arm
    mesh_obj.parent = arm
    mesh_obj.matrix_parent_inverse = arm.matrix_world.inverted()
    bpy.context.view_layer.update()
    assert any(m.type == "ARMATURE" for m in mesh_obj.modifiers)
    empty = [vg.name for vg in mesh_obj.vertex_groups
             if not any(any(g.group == vg.index for g in v.groups)
                        for v in mesh_obj.data.vertices)]
    print("bound %s: %d verts, %d groups, empty groups=%s, dims %s" %
          (mesh_name, len(mesh_obj.data.vertices), len(mesh_obj.vertex_groups),
           empty, tuple(round(d, 3) for d in mesh_obj.dimensions)))
    return mesh_obj

def export_fbx(path, objs, bake_anim):
    deselect()
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(
        filepath=path, use_selection=True, global_scale=1.0,
        apply_unit_scale=False, apply_scale_options="FBX_SCALE_ALL",
        bake_space_transform=False, object_types={"ARMATURE", "MESH"},
        use_mesh_modifiers=True, use_armature_deform_only=False,
        add_leaf_bones=False, bake_anim=bake_anim)
    print("wrote", path)

# ---------------------------------------------------------------- main
SPECIES = {
    "wolf": (WOLF_BONES, build_wolf_mesh, "Wolf"),
    "boar": (BOAR_BONES, build_boar_mesh, "Boar"),
}
for species, (bone_table, mesh_builder, label) in SPECIES.items():
    clear_scene()
    arm = make_armature(bone_table, label + "Armature")
    arm.name = label + "Armature"
    parts = mesh_builder(arm)
    mesh_obj = bind(arm, parts, label + "Mesh")
    assert len(arm.data.bones) == 20, len(arm.data.bones)

    # model: no action, pose at rest
    if arm.animation_data:
        arm.animation_data.action = None
    deselect()
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.pose.transforms_clear()
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.scene.frame_set(1)
    bpy.context.view_layer.update()
    export_fbx(os.path.join(OUTM, species + ".fbx"), [arm, mesh_obj], bake_anim=False)

    # clips: bake, export, and remove one at a time. (The FBX exporter
    # writes every action in the file as a take, so only one may exist
    # at export time.)
    clips = [
        ("Idle", 60, idle_fn if species == "wolf" else boar_idle_fn, True),
        ("Walk", 30, gait_fn(0.50, 0.35, 0.30, 0.025, 0.05, -0.15), True),
        ("Run", 20, gait_fn(0.75, 0.50, 0.40, 0.050, 0.07, -0.45), True),
        ("Attack", 24 if species == "wolf" else 28,
         wolf_attack_fn if species == "wolf" else boar_attack_fn, False),
    ]
    for clip_name, n_frames, fn, loop in clips:
        act, last = bake_action(arm, "%s_%s" % (label, clip_name), n_frames, fn, loop)
        print("%s %s: %d frames, %d fcurves" % (species, clip_name, last, len(act.fcurves)))
        arm.animation_data.action = act
        if len(act.slots) > 0:
            arm.animation_data.action_slot = act.slots[0]
        bpy.context.scene.frame_start = 1
        bpy.context.scene.frame_end = last
        export_fbx(os.path.join(OUTA, "%s_%s.fbx" % (species, clip_name)),
                   [arm], bake_anim=True)
        arm.animation_data.action = None
        bpy.data.actions.remove(act)
    print("finished", species)
print("DONE")
