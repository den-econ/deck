# Perbaikan tertunda: template revealjs DEN

Dicatat 20 Oktober 2026 saat menyiapkan deck *global-tax* (Diskusi DJSEF), yang dirender ke Beamer
dan revealjs. Versi PDF bersih, tetapi versi HTML memperlihatkan bug template berikut. Semua
ditemukan dengan `_extensions/den/check-deck-html.py` dan dikonfirmasi lewat tangkapan layar.

## Status kerja yang belum di-commit

- `_extensions/den/check-deck-html.py` (baru), `README.md` (bagian "Pemeriksaan overflow
  (revealjs)"), `_extensions/den/SLIDE-RULES.md` (langkah 6–8) dan `.gitignore`
  (`*_check_html/`, `__pycache__/`). Tinjau, lalu commit bersama perbaikan di bawah.

## 1. Judul berformat kehilangan spasi (prioritas tinggi)

- **Gejala**: `## Lampiran: sektor kunci menurut *backward* dan *forward linkage*` tampil sebagai
  "menurutbackwarddanforward linkage". Mengenai setiap `h2` yang memuat `*miring*`, `**tebal**`,
  `` `kode` `` atau tautan.
- **Penyebab**: `revealjs.scss` sekitar baris 110, `section:not(#title-slide) h2 { display: flex; }`.
  Dalam *flex*, setiap node teks dan elemen inline menjadi item terpisah, sehingga spasi di
  tepinya hilang. Flex hanya dipakai untuk garis cokelat `::before`.
- **Usulan**: buang `display: flex` dan gambar garis tanpa flex, misalnya
  `h2 { position: relative; padding-left: 21px; }` dan
  `h2::before { position: absolute; left: 0; top: 50%; transform: translateY(-50%); height: 1.4em; }`.
  Periksa juga `h2.heading-long` dan `h2.heading-very-long` serta judul dua baris (garis harus
  setinggi baris pertama atau seluruh judul; putuskan mana).
- **Verifikasi**: checker memberi warning `heading loses the spaces around formatted words`; harus
  hilang di `gallery.qmd` dan deck *global-tax* (slide 3, 4, 9, 21).

## 2. Slide judul: subjudul dan penulis menimpa lambang DEN (prioritas tinggi)

- **Gejala**: deck dengan `subtitle` atau blok `author` (nama, ORCID, email, afiliasi) menampilkan
  teks itu di bagian atas, tepat di atas lambang dan tulisan "DEWAN EKONOMI NASIONAL" yang
  tertanam di `title.jpg`. Subjudul berwarna gelap di atas foto. `template.qmd` tidak terkena
  karena tidak punya subjudul/penulis; `gallery.qmd` terkena.
- **Penyebab**: `revealjs.scss` baris 33–90 menata `.author` dan `.date`, tetapi Quarto
  merender penulis sebagai `.quarto-title-authors`, `.quarto-title-author-name`,
  `.quarto-title-author-email`, `.quarto-title-author-orcid`, `.quarto-title-affiliation`, dan
  subjudul sebagai `.subtitle`. Kelas-kelas ini tidak punya aturan, jadi jatuh ke posisi bawaan.
  Judul dan tanggal juga diposisikan dengan offset negatif mutlak (`bottom: -300px`,
  `bottom: -500px`) yang rapuh.
- **Usulan**: tata ulang slide judul dalam satu kolom di bawah lambang: judul → garis putih →
  subjudul → penulis (nama saja, atau nama + afiliasi; sembunyikan email dan ORCID di HTML) →
  tanggal. Semua putih dengan `text-shadow`. Lebih aman memakai satu wadah *flex column* yang
  dimulai di bawah zona lambang (kira-kira 31% tinggi kanvas) daripada offset negatif per elemen.
- **Verifikasi**: checker memberi `ERROR text covers the DEN emblem on the title slide` (zona
  lambang: `TITLE_EMBLEM_ZONE` di checker). Uji dengan judul 1, 2 dan 3 baris, dengan dan tanpa
  subjudul. Tanggal tidak boleh menyentuh tepi bawah (saat ini warning pada judul dua baris).

## 3. Isi card meluber keluar bingkai tanpa peringatan (prioritas sedang)

- **Gejala**: di HTML, bullet terakhir card bisa tercetak di bawah bingkai card dan menimpa
  *takeaway*, padahal di PDF muat. Contoh: slide "Bukti awal" deck *global-tax* sebelum
  teksnya diringkas.
- **Penyebab**: `.cols` memakai grid dengan `> div { min-height: 0; }` dan `.card-body
  { min-height: 0; }`, dengan `overflow` bawaan `visible`. Tinggi baris grid tetap, jadi isi
  yang terlalu panjang tumpah keluar.
- **Usulan**: jangan diam-diam memotong (`overflow: hidden` menyembunyikan isi). Biarkan
  checker yang menangkap (`text spills out of its box`), dan tambahkan di `SLIDE-RULES.md` batas
  isi card untuk revealjs, karena huruf HTML relatif lebih besar daripada Beamer.

## 4. Judul lebih cepat terbungkus di HTML daripada di PDF (prioritas sedang)

- **Gejala**: judul ±45 karakter muat satu baris di Beamer tetapi dua baris di revealjs, sehingga
  isi slide turun dan *takeaway* keluar kanvas (kasus "Apa yang berubah dengan Pajak Minimum
  Global").
- **Penyebab**: ambang `heading-long` (> 50 karakter) dan `heading-very-long` (> 70) di
  `title-detect.html` terlalu longgar untuk ukuran `h2` revealjs.
- **Usulan**: turunkan ambang (misalnya > 38 dan > 55), atau ukur lebar sebenarnya
  (`scrollWidth` terhadap lebar slide) alih-alih menghitung karakter. Tambahkan ke
  `SLIDE-RULES.md`: judul ≤ 38 karakter agar satu baris di kedua format.

## 5. Paragraf menempel tepi kiri kanvas (prioritas rendah)

- **Gejala**: paragraf biasa, terutama keterangan setelah gambar `{.fig-full}` (`r-stretch`),
  mulai di x ≈ 0–6 px, sementara bullet dan judul menjorok ±20 px.
- **Usulan**: beri `padding-left` yang sama dengan indentasi judul pada paragraf tingkat slide,
  atau terima sebagai desain. Checker saat ini memberi warning margin untuk kasus ini;
  `SIDE_MARGIN` sudah diturunkan ke 0,3% agar paragraf biasa tidak terlapor.

## Catatan lain

- Salinan ekstensi di proyek lain (mis. `Downloads/global-tax/_extensions/den-econ/den/`) memakai
  akhir baris CRLF; isinya sama dengan repo. Setelah perbaikan, salin ulang ke proyek yang
  dirender ke HTML dan render ulang (termasuk `krisna/static/djsef/` di blog).
- Keterbatasan `check-deck-html.py`: zona lambang dikodekan tetap untuk `title.jpg` saat ini;
  ambang margin, ukuran huruf minimum dan toleransi luberan dikalibrasi pada `template.qmd`,
  `gallery.qmd` dan deck *global-tax* saja. MathJax 2, MathJax 3 dan KaTeX sudah ditangani.
- Urutan kerja yang disarankan: (1) perbaiki `revealjs.scss` untuk butir 1 dan 2, (2) render
  `gallery.qmd` ke revealjs dan Beamer, (3) jalankan kedua checker, (4) perbarui `SLIDE-RULES.md`
  untuk butir 3–4, (5) commit, (6) perbarui salinan ekstensi di proyek yang aktif.
