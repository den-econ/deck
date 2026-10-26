## Tentang repo ini

Ini adalah repo untuk panduan presentasi dengan branding Dewan Ekonomi Nasional (DEN). Outputnya dapat berupa HTML (dengan Reveal.js) dan PDF (dengan Beamer), dengan tampilan master PowerPoint DEN.

Kedua format memakai halaman master PowerPoint (13,333 × 7,5 inci; revealjs 960 × 540 px, 72 px per inci), huruf Arial untuk judul dan Calibri untuk isi. Ukuran huruf dan posisi elemen sama di PDF dan HTML, sehingga teks terbungkus pada kata yang sama di kedua format.

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

Text-only slides (bullets, equations) are set at 16pt automatically; slides with a figure, table or `.cols` grid stay at 14pt.
Use {.normal} to keep a text-only slide at 14pt, and {.small} or {.smaller} for a slide with a heavily worded content.

## Bagian 2: Analisis {.section-divider}

## Terima kasih {.ending-slide}

## Lampiran

Konten tambahan setelah slide penutup.
```

### Section divider

Gunakan `{.section-divider}` pada header H2 untuk membuat slide pembatas bagian. Teks header ditampilkan di tengah-kiri dengan warna putih di atas `divider.jpg` (foto yang digelapkan ke kiri, lambang DEN di kiri atas).

```markdown
## Bagian 3: Hasil {.section-divider}
```

Atribut `background-image` opsional. Anda dapat menyediakan gambar sendiri (misalnya `divider.png`) di folder yang sama dengan `.qmd` Anda.

### Ending / thank-you slide

Gunakan `{.ending-slide}` pada header H2. Teks header ditampilkan berwarna cokelat di tengah gambar `end.jpg`, sehingga Anda dapat memakai bahasa apa pun, misalnya "Terima kasih" atau "Matur nuwun".

```markdown
## Terima kasih {.ending-slide}
```

Jika header dibiarkan kosong (`## {.ending-slide}`), teks default adalah "Thank you".

Gambar lain bisa dipakai lewat `background-image="..."`.

`title.jpg`, `divider.jpg` dan `end.jpg` dibangun oleh `python tools/make-backgrounds.py` dari foto master (`tools/assets/photo.jpg`), lambang (`logo.png`) dan lapisan kabut `Picture1.png`, mengikuti master PowerPoint DEN: foto dengan bingkai putih, lambang dan nama lembaga. Judul, garis putih dan tanggal digambar oleh template, sehingga ikut bergeser bila judul dua atau tiga baris.

> **Catatan:** ending slide sekarang adalah _environment_ yang bisa dipanggil kapan saja — Anda boleh meletakkan slide lampiran setelahnya. Sintaks lama dengan `::: {.ending-slide} :::` div di bawah header masih didukung tetapi tidak lagi diperlukan.

### Kotak takeaway

Gunakan div `{.takeaway}` untuk satu pesan utama slide. Kotak ini selebar teks dan berukuran sama di semua slide.

```markdown
::: {.takeaway}
Pesan utama slide, paling banyak dua baris.
:::
```

### Sumber dan catatan

Seperti di deck DEN, sumber data tercetak di kanan bawah di samping nomor halaman, dan catatan di baris atasnya, di kiri. Posisinya tetap, di mana pun div ditulis dalam slide.

```markdown
::: {.note}
Posisi per 30 Juni 2026.
:::

::: {.source}
Bank Indonesia & CEIC, diolah
:::
```

Hasilnya "**Catatan:** Posisi per 30 Juni 2026." dan "**Sumber:** Bank Indonesia & CEIC, diolah". `label="Source"` mengganti label.

### Takeaway di posisi tetap: `.pin`

Tambahkan `.pin` agar takeaway selalu berada di dasar badan slide (tepi bawahnya 0,6 inci dari kaki halaman), berapa pun tinggi isi di atasnya. Berlaku di Beamer dan Reveal.js.

