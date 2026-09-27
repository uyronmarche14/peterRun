"""Validate PR V04 collections, aligned PNGs, lanes, and landmark dominance."""

import os

import bpy


ROOT=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(ROOT,"generated","l01_v04_fresh")
W,H=960,540
EXPECTED_COLLECTIONS=(
    "PR_V04_Sky","PR_V04_Sun","PR_V04_Clouds","PR_V04_Mountains",
    "PR_V04_Tall_Barangay_Hall","PR_V04_Market","PR_V04_Houses_Left",
    "PR_V04_Houses_Right","PR_V04_SariSari","PR_V04_Waiting_Shed",
    "PR_V04_Roadside_Plants","PR_V04_Street_Details","PR_V04_Road",
    "PR_V04_Lane_Overlay","PR_V04_Foreground","PR_V04_Lighting",
    "PR_V04_Render_Cameras","PR_V04_PlantsAndForeground",
    "PR_V04_Landmark_Barangay_Entry","L01_SariSariStore",
    "PR_V04_Landmark_Waiting_Shed","PR_V04_Landmark_Garden_Plaza",
    "PR_House_Concrete","PR_House_Sawali",
    "PR_House_CoralRoof","PR_House_Residence",
)
FILES=(
    "l01_v04_sky.png","l01_v04_sun.png","l01_v04_clouds.png",
    "l01_v04_mountains.png","l01_v04_barangay_hall.png","l01_v04_market.png",
    "l01_v04_houses_far.png","l01_v04_houses_mid.png","l01_v04_roadside.png",
    "l01_v04_road.png","l01_v04_lane_overlay.png","l01_v04_foreground.png",
    "l01_v04_plants_foreground.png","l01_v04_plant_sway_overlay.png",
    "l01_v04_light_overlay.png",
    "l01_landmark_barangay_entry_v01.png",
    "l01_landmark_sari_sari_v01.png",
    "l01_landmark_waiting_shed_v01.png",
    "l01_landmark_garden_or_plaza_v01.png",
)

LANDMARK_EXPORTS={
    "barangay_entry":"l01_landmark_barangay_entry_v01",
    "sari_sari":"l01_landmark_sari_sari_v01",
    "waiting_shed":"l01_landmark_waiting_shed_v01",
    "garden_or_plaza":"l01_landmark_garden_or_plaza_v01",
}
LANDMARK_COLLECTIONS={
    "barangay_entry":"PR_V04_Landmark_Barangay_Entry",
    "sari_sari":"L01_SariSariStore",
    "waiting_shed":"PR_V04_Landmark_Waiting_Shed",
    "garden_or_plaza":"PR_V04_Landmark_Garden_Plaza",
}
HOUSE_COLLECTIONS={
    "concrete":"PR_House_Concrete",
    "sawali":"PR_House_Sawali",
    "coralroof":"PR_House_CoralRoof",
    "residence":"PR_House_Residence",
}
HOUSE_COMPONENTS={"roof","facade","windows","veranda_fence","plants","shadows"}


def alpha_bbox(image):
    w,h=image.size
    pixels=list(image.pixels)
    xs=[]; ys=[]
    for y in range(h):
        for x in range(w):
            if pixels[(y*w+x)*4+3]>.08:
                xs.append(x); ys.append(h-1-y)
    return (min(xs),min(ys),max(xs),max(ys)) if xs else None


def alpha(image,x,y):
    w,h=image.size
    return image.pixels[((h-1-y)*w+x)*4+3]


for name in EXPECTED_COLLECTIONS:
    assert name in bpy.data.collections,name
assert "PETER_RUN_L01_HOUSE_ASSET_LIBRARY" in bpy.data.scenes
master_root=bpy.data.collections["PETER_RUN_L01_V04_FRESH"]
asset_scene=bpy.data.scenes["PETER_RUN_L01_HOUSE_ASSET_LIBRARY"]
for collection_name in HOUSE_COLLECTIONS.values():
    assert bpy.data.collections[collection_name].name not in {child.name for child in master_root.children},collection_name
    assert bpy.data.collections[collection_name].name in {child.name for child in asset_scene.collection.children},collection_name
for filename in FILES:
    path=os.path.join(OUT,filename)
    assert os.path.exists(path),path
    image=bpy.data.images.load(path,check_existing=False)
    assert tuple(image.size)==(960,540),(filename,tuple(image.size))
    assert image.channels==4,filename
    bpy.data.images.remove(image)

for landmark,stem in LANDMARK_EXPORTS.items():
    collection=bpy.data.collections[LANDMARK_COLLECTIONS[landmark]]
    objects=list(collection.all_objects)
    assert objects,(landmark,"landmark collection must not be empty")
    assert {obj.get("parallax_depth") for obj in objects}=={"far","mid","near"},landmark
    assert {obj.get("route_phase") for obj in objects}=={landmark},landmark
    for depth in ("far","mid","near"):
        filename=f"{stem}_{depth}.png"
        path=os.path.join(OUT,filename)
        assert os.path.exists(path),path
        image=bpy.data.images.load(path,check_existing=False)
        assert tuple(image.size)==(W,H),(filename,tuple(image.size))
        assert image.channels==4,filename
        assert alpha_bbox(image),(filename,"parallax layer must not be empty")
        assert alpha(image,480,430)<.05,(filename,"must keep lower central route clear")
        bpy.data.images.remove(image)

