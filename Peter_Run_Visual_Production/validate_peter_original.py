"""Inspect evaluated rig geometry and rendered images; no source mutation."""
import json
import math
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'generated/peter_original_v01'
EVIDENCE=ROOT.parent/'test_evidence/peter_original_v01'
EVIDENCE.mkdir(parents=True,exist_ok=True)
scene=bpy.context.scene
rig=bpy.data.objects['Peter_Rig']
assert len(rig.data.bones)==22
assert rig['asset_origin']=='original procedural mesh and skeletal animation'
meshes=[o for o in bpy.data.objects if o.type=='MESH']
for obj in meshes:
    assert any(m.type=='ARMATURE' and m.object==rig for m in obj.modifiers),obj.name
    for v in obj.data.vertices:
        assert abs(sum(g.weight for g in v.groups)-1)<.001,(obj.name,v.index,'weights')
report={'source_vertices':sum(len(o.data.vertices) for o in meshes),'bone_count':22,'clips':{},'foot_floor_min':1,'frame_checks':0}
for act in bpy.data.actions:
    if not act.name.startswith('Peter_'): continue
    rig.animation_data.action=act
    duration=float(act['duration_seconds'])
    worst_floor=1
    for t in np.linspace(0,duration,9):
        f=1+t*30; scene.frame_set(math.floor(f),subframe=f%1)
        deps=bpy.context.evaluated_depsgraph_get()
        for obj in meshes:
            evaluated=obj.evaluated_get(deps)
            mesh=evaluated.to_mesh()
            if 'Rubber_Sole' in obj.name:
                floor=min((evaluated.matrix_world@v.co).z for v in mesh.vertices)
                worst_floor=min(worst_floor,floor)
            for corner in evaluated.bound_box:
                p=world_to_camera_view(scene,scene.camera,evaluated.matrix_world@Vector(corner))
                assert -.005<p.x<1.005 and -.005<p.y<1.005,(act.name,obj.name,'clipped',tuple(p))
            evaluated.to_mesh_clear()
    assert worst_floor>-.01,(act.name,'sole below floor',worst_floor)
    report['foot_floor_min']=min(report['foot_floor_min'],worst_floor)
    report['clips'][act.name]={'duration':duration,'loop':bool(act['loop']),'minimum_sole_z':worst_floor}
manifest_path=ROOT.parent/'code/art/characters/peter_original_v01/animation_manifest.json'
if manifest_path.exists():
    manifest=json.loads(manifest_path.read_text())
    total_bytes=0
    for name,spec in manifest['animations'].items():
        first=last=None
        for i in range(spec['frames']):
            path=OUT/name/f'{name}_{i:03d}.png'
            image=bpy.data.images.load(str(path),check_existing=False)
            assert tuple(image.size)==(512,512)
            values=np.empty(512*512*4,dtype=np.float32); image.pixels.foreach_get(values)
            alpha=values.reshape((512,512,4))[:,:,3]
            ys,xs=np.where(alpha>.05)
            assert len(xs)>100 and xs.min()>2 and xs.max()<509 and ys.min()>2 and ys.max()<509,(name,i,'crop')
            if i==0: first=values.copy()
            last=values.copy()
            report['frame_checks']+=1
            bpy.data.images.remove(image)
        assert abs(sum(spec['frame_durations'])-spec['duration_seconds'])<1e-7
        if spec['loop']: assert not np.array_equal(first,last),(name,'duplicate endpoint')
        atlas=bpy.data.images.load(str(manifest_path.parent/spec['atlas']),check_existing=False)
        total_bytes+=atlas.size[0]*atlas.size[1]*4
        bpy.data.images.remove(atlas)
    report['runtime_atlas_rgba_bytes']=total_bytes
    report['runtime_atlas_mib']=round(total_bytes/1024/1024,2)
(EVIDENCE/'source_validation.json').write_text(json.dumps(report,indent=2))
print('PETER_ORIGINAL_SOURCE_VALIDATION_PASS',json.dumps(report))
