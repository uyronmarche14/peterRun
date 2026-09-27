"""Fresh Blender character, object-joint animation, and fixed-camera RGBA export.
No previous protagonist meshes/images are read. Run in background Blender, then
append CLASSIC_CHARACTER_STUDIO to the live session without discarding user data.
"""
import bpy
import math
import json
import sys
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'code/art/characters/runner_classic_v01'
SOURCE = ROOT / 'Peter_Run_Visual_Production/Classic_Character_Studio_v01.blend'
OUT.mkdir(parents=True, exist_ok=True)
SPECS = [('idle_ready',8,8,True,1.75),('walk_forward',10,10,True,1.2),
         ('move_left',8,10,False,.8),('move_right',8,10,False,.8),
         ('jump_low',10,12,False,10/12),('slide_duck',10,10,False,1.0),
         ('success_settle',8,8,False,1.0),('neutral_clear',6,8,False,.75),
         ('paused',1,1,False,1.0),('rest',6,6,True,1.5)]
scene = bpy.data.scenes.new('CLASSIC_CHARACTER_STUDIO')
bpy.context.window.scene = scene
scene['asset_id'] = 'runner_classic_v01'
scene['authorship'] = 'New procedural fictional adult. No prior character art or model imported.'
scene['rig_kind'] = 'Editable object-joint rig with baked transform keys at 24fps; not a skinned armature.'
scene['pivot_pixels'] = [256,432]
scene['canvas'] = [512,512]
scene.render.engine = 'CYCLES'
scene.cycles.samples = 24
scene.cycles.use_denoising = True
scene.render.resolution_x = scene.render.resolution_y = 512
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.render.film_transparent = True
scene.render.fps = 24
scene.world = bpy.data.worlds.new('Classic_Morning_Ambient')
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.72,.81,.84,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = .35
scene.view_settings.view_transform = 'AgX'
scene.view_settings.look = 'AgX - Medium High Contrast'
collection = bpy.data.collections.new('CLASSIC_NEW_ADULT_GEOMETRY')
scene.collection.children.link(collection)
objects = []

def mat(name, rgb, rough=.75):
    m = bpy.data.materials.new('Classic_'+name)
    m.diffuse_color = (*rgb,1)
    m.use_nodes = True
    bs = m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = (*rgb,1)
    bs.inputs['Roughness'].default_value = rough
    return m
skin = mat('Warm_Brown', (.43,.205,.105))
skin_hi = mat('Ear_Cheek', (.49,.245,.135))
hair = mat('Espresso_Hair', (.025,.018,.017),.83)
hair_hi = mat('Hair_Soft_Planes', (.043,.029,.023))
shirt = mat('Terracotta_Linen', (.64,.155,.075))
shirt_hi = mat('Linen_Seam', (.76,.24,.115))
trim = mat('Deep_Teal_Habi', (.035,.235,.215))
weft = mat('Warm_Thread', (.83,.62,.30))
pants = mat('Ink_Charcoal', (.042,.071,.098))
pants_hi = mat('Trouser_Seam', (.065,.105,.13))
shoe = mat('Oat_Walking_Shoes', (.63,.60,.51))
sole = mat('Shoe_Sole', (.22,.265,.255))
white = mat('Eye_White', (.67,.59,.45))
eye = mat('Eye_Dark', (.028,.024,.023))

# Mesh rings preserve adult taper; bevel/subdivision soften without babyish spheres.
def rings(name, levels, material, n=16, sub=1):
    verts=[]
    for z,rx,ry,cy in levels:
        verts += [(rx*math.cos(i*math.tau/n),cy+ry*math.sin(i*math.tau/n),z) for i in range(n)]
    faces=[tuple(reversed(range(n)))]
    for j in range(len(levels)-1):
        for i in range(n):
            a=j*n+i;b=j*n+(i+1)%n
            faces.append((a,b,b+n,a+n))
    faces.append(tuple(range((len(levels)-1)*n,len(levels)*n)))
    mesh=bpy.data.meshes.new(name+'_mesh');mesh.from_pydata(verts,[],faces);mesh.update()
    obj=bpy.data.objects.new('Classic_'+name,mesh);collection.objects.link(obj)
    obj.data.materials.append(material)
    for p in mesh.polygons:p.use_smooth=True
    if sub:
        mod=obj.modifiers.new('Soft_Illustrated_Surface','SUBSURF');mod.levels=sub;mod.render_levels=sub
    objects.append(obj)
    return obj

