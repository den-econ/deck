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

## Bagian 2: Analisis {.section-divider background-image="title.jpg"}

## Terima kasih {.ending-slide background-image="end.jpg" background-size="cover"}

## Lampiran

Konten tambahan setelah slide penutup.
```

### Section divider

Gunakan `{.section-divider}` pada header H2 untuk membuat slide pembatas bagian. Teks header akan ditampilkan di tengah-kiri dengan warna putih di atas gambar latar.

```markdown
## Bagian 3: Hasil {.section-divider background-image="title.jpg"}
```

Atribut `background-image` opsional (default `title.jpg`). Anda dapat menyediakan gambar sendiri (misalnya `divider.png`) di folder yang sama dengan `.qmd` Anda.

### Ending / thank-you slide

Gunakan `{.ending-slide}` pada header H2. Teks header akan ditampilkan di tengah di atas gambar `end.jpg`, sehingga Anda dapat mengubah kata "Thank you" menjadi bahasa apa pun — misalnya "Terima kasih", "Matur nuwun", dst.

```markdown
## Terima kasih {.ending-slide background-image="end.jpg" background-size="cover"}
```

Jika header dibiarkan kosong (`## {.ending-slide ...}`), teks default adalah "Thank you".

> **Catatan:** ending slide sekarang adalah _environment_ yang bisa dipanggil kapan saja — Anda boleh meletakkan slide lampiran setelahnya. Sintaks lama dengan `::: {.ending-slide} :::` div di bawah header masih didukung tetapi tidak lagi diperlukan.

### Kotak takeaway

Gunakan div `{.takeaway}` untuk satu pesan utama slide. Kotak ini selebar teks dan berukuran sama di semua slide.

```markdown
::: {.takeaway}
Pesan utama slide, paling banyak dua baris.
:::
```

### Gambar

Gunakan slot agar gambar tidak mendorong isi keluar slide (khusus Beamer):

```markdown
![](gambar.png){.fig-full}   <!-- gambar adalah isi slide -->
![](gambar.png){.fig-half}   <!-- gambar berbagi tempat dengan teks -->
```

Gambar dari code chunk secara default berukuran 5,5 × 2,2 inci, sama dengan slot `.fig-full`, sehingga huruf pada gambar tercetak pada ukuran sebenarnya.

### Tabel dan kolom

Tabel otomatis memakai gaya DEN di Beamer (header cokelat tebal, jarak antarbaris, garis cokelat). Kolom (`.columns`) dijaga tetap di dalam lebar teks.

### `.shrink` tidak didukung

Kelas `{.shrink}` diabaikan di Beamer dan memunculkan peringatan saat render, karena membuat ukuran huruf berbeda di tiap slide. Gunakan `{.small}`/`{.smaller}` atau pecah slide.

### Pemeriksaan overflow (Beamer)

Setelah render, jalankan:

```bash
python _extensions/den/check-deck.py presentation.pdf
```

Skrip ini melaporkan slide yang isinya keluar halaman, masuk ke margin, menabrak logo atau nomor halaman, saling menimpa, atau terlalu kecil, dan menyimpan gambar tiap slide di `presentation_check/` untuk diperiksa. Butuh [PyMuPDF](https://pymupdf.readthedocs.io/) (`pip install pymupdf`).

### Galeri dan aturan penulisan

- `gallery.qmd` (di repo ini) memuat contoh tiap komponen.
- `_extensions/den/SLIDE-RULES.md` memuat batas isi per slide dan langkah pemeriksaan wajib; berikan berkas ini kepada asisten AI sebelum memintanya menulis slide.

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
