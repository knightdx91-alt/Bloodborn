#!/usr/bin/env python3
"""
Marrowmark Stage 1 prototype asset set.
Run: blender --background --python build_assets.py

Generates (meters, Z-up, exported FBX with Y-up for Unity):
  humanoid.fbx   - 1.8m rigged biped, Unity-Humanoid bone names, A-pose.
                   WeaponSocket empty parented to Hand_R.
  weapon_sword.fbx / weapon_axe.fbx / weapon_spear.fbx
                 - quick / heavy / committed silhouettes, origin at grip.
  dummy.fbx      - training pell (post + crossbar + straw torso).
  arena.fbx      - 24m ground, walls, 4 pillars, sparring ring, crates.
  preview.png    - workbench render of the set.

Design notes served: silhouette readability (distinct weapon outlines,
broad shoulders, clear limb segments), no emissive anything, flat
PBR-ish materials. Prototype grade, not production.
"""
import bpy, math, os
from mathutils import Vector, Quaternion

OUT = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------------- materials
def make_mat(name, color, metallic=0.0, roughness=0.8):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return m

SKIN   = make_mat("Skin",   (0.72, 0.54, 0.42))
CLOTH  = make_mat("Cloth",  (0.16, 0.15, 0.19), roughness=0.95)
LEATHER= make_mat("Leather",(0.34, 0.22, 0.13), roughness=0.9)
STEEL  = make_mat("Steel",  (0.60, 0.63, 0.68), metallic=0.9, roughness=0.38)
WOOD   = make_mat("Wood",   (0.40, 0.27, 0.14), roughness=0.9)
STRAW  = make_mat("Straw",  (0.70, 0.58, 0.30), roughness=0.95)
BURLAP = make_mat("Burlap", (0.55, 0.46, 0.33), roughness=0.95)
STONE  = make_mat("Stone",  (0.44, 0.44, 0.47), roughness=0.95)
GROUND = make_mat("Ground", (0.29, 0.31, 0.27), roughness=1.0)
RING   = make_mat("Ring",   (0.75, 0.72, 0.65), roughness=0.9)

# ---------------------------------------------------------------- helpers
def deselect():
    bpy.ops.object.select_all(action='DESELECT')

def new_primitive(add_op, mat, **kw):
    deselect()
    add_op(**kw)
    o = bpy.context.active_object
    o.data.materials.append(mat)
    for p in o.data.polygons:
        p.use_smooth = True
    return o

def limb(p1, p2, r1, r2, mat, seg=12):
    """Cylinder from p1 to p2 with end radii r1, r2."""
    a, b = Vector(p1), Vector(p2)
    d = b - a
    length = d.length
    deselect()
    bpy.ops.mesh.primitive_cylinder_add(vertices=seg, radius=r1,
        depth=length, location=((a + b) / 2))
    o = bpy.context.active_object
    # taper: scale top verts (local +Z end)
    q = Vector((0, 0, 1)).rotation_difference(d.normalized())
    o.rotation_euler = q.to_euler()
    # taper via simple scale of top ring is fiddly; use two stacked cylinders
    # instead -- here we just accept straight and add joint spheres separately.
    o.data.materials.append(mat)
    for p in o.data.polygons:
        p.use_smooth = True
    return o

