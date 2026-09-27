"""Original Peter: connected weighted surfaces, editable IK rig, 30 fps actions.

Run only in a background Blender process. Never loads the supplied character.
Export is a separate script, so building does not overwrite gameplay artwork.
"""
import math
from pathlib import Path

import bpy
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "Peter_Original_Rigged_v01.blend"
CLIPS = {
    "idle_ready": (2.0, True), "walk_forward": (1.2, True),
    "move_left": (.22, False), "move_right": (.22, False),
    "jump_low": (.62, False), "slide_duck": (.48, False),
    "rest": (2.0, True), "success_settle": (.5, False),
    "neutral_clear": (.25, False), "paused": (1/24, False),
}
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.name = "Peter_Original_Studio"
scene.render.engine = "BLENDER_EEVEE"
scene.eevee.taa_render_samples = 16
scene.render.resolution_x = scene.render.resolution_y = 512
scene.render.resolution_percentage = 100
scene.render.fps = 30
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.image_settings.color_depth = "8"
scene.render.image_settings.compression = 30
scene.render.filepath = str(ROOT / "generated/peter_original_v01/preview_rear.png")
scene.world = bpy.data.worlds.new("Peter_Studio_World")
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.42,.49,.52,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = .35
scene.view_settings.view_transform = "AgX"
scene.view_settings.look = "AgX - Medium High Contrast"
scene.render.image_settings.color_mode = "RGBA"
coll = bpy.data.collections.new("PETER_ORIGINAL_CHARACTER")
scene.collection.children.link(coll)

def move_collection(obj):
    for c in list(obj.users_collection): c.objects.unlink(obj)
    coll.objects.link(obj)

def mat(name, color, rough=.78):
    m=bpy.data.materials.new(name)
    m.diffuse_color=(*color,1)
    m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Roughness'].default_value=rough
    return m

skin=mat('Peter_Warm_Brown_Skin',(.36,.17,.085))
shirt=mat('Peter_Terracotta_Cotton',(.57,.115,.062))
teal=mat('Peter_Woven_Teal',(.025,.22,.22))
navy=mat('Peter_Navy_Twill',(.025,.046,.073))
cream=mat('Peter_Cream_Canvas',(.76,.68,.49))
sole=mat('Peter_Teal_Rubber',(.025,.11,.12))
hair=mat('Peter_Textured_Dark_Hair',(.018,.012,.010))
eye=mat('Peter_Eyes',(.009,.012,.012))
white=mat('Peter_Eye_Warm_White',(.75,.69,.56))
lip=mat('Peter_Lip',(.23,.067,.04))

def sphere(name, location, scale, material, segments=24, rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=location)
    o=bpy.context.object; o.name=name; o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(material); move_collection(o)
    for p in o.data.polygons: p.use_smooth=True
    return o

def loft(name, rings, material, count=16):
    # Continuous quad rings give joints multiple deforming cross sections.
    verts=[]
    for x,y,z,rx,ry in rings:
        verts.extend((x+rx*math.cos(a*math.tau/count),y+ry*math.sin(a*math.tau/count),z) for a in range(count))
    faces=[]
    for j in range(len(rings)-1):
        for a in range(count):
            n=(a+1)%count
            faces.append((j*count+a,j*count+n,(j+1)*count+n,(j+1)*count+a))
    faces.extend([tuple(reversed(range(count))),tuple((len(rings)-1)*count+a for a in range(count))])
    mesh=bpy.data.meshes.new(name+'_Topology'); mesh.from_pydata(verts,[],faces); mesh.update()
    o=bpy.data.objects.new(name,mesh); coll.objects.link(o); o.data.materials.append(material)
    for p in mesh.polygons: p.use_smooth=True
    return o

def union(name, objects, voxel=.019):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects: o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.join(); o=objects[0]; o.name=name
    rem=o.modifiers.new('Connected_Surface','REMESH'); rem.mode='VOXEL'; rem.voxel_size=voxel; rem.use_smooth_shade=True
    bpy.ops.object.modifier_apply(modifier=rem.name)
    sm=o.modifiers.new('Relax_Topology','SMOOTH'); sm.factor=.75; sm.iterations=5
    bpy.ops.object.modifier_apply(modifier=sm.name)
    return o

