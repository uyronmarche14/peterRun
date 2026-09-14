"""Headless Blender contract for the Peter Run source-character generator."""

from pathlib import Path
import runpy
import sys

import bpy
from bpy_extras.anim_utils import animdata_get_channelbag_for_assigned_slot


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ADDON_PATH = PROJECT_ROOT / "addon" / "peter_run_blender_bridge.py"


def expect(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def main() -> None:
    bridge = runpy.run_path(str(ADDON_PATH), run_name="peter_run_bridge_test")
    result = bridge["create_character"]()
    collection = bpy.data.collections.get("PETER_RUN_GENERATED")
    expect(collection is not None, "Peter source collection is created")
    meshes = [item for item in collection.objects if item.type == "MESH"]
    expect(len(meshes) >= 24, "Peter uses detailed layered mesh parts, not a minimal block figure")
    expect(bpy.data.objects.get("Peter_Root") is not None, "Peter has a single animation root")
    expect(bpy.data.objects.get("Peter_GroundAnchor") is not None, "Peter has a stable ground anchor")
    expect(bpy.data.objects.get("Peter_ArmPivot_L") is not None, "Left arm rotates from the shoulder")
    expect(bpy.data.objects.get("Peter_ArmPivot_R") is not None, "Right arm rotates from the shoulder")
    expect(bpy.data.objects.get("Peter_LegPivot_L") is not None, "Left leg rotates from the hip")
    expect(bpy.data.objects.get("Peter_LegPivot_R") is not None, "Right leg rotates from the hip")
    expect(bpy.data.objects.get("Peter_ElbowPivot_L") is not None, "Left arm has an elbow joint")
    expect(bpy.data.objects.get("Peter_ElbowPivot_R") is not None, "Right arm has an elbow joint")
    expect(bpy.data.objects.get("Peter_KneePivot_L") is not None, "Left leg has a knee joint")
    expect(bpy.data.objects.get("Peter_KneePivot_R") is not None, "Right leg has a knee joint")
    expect(bpy.data.objects.get("Peter_AnklePivot_L") is not None, "Left leg has an ankle joint")
    expect(bpy.data.objects.get("Peter_AnklePivot_R") is not None, "Right leg has an ankle joint")
    expect(bpy.data.objects["Peter_Forearm_L"].parent == bpy.data.objects["Peter_ElbowPivot_L"], "Forearm follows its elbow, not the shoulder as one rigid limb")
    expect(bpy.data.objects["Peter_Shin_L"].parent == bpy.data.objects["Peter_KneePivot_L"], "Shin follows its knee, not the hip as one rigid leg")
    expect(abs(bpy.data.objects["Peter_UpperArm_L"].matrix_world.translation.z - 2.24) < 0.02, "Upper arm keeps its shoulder-relative rest position")
    expect(abs(bpy.data.objects["Peter_Forearm_L"].matrix_world.translation.z - 1.76) < 0.02, "Forearm keeps its elbow-relative rest position")
    expect(abs(bpy.data.objects["Peter_Shin_L"].matrix_world.translation.z - 0.52) < 0.02, "Shin keeps its knee-relative rest position")
    expect(bpy.data.objects.get("PeterSpriteCamera").data.type == "ORTHO", "Sprite camera stays orthographic")
    expect(result["size"] == [192, 256], "Source render size is stable")
    expect(bpy.context.scene.render.film_transparent, "Sprite frames render with transparency")
    expect(bpy.data.materials.get("PeterShirtHighlight") is not None, "Outfit includes a readable highlight")
    expect(bpy.data.materials.get("PeterSkinHighlight") is not None, "Skin shading has a warm highlight")
    expect(bpy.data.materials.get("PeterEyeWhite") is not None, "Face details use a dedicated eye material")
    expect(bpy.data.objects.get("Peter_Eye_L") is not None and bpy.data.objects.get("Peter_Eye_R") is not None, "Eyes are deliberate face features, separate from hair")
    expect(bpy.data.objects.get("Peter_HairTuft") is not None, "Hair uses a single readable silhouette tuft")
    expect(bpy.data.objects.get("Peter_HairCurl_L") is None, "Loose rear hair curls that read as eyes are removed")
    motion = bridge["pose"]("run")
    expect(motion == {"animation": "run", "frames": 12, "fps": 24}, "Run motion uses a full contact-to-contact cycle")
    channelbag = animdata_get_channelbag_for_assigned_slot(bpy.data.objects["Peter_Root"].animation_data)
    expect(channelbag is not None, "Run motion creates layered Blender 5.2 animation data")
    expect(all(point.interpolation == "BEZIER" for curve in channelbag.fcurves for point in curve.keyframe_points), "Run motion uses smooth Bezier interpolation")
    leg_channelbag = animdata_get_channelbag_for_assigned_slot(bpy.data.objects["Peter_LegPivot_L"].animation_data)
    expect(leg_channelbag is not None and len(leg_channelbag.fcurves) > 0, "Run motion animates the leg from its hip pivot")
    stride_curves = [curve for curve in leg_channelbag.fcurves if curve.data_path == "rotation_euler" and curve.array_index == 0]
    expect(any(max(abs(point.co.y) for point in curve.keyframe_points) > 0.1 for curve in stride_curves), "Run motion includes a visible lift-and-extend stride")
    knee_channelbag = animdata_get_channelbag_for_assigned_slot(bpy.data.objects["Peter_KneePivot_L"].animation_data)
    expect(knee_channelbag is not None and len(knee_channelbag.fcurves) > 0, "Run motion bends the knee")
    ankle_channelbag = animdata_get_channelbag_for_assigned_slot(bpy.data.objects["Peter_AnklePivot_L"].animation_data)
    expect(ankle_channelbag is not None and any(curve.data_path == "location" for curve in ankle_channelbag.fcurves), "Run motion visibly lifts the foot off the ground")
    scene = bpy.context.scene
    scene.frame_set(4)
    left_ankle = bpy.data.objects["Peter_AnklePivot_L"]
    left_lift = left_ankle.location.z - left_ankle["peter_rest_location"][2]
    scene.frame_set(10)
    right_ankle = bpy.data.objects["Peter_AnklePivot_R"]
    right_lift = right_ankle.location.z - right_ankle["peter_rest_location"][2]
    expect(left_lift > 0.12 and right_lift > 0.12, "Opposite feet lift on the passing poses")
    print("PETER RUN detailed Peter source test: PASS")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as error:
        print("PETER RUN detailed Peter source test: FAIL - " + str(error), file=sys.stderr)
        raise SystemExit(1)