def ellipsoid(name, loc, scale, material, seg=20):
    # UV sphere built with data API, not dependent on selected Blender objects.
    levels=[]
    for j in range(13):
        phi=math.pi*j/12
        radius=max(.001,math.sin(phi))
        levels.append((math.cos(phi)*scale[2],radius*scale[0],radius*scale[1],0))
    ob=rings(name,levels,material,n=seg,sub=0);ob.location=loc
    return ob

def tube(name, a, b, r1, r2, material, depth=1.0):
    ob=rings(name,[(-.025,r1*.95,r1*depth*.95,0),(.025,r1,r1*depth,0),(.975,r2,r2*depth,0),(1.025,r2*.95,r2*depth*.95,0)],material,16,1)
    return ob

def segment(ob,a,b):
    a=Vector(a);b=Vector(b);d=b-a
    ob.location=a;ob.rotation_euler=d.to_track_quat('Z','Y').to_euler();ob.scale=(1,1,d.length)

body=bpy.data.objects.new('Classic_Torso_Pivot',None);collection.objects.link(body);objects.append(body)
body.empty_display_type='PLAIN_AXES';body.empty_display_size=.12
# Coordinates local to hip at z=.98.
trunk=rings('Tailored_Linen_Top',[(0,.15,.094,0),(.025,.173,.102,0),(.15,.158,.101,0),(.31,.189,.108,0),(.40,.204,.094,0),(.455,.15,.075,0),(.475,.076,.06,0)],shirt,20,2)
trunk.parent=body
pelvis=rings('Jogger_Hip',[(.83,.132,.087,0),(.87,.158,.096,0),(.99,.159,.094,0),(1.02,.148,.088,0)],pants,20,2)
hem=rings('Woven_Hem',[(.022,.175,.103,0),(.035,.176,.104,0),(.061,.17,.102,0),(.064,.168,.101,0)],trim,24,1);hem.parent=body
# Small localized woven bars, not text/flag or a costume.
for j in range(7):
    x=-.12+j*.014
    bar=ellipsoid('Habi_Thread_%02d'%j,(x,-.101,.045),(.0025,.0018,.010),weft,12);bar.parent=body
neck=ellipsoid('Neck',(0,0,.49),(.063,.057,.079),skin);neck.parent=body
head_pivot=bpy.data.objects.new('Classic_Head_Pivot',None);collection.objects.link(head_pivot);objects.append(head_pivot);head_pivot.parent=body
head=rings('Adult_Face',[(0,.041,.057,.017),(.020,.064,.072,.009),(.058,.083,.082,0),(.13,.089,.089,-.003),(.195,.084,.079,-.01),(.225,.06,.055,-.012),(.234,.016,.014,-.012)],skin,24,2);head.parent=head_pivot
for side in [-1,1]:
    ob=ellipsoid(('Left' if side<0 else 'Right')+'_Ear',(side*.086,-.001,.105),(.017,.019,.033),skin_hi);ob.parent=head_pivot
    ob=ellipsoid('Calm_Eye_White_'+str(side),(side*.037,.076,.121),(.020,.012,.006),white);ob.parent=head_pivot
    ob=ellipsoid('Calm_Iris_'+str(side),(side*.037,.085,.121),(.006,.004,.005),eye);ob.parent=head_pivot
    ob=ellipsoid('Soft_Brow_'+str(side),(side*.037,.078,.141),(.022,.005,.004),hair);ob.parent=head_pivot
