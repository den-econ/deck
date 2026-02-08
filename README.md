## Tentang repo ini

Ini adalah repo untuk panduan presentasi dengan branding Dewan Ekonomi Nasional (DEN). Outputnya dapat berupa HTML (dengan Reveal.js) dan PDF (dengan Beamer)

## Instalasi

### From GitHub

buka terminal favorit anda, navigasikan ke folder kerja anda, lalu ketik

```bash
quarto use template imedkrisna/den-slides
```

### Local Installation

Clone repo ini dan kopi folder `_extensions` ke project anda.

## Penggunaan

Buat `.qmd` dengan YAML:

```yaml
---
title: "Your Presentation Title"
date: "4 February 2026"
date-format: "DD MMMM YYYY"
format:
  den-revealjs: default
  den-beamer: default
---
```

### Creating Slides

```markdown
## Slide Title

Your content here.

- Bullet point 1
- Bullet point 2

## Another Slide

| Column 1 | Column 2 |
|----------|----------|
| Data A   | Data B   |

## Heavy content {.small}

use class {.small} or {.smaller} for a slide with a heavily worded content.

## {.ending-slide background-image="end.png" background-size="cover"}

::: {.ending-slide}
:::
```

> **Note:** ending slide wajib ada header `## {.ending-slide ...}` untuk html dan `::: {.ending-slide} :::` div (for PDF). Header terakhir sebaiknya tidak diubah, dan jangan ada konten lagi setelah header terakhir (ending-slide)

### Rendering

```bash
# Render to HTML (Reveal.js)
quarto render presentation.qmd --to den-revealjs

# Render to PDF (Beamer)
quarto render presentation.qmd --to den-beamer

# Render both formats
quarto render presentation.qmd
```

## Requirements

- [Quarto](https://quarto.org/) >= 1.4
- For PDF output: LaTeX distribution (e.g., TinyTeX, TeX Live)

## Atribusi

Pembuatan template ini dibantu oleh Claude Opus 4.5
