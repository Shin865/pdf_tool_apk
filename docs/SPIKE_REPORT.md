# Document Reviewer — Technical Spike Report

## Executive Summary

This report documents the empirical outcomes, architectural evaluations, binary footprint, and licensing assessments from **Tahap 1: Technical Spikes** for Document Reviewer. 
All evaluations strictly enforce the **Universal Android Compatibility Standards**:
- minSdk 26, targetSdk 36, compileSdk 36.
- Multi-ABI support (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
- **16 KB ELF memory page size alignment** audit on all native `.so` binaries for Android 15+ readiness.
- Offline-first execution: zero internet connectivity required, airplane mode verified, zero telemetry/analytics.
- Atomic file operations via Storage Access Framework with SHA-256 byte immutability on original sources.

---

## 1. Spike A — Office Document Engine (DOCX & XLSX)

### 1.1 Objective & Scope
Evaluate whether an offline, embedded Office engine can operate inside Document Reviewer on Android without relying on cloud services, external server processes, or third-party applications.
Target capabilities:
1. Open and parse DOCX (Word) and XLSX (Excel) documents.
2. Perform safe modifications (text updates, table rows, cell values).
3. Enforce the **Edit Verification Cycle**: clone to scratchpad → modify → save new → simulate force-close → reopen → verify byte & structure integrity → assert original source file SHA-256 remains strictly untouched.

### 1.2 Evaluation of Options
- **Option A (LibreOfficeKit / LOKit)**: **NO-GO ❌**. Native C++ shared library bloat exceeds **180 MB - 280 MB per ABI**, requires massive cross-compilation toolchains with hundreds of dependencies, and poses copyleft licensing risks (**MPL-2.0 / LGPLv3 / GPLv3**).
- **Option B (Apache POI 5.3.0 Java/Kotlin)**: **GO-BERSYARAT ✅**. Adds only **+3.00 MB** to the release arm64 APK, passes 100% of automated edit verification cycles, preserves original file SHA-256, and is licensed under **Apache-2.0**.
- **Option C (Read-Only Viewer + PDF Export)**: **RECOMMENDED AS COMPLEMENTARY PREVIEW LAYER ✅**.

### 1.3 Measured Metrics vs. Pass/Fail Criteria (Spike A)
| Metric | Target / Threshold | Measured Result | Status | Measurement Method |
|---|---|---|:---:|---|
| **Release APK Size Delta** (arm64-v8a) | <= 150 MB (Hard Fail: >250 MB) | **+3.00 MB** *(Baseline: 17.57 MB, POI: 20.57 MB)* | **PASSED** ✅ | **Terukur** (`app-release.apk` R8) |
| **DOCX Open Time** (Synthetic Fixture) | <= 5.0 s | **443 ms** | **PASSED** ✅ | **Terukur** (`PoiVerificationTest`) |
| **DOCX Save Time** | <= 3.0 s | **85 ms** | **PASSED** ✅ | **Terukur** (`PoiVerificationTest`) |
| **DOCX Reopen Time** | <= 2.0 s | **31 ms** | **PASSED** ✅ | **Terukur** (`PoiVerificationTest`) |
| **XLSX Open Time** (Synthetic Fixture) | <= 5.0 s | **133 ms** | **PASSED** ✅ | **Terukur** (`PoiVerificationTest`) |
| **XLSX Save Time** | <= 3.0 s | **29 ms** | **PASSED** ✅ | **Terukur** (`PoiVerificationTest`) |
| **XLSX Reopen Time** | <= 2.0 s | **32 ms** | **PASSED** ✅ | **Terukur** (`PoiVerificationTest`) |
| **Edit Verification Cycle** | 100% Pass, No File Damage | **100% Pass** (DOCX & XLSX) | **PASSED** ✅ | **Terukur** (Automated assertions) |
| **Original File Preservation** | SHA-256 Byte Identical | **100% Match** (Both fixtures) | **PASSED** ✅ | **Terukur** (SHA-256 verified) |
| **Output ZIP Structure** | Valid OOXML Zip & Schema | **Valid** (`[Content_Types].xml`, `word/document.xml`, `xl/workbook.xml`) | **PASSED** ✅ | **Terukur** (ZipFile inspection) |
| **Peak Heap RAM** (Small/Synthetic) | <= 500 MB | **~55 MB - 82 MB** | **PASSED** ✅ | **Terukur** (JVM Test Runner) |
| **Peak Heap RAM** (Large 20-Page Doc) | <= 500 MB | **~120 MB - 250 MB** | **PASSED** (Est.) | **Estimasi** (Based on POI DOM model) |
| **License Compliance** | Permissive (Tier 1) | **Apache-2.0** | **PASSED** ✅ | **Terukur** (`LICENSE_AUDIT.md`) |

---

## 2. Spike B — PDF Engine (Rendering, Search & Annotation)

### 2.1 Objective & Scope
Compare and validate PDF rendering, text extraction, search, highlight annotation, and corrupted document resilience across three candidates:
1. `PdfRenderer` (Android native built-in framework, API 21+)
2. `pdfrx` / PDFium (Google Chrome PDFium wrapper)
3. `PdfBox-Android` (Apache PDFBox port for Android)

### 2.2 Evaluation of Candidates
- **Candidate B1 (`android.graphics.pdf.PdfRenderer`)**: Built into Android OS. Zero binary footprint increase. Hardware accelerated multi-page bitmap rendering. Lacks built-in text search and annotation writing.
- **Candidate B2 (`pdfrx` / PDFium)**: Highly functional, but build failed on standard Windows developer environments due to non-admin symlink permission restrictions (`CMakeLists.txt:68: file failed to create symbolic link`). Additionally attempts runtime network download of prebuilt binaries, conflicting with offline-first build reproducibility.
- **Candidate B3 (`PdfBox-Android` 2.0.27.0)**: Pure JVM/Kotlin bytecode running directly on Android ART. Adds only **+1.65 MB** to the release arm64 APK. Full support for text extraction, text search, highlight annotations, encrypted PDF handling, and corrupted file recovery. 

### 2.3 Measured Metrics vs. Pass/Fail Criteria (Spike B)
| Metric | Target / Threshold | Measured Result | Status | Measurement Method |
|---|---|---|:---:|---|
| **Release APK Size Delta** (arm64-v8a) | <= 30 MB | **+1.65 MB** *(Baseline: 17.57 MB, Spike B: 19.22 MB)* | **PASSED** ✅ | **Terukur** (`app-release.apk`) |
| **PDF Open Time** (Synthetic Fixture) | <= 1.0 s | **2 ms** | **PASSED** ✅ | **Terukur** (`PdfBoxVerificationTest`) |
| **Text Extraction & Search Time** | < 1.0 s | **136 ms** (Extracted 234 chars, found term) | **PASSED** ✅ | **Terukur** (`PdfBoxVerificationTest`) |
| **Highlight Annotation Save Time** | <= 1.0 s | **6 ms** | **PASSED** ✅ | **Terukur** (`PdfBoxVerificationTest`) |
| **PDF Reopen & Annotation Survival** | 100% visible on reload | **PASSED** (`subtype == HIGHLIGHT` confirmed) | **PASSED** ✅ | **Terukur** (`PdfBoxVerificationTest`) |
| **Original File Preservation** | SHA-256 Byte Identical | **100% Match** | **PASSED** ✅ | **Terukur** (SHA-256 verified) |
| **Corrupted PDF Error Resilience** | Graceful error / No crash | **PASSED** (Handled without process abort) | **PASSED** ✅ | **Terukur** (`PdfBoxVerificationTest`) |
| **16 KB ELF Page Size Audit** | `p_align` >= 16384 bytes | **64 KB (65,536 B)** for `.so` files; `PdfBox-Android` is pure DEX | **PASSED** ✅ | **Terukur** (ELF header inspector) |
| **License Compliance** | Permissive (Tier 1) | **Apache-2.0** (`PdfBox-Android`), Apache-2.0 (`PdfRenderer`) | **PASSED** ✅ | **Terukur** (`LICENSE_AUDIT.md`) |

### 2.4 Verdict & Recommendation
- **Verdict: GO ✅**.
- **Architectural Hybrid Strategy**: Use Android framework's built-in `PdfRenderer` for fast, hardware-accelerated page surface rendering + `PdfBox-Android` for text search, highlighting, and annotation round-tripping. Zero native C++ `.so` baggage.

---

## 3. Spike C — Document Scanner & Offline OCR

### 3.1 Objective & Scope
Evaluate offline computer vision pipeline (quadrilateral document contour detection, perspective warping, deskewing) and OCR text extraction using OpenCV and Tesseract with bundled `tessdata_fast` (`ind.traineddata` + `eng.traineddata`).

### 3.2 Evaluation of Components
- **OpenCV Android (4.5.3)**: High-speed computer vision operations (Canny edge detection, Douglas-Peucker polygon approximation, perspective transform matrix).
- **Tesseract4Android (4.7.0)**: Modern Android port of Tesseract 5.3 + Leptonica (Apache-2.0).
- **Bundled Language Models**: Pre-bundled `eng.traineddata` (4.11 MB) and `ind.traineddata` (1.12 MB) located in `assets/ocr/`.

### 3.3 Measured Metrics vs. Pass/Fail Criteria (Spike C)
| Metric | Target / Threshold | Measured Result | Status | Measurement Method |
|---|---|---|:---:|---|
| **Bundled Offline OCR Assets** | 100% bundled, 0 network calls | **eng: 4.11 MB, ind: 1.12 MB in `assets/ocr`** | **PASSED** ✅ | **Terukur** (`ScannerVerificationTest`) |
| **Airplane Mode / Offline Operation**| Zero network sockets opened | **100% Offline** | **PASSED** ✅ | **Terukur** (Local test execution) |
| **Geometric Pipeline Verification** | Quad aspect calculation | **640 x 870 target warp dimensions** | **PASSED** ✅ | **Terukur** (`ScannerVerificationTest`) |
| **Multi-ABI APK Compilation** | Supports arm64-v8a, armeabi-v7a, x86_64 | **Built Release APK (124.5 MB fat multi-ABI)** | **PASSED** ✅ | **Terukur** (Gradle release build) |
| **16 KB Memory Page Size Audit** | `p_align` >= 16384 bytes | **CRITICAL FINDING: Prebuilt AARs use 4 KB** | **GO-BERSYARAT** ⚠️ | **Terukur** (ELF header inspection) |
| **License Compliance** | Permissive (Tier 1) | **Apache-2.0** (OpenCV, Tesseract, Leptonica) | **PASSED** ✅ | **Terukur** (`LICENSE_AUDIT.md`) |

### 3.4 Critical Finding: 16 KB Memory Page Size Alignment
Our automated ELF header inspection of the bundled `.so` binaries revealed:
```
lib/arm64-v8a/libapp.so: alignment = 65536 bytes (64 KB) -> PASS (>= 16KB)
lib/arm64-v8a/libflutter.so: alignment = 65536 bytes (64 KB) -> PASS (>= 16KB)
lib/arm64-v8a/libc++_shared.so: alignment = 4096 bytes (4 KB) -> FAIL (< 16KB)
lib/arm64-v8a/libjpeg.so: alignment = 4096 bytes (4 KB) -> FAIL (< 16KB)
lib/arm64-v8a/libleptonica.so: alignment = 4096 bytes (4 KB) -> FAIL (< 16KB)
lib/arm64-v8a/libopencv_java4.so: alignment = 4096 bytes (4 KB) -> FAIL (< 16KB)
lib/arm64-v8a/libpngx.so: alignment = 4096 bytes (4 KB) -> FAIL (< 16KB)
lib/arm64-v8a/libtesseract.so: alignment = 4096 bytes (4 KB) -> FAIL (< 16KB)
```
- **Implication**: Precompiled legacy AARs on Maven/JitPack (`quickbirdstudios:opencv` and `tesseract4android:4.7.0`) were built with older NDK toolchains using 4 KB page alignment. On Android 15 devices configured with 16 KB memory pages, these prebuilt `.so` files will trigger load errors.
- **Actionable Mitigation for Production (Tahap 2+)**:
  1. Rebuild Tesseract and OpenCV native shared objects using NDK r27+ with linker flag `-Wl,-z,max-page-size=16384`.
  2. Implement a pure Kotlin lightweight edge detection and perspective warping fallback for document scanning that runs entirely in Java bytecode with zero `.so` dependencies.

---

## 4. Overall Architecture Recommendations & Decisions

### Decision 1: Document Processing Engines
1. **Office Engine**: **Apache POI 5.3.0** via Kotlin platform channel. Reject LibreOfficeKit due to binary bloat and copyleft risk.
2. **PDF Engine**: **Android `PdfRenderer`** (hardware accelerated rendering) + **`PdfBox-Android`** (annotations, search, encrypted document unlocking, recovery).
3. **Scanner & OCR Engine**: **OpenCV 4.x + Tesseract 5.x** with mandatory NDK 16 KB page-aligned builds, complemented by a pure-Kotlin quad detection fallback.

### Decision 2: Realistic Compatibility Scopes
- **Release 1 Scope**:
  - Full PDF viewing, page panning/zooming, text search, highlight & freehand annotation.
  - DOCX & XLSX inspection, structured text/cell editing, metadata viewing.
  - Document camera scanner with automatic quad edge detection, perspective crop, and offline OCR to text.
  - Storage Access Framework integration with safe sandboxed working copies.
- **Release 2 Scope**:
  - OOXML to PDF export.
  - Multi-page batch scan and PDF compilation.
  - Advanced spreadsheet formula evaluation.
  - Side-by-side visual diffing of document revisions.

### Decision 3: License & Distribution Compliance
- All approved components (`Apache POI`, `PdfBox-Android`, `OpenCV`, `Tesseract`, `Drift`, `Riverpod`) operate exclusively under **Tier 1 Permissive Licenses (Apache-2.0, MIT, BSD-3-Clause)**.
- Zero GPL/AGPL copyleft contamination. 100% compliant with offline, standalone distribution.

---

## 5. Tahap 4 Implementation & Verification: PDF Tools

Tahap 4 implemented the complete PDF manipulation toolset atop `PdfBox-Android` and native platform channels, integrating with Flutter UI via `PdfAnnotationController` and `PdfPageEngine`:

### 5.1 Capabilities Delivered
1. **Annotations (`PdfAnnotationEngine`)**:
   - Highlight, Underline, Freehand Ink Drawing, Text Notes, Handwritten Signature.
   - Handwritten signature capture dialog with prominent legal disclaimer: *"Ini BUKAN tanda tangan elektronik tersertifikasi / This is NOT a certified digital signature"*.
   - Signatures saved exclusively in private app support directory (`signatures/`).
2. **Page Operations (`PdfPageEngine`)**:
   - Reorder pages via drag-and-drop or index list.
   - Rotate pages in increments of 90 degrees.
   - Delete pages with safety checks (preventing deleting all pages).
   - Merge multiple external/internal PDF documents into a combined output.
   - Split / Extract page ranges into dedicated output PDFs.
   - Export individual pages to PNG bitmap images.
3. **Save Coordinator Integration**:
   - Default save mode: **Save as New File** (`Save As`) to avoid accidental data loss.
   - Overwrite mode: requires explicit user confirmation dialog and processes atomically through `SaveCoordinator`.
   - Undo/Redo stack and autosave draft JSON to protect unsaved annotations across process death.
4. **Validation & Verification**:
   - 12 unit tests + 6 widget tests added in `test/unit/tahap4_pdf_tools_test.dart` and `test/widget/pdf_tools_widget_test.dart`.
   - 500-page document simulation verified without out-of-memory or frame freeze.
   - 88/88 automated test suites passing.

---

## 6. Tahap 5 Implementation & Verification: Office Editor (Jalur GO)

Tahap 5 executed the **Jalur GO** for the Office engine (Apache POI 5.3.0) via `OfficeEditorEngine` and native Kotlin bridge with background thread crash isolation.

### 6.1 Capabilities Delivered
1. **Thread & Crash Isolation**:
   - All Apache POI execution runs in a dedicated background executor thread (`Executors.newSingleThreadExecutor()`).
   - All calls wrapped in `try { ... } catch (t: Throwable) { ... }`, capturing `OutOfMemoryError` and JVM exceptions safely without crashing the app process.
   - Results dispatched strictly back to Flutter's main looper via `Handler(Looper.getMainLooper())`.
2. **DOCX Structured Editing**:
   - Full block-based editing: Paragraphs, Headings (H1, H2, H3), Tables (multi-row x multi-col grid), Page Breaks, Headers, Footers, and embedded image insertion.
3. **XLSX Spreadsheet Editing**:
   - Multi-sheet management: sheet tabs switching, adding new sheets, renaming sheets.
   - Formula bar (`fx`): supports direct cell coordinate selection (e.g. `A1`), mathematical/statistical formulas (e.g. `=SUM(A1:A10)`), numeric/text inputs.
   - Cell formatting: font bold, italic, numeric & date formatting.
   - Row operations: dynamic row addition and deletion.
4. **Alur Simpan & Autosave Recovery**:
   - Default save mode: **Save As** (new file) to safeguard original documents.
   - Overwrite mode: requires explicit confirmation dialog and atomicity via `SaveCoordinator`.
   - Full Undo / Redo action history stack (`OfficeEditAction`).
   - Autosave draft JSON in sandboxed private support directory (`drafts/`) after every edit mutation.
   - Startup recovery prompt restores unsaved drafts after simulated process termination.
5. **Adaptive UI**:
   - Phone (<600dp): Contextual bottom toolbar with quick format/insert and Save actions.
   - Tablet (>=600dp): Scrollable top ribbon bar with grouped commands (Edit, Sisipkan, Format, File).
   - Hardware keyboard shortcuts: `Ctrl+Z` (Undo), `Ctrl+Y` (Redo), `Ctrl+S` (Save).
6. **Mandatory Verification Cycle**:
   - Tested against `synth_simple.docx` and `synth_simple.xlsx`.
   - Original fixture files verified 100% byte-identical after edit cycles.
   - 10 unit tests + 5 widget tests in `test/unit/tahap5_office_editor_test.dart` and `test/widget/office_editor_widget_test.dart`.
   - 103/103 automated tests passing.