# Six heads tall: floor=0, crown=1.8, head approximately .30m.
torso=loft('Torso',[(0,0,z,rx,ry) for z,rx,ry in [(0.91,.18,.105),(1.0,.185,.12),(1.16,.19,.115),(1.32,.24,.125),(1.40,.215,.11),(1.44,.115,.08)]],shirt)
sleeves=[]
arms=[]
for sign,side in [(-1,'L'),(1,'R')]:
    sleeves.append(loft('Sleeve_'+side,[(sign*x,0,z,rx,ry) for x,z,rx,ry in [(.23,1.37,.107,.095),(.28,1.30,.101,.091),(.31,1.23,.093,.085),(.32,1.20,.088,.081)]],shirt))
    arm=loft('ArmSkin_'+side,[(sign*x,y,z,rx,ry) for x,y,z,rx,ry in [(.27,0,1.34,.079,.077),(.31,0,1.25,.074,.074),(.34,-.018,1.16,.067,.067),(.355,-.025,1.12,.063,.063),(.36,-.03,1.08,.061,.061),(.375,-.035,.99,.056,.055),(.39,-.04,.91,.048,.049),(.395,-.04,.88,.048,.051)]],skin)
    hand=sphere('Palm_'+side,(sign*.395,-.041,.844),(.060,.052,.085),skin)
    thumb=sphere('Thumb_'+side,(sign*.351,-.063,.849),(.030,.035,.050),skin)
    arms.append(union('Peter_Continuous_Arm_Hand_'+side,[arm,hand,thumb],.012))
torso=union('Peter_Continuous_Shirt_Shoulders', [torso]+sleeves,.014)
pelvis=sphere('PelvisCloth',(0,0,.93),(.19,.115,.155),navy)
leg_parts=[pelvis]
for sign,side in [(-1,'L'),(1,'R')]:
    leg_parts.append(loft('TrouserLeg_'+side,[(sign*.115,y,z,rx,ry) for y,z,rx,ry in [(0,.94,.105,.105),(-.012,.83,.095,.095),(-.035,.66,.081,.083),(-.045,.57,.075,.076),(-.044,.53,.074,.074),(-.031,.48,.072,.072),(0,.32,.066,.067),(.005,.18,.061,.060)]],navy))
pants=union('Peter_Continuous_Trousers_Hips_Knees',leg_parts,.013)
neck=loft('Peter_Neck',[(0,0,1.38,.073,.065),(0,0,1.49,.069,.062)],skin)
head=sphere('Peter_Head',(0,-.004,1.606),(.128,.112,.157),skin,32,24)
details=[(neck,'neck'),(head,'head')]
for sign,side in [(-1,'L'),(1,'R')]:
    details.append((sphere('Peter_Ear_'+side,(sign*.126,.0,1.61),(.025,.023,.043),skin),'head'))
    details.append((sphere('Peter_EyeWhite_'+side,(sign*.047,-.104,1.63),(.030,.012,.018),white),'head'))
    details.append((sphere('Peter_Iris_'+side,(sign*.047,-.115,1.629),(.012,.004,.012),eye),'head'))
    brow=sphere('Peter_Brow_'+side,(sign*.047,-.108,1.661),(.033,.009,.008),hair)
    brow.rotation_euler.y=sign*.10; details.append((brow,'head'))
details.append((sphere('Peter_Nose',(0,-.117,1.602),(.025,.032,.026),skin),'head'))
details.append((sphere('Peter_Smile',(0,-.104,1.555),(.038,.008,.005),lip),'head'))
# A connected, scalloped hair cap, with a quiet asymmetric swept crest.
cap=sphere('HairCap',(0,.009,1.701),(.133,.113,.090),hair)
tufts=[cap]
for i,(x,y,z,sx,sy,sz) in enumerate([(-.075,-.035,1.745,.063,.071,.060),(-.01,-.036,1.764,.065,.074,.059),(.056,-.027,1.759,.054,.066,.051),(.091,.021,1.719,.044,.072,.051),(0,.078,1.698,.11,.047,.046)]):
    tufts.append(sphere('HairCrest'+str(i),(x,y,z),(sx,sy,sz),hair))
details.append((union('Peter_Original_Hair_Silhouette',tufts,.009),'head'))

