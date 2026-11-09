# Document Reviewer — Product Specification

## 1. Vision & Core Principles

### 1.1 Vision
**Document Reviewer** is an offline-first, privacy-respecting document viewer, annotator, and editor built for Android. The application provides complete data sovereignty to users by processing all files strictly on-device without telemetry, external servers, advertising, or account requirements. It bridges the gap between high-performance native document processing engines and a modern, accessible Flutter user interface.

### 1.2 Core Principles
1. **Privacy-First (Zero Leaks)**: Not a single byte of user data or document content ever leaves the physical device. The app operates with zero network dependencies.
2. **No Ads, No Trackers**: No advertising SDKs, no behavioral tracking, no third-party crash reporting frameworks, and no marketing telemetry.
3. **No Accounts, No Barriers**: Instant utility out-of-the-box. Users do not sign in, register, link email accounts, or configure cloud profiles.
4. **No Backend Dependency**: All rendering, parsing, indexing, OCR, and editing tasks execute locally using device CPU, GPU, and native libraries.
5. **Permissive Licensing**: Core software and all third-party dependencies are governed strictly by permissive open-source licenses (MIT, BSD-3-Clause, Apache-2.0), guaranteeing architectural freedom and clean distribution.
6. **Data Integrity & Non-Destructive Editing**: The application adheres to an atomic edit-verification cycle. User documents are never corrupted by unexpected crashes or incomplete write operations.

---

## 2. Target Audience & User Personas

| Persona | Key Needs | Primary Pain Points Solved |
|---|---|---|
| **Confidentiality-Bound Professionals**<br>*(Legal, Medical, Financial)* | Viewing, signing, and annotating NDAs, patient records, contracts, and financial statements offline. | Eliminates compliance risks associated with cloud-connected PDF apps that upload files for OCR or rendering. |
| **Students & Academics** | Reading extensive research papers (PDFs), highlighting text, adding margin notes, reading DOCX/PPTX lecture slides. | Fast navigation across large documents, high-fidelity vector rendering, and zero battery-draining background trackers. |
| **Field & Off-Grid Operators**<br>*(Maritime, Aviation, Remote Engineering)* | Accessing technical manuals, schematics, and inspection spreadsheets in environments without cellular or Wi-Fi connectivity. | Reliable offline document loading, smooth pan/zoom on large technical drawings, and zero reliance on server authentication tokens. |
| **General Privacy-Conscious Users** | Clean document viewing and basic document scanning without subscriptions, watermarks, or intrusive permission prompts. | No subscription paywalls, no "sign in to export" traps, no ad banners obscuring content. |

---

## 3. Scope & Feature Specifications

### 3.1 Document Viewing & Navigation
- **Supported Formats**:
  - Portable Document Format: `PDF`
  - Microsoft Office: `DOCX`, `XLSX`, `PPTX`
  - OpenDocument Formats: `ODT`, `ODS`, `ODP`
  - Plain Text & Rich Text: `TXT`, `RTF`, `CSV`, `LOG`, `MD`
  - Raster Images: `JPEG`, `PNG`, `TIFF`, `BMP`, `WEBP`
- **Navigation Controls**:
  - Continuous vertical scroll and single-page horizontal flip modes.
  - Document outline / Table of Contents (TOC) hierarchy tree with one-tap jumping.
  - Interactive visual page thumbnail grid and scrub bar with rapid page previews.
  - Deep-zoom viewport: Smooth Pinch-to-Zoom supporting up to 800% magnification with anti-aliasing.
  - Fast in-document text search with keyword highlighting, match counters, and instant navigation.
  - Orientation locking, dark mode reading filters, and inverted contrast for night reading.

### 3.2 PDF Annotation & Markup Suite
- **Text Markup**:
  - Text selection highlight, underline, strike-through, and squiggly mark.
  - Configurable palette (HEX colors, predefined pastel markers, and opacity sliders).
- **Ink & Stylus Drawing**:
  - Pressure-sensitive freehand drawing tool with palm rejection support.
  - Variable line widths, pen types (fountain pen, ballpoint, marker), and color palettes.
- **Signatures & Stamps**:
  - Secure local vector signature capture pad.
  - Signature library stored encrypted/sandboxed locally for quick reuse across forms.
  - Pre-defined and custom rubber stamps (e.g., "APPROVED", "DRAFT", "CONFIDENTIAL", date stamps).
- **Sticky Notes & Geometric Shapes**:
  - Anchored sticky comment notes with timestamp and editing history.
  - Shape tools: rectangles, bounding boxes, ellipses, straight lines, and directional arrows.
- **Annotation Management**:
  - Comprehensive annotation drawer listing all comments, marks, and signatures.
  - Capability to export annotations to a standalone summary report.

### 3.3 Office Document Editing (Word & Spreadsheet)
- **Word Processor (`DOCX`)**:
  - Basic WYSIWYG text formatting: Font family, font size, bold, italic, underline, strikeout, text color, and background highlight.
  - Paragraph formatting: Left, center, right, justified alignment, line spacing, and bulleted/numbered lists.
  - Content insertion: Images, horizontal dividers, and tables.
