"""Build end.jpg, the ending-slide background.

The picture carries no closing text; ending-slide.lua draws the slide
heading over it. It is built from two sources:

    _extensions/den/title.jpg   the photo, with the logo, the institution
                                name and a white horizontal rule
    Picture1.png                the semi-transparent white haze layer of the
                                ending slide

It removes the white rule from the photo, then lays the haze over it,
leaving the logo clear of haze, and writes the result to the extension
folder and to the repo root.

Usage (from the repo root):
    python tools/make-end.py

Requires: numpy and Pillow.
"""
from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
PHOTO = ROOT / "_extensions" / "den" / "title.jpg"
HAZE = ROOT / "Picture1.png"
TARGETS = [ROOT / "_extensions" / "den" / "end.jpg", ROOT / "end.jpg"]

# The white rule in title.jpg, with a margin for JPEG ringing (pixels).
RULE_ROWS = (842, 857)
RULE_COLS = (432, 2176)

# The logo disc in title.jpg: centre (x, y) and radius, in pixels.
LOGO_CENTRE = (1263, 237)
LOGO_RADIUS = 89


def remove_rule(photo: np.ndarray) -> np.ndarray:
    """Replace the rule with the texture just above and below it, cross-faded."""
    top, bottom = RULE_ROWS
    left, right = RULE_COLS
    height = bottom - top
    above = photo[top - height:top, left:right]
    below = photo[bottom:bottom + height, left:right]
    weight = np.linspace(0, 1, height)[:, None, None]
    patched = photo.copy()
    patched[top:bottom, left:right] = (1 - weight) * above + weight * below
    return patched


def outside_logo(shape: tuple[int, int]) -> np.ndarray:
    """1 away from the logo, 0 on it, with a two-pixel soft edge."""
    y, x = np.mgrid[:shape[0], :shape[1]]
    distance = np.hypot(x - LOGO_CENTRE[0], y - LOGO_CENTRE[1])
    return np.clip((distance - LOGO_RADIUS) / 2, 0, 1)[..., None]


def main() -> None:
    photo = np.asarray(Image.open(PHOTO).convert("RGB"), dtype=float)
    clean = remove_rule(photo)

    haze = Image.open(HAZE).convert("RGBA").resize((photo.shape[1], photo.shape[0]), Image.LANCZOS)
    haze = np.asarray(haze, dtype=float)
    alpha = haze[..., 3:4] / 255 * outside_logo(photo.shape[:2])
    result = alpha * haze[..., :3] + (1 - alpha) * clean

    picture = Image.fromarray(result.round().clip(0, 255).astype(np.uint8))
    for target in TARGETS:
        picture.save(target, quality=85, optimize=True, progressive=True)
        print(f"wrote {target} ({target.stat().st_size / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