nose=ellipsoid('Natural_Nose',(0,.089,.101),(.017,.025,.032),skin_hi);nose.parent=head_pivot
mouth=ellipsoid('Relaxed_Mouth',(0,.078,.056),(.025,.004,.0025),skin_hi);mouth.parent=head_pivot
# Asymmetric swept short cut with tapered nape, custom cap silhouette.
cap=rings('Swept_Short_Hair',[(.12,.085,.083,-.010),(.165,.094,.09,-.010),(.205,.095,.087,-.014),(.24,.068,.063,-.011),(.25,.029,.033,-.004)],hair,24,2);cap.parent=head_pivot
# Sloping hairline: lower at the nape, open at the forehead, not a bowl band.
for i in range(24):
    cap.data.vertices[i].co.z += .047*math.sin(i*math.tau/24)
for i in range(5):
    ob=ellipsoid('Swept_Lock_%02d'%i,(-.052+i*.023,.015,.231+math.sin(i*.6)*.007),(.023,.058,.014),hair_hi if i%2 else hair)
    ob.rotation_euler=(0,-.20,-.25);ob.parent=head_pivot
# Long adult limbs with elbow/knee structure and soft joins.
limbs={}
for side in [-1,1]:
    key='L' if side<0 else 'R'
    d={}
    d['thigh']=tube(key+'_Trouser_Thigh',(0,0,0),(0,0,1),.091,.061,pants,1.12)
    d['shin']=tube(key+'_Trouser_Calf',(0,0,0),(0,0,1),.065,.043,pants,1.06)
    d['knee']=ellipsoid(key+'_Knee',(0,0,0),(.060,.064,.062),pants)
    d['cuff']=ellipsoid(key+'_Jogger_Cuff',(0,0,0),(.044,.048,.028),pants_hi)
    d['shoe']=ellipsoid(key+'_Walking_Shoe',(0,0,0),(.059,.125,.055),shoe)
    d['sole']=ellipsoid(key+'_Quiet_Sole',(0,0,0),(.061,.13,.018),sole)
    for i in range(3):
        d['lace'+str(i)]=ellipsoid(key+'_Lace_'+str(i),(0,0,0),(.039,.006,.003),weft,12)
    d['sleeve']=tube(key+'_Soft_Sleeve',(0,0,0),(0,0,1),.071,.066,shirt)
    d['sleeve_lower']=tube(key+'_Rolled_Linen_Sleeve',(0,0,0),(0,0,1),.063,.058,shirt)
    d['rolled_cuff']=ellipsoid(key+'_Rolled_Cuff',(0,0,0),(.060,.061,.024),shirt_hi)
    d['upper']=tube(key+'_Upper_Arm',(0,0,0),(0,0,1),.052,.044,skin)
    d['fore']=tube(key+'_Forearm',(0,0,0),(0,0,1),.043,.030,skin)
    d['elbow']=ellipsoid(key+'_Elbow',(0,0,0),(.042,.043,.043),skin)
    d['hand']=ellipsoid(key+'_Relaxed_Hand',(0,0,0),(.037,.028,.064),skin_hi)
    d['thumb']=ellipsoid(key+'_Thumb',(0,0,0),(.016,.018,.033),skin)
    limbs[side]=d

# Soft illustration studio; no floor, road, UI or shadow in character renders.
cdata=bpy.data.cameras.new('Classic_Orthographic');camera=bpy.data.objects.new('Classic_Rear_Three_Quarter',cdata);scene.collection.objects.link(camera)
camera.location=(4.1,-7.7,3.0);target=Vector((0,0,.86));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();cdata.type='ORTHO';cdata.ortho_scale=2.32;scene.camera=camera
bpy.context.view_layer.update()
# Solve film shift to map world ground origin to (256,432); same for ALL frames.
base=world_to_camera_view(scene,camera,Vector((0,0,0)))
cdata.shift_y += base.y-(1-432/512)
cdata.shift_x += base.x-.5
for name,loc,energy,size,color in [('Key',(-3,-4,6),420,4,(1,.84,.67)),('Fill',(4,-1,3),190,4,(.68,.85,1)),('Rim',(0,4,4),310,3,(1,.80,.53))]:
    data=bpy.data.lights.new('Classic_'+name,'AREA');data.energy=energy;data.shape='DISK';data.size=size;data.color=color
    obj=bpy.data.objects.new('Classic_'+name,data);scene.collection.objects.link(obj);obj.location=loc;obj.rotation_euler=(Vector((0,0,.85))-obj.location).to_track_quat('-Z','Y').to_euler()

