"""Build the full-slide backgrounds: title.jpg, divider.jpg and end.jpg.

Each background is a 16:9 canvas (13.333 x 7.5 in, the PowerPoint widescreen
size) with the photo inset on a white frame, as in the DEN PowerPoint master:

    title.jpg     photo darkened towards the bottom, emblem and institution
                  name at the top centre; the title, its rule and the date
                  are drawn by the template so they can move with the title
    divider.jpg   photo darkened towards the left, emblem at the top left
    end.jpg       photo under a white haze, emblem and institution name at
                  the top centre; the closing text is drawn by the template

Sources:

    tools/assets/photo.jpg      the master photo, uncropped
    _extensions/den/logo.png    the emblem
    Picture1.png                the semi-transparent white haze layer

Writes the three files to the extension folder and title.jpg and end.jpg to
the repo root as well (examples reference them from there).

Usage (from the repo root):
    python tools/make-backgrounds.py

Requires numpy and Pillow, and Arial Bold (or Liberation Sans Bold) for the
institution name.
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
EXT = ROOT / "_extensions" / "den"
PHOTO = ROOT / "tools" / "assets" / "photo.jpg"
EMBLEM = EXT / "logo.png"
HAZE = ROOT / "Picture1.png"

DPI = 200
CANVAS = (13.333, 7.5)                  # inches
PHOTO_BOX = (0.243, 0.205, 12.847, 7.02)  # x, y, w, h in inches, from the master
PHOTO_CROP = 0.2818                     # share of the photo height cut at top and bottom
EMBLEM_SIZE = 0.945
EMBLEM_TOP_CENTRE = ((CANVAS[0] - EMBLEM_SIZE) / 2, 0.993)
EMBLEM_TOP_LEFT = (0.625, 0.536)
NAME_TOP = 2.02                         # top of the two-line institution name
NAME_PT = 12
FONTS = ["C:/Windows/Fonts/arialbd.ttf", "/Library/Fonts/Arial Bold.ttf",
         "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"]


def px(inches: float) -> int:
    return round(inches * DPI)


def smoothstep(edge0: float, edge1: float, x: np.ndarray) -> np.ndarray:
    t = np.clip((x - edge0) / (edge1 - edge0), 0, 1)
    return t * t * (3 - 2 * t)


def photo() -> Image.Image:
    image = Image.open(PHOTO).convert("RGB")
    cut = round(image.height * PHOTO_CROP)
    image = image.crop((0, cut, image.width, image.height - cut))
    return image.resize((px(PHOTO_BOX[2]), px(PHOTO_BOX[3])), Image.LANCZOS)


def darken(image: Image.Image, light: np.ndarray) -> Image.Image:
    """Multiply the photo by `light` (1 = unchanged, 0 = black)."""
    pixels = np.asarray(image, dtype=float) * light[..., None]
    return Image.fromarray(pixels.round().clip(0, 255).astype(np.uint8))


def bottom_shade(image: Image.Image) -> Image.Image:
    y = np.linspace(0, 1, image.height)[:, None] * np.ones((1, image.width))
    return darken(image, 1 - smoothstep(0.55, 0.86, y))


def left_shade(image: Image.Image) -> Image.Image:
    x = np.ones((image.height, 1)) * np.linspace(0, 1, image.width)[None, :]
    return darken(image, smoothstep(0.08, 0.66, x) ** 1.6)


def haze(image: Image.Image, keep_clear: tuple[float, float, float]) -> Image.Image:
    """Lay the white haze over the photo, leaving a disc (x, y, d in canvas inches) clear."""
    layer = np.asarray(Image.open(HAZE).convert("RGBA").resize(image.size, Image.LANCZOS), dtype=float)
    cx = px(keep_clear[0] + keep_clear[2] / 2 - PHOTO_BOX[0])
    cy = px(keep_clear[1] + keep_clear[2] / 2 - PHOTO_BOX[1])
    y, x = np.mgrid[:image.height, :image.width]
    outside = np.clip((np.hypot(x - cx, y - cy) - px(keep_clear[2] / 2)) / 2, 0, 1)
    alpha = layer[..., 3] / 255 * outside
    pixels = alpha[..., None] * layer[..., :3] + (1 - alpha[..., None]) * np.asarray(image, dtype=float)
    return Image.fromarray(pixels.round().clip(0, 255).astype(np.uint8))


def framed(image: Image.Image) -> Image.Image:
    canvas = Image.new("RGB", (px(CANVAS[0]), px(CANVAS[1])), "white")
    canvas.paste(image, (px(PHOTO_BOX[0]), px(PHOTO_BOX[1])))
    return canvas


def add_emblem(canvas: Image.Image, at: tuple[float, float]) -> None:
    emblem = Image.open(EMBLEM).convert("RGBA").resize((px(EMBLEM_SIZE),) * 2, Image.LANCZOS)
    canvas.paste(emblem, (px(at[0]), px(at[1])), emblem)


def add_name(canvas: Image.Image) -> None:
    path = next((f for f in FONTS if Path(f).exists()), None)
    if path is None:
        raise SystemExit("Arial Bold or Liberation Sans Bold not found")
    font = ImageFont.truetype(path, round(NAME_PT / 72 * DPI))
    draw = ImageDraw.Draw(canvas)
    line_height = round(NAME_PT / 72 * DPI * 1.05)
    for i, text in enumerate(["DEWAN EKONOMI NASIONAL", "REPUBLIK INDONESIA"]):
        draw.text((canvas.width / 2, px(NAME_TOP) + i * line_height), text, font=font, fill="white", anchor="mt")


def save(canvas: Image.Image, name: str, also_root: bool) -> None:
    targets = [EXT / name] + ([ROOT / name] if also_root else [])
    for target in targets:
        canvas.save(target, quality=85, optimize=True, progressive=True)
        print(f"wrote {target} ({target.stat().st_size / 1024:.0f} KB)")


def main() -> None:
    base = photo()

    title = framed(bottom_shade(base))
    add_emblem(title, EMBLEM_TOP_CENTRE)
    add_name(title)
    save(title, "title.jpg", also_root=True)

    divider = framed(left_shade(base))
    add_emblem(divider, EMBLEM_TOP_LEFT)
    save(divider, "divider.jpg", also_root=False)

    end = framed(haze(base, (*EMBLEM_TOP_CENTRE, EMBLEM_SIZE)))
    add_emblem(end, EMBLEM_TOP_CENTRE)
    add_name(end)
    save(end, "end.jpg", also_root=True)


if __name__ == "__main__":
    main()
