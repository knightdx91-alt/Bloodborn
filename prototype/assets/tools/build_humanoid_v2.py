# build_humanoid_v2.py — rebuild models/humanoid.fbx on the Mixamo 65-bone skeleton.
#
# Implements SPEC-humanoid-v2.md. Instead of the spec's suggested Mixamo
# auto-rigger round-trip, the skeleton is taken directly from the existing
# animation clips (anim_Walking.fbx), which guarantees the bone hierarchy is
# identical to the clips by construction — no re-download needed.
#
# Why a new body instead of the old mesh: the old mesh's proportions
# (shoulder z=1.65, arms spanning x 0.24->0.37) do not fit the Mixamo
# skeleton (shoulder z=1.44, arms spanning x 0.15->0.80, hips z=1.04).
# The spec allows "an equivalent placeholder body of similar blockiness",
# so we build one whose joints sit exactly on the Mixamo bones.
#
# Pipeline:
#   1. Import the 65-bone skeleton from ../animations/anim_Walking.fbx, drop
#      the clip's animation, bake the importer's object transform into the
#      bones so the armature object is clean identity.
#      (Blender's transform_apply leaves pose.bones[].matrix stale and the FBX
#      exporter reads POSE matrices for bones, so the pose is reset to rest.)
#   2. Compute an A-pose for the arm chains analytically (shoulder fixed,
#      32/36/36 deg downward tilt), build the blocky body around those joints.
#   3. Repose the skeleton's arm chains onto the same joints.
#   4. Deterministic rigid skinning: every vertex -> nearest bone segment at
#      100% (bone-heat fails on joined primitives; rigid is crisp and
#      predictable for a placeholder).
#   5. Export FBX at meter scale (Apply Scalings: FBX All).
#
# Run from this directory: blender --background --python build_humanoid_v2.py
# Output: ../models/humanoid.fbx

