# Document Reviewer — Known Issues & Technical Limitations

Dokumen ini mencatat secara transparan batasan teknis yang diketahui (*known limitations*), kompromi arsitektur, dan perilaku khusus pada **Document Reviewer v1.0.0**. Batasan ini tidak menimbulkan risiko korupsi berkas atau kehilangan data, melainkan merupakan trade-off sadar demi menjaga performa, ukuran APK hemat, dan prinsip 100% offline.

---

## 1. Batasan Format & Editing Dokumen

### 1.1 Dokumen Word (`.docx`)
- **Elemen Grafis Tingkat Lanjut (SmartArt, WordArt, Diagram 3D)**:
  - *Perilaku*: Elemen grafis kompleks ini tidak dapat diedit secara langsung dari toolbar ponsel.
  - *Jaminan Keamanan*: Berkas asli dan elemen OpenXML internal (`word/diagrams/`, `word/drawings/`) tetap dipertahankan secara utuh tanpa rusak ketika teks paragraf atau tabel di sekitarnya diubah dan disimpan via `SaveCoordinator`.
- **Macro & VBA Scripts (`.docm`)**:
  - *Perilaku*: Skrip makro tidak dieksekusi demi alasan keamanan sandboxing Android.

### 1.2 Dokumen Spreadsheet (`.xlsx`)
- **Formula Dinamis Modern (Dynamic Spill Formulas / Excel 365)**:
  - *Perilaku*: Formula standar (`SUM`, `AVERAGE`, `COUNT`, `IF`, `MIN`, `MAX`, aritmatika sel dasar) dihitung dan dievaluasi secara akurat. Formula array matriks dinamis yang baru diperkenalkan di Excel 365 mempertahankan nilai kalkulasi terakhir (*cached calculation value*).
- **Pivot Table & Bagan Interaktif**:
  - *Perilaku*: Struktur lembar kerja Pivot Table dapat dilihat dalam mode hanya-baca; konfigurasi ulang relasi tabel pivot disarankan menggunakan desktop office suite.

### 1.3 Dokumen PDF (`.pdf`)
- **Tanda Tangan Gambar vs Sertifikat Digital Kriptografis (X.509)**:
  - *Perilaku*: Fitur tanda tangan dokumen menyematkan gambar coretan tangan pengguna pada koordinat halaman yang dipilih.
  - *Pemberitahuan Hukum*: Sesuai peringatan wajib di dalam aplikasi (*disclaimer*), tanda tangan ini merupakan penanda visual dan **BUKAN** tanda tangan elektronik tersertifikasi dengan sertifikat digital X.509 / PKI.
- **Formulir Interaktif AcroForms & XFA**:
  - *Perilaku*: Dokumen PDF dengan formulir dinamis XFA berbasis XML tidak didukung untuk pengisian dinamis; disarankan meratakan (*flatten*) formulir terlebih dahulu.

---

## 2. Batasan Pemindai Kamera & OCR

### 2.1 Perangkat dengan Kamera Resolusi Rendah / Tanpa Autofokus
- *Perilaku*: Pada beberapa ponsel entry-level dengan lensa kamera fixed-focus murah, teks berukuran < 8pt mungkin tampak kabur dalam kondisi pencahayaan redup.
- *Solusi & Mitigasi*: Pengguna dapat memanfaatkan slider kontras manual pada bilah filter dokumen atau mengimpor foto beresolusi tinggi langsung dari galeri.

### 2.2 Kecepatan OCR pada Perangkat RAM $\le 2\text{ GB}$ (Android Go)
- *Perilaku*: Demi mencegah *Out-Of-Memory (OOM)* pada perangkat RAM 2 GB, antrean multi-halaman OCR memproses satu halaman pada satu waktu secara serial dan melakukan pra-downsample gambar ke 1200px. Waktu pemrosesan membutuhkan sekitar 3 hingga 5 detik per halaman.
- *Status UI*: Indikator progres dengan tombol "Batal" selalu tersedia sehingga antarmuka tetap interaktif tanpa freeze.

---

## 3. Batasan Sistem Operasi & Platform Android

### 3.1 Privasi Layar & Screenshot (FLAG_SECURE)
- *Perilaku*: Saat opsi "Blokir Tangkapan Layar (FLAG_SECURE)" diaktifkan di Pengaturan Keamanan, beberapa antarmuka perekam layar sistem dan asisten AI Android pihak ketiga tidak dapat membaca konten layar.
- *Penyebab*: Ini merupakan perilaku keamanan yang disengaja sesuai spesifikasi `FLAG_SECURE` Android untuk mencegah kebocoran dokumen rahasia.

### 3.2 Pencabutan Izin URI oleh Sistem Operasi
- *Perilaku*: Pada beberapa varian custom ROM agresif (misal: penghemat baterai ekstrem yang menghapus data sistem), izin persistensi URI SAF (`takePersistableUriPermission`) berpotensi dicabut oleh sistem OS setelah perangkat tidak digunakan dalam jangka waktu sangat lama.
- *Penanganan*: Aplikasi mendeteksi status ini melalui `StorageDirectoryManager.isUriAccessible()`. Jika izin dicabut, aplikasi menampilkan pesan ramah meminta pengguna memilih kembali berkas tersebut tanpa menghapus riwayat metadata.

---

## 4. Rencana Peningkatan untuk Versi Mendatang (Roadmap v1.1.0)

| Fitur / Perbaikan | Rencana Rilis | Keterangan |
|---|:---:|---|
| **Pencarian Teks Penuh pada Dokumen Office (DOCX/XLSX)** | v1.1.0 | Menambahkan indeks pencarian kata kunci langsung di antarmuka editor office. |
| **Kamus OCR Bahasa Tambahan** | v1.1.0 | Opsi unduh paket bahasa tambahan (misal: Arab, Mandarin, Jepang) secara mandiri via berkas lokal. |
| **Penyimpanan Format Terbuka OpenDocument (`.odt`, `.ods`)** | v1.2.0 | Implementasi penuh siklus edit untuk keluarga ODF. |