# Back panel conforms to the shirt, and shares chest weights.
panel=loft('Peter_Teal_Upper_Back',[(0,.119,1.255,.163,.009),(0,.126,1.28,.171,.009),(0,.128,1.335,.183,.009),(0,.116,1.36,.169,.009)],teal)
details.append((panel,'chest'))
for sign,side in [(-1,'L'),(1,'R')]:
    cuff=loft('Peter_Trouser_Cuff_'+side,[(sign*.115,.005,.175,.063,.062),(sign*.115,.005,.209,.065,.062)],teal)
    details.append((cuff,'shin.'+side))
    shoe=sphere('Peter_Walking_Shoe_'+side,(sign*.115,-.065,.091),(.091,.17,.084),cream)
    bottom=sphere('Peter_Rubber_Sole_'+side,(sign*.115,-.065,.039),(.093,.172,.033),sole)
    heel=sphere('Peter_Heel_Tab_'+side,(sign*.115,.077,.104),(.049,.012,.035),teal)
    for o in (shoe,bottom,heel): details.append((o,'foot.'+side))
    for lace in range(3):
        o=sphere('Peter_Lace_'+side+str(lace),(sign*.115,-.060-lace*.028,.159-lace*.005),(.061,.009,.009),cream)
        details.append((o,'foot.'+side))

# Editable skeleton. Local control axes are resolved from rest matrices below.
data=bpy.data.armatures.new('Peter_Deform_Skeleton')
rig=bpy.data.objects.new('Peter_Rig',data); coll.objects.link(rig)
bpy.context.view_layer.objects.active=rig; rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
def bone(name,head,tail,parent=None,deform=True):
    b=data.edit_bones.new(name); b.head=head; b.tail=tail; b.use_deform=deform
    if parent: b.parent=data.edit_bones[parent]
    return b
bone('root',(0,0,0),(0,0,.15),deform=False)
bone('pelvis',(0,0,.91),(0,0,1.06),'root')
bone('spine',(0,0,1.06),(0,0,1.23),'pelvis')
bone('chest',(0,0,1.23),(0,0,1.40),'spine')
bone('neck',(0,0,1.40),(0,0,1.48),'chest')
bone('head',(0,0,1.48),(0,0,1.78),'neck')
for sign,side in [(-1,'L'),(1,'R')]:
    bone('upper_arm.'+side,(sign*.23,0,1.35),(sign*.355,-.025,1.12),'chest')
    bone('forearm.'+side,(sign*.355,-.025,1.12),(sign*.395,-.04,.895),'upper_arm.'+side)
    bone('hand.'+side,(sign*.395,-.04,.895),(sign*.395,-.04,.79),'forearm.'+side)
    bone('thigh.'+side,(sign*.115,0,.94),(sign*.115,-.045,.535),'pelvis')
    bone('shin.'+side,(sign*.115,-.045,.535),(sign*.115,0,.14),'thigh.'+side)
    bone('foot.'+side,(sign*.115,0,.14),(sign*.115,-.18,.09),'shin.'+side)
    bone('foot_ctrl.'+side,(sign*.115,0,.14),(sign*.115,0,.29),'root',False)
    bone('knee_pole.'+side,(sign*.115,-1,.535),(sign*.115,-1,.70),'root',False)
bpy.ops.object.mode_set(mode='OBJECT')
rig.show_in_front=True
for pb in rig.pose.bones: pb.rotation_mode='XYZ'
for side in ('L','R'):
    ik=rig.pose.bones['shin.'+side].constraints.new('IK')
    ik.target=rig; ik.subtarget='foot_ctrl.'+side; ik.chain_count=2
    # Explicit pole prevents knees from choosing arbitrary bend planes.
    ik.pole_target=rig; ik.pole_subtarget='knee_pole.'+side; ik.pole_angle=-math.pi/2
    ik.use_stretch=False
    foot=rig.pose.bones['foot.'+side]
    # World-space fixed foot rotation prevents soles tilting during IK solves.
    c=foot.constraints.new('LIMIT_ROTATION'); c.use_limit_x=c.use_limit_y=c.use_limit_z=True
    e=data.bones['foot.'+side].matrix_local.to_euler()
    c.min_x=c.max_x=e.x; c.min_y=c.max_y=e.y; c.min_z=c.max_z=e.z
    c.owner_space='WORLD'

def blend(a,b,t): return {a:1-t,b:t}
def clamp(x): return max(0,min(1,x))
def skin_mesh(o,weight_fn):
    groups={b.name:o.vertex_groups.new(name=b.name) for b in data.bones if b.use_deform}
    for v in o.data.vertices:
        pos=o.matrix_world@v.co
        for name,w in weight_fn(pos).items():
            if w>0: groups[name].add([v.index],w,'REPLACE')
    mod=o.modifiers.new('Peter_Skeletal_Deformation','ARMATURE'); mod.object=rig; mod.use_deform_preserve_volume=True
    sub=o.modifiers.new('Peter_Surface_Finish','SUBSURF'); sub.levels=1; sub.render_levels=1
    o.parent=rig

