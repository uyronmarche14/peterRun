"""Compose Runner V2 individual RGBA frames into sprite sheets and a contact sheet."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parent
ASSET_ROOT = ROOT.parent / "code" / "art" / "characters" / "runner_v2"
FRAME_SIZE = 512
ANIMATIONS = {
    "idle_ready": 8,
    "walk_forward": 10,
    "move_left": 8,
    "move_right": 8,
    "jump_low": 10,
    "slide_duck": 10,
    "success_settle": 8,
    "neutral_clear": 6,
    "rest": 6,
}


def read_frame(path: Path) -> Image.Image:
    with Image.open(path) as source:
        image = source.convert("RGBA")
    if image.size != (FRAME_SIZE, FRAME_SIZE):
        raise RuntimeError(f"Unexpected frame dimensions: {path}")
    return image


def main() -> None:
    sheet_root = ASSET_ROOT / "sheets"
    sheet_root.mkdir(parents=True, exist_ok=True)
    rows: list[tuple[str, list[Image.Image]]] = []

    for animation, count in ANIMATIONS.items():
        frames = [read_frame(ASSET_ROOT / animation / f"runner_v2_{animation}_{index:02d}.png") for index in range(count)]
        sheet = Image.new("RGBA", (FRAME_SIZE * count, FRAME_SIZE), (0, 0, 0, 0))
        for index, frame in enumerate(frames):
            sheet.alpha_composite(frame, (FRAME_SIZE * index, 0))
        sheet.save(sheet_root / f"runner_v2_{animation}_sheet.png")
        rows.append((animation, frames))

    rows.append(("paused", [read_frame(ASSET_ROOT / "paused" / "runner_v2_paused_00.png")]))
    cell = 128
    label_h = 26
    max_frames = max(len(frames) for _name, frames in rows)
    contact = Image.new("RGBA", (max_frames * cell, len(rows) * (cell + label_h)), (0, 0, 0, 0))
    draw = ImageDraw.Draw(contact)
    for row_index, (animation, frames) in enumerate(rows):
        y = row_index * (cell + label_h)
        draw.text((4, y + 3), animation.upper(), fill=(18, 42, 45, 255))
        for frame_index, frame in enumerate(frames):
            thumb = frame.resize((cell, cell), Image.Resampling.LANCZOS)
            contact.alpha_composite(thumb, (frame_index * cell, y + label_h))
    contact.save(ASSET_ROOT / "runner_v2_contact_sheet.png")
    print("RUNNER_V2_SPRITE_SHEETS_PASS", len(rows), "rows")


if __name__ == "__main__":
    main()
