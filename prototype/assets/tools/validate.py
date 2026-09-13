#!/usr/bin/env python3
"""Validate exported FBX files: reimport each, report structure."""
import bpy, os, sys

OUT = os.path.dirname(os.path.abspath(__file__))

def check(path):
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.fbx(filepath=path)
    print(f"== {os.path.basename(path)} ==")
    for o in bpy.context.scene.objects:
        extra = ""
        if o.type == 'ARMATURE':
            bn = [b.name for b in o.data.bones]
            extra = f"bones={len(bn)}"
        elif o.type == 'MESH':
            me = o.data
            vg = len(o.vertex_groups)
            dims = tuple(round(v, 3) for v in o.dimensions)
            extra = f"verts={len(me.vertices)} vgroups={vg} dims={dims} mats={[m.name for m in me.materials]}"
        print(f"  {o.type:8} {o.name:24} {extra}")

for f in ["humanoid.fbx", "weapon_sword.fbx", "weapon_axe.fbx",
          "weapon_spear.fbx", "dummy.fbx", "arena.fbx"]:
    check(os.path.join(OUT, f))