- **Spreadsheet Editor (`XLSX`)**:
  - Interactive grid view with touch-friendly cell selection, drag handles, and multi-cell ranges.
  - Cell data entry for strings, numbers, dates, and formulas.
  - Formula computation engine: Core mathematical and statistical formulas (`SUM`, `AVERAGE`, `MIN`, `MAX`, `COUNT`, `IF`).
  - Row and column manipulation: Insert, delete, hide, resize width/height.
  - Multi-sheet workbook navigation (tabs for sheet switching, renaming, adding, and deleting).
- **Edit Verification Cycle**:
  - Pre-save structural validation: Ensures modified DOM/XML conforms strictly to OpenXML standards.
  - Atomic write execution: Modifies a working copy, validates file integrity, and replaces the target document atomically.

### 3.4 Camera Document Scanner
- **Live Viewfinder & Edge Detection**:
  - Native camera viewfinder leveraging OpenCV for real-time document contour tracking.
  - Automatic frame capture upon steady edge stabilization.
- **Perspective Correction & Enhancement**:
  - 4-point quadrilateral warp and de-skewing algorithms.
  - Clean-up processing filters:
    - *Magic Color*: Enhances text clarity while balancing white background.
    - *High-Contrast B&W*: Threshold binarization optimized for OCR and black-and-white printing.
    - *Grayscale*: Retains gradient details without color noise.
    - *Shadow Removal*: Normalizes uneven ambient lighting across captured pages.
- **Batch Scanning**:
  - Multi-page document acquisition workflow with page reordering, rotation, and deletion.

### 3.5 Optical Character Recognition (OCR)
- **Engine**: On-device native Tesseract OCR engine integrated via C++/JNI.
- **Bundled Language Packs**:
  - Indonesian (`ind.traineddata`)
  - English (`eng.traineddata`)
- **Deliverables**:
  - Searchable "Sandwich" PDF: Creates a PDF overlaying invisible, selectable text directly above the scanned image.
  - Plain Text Extraction: Extracts structured text blocks directly to a `.txt` file or system clipboard.
  - Selective OCR: Bounding-box OCR selection for specific paragraphs or tables within scanned pages.

### 3.6 File Conversion & Export
- Document to PDF conversion (DOCX, XLSX, TXT, Images to standard PDF/A compliant documents).
- PDF page manipulations: Split document by page ranges, merge multiple PDFs into one, extract specific pages, rotate pages, and delete pages.
- PDF to image rasterization (export pages as high-resolution PNG or JPEG files).
- Native Android Print Framework integration for direct Wi-Fi/Direct-to-printer execution.

### 3.7 Storage Access Framework (SAF) & File Management
- **SAF First**: Seamless integration with Android's `DocumentsContract` and `StorageAccessFramework` (`ACTION_OPEN_DOCUMENT`, `ACTION_OPEN_DOCUMENT_TREE`, `ACTION_CREATE_DOCUMENT`).
- **Persistable Permissions**: Retains persistent URI permissions (`takePersistableUriPermission`) to re-open user-selected files and directories across app restarts.
- **Recent Files & Bookmarks**: Local metadata database tracking recently opened files, reading progress, page bookmarks, and user tags.
- **Internal Scratch Staging**: Secure private cache sandbox for temporary file manipulation, ensuring external storage is touched only during explicit user save actions.

### 3.8 Backup & Restore
- Full offline backup of application state (reading history, bookmarks, cached signatures, custom stamps, and app preferences) packaged into an encrypted or unencrypted `.drbackup` ZIP archive.
- Instant restore functionality with schema-version validation.

---

## 4. Non-Goals (Explicit Exclusions)

To maintain focus, security, and an uncluttered user experience, the following features are explicitly out of scope:
- **Cloud Synchronization**: No built-in syncing with Google Drive, Dropbox, OneDrive, iCloud, or custom WebDAV servers. File syncing is delegated to system-level Android file sync providers (e.g., Syncthing, Nextcloud app via SAF).
- **Accounts & Social Features**: No user profiles, collaboration channels, team sharing, commenting threads across users, or chat functionality.
- **Telemetry & Analytics**: No Google Analytics, Firebase, Sentry, Mixpanel, or custom heartbeat services.
- **Digital Rights Management (DRM)**: No proprietary DRM locks, licensing servers, or encrypted document containers that restrict user ownership.
- **In-App Advertisements**: No banner ads, interstitial popups, native ads, or affiliate offers.

---

## 5. Target Platform & Technical Constraints

| Parameter | Specification | Notes |
|---|---|---|
| **Operating System** | Android Only | Tailored specifically to Android UX guidelines and Android storage architecture. |
| **Minimum SDK** | API Level 26 (Android 8.0 Oreo) | Ensures compatibility with modern Java 8+ APIs, SAF features, and 95%+ of active Android devices. |
| **Target / Compile SDK**| API Level 35 / 36 | Fully compliant with the latest Google Play Store requirements and modern security sandboxing. |
| **Primary Architecture**| `arm64-v8a` | Primary target for 64-bit modern mobile performance; secondary support for `armeabi-v7a` and `x86_64` (emulator). |
| **Storage Architecture**| Scoped Storage & SAF | Strictly uses Android SAF for external files; no legacy `MANAGE_EXTERNAL_STORAGE` permission required unless strictly needed for directory batch processing. |
| **Memory Ceiling** | Peak RAM < 250MB | Strict memory bounding for PDF page caches and image rasterization to prevent OOM errors on entry-level Android hardware. |
| **Threading Model** | Main UI Thread Unblocked | All I/O, parsing, rendering, and OCR tasks are isolated to background Dart isolates or native thread pools. |
