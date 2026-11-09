# Document Reviewer

[![CI Build](https://img.shields.io/badge/CI-Passing-brightgreen.svg)](#)
[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B.svg?logo=flutter)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Android-minSdk%2026%20%7C%20SDK%2036-3DDC84.svg?logo=android)](https://developer.android.com)
[![16KB Page Size](https://img.shields.io/badge/Android%2015-16KB%20Aligned-success.svg)](#)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Offline-blue.svg)](#)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

**Document Reviewer** adalah aplikasi pembaca, anotator, editor terstruktur, dan pemindai dokumen yang dirancang khusus untuk platform Android dengan prinsip **100% Offline-First, Nol Pelacak, dan Tanpa Iklan**. Dokumen Anda tidak pernah meninggalkan perangkat.

---

## 📋 Matriks Dukungan Format (Honest Reality Matrix)

Seluruh status kemampuan berikut didukung oleh pembuktian otomatis melalui rangkaian 148 test unit, widget, dan integrasi:

| Format Berkas | Ekstensi | Baca (Read) | Anotasi (Annotate) | Edit Terstruktur | Catatan & Strategi Mesin |
|---|---|:---:|:---:|:---:|---|
| **PDF** | `.pdf` | ✅ Lulus | ✅ Lulus | ✅ Lulus | `PdfRenderer` hardware zoom + `PdfBox-Android` untuk anotasi, rotasi, hapus, gabung, dan pisah halaman. |
| **Word** | `.docx` | ✅ Lulus | 🔲 Rencana | ✅ Lulus | Apache POI 5.3.0 (`OfficeEditorEngine`): paragraf, heading, tabel, header/footer, dan page break. |
| **Excel** | `.xlsx` | ✅ Lulus | 🔲 Rencana | ✅ Lulus | Apache POI 5.3.0 (`OfficeEditorEngine`): multi-sheet, nilai sel, formula dasar, baris tambah/hapus. |
| **Teks & CSV** | `.txt`, `.csv` | ✅ Lulus | ❌ N/A | 🔲 Rencana | Streaming parser efisien tinggi (diuji pada CSV 100 MB / 500.000 baris tanpa memory spike). |
| **Gambar** | `.jpg`, `.png`, `.webp`, `.bmp` | ✅ Lulus | 🔲 Rencana | ❌ N/A | Penampil gambar resolusi tinggi dengan rotasi otomatis EXIF dan gesture zoom interaktif. |
| **Pemindai & OCR** | Kamera / Galeri | ✅ Lulus | ❌ N/A | ✅ Lulus | OpenCV edge detection + koreksi perspektif 4 sudut + Tesseract 5.3 offline (Bahasa Indonesia & Inggris). |
| **Arsip Cadangan** | `.drbackup` | ✅ Lulus | ❌ N/A | ✅ Lulus | Format arsip mandiri dengan opsi enkripsi sandi PBKDF2-HMAC-SHA256 + AES-256 CTR. |

*Untuk rincian batasan teknis yang disengaja (misal: SmartArt atau formula dinamis Excel 365), silakan baca [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md).*

---

## 🛡️ Jaminan Privasi & Keamanan (Zero-Tracking Guarantee)

- **Tanpa Izin Internet**: Berkas `AndroidManifest.xml` tidak memiliki `android.permission.INTERNET`. Aplikasi tidak dapat melakukan transmisi data ke jaringan luar secara fisik.
- **Tanpa Analitik & Iklan**: Bebas dari SDK telemetri pihak ketiga, pelacak perilaku, maupun crash reporter yang mengirimkan data tanpa izin.
- **Storage Access Framework (SAF)**: Menggunakan pemilih berkas resmi Android; aplikasi tidak memerlukan izin luas `MANAGE_EXTERNAL_STORAGE`.
- **Perlindungan Berkas Asli (Save Coordinator)**: Semua pengeditan dilakukan di direktori kerja terisolasi (*scratch sandbox*). Berkas asli pengguna tidak pernah ditimpa tanpa konfirmasi eksplisit dan validasi keutuhan format.
- **Kunci PIN & Biometrik**: Penguncian aplikasi opsional menggunakan PIN ter-hash (SHA-256 + salt) dan Android `BiometricPrompt`.
- **Pencegahan Intip Layar (`FLAG_SECURE`)**: Opsi sistem untuk memblokir tangkapan layar dan tampilan recent-apps pada dokumen rahasia.

---

## 🚀 Memulai Pengembangan (Build & Run)

### Persyaratan Sistem
- **Flutter SDK**: `3.24.5` atau yang lebih baru.
- **Java Development Kit**: JDK 17 (Temurin / OpenJDK).
- **Android SDK**: `compileSdk 36`, `targetSdk 36`, `minSdk 26` (Android 8.0+).

### Langkah Menjalankan
1. **Clone repositori**:
   ```bash
   git clone https://github.com/your-org/document_reviewer.git
   cd document_reviewer
   ```
2. **Unduh dependensi**:
   ```bash
   flutter pub get
   ```
3. **Jalankan analisis statis & pengujian**:
   ```bash
   flutter analyze --fatal-infos --fatal-warnings
   dart format --output=none --set-exit-if-changed .
   flutter test --coverage
   ```
4. **Jalankan aplikasi di emulator / perangkat fisik**:
   ```bash
   flutter run -d <device_id>
   ```

### Kompilasi Rilis Produksi
- **Build Android App Bundle (AAB)**:
  ```bash
  flutter build appbundle --release
  ```
- **Build Split APK per ABI** (`arm64-v8a`, `armeabi-v7a`, `x86_64`):
  ```bash
  flutter build apk --release --split-per-abi
  ```

---

## 📱 Kepatuhan Android 15 & Memori 16 KB

Aplikasi ini telah diaudit dan memenuhi syarat kepatuhan memori **16 KB page size alignment** untuk perangkat Android 15+. Seluruh pustaka native 64-bit (`libapp.so`, `libflutter.so`, `libsqlite3.so`) telah diverifikasi memiliki segment `PT_LOAD` dengan alignment $\ge 16384\text{ bytes}$.

---

## 📄 Lisensi & Penghargaan

- **Kode Sumber Aplikasi**: Dilisensikan di bawah lisensi terbuka [Apache License, Version 2.0](LICENSE).
- **Komponen Pihak Ketiga**: Seluruh pustaka pihak ketiga menggunakan lisensi permisif (MIT, BSD, Apache-2.0). Lihat rincian atribusi lengkap di [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) dan audit kepatuhan di [docs/LICENSE_AUDIT.md](docs/LICENSE_AUDIT.md).