for obj in bpy.data.collections["L01_SariSariStore"].all_objects:
    if obj.type=="FONT":
        assert obj.data.body=="SARI-SARI",(obj.name,obj.data.body)
assert any(obj.type=="FONT" for obj in bpy.data.collections["L01_SariSariStore"].all_objects)
for collection_name in LANDMARK_COLLECTIONS.values():
    for obj in bpy.data.collections[collection_name].all_objects:
        if obj.type=="FONT":
            assert obj.data.body not in {"SCORE","STREAK","RANK","COUNTDOWN","TROPHY"},obj.name

for house_id,collection_name in HOUSE_COLLECTIONS.items():
    objects=list(bpy.data.collections[collection_name].all_objects)
    assert objects,(house_id,"house collection must not be empty")
    assert {obj.get("house_facing") for obj in objects}=={"left","right"},house_id
    assert {obj.get("house_component") for obj in objects}==HOUSE_COMPONENTS,house_id
    assert not any(obj.type=="FONT" for obj in objects),(house_id,"houses must not use tiny signs")
    for facing in ("left","right"):
        variant_heights=[]
        for depth in ("far","mid","near"):
            filename=f"l01_house_{house_id}_{facing}_{depth}_v01.png"
            path=os.path.join(OUT,filename)
            assert os.path.exists(path),path
            image=bpy.data.images.load(path,check_existing=False)
            assert tuple(image.size)==(W,H),(filename,tuple(image.size))
            assert image.channels==4,filename
            bounds=alpha_bbox(image)
            assert bounds,(filename,"house variant must not be empty")
            variant_heights.append(bounds[3]-bounds[1]+1)
            assert 8<bounds[0] and bounds[2]<W-8 and 8<bounds[1] and bounds[3]<H-8,(filename,"house must not clip")
            assert alpha(image,0,0)<.05 and alpha(image,W-1,H-1)<.05,(filename,"transparent background required")
            bpy.data.images.remove(image)
        assert variant_heights[0]<variant_heights[1]<variant_heights[2],(house_id,facing,variant_heights)
    for component in sorted(HOUSE_COMPONENTS):
        filename=f"l01_house_{house_id}_{component}_v01.png"
        path=os.path.join(OUT,filename)
        assert os.path.exists(path),path
        image=bpy.data.images.load(path,check_existing=False)
        assert tuple(image.size)==(W,H),(filename,tuple(image.size))
        assert image.channels==4,filename
        assert alpha_bbox(image),(filename,"component layer must not be empty")
        assert alpha(image,0,0)<.05 and alpha(image,W-1,H-1)<.05,(filename,"transparent background required")
        bpy.data.images.remove(image)

hall=bpy.data.images.load(os.path.join(OUT,"l01_v04_barangay_hall.png"),check_existing=False)
hall_box=alpha_bbox(hall)
assert hall_box is not None
hall_height=hall_box[3]-hall_box[1]+1
assert .30*H<=hall_height<=.38*H,("hall height fraction",hall_height/H,hall_box)
assert .12*H<=hall_box[1]<=.18*H,("tower top",hall_box)
assert alpha(hall,480,510)<.05,"hall must not enter lower safe zone"
bpy.data.images.remove(hall)

market=bpy.data.images.load(os.path.join(OUT,"l01_v04_market.png"),check_existing=False)
market_box=alpha_bbox(market)
assert market_box and (market_box[3]-market_box[1])>.18*H,"market must have substantial two-storey height"
assert (market_box[3]-market_box[1])<hall_height,"market must remain lower than hall"
bpy.data.images.remove(market)

road=bpy.data.images.load(os.path.join(OUT,"l01_v04_road.png"),check_existing=False)
assert alpha(road,480,510)>.8 and alpha(road,30,510)<.05
bpy.data.images.remove(road)
lane=bpy.data.images.load(os.path.join(OUT,"l01_v04_lane_overlay.png"),check_existing=False)
assert alpha(lane,480,510)<.05
visible=[x for x in range(960) if alpha(lane,x,510)>.35]
assert len(visible)>8,"two separators and curb edges must render"
bpy.data.images.remove(lane)
clouds=bpy.data.images.load(os.path.join(OUT,"l01_v04_clouds.png"),check_existing=False)
assert alpha_bbox(clouds),"cloud export must not be empty"
bpy.data.images.remove(clouds)
sun=bpy.data.images.load(os.path.join(OUT,"l01_v04_sun.png"),check_existing=False)
assert alpha_bbox(sun),"sun export must not be empty"
bpy.data.images.remove(sun)

plants=bpy.data.images.load(os.path.join(OUT,"l01_v04_plants_foreground.png"),check_existing=False)
assert alpha_bbox(plants),"plants/foreground export must not be empty"
assert alpha(plants,480,430)<.05,"static plants must keep the centre prompt corridor clear"
bpy.data.images.remove(plants)
sway=bpy.data.images.load(os.path.join(OUT,"l01_v04_plant_sway_overlay.png"),check_existing=False)
assert alpha_bbox(sway),"plant sway overlay must not be empty"
assert alpha(sway,480,430)<.05,"sway overlay must stay outside the centre road"
bpy.data.images.remove(sway)
print("PETER_RUN_L01_V04_VALIDATION_PASS",hall_box,hall_height)
