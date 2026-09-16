# tools/build_enemies.py — build models/brute.fbx and models/raider.fbx
#
# Two procedural enemy variants on the exact Mixamo 65-bone skeleton taken
# from animations/anim_Walking.fbx, so all seven existing Mixamo clips play
# with zero retargeting.
#
# Pipeline (validated 2026-09-16 by exp_notouch2.py):
#   1. Import the 65-bone skeleton from ../animations/anim_Walking.fbx and
#      LEAVE THE ARMATURE OBJECT TRANSFORM ALONE (no transform_apply).
#      Baking it into the bones breaks the clip's *location* curves (they
#      are authored in the clip's armature space); untouched, the rest pose
#      round-trips bit-identical and animated poses match the clip's native
#      armature to 0.00000 m.
#   2. Build the body AROUND THE TRUE REST POSE (Mixamo T-pose) in world
#      space — no bone repose. Reposing bones is what broke
#      build_humanoid_v2.py's arms: clip rotations are relative to rest,
#      so a different rest = wrong animation. Silhouette differences
#      (brute bulk/hunch, raider leanness) come from the mesh only.
#   3. Deterministic rigid skinning: every vertex -> nearest bone segment
#      at 100% (bone-heat fails on joined primitives).
#   4. Export FBX with the pose reset to rest.
#
# Run from this directory: blender --background --python build_enemies.py
# Output: ../models/brute.fbx, ../models/raider.fbx