```markdown
::: {.takeaway .pin}
Pesan utama slide.
:::
```

Takeaway tanpa `.pin` tetap mengikuti isi di atasnya. Dengan `.pin`, isi di atasnya harus berhenti sebelum bilah takeaway (grid `.cols` paling tinggi `height="85%"`), dan catatan (`.note`) paling banyak satu baris.

### Grid slot dan card

`:::: {.cols n=N}` menata div di dalamnya menjadi N kolom sama lebar, baris demi baris. Tiap div adalah satu slot. Berlaku di Beamer dan Reveal.js.

| Slot | Penulisan | Tampilan |
|:--|:--|:--|
| Card berkepala | `::: {.card title="..."}` | kotak putih di bawah bilah judul cokelat tua; `kicker="FISKAL"` menambah baris kecil di atas judul, `icon="img/x.png"` ikon di kirinya |
| Card lembut | `::: {.card .soft title="..." icon="img/x.png"}` | kotak krem berbingkai oranye, judul cokelat di dalam, ikon dalam lingkaran oranye |
| Card berwarna | `::: {.card .fill title="..."}` | seluruh card satu warna, teks putih; `icon` menaruh logo di kiri judul |
| Card polos | `::: {.card}` | kotak krem berbingkai oranye |
| Banner | `::: {.banner}` | bilah teks tebal, misalnya "REKOMENDASI"; `.dark` untuk bilah cokelat bergradasi |
| Grafik | `::: {.plain title="..." unit="Persen"}` | gambar dengan judul tebal di tengah dan "(Persen)" di bawahnya |
| Polos | `::: {.plain}` | tanpa kotak, untuk gambar atau teks biasa |

Warna bilah judul, card berwarna dan banner: `.gold`, `.amber`, `.rust`, `.orange`, `.tan`, `.brown`, `.dark`. Slot dengan `.wide` mengambil satu baris penuh.

```markdown
:::: {.cols n=3 rows="1.5,0.3,1.2" height="100%"}

::: {.card title="Permintaan meningkat, tetapi rapuh" kicker="Fiskal" icon="img/bank.png"}
- Defisit APBN di atas asumsi awal.
:::

::: {.card title="Menahan guncangan" kicker="Bank Indonesia" icon="img/coins.png"}
- BI Rate naik 25 bps.
:::

::: {.card title="Menekan nilai tukar" kicker="Sektor riil" icon="img/factory.png"}
- Impor migas naik.
:::

::: {.banner .wide}
REKOMENDASI
:::

::: {.card .gold title="1  Penciptaan ruang fiskal"}
Peningkatan *tax ratio*.
:::

::: {.card .gold title="2  Penegasan posisi BI"}
Kredit ke manufaktur berorientasi ekspor.
:::

::: {.card .gold title="3  Penguatan kualitas"}
Deregulasi.
:::

::::
```

`rows="2,1"` mengatur perbandingan tinggi baris; `height="80%"` mengatur bagian badan slide yang dipakai grid (default 80%, cukup untuk satu takeaway; pakai 100% bila grid sendirian di slide). Tinggi baris tetap, sehingga card dalam satu baris sama tinggi dan gambar di dalam slot diperkecil agar muat. Ukuran huruf ditentukan oleh N. Jangan memakai `###` di dalam slot. Ikon contoh di `img/` dibuat oleh `tools/make-icons.py`; ikon sendiri sebaiknya putih di atas latar transparan. Output Beamer memerlukan paket LaTeX `tcolorbox`.

#### Komposisi: kolom tidak sama lebar, tumpukan, angka kunci, panel grafik

Bagian ini untuk komposisi ala deck DEN terbaru: grafik lebar di kiri, kolom sempit berisi card bertumpuk atau angka kunci di kanan.

