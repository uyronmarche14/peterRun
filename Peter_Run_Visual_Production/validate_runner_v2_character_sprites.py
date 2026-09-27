"""Validate the original Runner V2 transparent sprite animation package."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
ASSET_ROOT = ROOT.parent / "code" / "art" / "characters" / "runner_v2"
SOURCE_BLEND = ROOT / "RunnerV2_Character_Source_v01.blend"
FRAME_SIZE = (512, 512)
ANIMATIONS = {
    "idle_ready": (8, 8, True),
    "walk_forward": (10, 10, True),
    "move_left": (8, 10, False),
    "move_right": (8, 10, False),
    "jump_low": (10, 12, False),
    "slide_duck": (10, 10, False),
    "success_settle": (8, 8, False),
    "neutral_clear": (6, 8, False),
    "rest": (6, 6, True),
}


def alpha_bounds(image: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel("A")
    return alpha.getbbox()


def main() -> None:
    assert SOURCE_BLEND.is_file(), f"Missing Blender source: {SOURCE_BLEND}"
    assert ASSET_ROOT.is_dir(), f"Missing sprite export root: {ASSET_ROOT}"

    manifest = ASSET_ROOT / "animation_manifest.txt"
    assert manifest.is_file(), "Missing animation manifest"
    manifest_text = manifest.read_text(encoding="utf-8")
    metadata_path = ASSET_ROOT / "frame_metadata.json"
    assert metadata_path.is_file(), "Missing frame metadata"
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    expected_pivot = [256, 416]

    for animation, (frame_count, fps, seamless) in ANIMATIONS.items():
        assert f"{animation}: {fps} fps" in manifest_text, f"Missing timing for {animation}"
        assert f"{animation} loop: {'seamless' if seamless else 'one-shot'}" in manifest_text, f"Missing loop mode for {animation}"
        frame_dir = ASSET_ROOT / animation
        frames = sorted(frame_dir.glob(f"runner_v2_{animation}_*.png"))
        assert len(frames) == frame_count, f"{animation}: expected {frame_count} frames, got {len(frames)}"

        for index, frame_path in enumerate(frames):
            with Image.open(frame_path) as image:
                assert image.mode == "RGBA", f"{frame_path.name}: must be RGBA"
                assert image.size == FRAME_SIZE, f"{frame_path.name}: expected {FRAME_SIZE}, got {image.size}"
                assert image.getpixel((0, 0))[3] == 0, f"{frame_path.name}: top-left must be transparent"
                bounds = alpha_bounds(image)
                assert bounds is not None, f"{frame_path.name}: contains no visible character"
                assert 40 < bounds[0] < 220 and 270 < bounds[2] < 475, f"{frame_path.name}: character is not centred"
                top_padding = 16 if animation == "jump_low" else 40
                assert top_padding < bounds[1] < 180 and bounds[3] <= expected_pivot[1] + 2, f"{frame_path.name}: character exceeds its padded ground frame"
                assert metadata[frame_path.relative_to(ASSET_ROOT).as_posix()]["pivot"] == expected_pivot, f"{frame_path.name}: pivot must remain fixed between the feet"

        sheet_path = ASSET_ROOT / "sheets" / f"runner_v2_{animation}_sheet.png"
        with Image.open(sheet_path) as sheet:
            assert sheet.mode == "RGBA", f"{sheet_path.name}: must be RGBA"
            assert sheet.size == (FRAME_SIZE[0] * frame_count, FRAME_SIZE[1]), f"{sheet_path.name}: invalid dimensions"

    paused = ASSET_ROOT / "paused" / "runner_v2_paused_00.png"
    with Image.open(paused) as image:
        assert image.mode == "RGBA" and image.size == FRAME_SIZE, "Paused pose must be a 512x512 RGBA PNG"
        assert alpha_bounds(image) is not None, "Paused pose must be visible"

    shadow = ASSET_ROOT / "shadow" / "runner_v2_ground_shadow.png"
    with Image.open(shadow) as image:
        assert image.mode == "RGBA" and image.size == FRAME_SIZE, "Ground shadow must be a 512x512 RGBA PNG"
        assert alpha_bounds(image) is not None, "Ground shadow must be visible"
        assert image.getpixel((0, 0))[3] == 0, "Ground shadow must retain transparent corners"

    contact_sheet = ASSET_ROOT / "runner_v2_contact_sheet.png"
    with Image.open(contact_sheet) as image:
        assert image.mode == "RGBA", "Contact sheet must be RGBA"
        assert image.width >= 1024 and image.height >= 1024, "Contact sheet must visibly include all animation rows"

    print("RUNNER_V2_CHARACTER_SPRITES_VALIDATION_PASS", sum(frame_count for frame_count, _fps, _loop in ANIMATIONS.values()), "frames")


if __name__ == "__main__":
    main()
