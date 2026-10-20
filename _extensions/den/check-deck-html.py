"""Check a rendered DEN revealjs deck for overflow, overlap and undersized text.

Usage:
    python _extensions/den/check-deck-html.py deck.html [--out DIR] [--no-images]

Opens the deck in headless Chromium, steps through every slide with all
fragments shown, and reports content that runs off the slide canvas, sits in
the margin, collides with the logo, the slide number or the DEN emblem on
the title slide, overlaps other content, is clipped inside or spills out of a box (a card,
a takeaway or a cell that is too small), or is set too small to read. Writes one PNG per slide to DIR (default:
<deck>_check_html/) so the slides can also be inspected by eye.

Exit code is 1 if any error is found, 0 otherwise. Warnings do not fail.
Requires Playwright (pip install playwright; python -m playwright install chromium).
"""
from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

from playwright.sync_api import Page, sync_playwright

SIDE_MARGIN = 0.003             # share of canvas width; DEN paragraphs sit ~6px from the edge by design
BOTTOM_MARGIN = 0.015           # share of canvas height
MIN_FONT_SHARE = 0.45           # text below this share of the deck's base font size is too small
MIN_FONT_CHARS = 25             # ignore the odd subscript or axis tick
OVERLAP_SHARE = 0.30            # share of a text line that must lie on a figure
LINE_OVERLAP_HEIGHT = 0.40      # share of the shorter line's height two lines must share
LINE_OVERLAP_WIDTH = 0.20       # share of the narrower line's width two lines must share
MIN_OVERLAP_CHARS = 4           # ignore lone math glyphs such as a root sign
CLIP_TOLERANCE = 2              # px of hidden overflow tolerated inside a box
# The DEN emblem and name are part of the title-slide background image (title.jpg),
# so they are not elements; text placed over them is caught by this zone instead.
TITLE_EMBLEM_ZONE = (0.36, 0.05, 0.64, 0.31)   # x0, y0, x1, y1 as shares of the canvas

# Collects, for the current slide, every text line and figure box in canvas
# coordinates (the 1050 x 700 slide before reveal.js scales it), plus boxes
# whose content is cut off and the logo and slide-number boxes.
MEASURE_JS = """
() => {
  const cfg = Reveal.getConfig();
  const slides = document.querySelector('.reveal .slides').getBoundingClientRect();
  const scale = slides.width / cfg.width;
  const toCanvas = r => ({x0: (r.left - slides.left) / scale, y0: (r.top - slides.top) / scale,
                          x1: (r.right - slides.left) / scale, y1: (r.bottom - slides.top) / scale});
  const visible = el => {
    for (let e = el; e && e !== document.body; e = e.parentElement) {
      const s = getComputedStyle(e);
      if (s.display === 'none' || s.visibility === 'hidden' || parseFloat(s.opacity) === 0) return false;
    }
    return true;
  };
  const math = 'mjx-container, .MathJax, .MathJax_Display, .MathJax_SVG, .katex';
  const skip = 'script, style, mjx-assistive-mml, .MJX_Assistive_MathML, .visually-hidden, .sr-only, aside.notes, .quarto-title-block .hidden';
  const slide = Reveal.getCurrentSlide();
  // The nearest ancestor drawn as a box (background or border), e.g. a card or a takeaway
  const boxOf = el => {
    for (let e = el; e && e !== slide; e = e.parentElement) {
      const s = getComputedStyle(e);
      const filled = s.backgroundColor !== 'rgba(0, 0, 0, 0)' && s.backgroundColor !== 'transparent';
      const framed = ['Top', 'Right', 'Bottom', 'Left'].some(side => parseFloat(s['border' + side + 'Width']) > 0);
      if ((filled || framed) && !['TD', 'TH', 'TR', 'TABLE', 'THEAD', 'TBODY', 'CODE'].includes(e.tagName)) {
        return toCanvas(e.getBoundingClientRect());
      }
    }
    return null;
  };

  const lines = [];
  const walker = document.createTreeWalker(slide, NodeFilter.SHOW_TEXT);
  for (let node = walker.nextNode(); node; node = walker.nextNode()) {
    const text = node.textContent.trim();
    const parent = node.parentElement;
    if (!text || parent.closest(skip) || !visible(parent)) continue;
    const range = document.createRange();
    range.selectNodeContents(node);
    const size = parseFloat(getComputedStyle(parent).fontSize);
    const container = boxOf(parent);
    for (const r of range.getClientRects()) {
      if (r.width < 1 || r.height < 1) continue;
      lines.push({text, size, box: toCanvas(r), container});
    }
  }

  const figures = [...slide.querySelectorAll(`img, svg, canvas, iframe, video, ${math}`)]
    .filter(el => visible(el) && !(el.parentElement && el.parentElement.closest(math)))
    .map(el => ({tag: el.matches(math) ? 'math' : el.tagName.toLowerCase(),
                 box: toCanvas(el.getBoundingClientRect())}))
    .filter(f => f.box.x1 - f.box.x0 > 1 && f.box.y1 - f.box.y0 > 1);

  const clipped = [];
  for (const el of slide.querySelectorAll('*')) {
    // MathJax clips its own glyph boxes; equations are checked as figures instead
    if (el.closest(skip) || el.closest(math) || !visible(el)) continue;
    const s = getComputedStyle(el);
    const hides = v => v === 'hidden' || v === 'auto' || v === 'scroll' || v === 'clip';
    const tall = hides(s.overflowY) && el.scrollHeight - el.clientHeight > CLIP;
    const wide = hides(s.overflowX) && el.scrollWidth - el.clientWidth > CLIP;
    if ((tall || wide) && el.clientHeight > 0) {
      clipped.push({text: (el.innerText || el.tagName).trim().replace(/\\s+/g, ' '),
                    tall, by: tall ? el.scrollHeight - el.clientHeight : el.scrollWidth - el.clientWidth});
    }
  }

  const fixed = sel => {
    const el = document.querySelector(sel);
    return el && visible(el) && el.getBoundingClientRect().width > 0 ? toCanvas(el.getBoundingClientRect()) : null;
  };
  // A flex heading turns each formatted word into its own flex item, which drops the spaces around it
  const squashed = [...slide.querySelectorAll('h1, h2, h3')]
    .filter(h => getComputedStyle(h).display.includes('flex') && h.querySelector('em, strong, code, a, span'))
    .map(h => h.textContent.trim());
  const base = parseFloat(getComputedStyle(document.querySelector('.reveal')).fontSize);
  return {width: cfg.width, height: cfg.height, base, lines, figures, clipped, squashed, isTitle: slide.id === 'title-slide',
          logo: fixed('.reveal .slide-logo'), number: fixed('.reveal .slide-number')};
}
""".replace("CLIP", str(CLIP_TOLERANCE))


