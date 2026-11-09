# Phase 1 — Technical Spike Plan (FINALIZED)
# Last updated: 2026-11-02 — Criteria locked before coding begins

## 1. Overview & Methodology

Before committing to core dependencies and native integrations, three focused
**Technical Spikes** are executed during Phase 1.

### Methodology Rules
1. **Pre-Established Criteria**: All thresholds locked BEFORE writing spike code. ✅ Done.
2. **Measurable Results**: Empirical data where possible; labeled "Estimasi" otherwise.
3. **Honest labeling**: "Terukur" = actually measured; "Estimasi" = not measured yet.
4. **Decoupled Prototypes**: Spike code in `spikes/spike_X/` — never merged to `lib/`.
5. **Fixture labels**: `🔬 SINTETIS` = synthetic smoke test only; real fixtures needed for go/no-go.

### Environment Constraints (logged 2026-11-02)
- No physical Android device connected (ADB: 0 devices)
- No AVD configured
- **All runtime measurements (open time, RAM) → "Estimasi / Belum terukur"**
- **APK size measurements → "Terukur" (build + compare)**
- **Build feasibility → "Terukur" (compile success/fail)**

### 1.1 Universal Android Compatibility Standards (Applicable to All Spikes)
- **SDK Range**: `minSdk 26` (Android 8.0) up to latest targetSdk / compileSdk (API 34/36).
- **Supported ABIs**: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- **16 KB Memory Page Size**: Every native `.so` must be verified for 16 KB ELF page alignment for Android 15+ compatibility.
- **Low-RAM (2 GB / Android Go)**: Paging and bounded cache required; zero full-document memory dump.
- **Strict Storage Discipline**: Scoped storage + SAF only. Zero broad storage permissions.
- **Offline / Zero Telemetry**: 100% offline, airplane mode verified, zero network calls.

---

## 2. Fixture Inventory

### Available (Synthetic — 🔬 SINTETIS, smoke test only)
| File | Size | Purpose |
|---|---|---|
| `synth_simple.pdf` | 1.5 KB | PDF parse smoke test |
| `synth_corrupted.pdf` | 1.3 KB | Error handling test |
| `synth_simple.docx` | 1.4 KB | DOCX parse smoke test |
| `synth_simple.xlsx` | 1.9 KB | XLSX parse smoke test |
| `synth_scan_clean.bmp` | 2.6 MB | OCR/scanner smoke test |
| `synth_scan_skewed.bmp` | 2.6 MB | Edge detection smoke test |
| `synth_ocr_id.bmp` | 1.4 MB | Indonesian OCR smoke test |

### Required from User (Real fixtures — needed for go/no-go)
| File | Priority | Status |
|---|---|---|
| `fixture_complex.docx` — 20+ page DOCX | 🔴 CRITICAL | ⏳ Pending |
| `fixture_large.pdf` — 100+ page PDF | 🔴 CRITICAL | ⏳ Pending |
| `fixture_encrypted.pdf` — AES-256 encrypted | 🔴 CRITICAL | ⏳ Pending |
| `scan_clean_id.jpg` — Real Indonesian document photo | 🔴 CRITICAL | ⏳ Pending |
| `scan_skewed_30deg.jpg` — Photo at ~30° | 🟡 HIGH | ⏳ Pending |
| `fixture_id.xlsx` — XLSX with formulas | 🟡 HIGH | ⏳ Pending |
| `scan_shadow.jpg` — Photo with shadow | 🟡 HIGH | ⏳ Pending |
| `fixture_annotated.pdf` — PDF with annotations | 🟠 MEDIUM | ⏳ Pending |
| `scan_dim.jpg` — Dim lighting | 🟠 MEDIUM | ⏳ Pending |
| `scan_crumpled.jpg` — Crumpled paper | 🟠 MEDIUM | ⏳ Pending |

---

## 3. Spike A — Office Document Engine

### 3.1 Pass/Fail Criteria (FINAL — locked 2026-11-02)

| Metric | PASS | HARD FAIL | How Measured |
|---|---|---|---|
| APK size delta (release arm64-v8a) | ≤ 150 MB | > 250 MB | `flutter build apk --release --target-platform android-arm64` + compare |
| Open 20-page DOCX (cold start) | ≤ 5 s | > 10 s | Estimasi — needs device |
| Peak RAM during edit | ≤ 500 MB | > 700 MB | Estimasi — needs device |
| Edit cycle (open→edit→save new→reopen) | 100% fixture pass | Any failure | Manual + `zipfile` validation |
| Saved file opens in MS Word/LibreOffice | No repair dialog | Repair dialog appears | Manual |
| License | Tier 1 preferred; Tier 2 with isolation OK | Tier 3 (GPL/AGPL) | POM file inspection |
| Build compiles on clean Gradle | ✅ No manual steps | ❌ Requires undocumented steps | Build log |

