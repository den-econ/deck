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

## Bagian 2: Analisis {.section-divider background-image="title.png"}

## Terima kasih {.ending-slide background-image="end.png" background-size="cover"}

## Lampiran

Konten tambahan setelah slide penutup.
```

### Section divider

Gunakan `{.section-divider}` pada header H2 untuk membuat slide pembatas bagian. Teks header akan ditampilkan di tengah-kiri dengan warna putih di atas gambar latar.

```markdown
## Bagian 3: Hasil {.section-divider background-image="title.png"}
```

Atribut `background-image` opsional (default `title.png`). Anda dapat menyediakan gambar sendiri (misalnya `divider.png`) di folder yang sama dengan `.qmd` Anda.

### Ending / thank-you slide

Gunakan `{.ending-slide}` pada header H2. Teks header akan ditampilkan di tengah di atas gambar `end.png`, sehingga Anda dapat mengubah kata "Thank you" menjadi bahasa apa pun — misalnya "Terima kasih", "Matur nuwun", dst.

```markdown
## Terima kasih {.ending-slide background-image="end.png" background-size="cover"}
```

Jika header dibiarkan kosong (`## {.ending-slide ...}`), teks default adalah "Thank you".

> **Catatan:** ending slide sekarang adalah _environment_ yang bisa dipanggil kapan saja — Anda boleh meletakkan slide lampiran setelahnya. Sintaks lama dengan `::: {.ending-slide} :::` div di bawah header masih didukung tetapi tidak lagi diperlukan.

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