import bpy
import os
import math
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(HERE, "..", "animations")
OUT = os.path.join(HERE, "..", "models")
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- materials
def make_mat(name, rgb, roughness=0.9, metallic=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return m

SKIN = make_mat("Skin", (0.72, 0.54, 0.42))
CLOTH = make_mat("Cloth", (0.16, 0.15, 0.19), roughness=0.95)
LEATHER = make_mat("Leather", (0.34, 0.22, 0.13), roughness=0.9)

# ---------------------------------------------------------------- helpers
def deselect():
    bpy.ops.object.select_all(action="DESELECT")


def limb(p1, p2, r1, r2, mat, seg=12):
    """Tapered cylinder from p1 to p2."""
    a, b = Vector(p1), Vector(p2)
    d = b - a
    length = d.length
    deselect()
    bpy.ops.mesh.primitive_cylinder_add(vertices=seg, radius=r1,
                                        depth=length, location=(a + b) / 2)
    o = bpy.context.active_object
    q = Vector((0, 0, 1)).rotation_difference(d.normalized())
    o.rotation_euler = q.to_euler()
    if abs(r2 - r1) > 1e-9:
        me = o.data
        for v in me.vertices:  # local +Z is the p2 end
            if v.co.z > 0:
                v.co.x *= r2 / r1
                v.co.y *= r2 / r1
        me.update()
    o.data.materials.append(mat)
    for p in o.data.polygons:
        p.use_smooth = True
    return o


def ball(p, r, mat, seg=14):
    deselect()
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=max(8, seg // 2),
                                         radius=r, location=p)
    o = bpy.context.active_object
    o.data.materials.append(mat)
    for pg in o.data.polygons:
        pg.use_smooth = True
    return o


def box(p, dims, mat):
    deselect()
    bpy.ops.mesh.primitive_cube_add(location=p)
    o = bpy.context.active_object
    o.scale = (dims[0] / 2, dims[1] / 2, dims[2] / 2)
    deselect()
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.data.materials.append(mat)
    return o


def clear_scene():
    if bpy.context.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for coll in (bpy.data.meshes, bpy.data.armatures, bpy.data.actions,
                 bpy.data.materials):
        for x in list(coll):
            if x.name not in ("Skin", "Cloth", "Leather"):
                coll.remove(x)

# ---------------------------------------------------------------- 1. skeleton
clear_scene()
bpy.ops.import_scene.fbx(filepath=os.path.join(ASSETS, "animations", "anim_Walking.fbx"))
arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
for o in list(bpy.context.scene.objects):
    if o != arm:
        bpy.data.objects.remove(o, do_unlink=True)
for a in list(bpy.data.actions):
    bpy.data.actions.remove(a)
arm.name = "HumanoidArmature"

deselect()
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
arm.location = (0, 0, 0)
arm.rotation_euler = (0, 0, 0)
arm.scale = (1, 1, 1)
# transform_apply leaves pose.bones[].matrix stale (the FBX exporter reads the
# POSE matrices for bones, not the rest matrices); reset the pose so it exactly
# matches the baked rest pose.
bpy.ops.object.mode_set(mode='POSE')
bpy.ops.pose.select_all(action='SELECT')
bpy.ops.pose.transforms_clear()
bpy.ops.object.mode_set(mode='OBJECT')
bpy.context.view_layer.update()
bpy.context.view_layer.update()
ident = Matrix.Identity(4)
assert all(abs(a - b) < 1e-6 for ar, br in zip(arm.matrix_world.row, ident.row)
           for a, b in zip(ar, br)), "armature not at identity: %s" % arm.matrix_world

bones = arm.data.bones
assert len(bones) == 65, "expected 65 bones, got %d" % len(bones)
for n in ("mixamorig:Hips", "mixamorig:Spine", "mixamorig:LeftArm", "mixamorig:RightHand"):
    assert n in bones, "missing " + n
for b in bones:
    b.use_deform = True

top = max(((arm.matrix_world @ b.tail_local).z, b.name) for b in bones)
print("topmost bone: %s z=%.4f" % (top[1], top[0]))

# ---------------------------------------------------------------- 2. A-pose joints
def chain(side):
    """Analytical A-pose joints for one arm. Shoulder stays; segments tilt
    down 32/36/36 degrees in the x-z plane."""
    S = Vector(bones["mixamorig:%sArm" % side].head_local)
    L1 = (bones["mixamorig:%sArm" % side].tail_local -
          bones["mixamorig:%sArm" % side].head_local).length
    L2 = (bones["mixamorig:%sForeArm" % side].tail_local -
          bones["mixamorig:%sForeArm" % side].head_local).length
    L3 = (bones["mixamorig:%sHand" % side].tail_local -
          bones["mixamorig:%sHand" % side].head_local).length
    sgn = 1.0 if S.x >= 0 else -1.0
    th1, th2, th3 = math.radians(32), math.radians(36), math.radians(36)
    E = S + Vector((sgn * L1 * math.cos(th1), 0, -L1 * math.sin(th1)))
    W = E + Vector((sgn * L2 * math.cos(th2), 0, -L2 * math.sin(th2)))
    T = W + Vector((sgn * L3 * math.cos(th3), 0, -L3 * math.sin(th3)))
    return {"S": S, "E": E, "W": W, "T": T}

J = {"Left": chain("Left"), "Right": chain("Right")}
for side in ("Left", "Right"):
    print(side, {k: "(%.3f,%.3f,%.3f)" % tuple(v) for k, v in J[side].items()})

# ---------------------------------------------------------------- 3. body
parts = []

# pelvis / torso
parts.append(box((0, 0.008, 1.00), (0.30, 0.20, 0.24), CLOTH))
deselect()
bpy.ops.mesh.primitive_cylinder_add(vertices=14, radius=0.16, depth=0.07,
                                    location=(0, 0.008, 1.10))
belt = bpy.context.active_object
belt.data.materials.append(LEATHER)
parts.append(belt)
parts.append(limb((0, 0.008, 1.10), (0, 0.035, 1.40), 0.155, 0.175, CLOTH))
parts.append(box((0, 0.055, 1.44), (0.38, 0.15, 0.13), CLOTH))  # shoulder bar
parts.append(limb((0, 0.048, 1.48), (0, 0.046, 1.60), 0.050, 0.052, SKIN))  # neck
head_c = Vector((0, 0.045, 1.709))
parts.append(ball(head_c, 0.13, SKIN))  # crown ~1.84, matches Head bone tail

for side, sgn in (("Left", 1.0), ("Right", -1.0)):
    S, E, W, T = J[side]["S"], J[side]["E"], J[side]["W"], J[side]["T"]
    parts.append(ball(S, 0.075, CLOTH))                       # deltoid
    parts.append(limb(S, E, 0.060, 0.050, CLOTH))             # upper arm
    parts.append(ball(E, 0.050, SKIN))                        # elbow
    parts.append(limb(E, W, 0.046, 0.038, SKIN))              # forearm
    mid = (W + T) / 2
    parts.append(box(mid, (0.11, 0.10, 0.26), SKIN))          # hand
    # leg
    hip = Vector(bones["mixamorig:%sUpLeg" % side].head_local)
    knee = Vector(bones["mixamorig:%sLeg" % side].head_local)
    ankle = Vector(bones["mixamorig:%sFoot" % side].head_local)
    toe = Vector(bones["mixamorig:%sToeBase" % side].tail_local)
    parts.append(ball(hip, 0.095, CLOTH))
    parts.append(limb(hip + Vector((0, 0, -0.02)), knee + Vector((0, 0, 0.02)),
                      0.088, 0.062, CLOTH))
    parts.append(ball(knee, 0.062, SKIN))
    parts.append(limb(knee + Vector((0, 0, -0.02)), ankle + Vector((0, 0, 0.03)),
                      0.058, 0.045, SKIN))
    parts.append(box((hip.x, -0.05, 0.06), (0.12, 0.28, 0.12), LEATHER))  # boot

deselect()
for o in parts:
    o.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.object.join()
mesh_obj = bpy.context.active_object
mesh_obj.name = "HumanoidMesh"
bpy.context.view_layer.update()
print("mesh verts:", len(mesh_obj.data.vertices),
      "dims: x=%.3f y=%.3f z=%.3f" % tuple(mesh_obj.dimensions))

# ---------------------------------------------------------------- 4. repose
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
eb = arm.data.edit_bones
for side in ("Left", "Right"):
    names = ["mixamorig:%sArm" % side, "mixamorig:%sForeArm" % side,
             "mixamorig:%sHand" % side]
    snap = {n: (eb[n].head.copy(), eb[n].tail.copy()) for n in names}
    joints = [J[side]["S"], J[side]["E"], J[side]["W"], J[side]["T"]]
    for i, n in enumerate(names):
        eb[n].head = joints[i]
        eb[n].tail = joints[i + 1]
    # sanity: lengths preserved
    for n in names:
        h0, t0 = snap[n]
        assert abs((eb[n].tail - eb[n].head).length - (t0 - h0).length) < 1e-6, n
bpy.ops.object.mode_set(mode="OBJECT")
bpy.context.view_layer.update()

# ---------------------------------------------------------------- 5. bind+export
# NOTE: bone-heat (ARMATURE_AUTO) fails on this joined primitive mesh
# ("failed to find solution"), so assign deterministic rigid weights:
# every vertex goes 100% to its nearest bone segment. Crisp, predictable,
# and ideal for a blocky prototype.
deselect()
bpy.context.view_layer.objects.active = arm

# bone segments in armature space (armature is at identity => world == arm space)
segs = []
for b in arm.data.bones:
    segs.append((b.name, Vector(b.head_local), Vector(b.tail_local)))

def nearest_bone(p):
    best, best_d = None, 1e18
    for name, h, t in segs:
        d = p - h
        tt = t - h
        L2 = tt.dot(tt)
        if L2 > 1e-12:
            s = max(0.0, min(1.0, d.dot(tt) / L2))
            proj = h + tt * s
        else:
            proj = h
        dist = (p - proj).length
        if dist < best_d:
            best_d, best = dist, name
    return best

for b in arm.data.bones:
    mesh_obj.vertex_groups.new(name=b.name)
grp_index = {vg.name: vg.index for vg in mesh_obj.vertex_groups}
mw = mesh_obj.matrix_world
counts = {}
for v in mesh_obj.data.vertices:
    p = mw @ v.co
    bn = nearest_bone(p)
    mesh_obj.vertex_groups[grp_index[bn]].add([v.index], 1.0, 'REPLACE')
    counts[bn] = counts.get(bn, 0) + 1
print("weights assigned: %d verts -> %d bones" % (len(mesh_obj.data.vertices), len(counts)))

mod = mesh_obj.modifiers.new(name="Armature", type='ARMATURE')
mod.object = arm
# object-level parent to the armature (keep world transform), like the old asset
mesh_obj.parent = arm
mesh_obj.matrix_parent_inverse = arm.matrix_world.inverted()
bpy.context.view_layer.update()
assert any(m.type == "ARMATURE" for m in mesh_obj.modifiers)
assert len(mesh_obj.vertex_groups) == 65, \
    "expected 65 groups, got %d" % len(mesh_obj.vertex_groups)

raw_path = os.path.join(OUT, "humanoid.fbx")
deselect()
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.fbx(
    filepath=raw_path,
    use_selection=True,
    global_scale=1.0,
    apply_unit_scale=False,
    apply_scale_options="FBX_SCALE_ALL",
    bake_space_transform=False,
    object_types={"ARMATURE", "MESH"},
    use_mesh_modifiers=True,
    use_armature_deform_only=False,
    add_leaf_bones=False,
    bake_anim=False,
)
print("wrote", raw_path)