def smooth(t):
    t=max(0,min(1,t));return t*t*(3-2*t)
def hump(t,a,b):
    return math.sin(math.pi*smooth((t-a)/(b-a))) if a<t<b else 0

def pose(name,t):
    # All one-shots share exactly the same endpoint ready pose.
    if name not in ['idle_ready','walk_forward','rest'] and t >= 1.0:
        t=0.0
    tau=math.tau*t
    hip=Vector((0,0,.98));lean=0.0;turn=0.0;nod=0.0
    feet={s:Vector((s*.106,.025,.085)) for s in [-1,1]}
    arm_swing={-1:0.0,1:0.0};spread=0.0
    if name in ['idle_ready','rest']:
        hip.z+=.0035*math.sin(tau);hip.x+=.003*math.sin(tau)
        spread=.005*(1-math.cos(tau))
    elif name=='walk_forward':
        hip.z+=.006*(1-math.cos(2*tau));hip.x=.010*math.sin(tau)
        for s in [-1,1]:
            phase=tau+(0 if s<0 else math.pi)
            feet[s].y+=.13*math.cos(phase)
            feet[s].z+=.052*max(0,math.sin(phase))
            arm_swing[s]=-.11*math.cos(phase)
        lean=-.02
    elif name in ['move_left','move_right']:
        lead=-1 if name=='move_left' else 1
        travel=.24*smooth(t)
        # In-place export subtracts lateral root travel; runtime applies lane travel.
        for s in [-1,1]:
            ft=smooth(t/.56) if s==lead else smooth((t-.44)/.56)
            feet[s].x+=lead*(.24*ft-travel)
            feet[s].z+=.052*hump(t,0,.58) if s==lead else .040*hump(t,.43,1)
        hip.x=lead*.017*math.sin(math.pi*t)**2
        turn=-lead*.09*math.sin(math.pi*t)**2
        spread=.025*math.sin(math.pi*t)**2
    elif name=='jump_low':
        crouch=.07*hump(t,0,.28)+.06*hump(t,.65,1)
        lift=.12*hump(t,.22,.78)
        hip.z+=lift-crouch
        for s in [-1,1]:feet[s].z+=lift
        spread=.075*math.sin(math.pi*t)**2
        lean=-.07*(crouch/.07)
    elif name=='slide_duck':
        amount=smooth(t/.32) if t<.32 else (1-smooth((t-.68)/.32) if t>.68 else 1)
        hip.z-=.28*amount;hip.y-=.095*amount;lean=-.24*amount
        spread=.045*amount
        for s in [-1,1]:arm_swing[s]=.12*amount
    elif name=='success_settle':
        nod=.075*math.sin(math.pi*t)**2;spread=.065*math.sin(math.pi*t)**2
    elif name=='neutral_clear':
        turn=.07*math.sin(math.pi*t)**2;nod=.025*math.sin(math.pi*t)**2
    body.location=hip;body.rotation_euler=(lean,0,turn)
    pelvis.location=(hip.x,hip.y,hip.z-.98)
    head_pivot.location=(0,0,.515);head_pivot.rotation_euler=(nod,0,0)
    def bodypoint(v):
        return hip+body.rotation_euler.to_matrix()@Vector(v)
    for s,d in limbs.items():
        ankle=feet[s];h=hip+Vector((s*.096,0,-.035))
        delta=ankle-h;length=delta.length
        a=.445;b=.435
        # Analytic two-bone knee, bends towards character-forward +Y.
        unit=delta.normalized();along=(a*a-b*b+length*length)/(2*length)
        along=min(a,along);height=math.sqrt(max(0,a*a-along*along))
        bend=Vector((0,1,0));bend=(bend-unit*bend.dot(unit)).normalized()
        knee=h+unit*along+bend*height
        segment(d['thigh'],h,knee);segment(d['shin'],knee,ankle)
        d['knee'].location=knee
        d['cuff'].location=ankle+Vector((0,0,.012))
        d['shoe'].location=ankle+Vector((0,.036,-.031))
        d['sole'].location=ankle+Vector((0,.036,-.067))
        for i in range(3):d['lace'+str(i)].location=ankle+Vector((0,.035+i*.020,.012-i*.004))
        shoulder=bodypoint((s*.192,0,.403))
        elbow=bodypoint((s*(.23+spread*.6),arm_swing[s]*.6,.16))
        wrist=bodypoint((s*(.247+spread),.018+arm_swing[s],-.075))
        segment(d['sleeve'],shoulder,elbow)
        segment(d['sleeve_lower'],elbow,elbow.lerp(wrist,.45))
        d['rolled_cuff'].location=elbow.lerp(wrist,.45)
        d['rolled_cuff'].rotation_euler=(wrist-elbow).to_track_quat('Z','Y').to_euler()
        segment(d['upper'],shoulder.lerp(elbow,.4),elbow)
        segment(d['fore'],elbow,wrist);d['elbow'].location=elbow
        d['hand'].location=wrist+Vector((s*.006,0,-.040))
        d['thumb'].location=wrist+Vector((-s*.029,.014,-.028))
    bpy.context.view_layer.update()

