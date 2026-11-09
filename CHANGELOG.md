# Changelog

All notable changes to **Document Reviewer** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-11-09

### Added
- **Core Architecture & Offline Guarantee**:
  - 100% offline document processor for Android (minSdk 26, targetSdk 36).
  - Explicit removal of `INTERNET` and `ACCESS_NETWORK_STATE` permissions.
  - Deep Storage Access Framework (SAF) integration with persistable URI permissions.
  - Fail-safe `SaveCoordinator` with scratch working copy isolation, dirty-state recovery, and atomic commit.
  - SQLite database layer using Drift with indexed recents, bookmarks, and version history.
- **Document Viewing & Reading**:
  - High-performance PDF renderer with LRU bitmap tile cache and dynamic memory adaptation.
  - Microsoft Word (`.docx`) and Excel (`.xlsx`) structured document viewer.
  - High-throughput CSV streaming reader capable of parsing 500,000+ rows with low memory overhead.
  - Image viewer for JPEG, PNG, WEBP, and BMP with automatic EXIF orientation.
- **PDF Tools & Annotation Suite**:
  - In-place PDF annotations: text highlight, underline, freehand pen drawing, text callouts, and image signatures.
  - PDF page management: reorder, rotate, delete, merge multiple PDFs, and split page ranges.
  - Draft autosave and crash recovery across unexpected process terminations.
- **Office Document Editing**:
  - Structured DOCX editing: paragraphs, headings (H1-H3), tables, headers/footers, and page breaks.
  - Multi-sheet XLSX spreadsheet editing: cell values, basic formulas, cell formatting, row add/delete, and sheet renaming.
  - Edit Verification Cycle ensuring 100% file integrity and byte safety of original documents.
- **Mobile Document Scanner & Local OCR**:
  - Real-time camera viewfinder (CameraX) and Photo Picker image import.
  - Automatic quadrilateral edge detection and interactive 4-corner perspective correction.
  - Document enhancement filters: Magic Color, Grayscale, High Contrast B&W, and Original.
  - Completely offline on-device OCR using Tesseract v5 with bundled Indonesian (`ind`) and English (`eng`) neural models.
- **Security & Backup**:
  - Optional App Lock with SHA-256 salted PIN and Android `BiometricPrompt` fallback.
  - Native `FLAG_SECURE` platform channel to prevent screenshot snooping in sensitive environments.
  - Full application backup and restore (`.drbackup`) with optional PBKDF2-derived AES-256 CTR encryption.
  - Secure wipe action to clear all temporary files, OCR caches, and application database.
- **UI & Accessibility Polish**:
  - Full Material 3 responsive layout with adaptive two-panel view on tablets ($\ge 600\text{dp}$).
  - Dynamic System, Light, and Dark themes.
  - Full localization in Indonesian (`id`) and English (`en`).
  - Screen reader semantic accessibility (TalkBack) and large font scaling support (up to 200%).
- **Compliance & Android 15 Compatibility**:
  - Verification of 16 KB memory page size alignment across all 64-bit ELF shared libraries (`.so`).
  - R8 / ProGuard rules for native JNI bridges, Apache POI, PDFBox, and Tesseract.