import bpy
import os
import math
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
ANIM = os.path.join(HERE, "..", "animations", "anim_Walking.fbx")
OUT = os.path.join(HERE, "..", "models")
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- materials
def make_mat(name, rgb, roughness=0.9, metallic=0.0, emission=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 3.0
    return m

# ---------------------------------------------------------------- helpers
def deselect():
    bpy.ops.object.select_all(action="DESELECT")

def limb(p1, p2, r1, r2, mat, seg=12):
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

def ball(p, r, mat, seg=14, scale=None):
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
    bpy.ops.mesh.primitive_cone_add(radius1=r, radius2=0.0, depth=h, location=p,
                                    rotation=rot)
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

# ---------------------------------------------------------------- skeleton
def load_skeleton():
    """Import the Mixamo 65-bone skeleton from the walk clip. The armature
    object transform is deliberately left untouched (see pipeline note
    above); the pose is reset to rest. Bones are NOT reposed."""
    clear_scene()
    bpy.ops.import_scene.fbx(filepath=ANIM)
    arm = next(o for o in bpy.context.scene.objects if o.type == "ARMATURE")
    for o in list(bpy.context.scene.objects):
        if o != arm:
            bpy.data.objects.remove(o, do_unlink=True)
    for a in list(bpy.data.actions):
        bpy.data.actions.remove(a)
    arm.name = "EnemyArmature"
    deselect()
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    # No transform_apply: the importer's object transform must stay on the
    # object so the exported rest pose matches the clips bit-for-bit.
    # The FBX exporter reads POSE matrices for bones, so reset the pose.
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.select_all(action="SELECT")
    bpy.ops.pose.transforms_clear()
    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.context.view_layer.update()
    bones = arm.data.bones
    assert len(bones) == 65, "expected 65 bones, got %d" % len(bones)
    for n in ("mixamorig:Hips", "mixamorig:Spine", "mixamorig:LeftArm",
              "mixamorig:RightHand", "mixamorig:LeftToeBase"):
        assert n in bones, "missing " + n
    for b in bones:
        b.use_deform = True
    return arm

def J(arm, name):
    """(head, tail) of a bone in world space."""
    b = arm.data.bones["mixamorig:" + name]
    return arm.matrix_world @ b.head_local, arm.matrix_world @ b.tail_local

# ---------------------------------------------------------------- bodies
def build_brute(arm):
    SKIN = make_mat("BruteSkin", (0.30, 0.33, 0.27), roughness=0.95)
    CLOTH = make_mat("BruteCloth", (0.13, 0.11, 0.10), roughness=0.95)
    LEATHER = make_mat("BruteLeather", (0.22, 0.15, 0.10), roughness=0.9)
    EYE = make_mat("BruteEye", (0.1, 0.05, 0.02), emission=(1.0, 0.25, 0.05))
    parts = []
    # pelvis / barrel torso (faces -Y)
    parts.append(box((0, 0, 1.00), (0.44, 0.30, 0.26), CLOTH))
    parts.append(limb((0, -0.01, 1.10), (0, 0.01, 1.34), 0.21, 0.24, SKIN, seg=14))
    parts.append(box((0, 0, 1.42), (0.58, 0.34, 0.30), SKIN))          # barrel chest
    parts.append(ball((0, 0.05, 1.55), 1.0, SKIN, scale=(0.27, 0.18, 0.14)))  # trapezius hump
    parts.append(ball((0, 0.06, 1.44), 1.0, CLOTH, scale=(0.30, 0.16, 0.10))) # back plate
    # back spikes
    for z in (1.38, 1.48, 1.58):
        parts.append(cone((0, 0.14, z), 0.045, 0.16, LEATHER, rot=(-0.5, 0, 0)))
    # neck + hunched head (pushed forward/down of the Head bone)
    parts.append(limb((0, 0.03, 1.50), (0, -0.03, 1.62), 0.095, 0.085, SKIN))
    parts.append(box((0, -0.06, 1.64), (0.22, 0.26, 0.26), SKIN))      # skull
    parts.append(box((0, -0.15, 1.67), (0.20, 0.08, 0.10), SKIN))      # brow ridge
    parts.append(box((0, -0.13, 1.55), (0.16, 0.12, 0.10), SKIN))      # jaw
    parts.append(box((0.06, -0.195, 1.665), (0.045, 0.02, 0.035), EYE))
    parts.append(box((-0.06, -0.195, 1.665), (0.045, 0.02, 0.035), EYE))
    for side, sgn in (("Left", 1.0), ("Right", -1.0)):
        parts.append(ball((sgn * 0.20, 0.071, 1.46), 0.125, SKIN))     # deltoid mass
        parts.append(limb((sgn * 0.20, 0.071, 1.441), (sgn * 0.43, 0.071, 1.441),
                          0.095, 0.080, SKIN, seg=14))                 # upper arm
        parts.append(ball((sgn * 0.43, 0.071, 1.441), 0.075, SKIN))    # elbow
        parts.append(limb((sgn * 0.43, 0.071, 1.441), (sgn * 0.71, 0.071, 1.441),
                          0.075, 0.065, SKIN, seg=14))                 # forearm
        parts.append(box((sgn * 0.79, 0.071, 1.41), (0.17, 0.15, 0.20), SKIN))  # maul fist
        hip, knee = J(arm, side + "UpLeg")[0], J(arm, side + "Leg")[0]
        ankle = J(arm, side + "Foot")[0]
        parts.append(ball((sgn * 0.085, 0.016, 0.95), 0.12, CLOTH))
        parts.append(limb((sgn * 0.085, 0.015, 0.93), (sgn * 0.085, 0.015, 0.55),
                          0.115, 0.090, CLOTH, seg=14))
        parts.append(ball((sgn * 0.085, 0.02, 0.53), 0.085, SKIN))
        parts.append(limb((sgn * 0.085, 0.03, 0.51), (sgn * 0.085, 0.04, 0.10),
                          0.080, 0.060, SKIN, seg=14))
        parts.append(box((sgn * 0.085, -0.04, 0.07), (0.16, 0.32, 0.14), LEATHER))  # boot
    return parts

def build_raider(arm):
    SKIN = make_mat("RaiderSkin", (0.22, 0.20, 0.22), roughness=0.95)
    CLOTH = make_mat("RaiderCloth", (0.28, 0.09, 0.09), roughness=0.95)
    LEATHER = make_mat("RaiderLeather", (0.12, 0.10, 0.10), roughness=0.9)
    EYE = make_mat("RaiderEye", (0.1, 0.08, 0.02), emission=(1.0, 0.8, 0.2))
    parts = []
    parts.append(box((0, 0, 1.00), (0.30, 0.22, 0.24), CLOTH))
    parts.append(limb((0, -0.005, 1.10), (0, 0.005, 1.32), 0.150, 0.170, CLOTH, seg=12))
    parts.append(box((0, 0, 1.42), (0.36, 0.26, 0.28), CLOTH))         # lean chest
    parts.append(box((0, 0.05, 1.46), (0.40, 0.12, 0.12), LEATHER))    # shoulder bar
    for sgn in (1.0, -1.0):                                           # shoulder spikes
        parts.append(cone((sgn * 0.24, 0.05, 1.56), 0.05, 0.20, LEATHER,
                          rot=(0, sgn * 0.5, 0)))
    parts.append(limb((0, 0.045, 1.50), (0, 0.035, 1.62), 0.055, 0.050, SKIN))
    parts.append(box((0, -0.02, 1.70), (0.18, 0.20, 0.24), SKIN))      # head
    parts.append(cone((0, 0.03, 1.86), 0.17, 0.30, CLOTH, rot=(-0.25, 0, 0)))  # hood
    parts.append(box((0.05, -0.125, 1.71), (0.04, 0.02, 0.03), EYE))
    parts.append(box((-0.05, -0.125, 1.71), (0.04, 0.02, 0.03), EYE))
    for side, sgn in (("Left", 1.0), ("Right", -1.0)):
        parts.append(ball((sgn * 0.17, 0.071, 1.441), 0.070, CLOTH))
        parts.append(limb((sgn * 0.17, 0.071, 1.441), (sgn * 0.43, 0.071, 1.441),
                          0.055, 0.047, CLOTH))
        parts.append(ball((sgn * 0.43, 0.071, 1.441), 0.045, SKIN))
        parts.append(limb((sgn * 0.43, 0.071, 1.441), (sgn * 0.71, 0.071, 1.441),
                          0.045, 0.038, SKIN))
        parts.append(box((sgn * 0.76, 0.071, 1.43), (0.10, 0.09, 0.20), SKIN))  # claw hand
        parts.append(ball((sgn * 0.085, 0.016, 0.95), 0.085, CLOTH))
        parts.append(limb((sgn * 0.085, 0.015, 0.93), (sgn * 0.085, 0.015, 0.55),
                          0.080, 0.060, CLOTH))
        parts.append(ball((sgn * 0.085, 0.02, 0.53), 0.060, SKIN))
        parts.append(limb((sgn * 0.085, 0.03, 0.51), (sgn * 0.085, 0.04, 0.10),
                          0.055, 0.042, SKIN))
        parts.append(box((sgn * 0.085, -0.04, 0.07), (0.12, 0.28, 0.12), LEATHER))
    return parts

# ---------------------------------------------------------------- bind+export
def bind_and_export(arm, parts, out_path, mesh_name):
    deselect()
    for o in parts:
        o.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.join()
    mesh_obj = bpy.context.active_object
    mesh_obj.name = mesh_name
    bpy.context.view_layer.update()
    print("mesh verts:", len(mesh_obj.data.vertices),
          "dims: x=%.3f y=%.3f z=%.3f" % tuple(mesh_obj.dimensions))
    # deterministic rigid skinning: every vertex -> nearest bone segment 100%.
    # Bone segments are evaluated in world space (the armature object keeps
    # the importer's transform); the mesh is at identity in world space.
    segs = [(b.name, arm.matrix_world @ b.head_local, arm.matrix_world @ b.tail_local)
            for b in arm.data.bones]
    for b in arm.data.bones:
        mesh_obj.vertex_groups.new(name=b.name)
    grp_index = {vg.name: vg.index for vg in mesh_obj.vertex_groups}
    mw = mesh_obj.matrix_world
    counts = {}
    for v in mesh_obj.data.vertices:
        p = mw @ v.co
        best, best_d = None, 1e18
        for name, h, t in segs:
            d = p - h
            tt = t - h
            L2 = tt.dot(tt)
            proj = h + tt * max(0.0, min(1.0, d.dot(tt) / L2)) if L2 > 1e-12 else h
            dist = (p - proj).length
            if dist < best_d:
                best_d, best = dist, name
        mesh_obj.vertex_groups[grp_index[best]].add([v.index], 1.0, "REPLACE")
        counts[best] = counts.get(best, 0) + 1
    print("weights: %d verts -> %d bones" % (len(mesh_obj.data.vertices), len(counts)))
    mod = mesh_obj.modifiers.new(name="Armature", type="ARMATURE")
    mod.object = arm
    mesh_obj.parent = arm
    mesh_obj.matrix_parent_inverse = arm.matrix_world.inverted()
    bpy.context.view_layer.update()
    assert any(m.type == "ARMATURE" for m in mesh_obj.modifiers)
    assert len(mesh_obj.vertex_groups) == 65
    deselect()
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.fbx(
        filepath=out_path, use_selection=True, global_scale=1.0,
        apply_unit_scale=False, apply_scale_options="FBX_SCALE_ALL",
        bake_space_transform=False, object_types={"ARMATURE", "MESH"},
        use_mesh_modifiers=True, use_armature_deform_only=False,
        add_leaf_bones=False, bake_anim=False)
    print("wrote", out_path)

# ---------------------------------------------------------------- main
BUILDERS = (("brute", build_brute), ("raider", build_raider))
for name, builder in BUILDERS:
    arm = load_skeleton()
    parts = builder(arm)
    bind_and_export(arm, parts, os.path.join(OUT, name + ".fbx"),
                    name.capitalize() + "Mesh")
print("DONE")