# Save continuous 24fps keyed transforms with named timeline regions.
manifest={'asset_id':'runner_classic_v01','canvas':[512,512],'pivot':[256,432],
          'view':'rear three-quarter, orthographic, fixed warm morning light',
          'root_motion':'in-place; lateral lane translation is owned by Godot',
          'jump':'baked modest vertical lift; do not add a second visual jump',
          'animations':{},'notes':['Idle 8 fps uses 1.75 frame-duration multiplier for 1.75s loop.',
          'Walk 10 fps uses 1.2 frame-duration multiplier for 1.2s loop.',
          'Playback in gameplay is fitted to existing action-state timing, not used to change collision windows.']}
start=1
for name,count,fps,loop,duration in SPECS:
    length=round(duration*24)
    scene.timeline_markers.new(name.upper(),frame=start)
    for k in range(length+1):
        pose(name,k/length if length else 0)
        for ob in objects:
            for path in ['location','rotation_euler','scale']:
                ob.keyframe_insert(data_path=path,frame=start+k,group=name)
    manifest['animations'][name]={'frames':count,'fps':fps,'loop':loop,'duration_seconds':duration,
        'frame_duration_multiplier':duration*fps/count,'timeline_start':start,'timeline_end':start+length,
        'files':[f'{name}/{name}_{i:02d}.png' for i in range(count)]}
    start+=length+2
scene.frame_start=1;scene.frame_end=start-2
scene.frame_set(1)
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_perspective='CAMERA'
            area.spaces.active.overlay.show_overlays=False
            area.spaces.active.shading.type='MATERIAL'
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
(OUT/'animation_manifest.json').write_text(json.dumps(manifest,indent=2))

# The saved source retains real animation. Detach keys only in this temporary
# export process so render evaluation cannot replace the explicitly sampled pose.
for ob in objects:
    ob.animation_data_clear()

# Preview three key poses before bulk export.
for name,t in [('idle_ready',0),('slide_duck',.5),('walk_forward',.2)]:
    pose(name,t);scene.render.filepath=str(OUT/f'preview_{name}.png');bpy.ops.render.render(write_still=True)
if '--preview' in sys.argv:
    print('CLASSIC_PREVIEW_READY',SOURCE)
else:
    for name,count,fps,loop,duration in SPECS:
        (OUT/name).mkdir(exist_ok=True)
        for i in range(count):
            t=i/count if loop else (i/(count-1) if count>1 else 0)
            pose(name,t)
            scene.render.filepath=str(OUT/name/f'{name}_{i:02d}.png')
            bpy.ops.render.render(write_still=True)
    pose('idle_ready',0)
    scene.frame_set(1)
    print('CLASSIC_FULL_RENDER_READY',SOURCE)