@dataclass
class Box:
    x0: float
    y0: float
    x1: float
    y1: float

    @property
    def width(self) -> float:
        return max(0.0, self.x1 - self.x0)

    @property
    def height(self) -> float:
        return max(0.0, self.y1 - self.y0)

    @property
    def area(self) -> float:
        return self.width * self.height

    def __and__(self, other: "Box") -> "Box":
        return Box(max(self.x0, other.x0), max(self.y0, other.y0), min(self.x1, other.x1), min(self.y1, other.y1))

    def intersects(self, other: "Box") -> bool:
        return (self & other).area > 0


@dataclass
class Line:
    text: str
    box: Box
    size: float
    container: Box | None = None


def share_covered(a: Box, b: Box) -> float:
    """Share of the smaller of two boxes covered by their intersection."""
    smaller = min(a.area, b.area)
    return (a & b).area / smaller if smaller else 0.0


def lines_collide(a: Line, b: Line) -> bool:
    """Two text lines drawn on top of each other, not merely neighbours."""
    if a.text == b.text or min(len(a.text), len(b.text)) < MIN_OVERLAP_CHARS:
        return False
    inter = a.box & b.box
    if inter.area == 0:
        return False
    deep = inter.height >= LINE_OVERLAP_HEIGHT * min(a.box.height, b.box.height)
    wide = inter.width >= LINE_OVERLAP_WIDTH * min(a.box.width, b.box.width)
    return deep and wide


def quote(text: str, width: int = 48) -> str:
    return '"' + (text if len(text) <= width else text[: width - 1] + "…") + '"'


