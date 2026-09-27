"""Align non-airborne Runner V2 sprite exports to their declared 512px foot pivot."""

from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent
ASSET_ROOT = ROOT.parent / "code" / "art" / "characters" / "runner_v2"
GROUND_PIVOT_Y = 416
AIRBORNE_ANIMATION = "jump_low"


def shift_canvas(image: Image.Image, offset_y: int) -> Image.Image:
    if offset_y == 0:
        return image
    aligned = Image.new("RGBA", image.size, (0, 0, 0, 0))
    aligned.alpha_composite(image, (0, offset_y))
    return aligned


def align(path: Path) -> None:
    with Image.open(path) as source:
        image = source.convert("RGBA")
    bounds = image.getchannel("A").getbbox()
    if bounds is None:
        raise RuntimeError(f"Empty character frame: {path}")
    offset_y = GROUND_PIVOT_Y - bounds[3]
    aligned = shift_canvas(image, offset_y)
    aligned.save(path)


def main() -> None:
    aligned_count = 0
    for animation_dir in sorted(path for path in ASSET_ROOT.iterdir() if path.is_dir()):
        if animation_dir.name in {"sheets", "shadow", AIRBORNE_ANIMATION}:
            continue
        for frame in sorted(animation_dir.glob("runner_v2_*.png")):
            align(frame)
            aligned_count += 1
    print("RUNNER_V2_BASELINE_ALIGNMENT_PASS", aligned_count, "grounded frames")


if __name__ == "__main__":
    main()
