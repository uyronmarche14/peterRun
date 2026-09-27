"""Render immutable 512px source frames; pack aligned 256px runtime atlases."""
import json
import math
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector, Quaternion
from bpy_extras.object_utils import world_to_camera_view

ROOT=Path(__file__).resolve().parent
OUT=ROOT/'generated/peter_original_v01'
RUNTIME=ROOT.parent/'code/art/characters/peter_original_v01'
OUT.mkdir(parents=True,exist_ok=True); RUNTIME.mkdir(parents=True,exist_ok=True)
scene=bpy.context.scene; rig=bpy.data.objects['Peter_Rig']; cam=scene.camera
scene.eevee.taa_render_samples=16

def action(clip,time=0):
    rig.animation_data.action=bpy.data.actions['Peter_'+clip]
    frame=1+time*30; scene.frame_set(math.floor(frame),subframe=frame%1)

def render(path):
    scene.render.filepath=str(path); bpy.ops.render.render(write_still=True)

args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
if 'stress' in args:
    action('idle_ready')
    rig.animation_data_clear()
    for side,angle in [('L',1.8),('R',-1.8)]:
        name='upper_arm.'+side
        basis=rig.data.bones[name].matrix_local.to_quaternion()
        rig.pose.bones[name].rotation_euler=(basis.inverted() @ Quaternion((0,1,0),angle) @ basis).to_euler()
    rig.pose.bones['forearm.L'].rotation_euler.x=-1.0
    rig.pose.bones['forearm.R'].rotation_euler.x=-1.0
    bpy.context.view_layer.update()
    render(OUT/'stress_raised_arms.png')
    raise SystemExit(0)
if 'poses' in args:
    for clip,t in [('walk_forward',.25),('walk_forward',.75),('move_left',.11),('move_right',.11),('jump_low',.27),('jump_low',.52),('slide_duck',.24)]:
        action(clip,t); render(OUT/f'pose_{clip}_{t:.2f}.png')
    raise SystemExit(0)
if 'preview' in args:
    action('idle_ready')
    render(OUT/'preview_gameplay.png')
    for name,loc in [('front',(0,-6,2.1)),('side',(6,0,2.1)),('rear',(0,6,2.1))]:
        cam.location=loc; cam.rotation_euler=(Vector((0,0,.92))-cam.location).to_track_quat('-Z','Y').to_euler()
        cam.data.shift_x=cam.data.shift_y=0
        bpy.context.view_layer.update(); p=world_to_camera_view(scene,cam,Vector((0,0,0)))
        cam.data.shift_x=p.x-.5; cam.data.shift_y=p.y-(1-432/512)
        render(OUT/('preview_'+name+'.png'))
    raise SystemExit(0)

names=['idle_ready','walk_forward','move_left','move_right','jump_low','slide_duck','rest','success_settle','neutral_clear','paused']
manifest={'schema_version':1,'asset_origin':'original procedural mesh and skeletal animation','source_file':'Peter_Run_Visual_Production/Peter_Original_Rigged_v01.blend','source_canvas':[512,512],'canvas':[256,256],'pivot':[128,216],'source_pivot':[256,432],'authoring_fps':30,'sampling_fps':24,'jump_displacement':'baked_into_frames','shadow':'ground_shadow.png','animations':{}}
for clip in names:
    a=bpy.data.actions['Peter_'+clip]; duration=float(a['duration_seconds']); loop=bool(a['loop'])
    count=max(1,math.ceil(duration*24-1e-8))
    times=[i/24 for i in range(count)]
    folder=OUT/clip; folder.mkdir(exist_ok=True)
    for i,t in enumerate(times):
        path=folder/f'{clip}_{i:03d}.png'
        if 'pack' not in args:
            action(clip,t); render(path)
        if not path.exists(): raise RuntimeError('Missing source frame '+str(path))
    # Padded fixed tiles; alpha-edge color dilation is handled by Godot imports.
    cols=min(7,count); rows=math.ceil(count/cols); tile=260
    atlas=np.zeros((rows*tile,cols*tile,4),dtype=np.float32)
    for i in range(count):
        im=bpy.data.images.load(str(folder/f'{clip}_{i:03d}.png'),check_existing=False)
        im.scale(256,256)
        pix=np.empty(256*256*4,dtype=np.float32); im.pixels.foreach_get(pix); pix=pix.reshape((256,256,4))
        x=(i%cols)*tile+2; y=(rows-1-i//cols)*tile+2
        atlas[y-2:y+258,x-2:x+258]=np.pad(pix,((2,2),(2,2),(0,0)),mode='edge')
        bpy.data.images.remove(im)
    result=bpy.data.images.new(clip+'_Atlas',width=cols*tile,height=rows*tile,alpha=True)
    result.pixels.foreach_set(atlas.ravel()); result.filepath_raw=str(RUNTIME/(clip+'.png')); result.file_format='PNG'; result.save(); bpy.data.images.remove(result)
    manifest['animations'][clip]={'frames':count,'fps':24,'duration_seconds':duration,'loop':loop,'timestamps':times,'frame_durations':[min(1/24,duration-t) for t in times],'atlas':clip+'.png','regions':[[i%cols*tile+2,i//cols*tile+2,256,256] for i in range(count)]}
    print('PETER_CLIP_EXPORTED',clip,count,flush=True)
# Separate centered contact shadow: image pixels are bottom-up in Blender.
pixels=np.zeros((256,256,4),dtype=np.float32)
yy,xx=np.mgrid[0:256,0:256]; radius=((xx-128)/37)**2+((yy-39)/8)**2
pixels[:,:,:3]=(.09,.14,.13); pixels[:,:,3]=np.maximum(0,1-radius/2)**3*.27
im=bpy.data.images.new('Peter_Ground_Shadow',width=256,height=256,alpha=True)
im.pixels.foreach_set(pixels.ravel()); im.filepath_raw=str(RUNTIME/'ground_shadow.png'); im.file_format='PNG'; im.save()
(RUNTIME/'animation_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('PETER_ORIGINAL_EXPORT_PASS',sum(a['frames'] for a in manifest['animations'].values()),flush=True)
