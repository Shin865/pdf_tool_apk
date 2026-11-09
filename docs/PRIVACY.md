# Kebijakan Privasi (Privacy Policy)

**Terakhir diperbarui: 9 November 2026**

Document Reviewer dikembangkan dengan komitmen teguh terhadap privasi mutlak dan kedaulatan data pengguna.

---

## 1. Prinsip Utama: 100% Offline-First
Aplikasi ini beroperasi sepenuhnya secara offline di dalam perangkat Anda.
- **Tidak Memiliki Izin Internet**: Berkas manifes aplikasi (`AndroidManifest.xml`) secara eksplisit **TIDAK mendeklarasikan** izin `android.permission.INTERNET` maupun `android.permission.ACCESS_NETWORK_STATE`.
- **Tidak Ada Server Backend**: Kami tidak memiliki server, database jarak jauh, atau layanan cloud untuk aplikasi ini. Dokumen Anda tidak pernah dan tidak dapat dikirim ke luar perangkat.

---

## 2. Tanpa Pengumpulan Data & Tanpa Pelacak
- **Tanpa Akun**: Anda tidak perlu mendaftar, login, atau memberikan alamat email.
- **Tanpa Analitik & Iklan**: Aplikasi bebas dari SDK pelacak perilaku, Google Analytics, Firebase Analytics, Crashlytics pihak ketiga, maupun jaringan periklanan.
- **Tanpa Telemetri**: Tidak ada metadata penggunaan atau log aktivitas yang dikirim keluar.

---

## 3. Akses Berkas & Storage Access Framework (SAF)
- Document Reviewer menggunakan **Android Storage Access Framework (SAF)** resmi.
- Aplikasi hanya dapat membaca dan menulis dokumen yang Anda pilih secara sadar melalui pemilih berkas sistem (*system file picker*).
- Aplikasi tidak meminta atau membutuhkan izin sistem luas `MANAGE_EXTERNAL_STORAGE`.

---

## 4. Keamanan Lokal & Data Biometrik
- **Kunci PIN**: PIN keamanan di-hash menggunakan algoritma satu arah SHA-256 dengan cryptographic salt unik. PIN asli tidak pernah disimpan.
- **Verifikasi Biometrik**: Pemindaian sidik jari diproses sepenuhnya oleh subsistem keamanan Android OS (`BiometricPrompt`). Aplikasi tidak pernah mengakses atau menyimpan data biometrik Anda.
- **Enkripsi Cadangan**: Fitur cadangan menyediakan opsi enkripsi kuat berbasis kata sandi menggunakan standar industri **PBKDF2-HMAC-SHA256 + AES-256 CTR**.

---

## 5. Penghapusan Data
Anda memegang kendali penuh atas data Anda setiap saat:
- Anda dapat menghapus cache sementara pemindai dan OCR kapan saja.
- Tombol **"Hapus Semua Data Aplikasi"** di menu Pengaturan akan menghapus seluruh database riwayat, penanda favorit, dan kredensial kunci aplikasi secara permanen dalam satu kali klik.

---

## 6. Kontak Pengembang
Jika Anda memiliki pertanyaan mengenai komitmen privasi kami atau audit kode sumber, silakan buka Issue di repositori resmi GitHub proyek ini.