def torso_weights(p):
    side='L' if p.x<0 else 'R'
    arm_mix=clamp((abs(p.x)-.175)/.105)*clamp((p.z-1.14)/.1)
    spine=clamp((p.z-1.05)/.23)
    return {'spine':(1-arm_mix)*(1-spine),'chest':(1-arm_mix)*spine,'upper_arm.'+side:arm_mix}
skin_mesh(torso,torso_weights)
def pants_weights(p):
    side='L' if p.x<0 else 'R'
    if p.z>.81: return blend('thigh.'+side,'pelvis',clamp((p.z-.81)/.15))
    return blend('shin.'+side,'thigh.'+side,clamp((p.z-.475)/.15))
skin_mesh(pants,pants_weights)
for o,side in zip(arms,('L','R')):
    def weights(p,side=side):
        if p.z<.95: return blend('hand.'+side,'forearm.'+side,clamp((p.z-.86)/.09))
        return blend('forearm.'+side,'upper_arm.'+side,clamp((p.z-1.065)/.12))
    skin_mesh(o,weights)
for o,b in details: skin_mesh(o,lambda p,b=b:{b:1.0})

def shift(b,offset):
    rig.pose.bones[b].location=data.bones[b].matrix_local.to_3x3().inverted()@Vector(offset)
def rotate(b,x=0,y=0,z=0): rig.pose.bones[b].rotation_euler=(x,y,z)
def smooth(x): x=clamp(x); return x*x*(3-2*x)

def pose(clip,t):
    for pb in rig.pose.bones:
        pb.location=(0,0,0); pb.rotation_euler=(0,0,0); pb.scale=(1,1,1)
    # A slight knee bend at rest keeps the IK solution away from singularity.
    shift('pelvis',(0,0,-.015))
    if clip in ('idle_ready','rest','paused'):
        phase=t*math.tau
        rotate('chest',.006*math.sin(phase))
        rig.pose.bones['chest'].scale=(1+.008*math.sin(phase),1+.005*math.sin(phase),1)
        rotate('upper_arm.L',-.03,0,-.025); rotate('upper_arm.R',-.03,0,.025)
    elif clip=='walk_forward':
        for side,p in [('L',t),('R',(t+.5)%1)]:
            p=p%1
            if p<.60:
                fy=-.16+.32*(p/.60); lift=0
            else:
                q=(p-.60)/.40; fy=.16-.32*smooth(q); lift=.095*math.sin(math.pi*q)
            shift('foot_ctrl.'+side,(0,fy,lift))
            rotate('upper_arm.'+side,.34*math.cos(math.tau*p),0,0)
            rotate('forearm.'+side,-.14-.08*math.sin(math.tau*p))
        shift('pelvis',(.012*math.sin(math.tau*t),0,-.034+.009*math.cos(4*math.pi*t)))
        rotate('chest',.028,0,.045*math.sin(math.tau*t))
        rotate('pelvis',0,0,-.035*math.sin(math.tau*t))
    elif clip in ('move_left','move_right'):
        direction=-1 if clip=='move_left' else 1
        envelope=math.sin(math.pi*t)**2
        rotate('chest',0,-direction*.09*envelope,0)
        shift('pelvis',(direction*.035*envelope,0,-.025-.025*envelope))
        lead='L' if direction<0 else 'R'; trail='R' if direction<0 else 'L'
        shift('foot_ctrl.'+lead,(direction*.07*envelope,0,.052*math.sin(math.pi*clamp(t/.65))))
        shift('foot_ctrl.'+trail,(-direction*.03*envelope,0,.035*math.sin(math.pi*clamp((t-.3)/.7))))
        rotate('upper_arm.L',0,0,-.08*envelope); rotate('upper_arm.R',0,0,.08*envelope)
    elif clip=='jump_low':
        if t<.16:
            bend=.065*smooth(t/.16); height=0
        elif t<.73:
            q=(t-.16)/.57; height=.23*math.sin(math.pi*q); bend=.065*(1-smooth(q/.24))
        else:
            height=0; bend=.075*math.sin(math.pi*(t-.73)/.27)**2
        shift('root',(0,0,height))
        shift('pelvis',(0,.025*bend/.075,-.015-bend))
        envelope=math.sin(math.pi*t)**2
        rotate('chest',.12*envelope)
        for side,sign in [('L',-1),('R',1)]:
            shift('foot_ctrl.'+side,(sign*.013*envelope,.025*envelope,.02*envelope if height>0 else 0))
            rotate('upper_arm.'+side,-.35*envelope,0,sign*.08*envelope)
            rotate('forearm.'+side,-.22*envelope)
    elif clip=='slide_duck':
        amount=smooth(t/.32) if t<.32 else (1 if t<.58 else 1-smooth((t-.58)/.42))
        shift('pelvis',(0,.075*amount,-.015-.38*amount))
        rotate('spine',.19*amount); rotate('chest',.23*amount); rotate('head',-.16*amount)
        shift('foot_ctrl.L',(-.028*amount,-.03*amount,0))
        shift('foot_ctrl.R',(.028*amount,.04*amount,0))
        rotate('upper_arm.L',-.6*amount); rotate('upper_arm.R',-.6*amount)
        rotate('forearm.L',-.6*amount); rotate('forearm.R',-.6*amount)
    else:
        envelope=math.sin(math.pi*t)**2
        rotate('head',(.08 if clip=='success_settle' else .025)*envelope)
        rotate('chest',-.02*envelope)