| Penulisan | Fungsi | Beamer | Reveal.js |
|:--|:--|:--|:--|
| `:::: {.cols widths="2,1"}` | lebar kolom relatif (di sini 2/3 dan 1/3); N otomatis sama dengan jumlah angka, ukuran huruf mengikuti N | ya | ya |
| `::: {.plain .panel}` | gambar (atau teks) di dalam panel putih berbingkai tipis; `title` dan `unit` tetap bisa dipakai | ya | ya |
| `::: {.stack}` | satu slot berisi beberapa card atau `.kpi` yang ditumpuk vertikal; `rows="1,1,1.3"` mengatur perbandingan tingginya | ya (tinggi dibagi sesuai `rows`) | ya |
| `::: {.kpi value="..." label="..."}` | angka besar (24pt), label tebal, lalu teks isi div sebagai keterangan; warna angka dengan `.gold`, `.dark`, dst. (default cokelat) | ya | ya |
| `:::: {.cols .fit}` | tinggi baris mengikuti isi, gambar tetap pada ukuran gambarnya, grafik dan tumpukan dipusatkan terhadap tetangganya, isi slide (grid beserta takeaway tanpa `.pin`) dipusatkan vertikal | diabaikan: baris tetap memakai `height`/`rows` | ya |

Contoh grafik dan tiga card bertumpuk:

```markdown
:::: {.cols widths="2,1" height="85%"}

::: {.plain .panel}
![](grafik.png)
:::

::: {.stack rows="1,1,1.3"}

::: {.card title="Ekspor ke UE: US$19,5 miliar"}
6,9% dari total ekspor Indonesia.
:::

::: {.card .gold title="EUDR: US$6,9 miliar"}
Sawit, kayu dan kertas, kopi, kakao, karet.
:::

::: {.card .rust title="CBAM: US$2,3 miliar"}
Baja karbon lebih besar dari rantai nikel.
:::

:::

::::

::: {.takeaway .pin}
Pesan utama slide.
:::
```

Contoh grafik dan angka kunci (`.fit` hanya berpengaruh di Reveal.js):

```markdown
:::: {.cols .fit widths="3,2"}

::: {.plain .panel}
![](grafik.png)
:::

::: {.stack}

::: {.kpi value="30,7%" label="Rasio ULN terhadap PDB"}
Naik 1,0 poin dari kuartal sebelumnya.
:::

::: {.kpi .gold value="US$431 miliar" label="Posisi ULN"}
Sektor publik 48%, swasta 52%.
:::

:::

::::
```

Catatan:

- Gambar untuk panel digambar seukuran slotnya dikurangi 0,3 inci (bantalan panel). Pada `widths="2,1"` dengan `height="85%"` itu sekitar 7,8 × 4,4 inci; pada `widths="3,2"` sekitar 7 × 4 inci.
- Karena `.fit` diabaikan di Beamer, tetap tulis `height` yang wajar untuk PDF, misalnya `height="45%"` untuk satu baris card pendek. Di Reveal.js `height` diabaikan bila ada `.fit`.
- Card di dalam `.stack` tidak boleh memakai `.wide`; satu `.stack` paling banyak empat slot.

### Langkah berurutan: `.steps`

Bilah-bilah setinggi sama, masing-masing bergeser 0,35 inci ke kanan dari bilah di atasnya, bernomor dalam lingkaran putih. Warna berganti emas, amber, cokelat, gelap; kelas warna pada satu `.step` menggantinya. `height="80%"` (default) mengatur bagian badan slide yang dipakai. Berlaku di Beamer dan Reveal.js.

```markdown
:::: {.steps}

::: {.step title="MRV dulu: satu sistem pengukuran emisi"}
Metodologi selaras Annex IV CBAM dan verifikator terakreditasi.
:::

::: {.step title="Harga karbon domestik yang berurutan"}
Batas atas emisi, lalu ETS industri, lalu pajak karbon.
:::

::::
```

Judul langkah 14pt, keterangan 12pt; paling banyak lima langkah, satu sampai dua baris keterangan per langkah.

