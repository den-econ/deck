"""Check a rendered DEN beamer deck for overflow, overlap and undersized text.

Usage:
    python _extensions/den/check-deck.py deck.pdf [--out DIR] [--no-images]

Reads the PDF, reports every slide where content runs off the page, sits in
the margin, collides with the logo or the page number, overlaps other
content, or is set too small to read. Writes one PNG per slide to DIR
(default: <deck>_check/) so the slides can also be inspected by eye.

Exit code is 1 if any error is found, 0 otherwise. Warnings do not fail.
Requires PyMuPDF (pip install pymupdf).
"""
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

import fitz

CM = 28.35                      # points per centimetre
SIDE_MARGIN = 0.6 * CM          # text closer to a side edge than this is in the margin
BOTTOM_MARGIN = 0.25 * CM
PAGE_NUMBER_BOX = (0.9 * CM, 0.65 * CM)   # width, height of the corner page-number box
MIN_FONT_PT = 7.0               # \footnotesize is 9pt, \scriptsize 8pt in an 11pt deck
MIN_FONT_CHARS = 25             # ignore the odd subscript or axis tick
OVERLAP_SHARE = 0.30            # share of a text line that must lie on a figure
LINE_OVERLAP_HEIGHT = 0.40     # share of the shorter line's height two lines must share
LINE_OVERLAP_WIDTH = 0.20       # share of the narrower line's width two lines must share
MIN_OVERLAP_CHARS = 4           # ignore lone math glyphs such as a root sign
FULL_BLEED_SHARE = 0.90         # an image this large makes the slide a title/divider/ending


@dataclass
class Line:
    text: str
    box: fitz.Rect
    size: float


def text_lines(page: fitz.Page) -> list[Line]:
    """Every text line on the page, including text drawn outside the page."""
    flags = fitz.TEXTFLAGS_DICT & ~getattr(fitz, "TEXT_MEDIABOX_CLIP", 0)
    lines = []
    for block in page.get_text("dict", flags=flags)["blocks"]:
        for line in block.get("lines", []):
            text = "".join(s["text"] for s in line["spans"]).strip()
            spans = [s for s in line["spans"] if s["text"].strip()]
            if not text:
                continue
            lines.append(Line(
                text=text,
                box=fitz.Rect(line["bbox"]),
                size=max(s["size"] for s in spans),
            ))
    return lines


def image_boxes(page: fitz.Page) -> list[fitz.Rect]:
    return [fitz.Rect(info["bbox"]) for info in page.get_image_info()]


def share_covered(a: fitz.Rect, b: fitz.Rect) -> float:
    """Share of the smaller of two boxes covered by their intersection."""
    inter = a & b
    if inter.is_empty:
        return 0.0
    smaller = min(a.get_area(), b.get_area())
    return inter.get_area() / smaller if smaller else 0.0


def lines_collide(a: Line, b: Line) -> bool:
    """Two text lines printed on top of each other.

    Line boxes include ascender and descender space, so neighbouring lines
    and sub/superscripts always overlap a little. Only a deep vertical
    overlap together with a real horizontal one counts as a collision.
    """
    if min(len(a.text), len(b.text)) < MIN_OVERLAP_CHARS:
        return False
    inter = a.box & b.box
    if inter.is_empty:
        return False
    deep = inter.height >= LINE_OVERLAP_HEIGHT * min(a.box.height, b.box.height)
    wide = inter.width >= LINE_OVERLAP_WIDTH * min(a.box.width, b.box.width)
    return deep and wide


def quote(text: str, width: int = 48) -> str:
    return '"' + (text if len(text) <= width else text[: width - 1] + "…") + '"'


def check_page(page: fitz.Page) -> tuple[list[str], list[str]]:
    errors, warnings = [], []
    paper = page.rect
    images = image_boxes(page)

    if any(share_covered(img, paper) >= FULL_BLEED_SHARE and img.get_area() >= FULL_BLEED_SHARE * paper.get_area()
           for img in images):
        return errors, warnings

    corner = fitz.Rect(paper.x1 - PAGE_NUMBER_BOX[0], paper.y1 - PAGE_NUMBER_BOX[1], paper.x1, paper.y1)
    logo = next((img for img in images if img.y1 < 0.25 * paper.y1 and img.x0 > 0.75 * paper.x1), None)
    figures = [img for img in images if img is not logo]

    lines = text_lines(page)
    page_number = [ln for ln in lines if ln.box in corner and re.fullmatch(r"\d+", ln.text)]
    body = [ln for ln in lines if ln not in page_number]

    for ln in body:
        if ln.box.y1 > paper.y1 + 1 or ln.box.x1 > paper.x1 + 1 or ln.box.x0 < paper.x0 - 1:
            errors.append(f"text runs off the slide: {quote(ln.text)}")
        elif ln.box.intersects(corner):
            errors.append(f"text collides with the page number: {quote(ln.text)}")
        elif ln.box.y1 > paper.y1 - BOTTOM_MARGIN:
            warnings.append(f"text touches the bottom edge: {quote(ln.text)}")
        elif ln.box.x0 < paper.x0 + SIDE_MARGIN or ln.box.x1 > paper.x1 - SIDE_MARGIN:
            warnings.append(f"text sits in the side margin: {quote(ln.text)}")
        if logo is not None and ln.box.intersects(logo):
            errors.append(f"text collides with the logo: {quote(ln.text)}")

    for fig in figures:
        if fig.y1 > paper.y1 + 1 or fig.x1 > paper.x1 + 1 or fig.x0 < paper.x0 - 1 or fig.y0 < paper.y0 - 1:
            errors.append("a figure runs off the slide")
        elif fig.intersects(corner):
            errors.append("a figure collides with the page number")
        for ln in body:
            if share_covered(ln.box, fig) >= OVERLAP_SHARE:
                errors.append(f"text overlaps a figure: {quote(ln.text)}")

    for i, a in enumerate(body):
        for b in body[i + 1:]:
            if lines_collide(a, b):
                errors.append(f"text overlaps text: {quote(a.text, 30)} and {quote(b.text, 30)}")

    small = [ln for ln in body if ln.size < MIN_FONT_PT]
    if sum(len(ln.text) for ln in small) >= MIN_FONT_CHARS:
        smallest = min(ln.size for ln in small)
        warnings.append(f"text as small as {smallest:.1f}pt (minimum {MIN_FONT_PT:.0f}pt): {quote(small[0].text)}")

    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("pdf", type=Path)
    parser.add_argument("--out", type=Path, help="folder for the slide images")
    parser.add_argument("--no-images", action="store_true", help="skip writing slide images")
    args = parser.parse_args()

    doc = fitz.open(args.pdf)
    out = args.out or args.pdf.with_name(args.pdf.stem + "_check")
    if not args.no_images:
        out.mkdir(parents=True, exist_ok=True)

    n_errors = n_warnings = 0
    for number, page in enumerate(doc, start=1):
        if not args.no_images:
            page.get_pixmap(dpi=170).save(out / f"slide_{number:02d}.png")
        errors, warnings = check_page(page)
        n_errors += len(errors)
        n_warnings += len(warnings)
        for message in errors:
            print(f"page {number:>2}  ERROR    {message}")
        for message in warnings:
            print(f"page {number:>2}  warning  {message}")

    print(f"{len(doc)} pages, {n_errors} errors, {n_warnings} warnings")
    if not args.no_images:
        print(f"slide images: {out}")
    return 1 if n_errors else 0


if __name__ == "__main__":
    sys.exit(main())
