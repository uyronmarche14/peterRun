"""Run in Blender with --python-exit-code 1 against the saved character source."""
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

s=bpy.data.scenes['CLASSIC_CHARACTER_STUDIO']
bpy.context.window.scene=s
assert s['asset_id']=='runner_classic_v01'
assert s.camera.data.type=='ORTHO'
assert s.render.film_transparent
assert (s.render.resolution_x,s.render.resolution_y)==(512,512)
assert list(s['pivot_pixels'])==[256,432]
markers={m.name:m.frame for m in s.timeline_markers}
expected={'IDLE_READY','WALK_FORWARD','MOVE_LEFT','MOVE_RIGHT','JUMP_LOW','SLIDE_DUCK','SUCCESS_SETTLE','NEUTRAL_CLEAR','PAUSED','REST'}
assert set(markers)==expected
rig=bpy.data.collections['CLASSIC_NEW_ADULT_GEOMETRY']
assert not any(o.type=='FONT' for o in rig.objects)
assert not any(o.type=='EMPTY' and o.empty_display_type=='IMAGE' for o in rig.objects)
assert all(o.animation_data and o.animation_data.action for o in rig.objects)
s.frame_set(1)
p=world_to_camera_view(s,s.camera,Vector((0,0,0)))
assert abs(p.x*512-256)<.1 and abs((1-p.y)*512-432)<.1, tuple(p)
hip=bpy.data.objects['Classic_Torso_Pivot']
base=hip.location.z
s.frame_set(markers['SLIDE_DUCK']+12)
assert hip.location.z < base-.20, (hip.location.z,base)
s.frame_set(markers['JUMP_LOW']+10)
assert hip.location.z > base+.07
leg=bpy.data.objects['Classic_L_Trouser_Thigh']
s.frame_set(markers['WALK_FORWARD']);a=leg.rotation_euler.copy()
s.frame_set(markers['WALK_FORWARD']+7);b=leg.rotation_euler.copy()
assert (Vector(a)-Vector(b)).length>.05
s.frame_set(1)
print('CLASSIC_BLENDER_SOURCE_PASS: real keyed geometry, ten clips, fixed pivot, walk/duck/jump transform checks')