### Gambar

Gunakan slot agar gambar tidak mendorong isi keluar slide:

```markdown
![](gambar.png){.fig-full}   <!-- gambar adalah isi slide -->
![](gambar.png){.fig-half}   <!-- gambar berbagi tempat dengan teks -->
```

Gambar dari code chunk secara default berukuran 12 × 4,8 inci, selebar teks, sehingga huruf 12pt pada gambar tercetak 12pt. Untuk slot grafik di grid dua kolom, gambar sekitar 6 × 4,6 inci. Gunakan [fig-den](https://github.com/den-econ/fig-den) dengan `den.AMBER_GOLD` dan `den.CLAY` sebagai pasangan warna utama, seperti di deck DEN.

### Tabel dan kolom

Tabel otomatis memakai gaya DEN di kedua format: baris judul cokelat muda, baris selang-seling krem, garis tipis. Kolom (`.columns`) dijaga tetap di dalam lebar teks.

Untuk tabel selebar slide, bungkus tabel dengan div `.wide-table`:

```markdown
::: {.wide-table widths="2,6,4" row-height="0.5"}
| K/L | Peran terkait | Status |
|:----|:--------------|:-------|
| Kemenperin | Koordinator subsektor industri | Permenperin belum terbit |
:::
```

- `widths` mengatur lebar kolom relatif. Tanpa `widths`, lebar yang tertulis di tabel (jumlah tanda `-` pada tabel pipa yang panjang, atau lebar kolom tabel grid) diskalakan ke lebar penuh; bila tidak ada, lebar mengikuti sel terpanjang tiap kolom.
- `row-height` (inci, opsional) adalah tinggi minimum baris isi; teks tetap di atas sel.
- Berlaku di Beamer dan Reveal.js.

### `.shrink` tidak didukung

Kelas `{.shrink}` diabaikan di Beamer dan memunculkan peringatan saat render, karena membuat ukuran huruf berbeda di tiap slide. Gunakan `{.small}`/`{.smaller}` atau pecah slide.

### Pemeriksaan overflow (Beamer)

Setelah render, jalankan:

```bash
python _extensions/den/check-deck.py presentation.pdf
```

Skrip ini melaporkan slide yang isinya keluar halaman, masuk ke margin, menabrak logo atau nomor halaman, saling menimpa, atau terlalu kecil, dan menyimpan gambar tiap slide di `presentation_check/` untuk diperiksa. Butuh [PyMuPDF](https://pymupdf.readthedocs.io/) (`pip install pymupdf`).

### Pemeriksaan overflow (revealjs)

Ukuran di HTML sama dengan PDF, tetapi peramban bisa memakai huruf pengganti (Carlito bila Calibri tidak terpasang), sehingga tetap periksa HTML. Setelah render HTML, jalankan:

```bash
python _extensions/den/check-deck-html.py presentation.html
```

Skrip ini membuka deck di Chromium *headless*, menampilkan semua *fragment*, lalu melaporkan teks yang keluar kanvas slide, menabrak logo, nomor slide, atau lambang DEN di slide judul, pembatas atau penutup, terpotong di dalam kotak (*card* atau sel tabel), saling menimpa, atau terlalu kecil. Gambar tiap slide disimpan di `presentation_check_html/`. Butuh [Playwright](https://playwright.dev/python/) (`pip install playwright`, lalu `python -m playwright install chromium`).

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
- For PDF output: a LaTeX distribution with XeLaTeX (e.g., TinyTeX, TeX Live), and the fonts Arial and Calibri. Without them the template falls back to Liberation Sans or Arimo, and Carlito (metrically identical to Calibri; in TeX Live as the `carlito` package).
- For HTML output: nothing extra. The Carlito web font ships with the extension (`_extensions/den/fonts/`, SIL Open Font License) for viewers without Calibri.

## Atribusi

Pembuatan template ini dibantu oleh Claude Opus 4.5