rig['asset_origin']='original procedural mesh and skeletal animation'
rig['pose_design']='IK foot controls; connected weighted shoulders, elbows, hips and knees'
for clip,(duration,loop) in CLIPS.items():
    action=bpy.data.actions.new('Peter_'+clip); action.use_fake_user=True
    rig.animation_data_create(); rig.animation_data.action=action
    count=max(2,math.ceil(duration*30)+1)
    for i in range(count):
        t=i/(count-1)
        pose(clip,t)
        frame=1+t*duration*30
        for pb in rig.pose.bones:
            pb.keyframe_insert(data_path='location',frame=frame,group=pb.name)
            pb.keyframe_insert(data_path='rotation_euler',frame=frame,group=pb.name)
            pb.keyframe_insert(data_path='scale',frame=frame,group=pb.name)
    action['duration_seconds']=duration; action['loop']=loop
    for layer in action.layers:
        for strip in layer.strips:
            for slot in action.slots:
                bag=strip.channelbag(slot)
                if bag:
                    for fc in bag.fcurves:
                        for key in fc.keyframe_points:
                            key.interpolation='BEZIER'; key.handle_left_type='AUTO_CLAMPED'; key.handle_right_type='AUTO_CLAMPED'
rig.animation_data.action=bpy.data.actions['Peter_idle_ready']
scene.frame_set(1); scene.frame_end=61

def aim(o,point): o.rotation_euler=(Vector(point)-o.location).to_track_quat('-Z','Y').to_euler()
camdata=bpy.data.cameras.new('Peter_Gameplay_Locked'); cam=bpy.data.objects.new('Peter_Gameplay_Locked',camdata); scene.collection.objects.link(cam)
cam.location=(.18,6,2.75); aim(cam,(0,0,.92)); camdata.type='ORTHO'; camdata.ortho_scale=2.55; scene.camera=cam
bpy.context.view_layer.update()
ground=world_to_camera_view(scene,cam,Vector((0,0,0)))
camdata.shift_x=ground.x-.5; camdata.shift_y=ground.y-(1-432/512)
for name,location,power,color,size in [('Warm_Key',(-3,4,5),420,(1,.83,.67),4),('Cool_Fill',(3,-2,3),240,(.64,.81,1),3),('Soft_Rim',(-2,-3,4),290,(1,.90,.73),3)]:
    ld=bpy.data.lights.new(name,'AREA'); lo=bpy.data.objects.new(name,ld); scene.collection.objects.link(lo); lo.location=location
    ld.energy=power; ld.color=color; ld.shape='DISK'; ld.size=size; aim(lo,(0,0,1))
scene['export_canvas']=[512,512]; scene['ground_pivot']=[256,432]; scene['runtime_displacement']='Jump lift baked once; lane translation belongs to Godot'
for a in bpy.context.screen.areas if bpy.context.screen else []:
    if a.type=='VIEW_3D': a.spaces.active.region_3d.view_perspective='CAMERA'
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
print('PETER_ORIGINAL_BUILD_PASS',SOURCE,'bones',len(data.bones),'actions',len(CLIPS))