def ball(p, r, mat, seg=14):
    return new_primitive(bpy.ops.mesh.primitive_uv_sphere_add,
                         mat, segments=seg, ring_count=max(8, seg // 2),
                         radius=r, location=p)

def box(p, dims, mat):
    o = new_primitive(bpy.ops.mesh.primitive_cube_add, mat, location=p)
    o.scale = (dims[0] / 2, dims[1] / 2, dims[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    return o

def join_all(objs, name):
    # bake each part's own rotation/scale BEFORE joining: join() preserves
    # the ACTIVE object's transform instead of baking it, which would
    # otherwise corrupt the result. (transform_apply acts on selected.)
    deselect()
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.join()
    j = bpy.context.active_object
    j.name = name
    return j

def export_selected(path):
    bpy.ops.export_scene.fbx(
        filepath=path, use_selection=True, apply_unit_scale=True,
        bake_space_transform=False, object_types={'MESH', 'ARMATURE', 'EMPTY'},
        add_leaf_bones=False)

# ---------------------------------------------------------------- 1. HUMANOID
def build_humanoid():
    parts = []
    # pelvis + torso
    parts.append(new_primitive(bpy.ops.mesh.primitive_cylinder_add, CLOTH,
        vertices=14, radius=0.155, depth=0.20, location=(0, 0, 0.98)))
    parts.append(new_primitive(bpy.ops.mesh.primitive_cylinder_add, CLOTH,
        vertices=14, radius=0.175, depth=0.34, location=(0, 0, 1.24)))
    parts.append(box((0, 0, 1.40), (0.46, 0.17, 0.13), CLOTH))   # shoulder bar
    # neck + head
    parts.append(new_primitive(bpy.ops.mesh.primitive_cylinder_add, SKIN,
        vertices=10, radius=0.05, depth=0.10, location=(0, 0, 1.50)))
    parts.append(ball((0, 0, 1.63), 0.105, SKIN))
    # arms (slight A-pose)
    for s in (1, -1):
        x0, x1, x2, x3 = 0.20 * s, 0.26 * s, 0.30 * s, 0.31 * s
        parts.append(ball((x0, 0, 1.40), 0.07, CLOTH))            # deltoid
        parts.append(limb((x0, 0, 1.40), (x1, 0, 1.13), 0.058, 0.048, CLOTH))
        parts.append(ball((x1, 0, 1.13), 0.05, SKIN))             # elbow
        parts.append(limb((x1, 0, 1.13), (x2, 0, 0.88), 0.046, 0.038, SKIN))
        parts.append(box((x3, 0, 0.78), (0.07, 0.09, 0.17), SKIN))  # hand
    # legs
    for s in (1, -1):
        x = 0.105 * s
        parts.append(ball((x, 0, 0.95), 0.095, CLOTH))            # hip joint
        parts.append(limb((x, 0, 0.93), (x, 0, 0.52), 0.088, 0.062, CLOTH))
        parts.append(ball((x, 0, 0.52), 0.062, SKIN))            # knee
        parts.append(limb((x, 0, 0.50), (x, 0, 0.10), 0.058, 0.045, SKIN))
        parts.append(box((x, 0.055, 0.045), (0.095, 0.25, 0.09), LEATHER))  # boot
    # belt + bracers (silhouette detail, leather)
    parts.append(new_primitive(bpy.ops.mesh.primitive_cylinder_add, LEATHER,
        vertices=14, radius=0.165, depth=0.07, location=(0, 0, 1.06)))
    body = join_all(parts, "HumanoidBody")

    # --- armature (Unity Humanoid bone names) ---
    arm = bpy.data.armatures.new("HumanoidArmature")
    ao = bpy.data.objects.new("HumanoidArmature", arm)
    bpy.context.collection.objects.link(ao)
    bpy.context.view_layer.objects.active = ao
    bpy.ops.object.mode_set(mode='EDIT')
    bones = [
        ("Hips",      None,          (0, 0, 0.95),  (0, 0, 1.08)),
        ("Spine",     "Hips",        (0, 0, 1.08),  (0, 0, 1.25)),
        ("Chest",     "Spine",       (0, 0, 1.25),  (0, 0, 1.42)),
        ("Neck",      "Chest",       (0, 0, 1.42),  (0, 0, 1.52)),
        ("Head",      "Neck",        (0, 0, 1.52),  (0, 0, 1.74)),
    ]
    for s, suf in ((1, ".L"), (-1, ".R")):
        x0, x1, x2, x3 = 0.20 * s, 0.26 * s, 0.30 * s, 0.31 * s
        bones += [
            ("Shoulder" + suf, "Chest",          (0.06 * s, 0, 1.40), (x0, 0, 1.40)),
            ("UpperArm" + suf, "Shoulder" + suf,  (x0, 0, 1.40),      (x1, 0, 1.13)),
            ("LowerArm" + suf, "UpperArm" + suf,  (x1, 0, 1.13),      (x2, 0, 0.88)),
            ("Hand" + suf,     "LowerArm" + suf,  (x2, 0, 0.88),      (x3, 0, 0.70)),
        ]
        xl = 0.105 * s
        bones += [
            ("UpperLeg" + suf, "Hips",          (xl, 0, 0.95), (xl, 0, 0.52)),
            ("LowerLeg" + suf, "UpperLeg" + suf, (xl, 0, 0.52), (xl, 0, 0.10)),
            ("Foot" + suf,     "LowerLeg" + suf, (xl, 0, 0.10), (xl, 0.20, 0.03)),
            ("Toes" + suf,     "Foot" + suf,     (xl, 0.20, 0.03), (xl, 0.28, 0.03)),
        ]
    eb = {}
    for name, parent, head, tail in bones:
        b = arm.edit_bones.new(name)
        b.head, b.tail = head, tail
        if parent:
            b.parent = eb[parent]
        eb[name] = b
    bpy.ops.object.mode_set(mode='OBJECT')

    # weapon socket on right hand
    deselect()
    bpy.ops.object.empty_add(location=(0.31, 0, 0.78))
    sock = bpy.context.active_object
    sock.name = "WeaponSocket"
    sock.parent = ao
    sock.parent_type = 'BONE'
    sock.parent_bone = "Hand.R"

    # skin
    deselect()
    body.select_set(True)
    ao.select_set(True)
    bpy.context.view_layer.objects.active = ao
    bpy.ops.object.parent_set(type='ARMATURE_AUTO')
    return [body, ao, sock]

# ---------------------------------------------------------------- 2. WEAPONS
def build_sword():
    parts = []
    parts.append(box((0, 0.45, 0), (0.055, 0.72, 0.014), STEEL))       # blade
    tip = new_primitive(bpy.ops.mesh.primitive_cone_add, STEEL,
        vertices=4, radius1=0.039, depth=0.12, location=(0, 0.87, 0))
    tip.rotation_euler = (-math.pi / 2, 0, math.pi / 4)               # +Y, diamond
    parts.append(tip)
    parts.append(box((0, 0.02, 0), (0.17, 0.028, 0.03), STEEL))        # guard
    grip = new_primitive(bpy.ops.mesh.primitive_cylinder_add, LEATHER,
        vertices=10, radius=0.017, depth=0.12, location=(0, -0.06, 0))
    grip.rotation_euler = (math.pi / 2, 0, 0)                         # along Y
    parts.append(grip)
    parts.append(ball((0, -0.135, 0), 0.028, STEEL))                   # pommel
    return join_all(parts, "Sword")

def build_axe():
    parts = []
    haft = new_primitive(bpy.ops.mesh.primitive_cylinder_add, WOOD,
        vertices=10, radius=0.021, depth=0.88, location=(0, 0, 0))
    haft.rotation_euler = (math.pi / 2, 0, 0)
    parts.append(haft)
    parts.append(box((0, 0.36, 0.10), (0.055, 0.20, 0.20), STEEL))     # head
    parts.append(box((0, 0.36, -0.06), (0.04, 0.10, 0.10), STEEL))     # poll
    spike = new_primitive(bpy.ops.mesh.primitive_cone_add, STEEL,
        vertices=8, radius1=0.025, depth=0.12, location=(0, 0.36, -0.16))
    spike.rotation_euler = (math.pi, 0, 0)                            # -Z
    parts.append(spike)
    grip = new_primitive(bpy.ops.mesh.primitive_cylinder_add, LEATHER,
        vertices=10, radius=0.024, depth=0.14, location=(0, -0.36, 0))
    grip.rotation_euler = (math.pi / 2, 0, 0)
    parts.append(grip)
    return join_all(parts, "Axe")

def build_spear():
    parts = []
    shaft = new_primitive(bpy.ops.mesh.primitive_cylinder_add, WOOD,
        vertices=10, radius=0.016, depth=1.90, location=(0, 0, 0))
    shaft.rotation_euler = (math.pi / 2, 0, 0)
    parts.append(shaft)
    head = new_primitive(bpy.ops.mesh.primitive_cone_add, STEEL,
        vertices=4, radius1=0.045, depth=0.30, location=(0, 1.10, 0))
    head.rotation_euler = (-math.pi / 2, 0, math.pi / 4)
    parts.append(head)
    parts.append(box((0, 0.93, 0), (0.09, 0.03, 0.03), STEEL))         # langet bar
    grip = new_primitive(bpy.ops.mesh.primitive_cylinder_add, LEATHER,
        vertices=10, radius=0.019, depth=0.30, location=(0, -0.75, 0))
    grip.rotation_euler = (math.pi / 2, 0, 0)
    parts.append(grip)
    return join_all(parts, "Spear")

# ---------------------------------------------------------------- 3. DUMMY
def build_dummy():
    parts = []
    parts.append(new_primitive(bpy.ops.mesh.primitive_cylinder_add, WOOD,
        vertices=12, radius=0.09, depth=1.5, location=(0, 0, 0.75)))
    bar = new_primitive(bpy.ops.mesh.primitive_cylinder_add, WOOD,
        vertices=10, radius=0.05, depth=1.05, location=(0, 0, 1.28))
    bar.rotation_euler = (0, math.pi / 2, 0)
    parts.append(bar)
    parts.append(new_primitive(bpy.ops.mesh.primitive_cylinder_add, STRAW,
        vertices=14, radius=0.24, depth=0.62, location=(0, 0, 1.02)))
    parts.append(ball((0, 0, 1.48), 0.13, BURLAP))                     # head
    parts.append(new_primitive(bpy.ops.mesh.primitive_cylinder_add, STONE,
        vertices=12, radius=0.30, depth=0.12, location=(0, 0, 0.06)))   # base
    return join_all(parts, "TrainingDummy")

# ---------------------------------------------------------------- 4. ARENA
def build_arena():
    parts = []
    g = new_primitive(bpy.ops.mesh.primitive_plane_add, GROUND, size=24)
    parts.append(g)
    for x in (-12, 12):
        parts.append(box((x, 0, 0.6), (0.4, 24, 1.2), STONE))
    for y in (-12, 12):
        parts.append(box((0, y, 0.6), (24, 0.4, 1.2), STONE))
    for x in (-6, 6):
        for y in (-6, 6):
            parts.append(new_primitive(
                bpy.ops.mesh.primitive_cylinder_add, STONE,
                vertices=12, radius=0.35, depth=3.2, location=(x, y, 1.6)))
    ring = new_primitive(bpy.ops.mesh.primitive_torus_add, RING,
        major_radius=2.0, minor_radius=0.055, location=(0, 0, 0.03))
    parts.append(ring)
    parts.append(box((8.5, 8.5, 0.35), (0.7, 0.7, 0.7), WOOD))
    parts.append(box((9.3, 8.2, 0.35), (0.7, 0.7, 0.7), WOOD))
    parts.append(box((-8.8, -7.9, 0.5), (1.0, 1.0, 1.0), WOOD))
    return join_all(parts, "Arena")

# ---------------------------------------------------------------- main
def render_preview():
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
    scene.eevee.taa_render_samples = 24
    scene.render.resolution_x, scene.render.resolution_y = 1024, 768
    scene.render.film_transparent = False
    scene.render.filepath = os.path.join(OUT, "preview.png")
    # camera: level, framed on the lineup
    deselect()
    bpy.ops.object.camera_add(location=(0.45, -5.2, 1.9))
    cam = bpy.context.active_object
    scene.camera = cam
    target = Vector((0.45, 0.3, 1.0))
    d = target - cam.location
    cam.rotation_euler = d.to_track_quat('-Z', 'Y').to_euler()
    cam.data.lens = 40
    # key sun + fill
    deselect()
    bpy.ops.object.light_add(type='SUN', location=(3, -2, 6))
    key = bpy.context.active_object
    key.data.energy = 3.0
    deselect()
    bpy.ops.object.light_add(type='SUN', location=(-4, 3, 2))
    fill = bpy.context.active_object
    fill.data.energy = 1.0
    # ground for the preview only
    deselect()
    bpy.ops.mesh.primitive_plane_add(size=14, location=(0.45, 0.3, 0))
    gp = bpy.context.active_object
    gp.name = "PreviewGround"
    gp.data.materials.append(GROUND)
    bpy.ops.render.render(write_still=True)
    # remove preview-only objects (keep the real assets)
    for o in (gp, cam, key, fill):
        bpy.data.objects.remove(o, do_unlink=True)

def main():
    # start clean
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

    h = build_humanoid()

    weapons = []
    for name, fn, x in (("Sword", build_sword, 1.1),
                        ("Axe", build_axe, 1.75),
                        ("Spear", build_spear, 2.45)):
        w = fn()
        w.location = (x, 0, 0)
        w.rotation_euler = (math.pi / 2, 0, 0)   # stand upright for preview
        weapons.append((name, w))

    d = build_dummy()
    d.location = (-1.6, 0, 0)

    render_preview()

    # exports (reset weapon transforms to modeled space first)
    deselect()
    for o in h:
        o.select_set(True)
    export_selected(os.path.join(OUT, "humanoid.fbx"))

    for name, w in weapons:
        w.location = (0, 0, 0)
        w.rotation_euler = (0, 0, 0)
        deselect()
        w.select_set(True)
        export_selected(os.path.join(OUT, f"weapon_{name.lower()}.fbx"))
        deselect()
        bpy.data.objects.remove(w, do_unlink=True)

    d.location = (0, 0, 0)
    deselect()
    d.select_set(True)
    export_selected(os.path.join(OUT, "dummy.fbx"))
    deselect()
    bpy.data.objects.remove(d, do_unlink=True)

    a = build_arena()
    deselect()
    a.select_set(True)
    export_selected(os.path.join(OUT, "arena.fbx"))

    print("EXPORTS DONE:", sorted(os.listdir(OUT)))

main()