def check_slide(m: dict) -> tuple[list[str], list[str]]:
    errors, warnings = [], []
    canvas = Box(0, 0, m["width"], m["height"])
    side, bottom = SIDE_MARGIN * canvas.x1, BOTTOM_MARGIN * canvas.y1
    logo = Box(**m["logo"]) if m["logo"] else None
    number = Box(**m["number"]) if m["number"] else None
    emblem = None
    if m["isTitle"]:
        zx0, zy0, zx1, zy1 = TITLE_EMBLEM_ZONE
        emblem = Box(zx0 * canvas.x1, zy0 * canvas.y1, zx1 * canvas.x1, zy1 * canvas.y1)
    lines = [Line(ln["text"], Box(**ln["box"]), ln["size"], Box(**ln["container"]) if ln["container"] else None)
             for ln in m["lines"]]
    figures = [Box(**f["box"]) for f in m["figures"] if f["tag"] != "math"]
    math = [Box(**f["box"]) for f in m["figures"] if f["tag"] == "math"]

    for ln in lines:
        b = ln.box
        if b.y1 > canvas.y1 + 1 or b.x1 > canvas.x1 + 1 or b.x0 < canvas.x0 - 1 or b.y0 < canvas.y0 - 1:
            errors.append(f"text runs off the slide: {quote(ln.text)}")
        elif number and b.intersects(number):
            errors.append(f"text collides with the slide number: {quote(ln.text)}")
        elif b.y1 > canvas.y1 - bottom:
            warnings.append(f"text touches the bottom edge: {quote(ln.text)}")
        elif b.x0 < canvas.x0 + side or b.x1 > canvas.x1 - side:
            warnings.append(f"text sits in the side margin: {quote(ln.text)}")
        if logo and b.intersects(logo):
            errors.append(f"text collides with the logo: {quote(ln.text)}")
        c = ln.container
        if c and (b.y1 > c.y1 + CLIP_TOLERANCE or b.x1 > c.x1 + CLIP_TOLERANCE
                  or b.y0 < c.y0 - CLIP_TOLERANCE or b.x0 < c.x0 - CLIP_TOLERANCE):
            errors.append(f"text spills out of its box: {quote(ln.text)}")
        if emblem and b.intersects(emblem):
            errors.append(f"text covers the DEN emblem on the title slide: {quote(ln.text)}")

    for fig in figures + math:
        if fig.y1 > canvas.y1 + 1 or fig.x1 > canvas.x1 + 1 or fig.x0 < canvas.x0 - 1 or fig.y0 < canvas.y0 - 1:
            errors.append("a figure or equation runs off the slide")
        elif number and fig.intersects(number):
            errors.append("a figure or equation collides with the slide number")
        elif logo and fig.intersects(logo):
            errors.append("a figure or equation collides with the logo")
    for fig in figures:
        for ln in lines:
            if share_covered(ln.box, fig) >= OVERLAP_SHARE:
                errors.append(f"text overlaps a figure: {quote(ln.text)}")

    for i, a in enumerate(lines):
        for b in lines[i + 1:]:
            if lines_collide(a, b):
                errors.append(f"text overlaps text: {quote(a.text, 30)} and {quote(b.text, 30)}")

    for c in m["clipped"]:
        direction = "below" if c["tall"] else "to the side"
        errors.append(f"content cut off {c['by']:.0f}px {direction} inside a box: {quote(c['text'])}")

    for heading in m["squashed"]:
        warnings.append(f"heading loses the spaces around formatted words: {quote(heading)}")

    min_px = MIN_FONT_SHARE * m["base"]
    small = [ln for ln in lines if ln.size < min_px]
    if sum(len(ln.text) for ln in small) >= MIN_FONT_CHARS:
        smallest = min(ln.size for ln in small)
        warnings.append(f"text as small as {smallest:.0f}px (minimum {min_px:.0f}px): {quote(small[0].text)}")

    return list(dict.fromkeys(errors)), list(dict.fromkeys(warnings))


def open_deck(page: Page, html: Path) -> list[tuple[int, int]]:
    page.goto(html.resolve().as_uri())
    page.wait_for_function("window.Reveal && Reveal.isReady()")
    page.evaluate("Reveal.configure({transition: 'none', backgroundTransition: 'none', fragments: false})")
    page.evaluate("document.fonts.ready")
    page.wait_for_load_state("networkidle")
    return [tuple(ix) for ix in page.evaluate(
        "Reveal.getSlides().map(s => { const i = Reveal.getIndices(s); return [i.h, i.v || 0]; })")]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("html", type=Path)
    parser.add_argument("--out", type=Path, help="folder for the slide images")
    parser.add_argument("--no-images", action="store_true", help="skip writing slide images")
    args = parser.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    out = args.out or args.html.with_name(args.html.stem + "_check_html")
    if not args.no_images:
        out.mkdir(parents=True, exist_ok=True)

    n_errors = n_warnings = 0
    with sync_playwright() as pw:
        browser = pw.chromium.launch()
        page = browser.new_page(viewport={"width": 1280, "height": 800})
        indices = open_deck(page, args.html)
        for number, (h, v) in enumerate(indices, start=1):
            page.evaluate(f"Reveal.slide({h}, {v})")
            page.evaluate("new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)))")
            if not args.no_images:
                page.screenshot(path=out / f"slide_{number:02d}.png")
            errors, warnings = check_slide(page.evaluate(MEASURE_JS))
            n_errors += len(errors)
            n_warnings += len(warnings)
            for message in errors:
                print(f"slide {number:>2}  ERROR    {message}")
            for message in warnings:
                print(f"slide {number:>2}  warning  {message}")
        browser.close()

    print(f"{len(indices)} slides, {n_errors} errors, {n_warnings} warnings")
    if not args.no_images:
        print(f"slide images: {out}")
    return 1 if n_errors else 0


if __name__ == "__main__":
    sys.exit(main())