### 3.2 Candidate Evaluation Order
1. **A1 — Apache POI** (poi-ooxml 5.3.0, Apache-2.0) — lowest license risk
2. **A2 — docx4j** (11.5.x, Apache-2.0) — richer API, heavier
3. **A3 — LOKit/Collabora** — research only (expected FAIL on APK size)
4. **A4 — Custom Kotlin XmlPullParser** — Plan B fallback (read-only + PDF export)

### 3.3 Edit Verification Cycle (mandatory for any PASS)
```
open fixture → read text → modify 1 para/cell → save to NEW path →
force-kill process → reopen from new path → verify text preserved →
validate ZIP structure (DOCX/XLSX) → open in LibreOffice → no errors
```

---

## 4. Spike B — PDF Engine

### 4.1 Pass/Fail Criteria (FINAL — locked 2026-11-02)

| Metric | PASS | HARD FAIL | How Measured |
|---|---|---|---|
| First page render (100-page PDF) | ≤ 1 s | > 3 s | Estimasi — needs device |
| Render per page (1080p) | ≤ 200 ms | > 500 ms | Estimasi — needs device |
| Text search (100 pages) | < 1 s, returns matches | Not working | Estimasi — needs device |
| Highlight survives save + viewer | ✅ Visible in Adobe/Foxit | ❌ Lost | Manual (needs device + 2nd app) |
| Signature image survives save | ✅ Visible | ❌ Lost | Manual |
| Non-annotated pages SHA-256 match | ✅ Identical | ❌ Changed | Script comparison |
| Encrypted PDF (correct password) | Opens | Crash/hang | Terukur on emulator |
| Corrupted PDF | Graceful error message | Crash | Terukur on emulator |
| License | Tier 1 | Tier 3 | POM inspection |

### 4.2 Candidates
| ID | Library | Version | License | Flutter Integration |
|---|---|---|---|---|
| B1 | `PdfRenderer` (Android built-in) | API 26+ | Apache-2.0 | Direct via MethodChannel |
| B2 | `pdfrx` (PDFium wrapper) | Latest | BSD-3 / Apache-2.0 | Flutter pub package |
| B3 | `pdfbox-android` | 2.0.x | Apache-2.0 | Gradle AAR |

---

## 5. Spike C — Scanner & OCR

### 5.1 Pass/Fail Criteria (FINAL — locked 2026-11-02)

| Metric | PASS | HARD FAIL | How Measured |
|---|---|---|---|
| OCR accuracy — clean print (Indonesian) | ≥ 90% CER | < 80% | Script vs ground truth |
| OCR accuracy — degraded (shadow/skew) | ≥ 75% CER | < 60% | Script vs ground truth |
| Total pipeline time per A4 page | ≤ 8 s | > 15 s | Estimasi — needs device |
| Edge detection success rate | ≥ 80% on test set | < 60% | Visual + quadrilateral check |
| Airplane mode — all features work | ✅ No network calls | ❌ Any network call | `adb shell settings put global airplane_mode_on 1` |
| tessdata bundled (not downloaded) | ✅ In APK assets | ❌ Network fetch at runtime | APK contents inspection |
| License (OpenCV + Tesseract + tessdata) | Tier 1 | Tier 3 | Source inspection |

### 5.2 Components
| Component | Version | License | Notes |
|---|---|---|---|
| `opencv_dart` or OpenCV Android | ≥ 4.5.0 | Apache-2.0 | Via pub or Gradle |
| Tesseract OCR | 5.x | Apache-2.0 | JNI or Flutter plugin |
| Leptonica | 1.82+ | BSD-2-Clause | Tesseract dependency |
| tessdata_fast `eng` | Latest | Apache-2.0 | Bundled in assets/ocr/ |
| tessdata_fast `ind` | Latest | Apache-2.0 | Bundled in assets/ocr/ |

---

## 6. Execution Order & Status

| Spike | Status | Notes |
|---|---|---|
| **Spike A** | ✅ COMPLETED | Apache POI 5.3.0: +3.00 MB APK delta, 100% edit cycle pass, Apache-2.0. |
| **Spike B** | 🔄 IN PROGRESS | Evaluating PdfRenderer vs pdfrx (PDFium) vs PdfBox-Android + 16 KB ELF check. |
| **Spike C** | 🔄 IN PROGRESS | OpenCV + Tesseract (eng+ind bundled) + 16 KB ELF check. |
