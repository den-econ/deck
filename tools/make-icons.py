"""Draw the sample icons used by gallery.qmd into img/.

White glyphs on a transparent background, as icons in DEN cards are: they
sit on an orange disc (soft cards) or a dark header bar (header cards). Any
PNG or SVG of your own works the same way via icon="path".

Usage (from the repo root):
    python tools/make-icons.py

Requires Pillow.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "img"
SIZE = 256
WHITE = (255, 255, 255, 255)


def canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def bank() -> Image.Image:
    image, d = canvas()
    d.polygon([(128, 20), (236, 78), (20, 78)], fill=WHITE)
    for x in (44, 96, 148, 200):
        d.rectangle((x - 12, 96, x + 12, 196), fill=WHITE)
    d.rectangle((20, 208, 236, 232), fill=WHITE)
    return image


def coins() -> Image.Image:
    image, d = canvas()
    for top in (150, 110, 70):
        d.ellipse((40, top, 216, top + 70), fill=WHITE, outline=(0, 0, 0, 0), width=8)
    return image


def factory() -> Image.Image:
    image, d = canvas()
    d.rectangle((24, 40, 64, 232), fill=WHITE)
    d.polygon([(64, 232), (64, 120), (120, 150), (120, 120), (176, 150), (176, 120), (232, 150), (232, 232)], fill=WHITE)
    for x in (90, 146, 202):
        d.rectangle((x - 12, 180, x + 12, 204), fill=(0, 0, 0, 0))
    return image


def shield() -> Image.Image:
    image, d = canvas()
    d.polygon([(128, 16), (224, 52), (216, 140), (128, 240), (40, 140), (32, 52)], fill=WHITE)
    d.polygon([(128, 52), (190, 76), (184, 136), (128, 200)], fill=(0, 0, 0, 0))
    return image


def hourglass() -> Image.Image:
    image, d = canvas()
    d.rectangle((48, 20, 208, 44), fill=WHITE)
    d.rectangle((48, 212, 208, 236), fill=WHITE)
    d.polygon([(64, 52), (192, 52), (136, 128), (192, 204), (64, 204), (120, 128)], fill=WHITE)
    return image


def ship() -> Image.Image:
    image, d = canvas()
    d.rectangle((96, 40, 160, 100), fill=WHITE)
    d.rectangle((64, 100, 192, 150), fill=WHITE)
    d.polygon([(20, 150), (236, 150), (200, 220), (56, 220)], fill=WHITE)
    for x in (88, 128, 168):
        d.ellipse((x - 9, 116, x + 9, 134), fill=(0, 0, 0, 0))
    return image


def main() -> None:
    OUT.mkdir(exist_ok=True)
    for draw in (bank, coins, factory, shield, hourglass, ship):
        path = OUT / f"{draw.__name__}.png"
        draw().save(path)
        print(f"wrote {path}")


if __name__ == "__main__":
    main()
