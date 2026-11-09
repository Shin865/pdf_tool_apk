# Privacy and Permission Audit Report

**Date of Audit:** 2026-11-09  
**Application:** Document Reviewer (`com.example.documentreviewer.document_reviewer`)  
**Phase:** Tahap 7 — Backup, Keamanan, dan Polish  

---

## 1. Declared Permissions Audit

Every permission declared in `android/app/src/main/AndroidManifest.xml` must serve a strictly offline, functional purpose.

| Permission | Category | Justification / Rationale | Verified Status |
|---|---|---|---|
| `android.permission.USE_BIOMETRIC` | Normal / Authentication | Used solely for optional local in-app screen locking (`BiometricPrompt` / Keyguard credential fallback). Zero biometric data is handled by or visible to the application; verification is handled entirely by Android OS. | Active & Documented |

### Prohibited / Excluded Permissions:
- **`android.permission.INTERNET`**: **STRICTLY ABSENT**. The application does not declare and cannot acquire network access.
- **`android.permission.ACCESS_NETWORK_STATE`**: **ABSENT**. No connectivity checking required.
- **`android.permission.READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`**: **ABSENT**. All file access utilizes modern Android Storage Access Framework (SAF) (`Intent.ACTION_OPEN_DOCUMENT`) and private internal app storage.
- **`android.permission.MANAGE_EXTERNAL_STORAGE`**: **ABSENT**. No broad storage snooping permissions requested.
- **Telephony / Location / Camera / Microphone permissions**: **ABSENT**. Camera uses system photo picker or delegated contract without holding camera hardware permissions.

---

## 2. Zero Network Connections Invariant

1. **Network Inspector Verification:**
   - Under Android Studio Network Profiler and unit socket assertions, 0 outbound sockets and 0 HTTP requests are generated across all document viewing, editing, OCR scanning, and backup restoration workflows.
2. **Third-Party SDK Inspection:**
   - No Google Analytics, Firebase Analytics, Mixpanel, Segment, Sentry, or Crashlytics libraries are included in `pubspec.yaml` or `build.gradle.kts`.
   - No ad network SDKs (Google Mobile Ads, Unity Ads, AppLovin) are bundled.

---

## 3. Data Protection & Secure Deletion

1. **Data at Rest:**
   - Database entries (recents, favorites, editing sessions) are stored in an app-private SQLite database inside `/data/user/0/<package>/databases/app.db`.
   - Backup archives can be optionally encrypted with **AES-256** using keys derived via **PBKDF2** (HMAC-SHA256, 10,000 iterations).
2. **Data in Memory:**
   - Android native window flags (`FLAG_SECURE`) can be toggled by the user to prevent screen capture, screenshot leaks, and recents app switcher previews.
3. **Secure Wipe ("Hapus Aman"):**
   - The user can trigger cache deletion or a full application reset ("Hapus Semua Data Aplikasi"), wiping all SQLite records and temporary working copies while preserving user original files on external storage.

