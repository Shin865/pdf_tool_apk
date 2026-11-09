# Document Reviewer — Format Support Matrix

## 1. Overview

This document outlines the supported file formats, intended capabilities, and verification status for Document Reviewer. 

To maintain document integrity and avoid file corruption, all format implementations must pass automated verification suites and the **Edit Verification Cycle** before being marked as verified.

---

## 2. Format Support Matrix

| Format / Extension | MIME Type | Read | Annotate | Edit | Convert to PDF | Print | Target Engine / Strategy |
|---|---|:---:|:---:|:---:|:---:|:---:|---|
| **PDF** (`.pdf`) | `application/pdf` | ✅ Verified | ✅ Verified | ✅ Verified | ❌ Unsupported | 🔲 Not tested | `PdfRenderer` (UI) + `PdfBox-Android` (`PdfAnnotationEngine` & `PdfPageEngine`) |
| **DOCX** (`.docx`) | `application/vnd.openxmlformats-officedocument.wordprocessingml.document` | ✅ Verified | 🔲 Not tested | ✅ Verified | 🔲 Not tested | 🔲 Not tested | Apache POI 5.3.0 (`OfficeEditorEngine`: Paragraphs, headings, tables, page breaks, header/footer) |
| **XLSX** (`.xlsx`) | `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` | ✅ Verified | 🔲 Not tested | ✅ Verified | 🔲 Not tested | 🔲 Not tested | Apache POI 5.3.0 (`OfficeEditorEngine`: Multi-sheet, values, formulas, cell styles, rows) |
| **PPTX** (`.pptx`) | `application/vnd.openxmlformats-officedocument.presentationml.presentation` | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | Slide Rasterizer / POI |
| **ODT** (`.odt`) | `application/vnd.oasis.opendocument.text` | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | ODF Toolkit / XML Parser |
| **ODS** (`.ods`) | `application/vnd.oasis.opendocument.spreadsheet` | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | ODF Toolkit / XML Parser |
| **ODP** (`.odp`) | `application/vnd.oasis.opendocument.presentation` | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | ODF Toolkit / XML Parser |
| **TXT** (`.txt`, `.log`, `.md`) | `text/plain` | ✅ Verified | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | Native Dart UTF-8/UTF-16 Decoder (Line-by-line & chunked) |
| **RTF** (`.rtf`) | `application/rtf` | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | Native RTF Parser / Spanned String |
| **CSV** (`.csv`) | `text/csv` | ✅ Verified | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | Fast CSV Streaming Parser (50k rows tested in <3s) |
| **JPEG** (`.jpg`, `.jpeg`) | `image/jpeg` | ✅ Verified | 🔲 Not tested | ❌ Unsupported | 🔲 Not tested | 🔲 Not tested | Android BitmapFactory / Flutter Image & InteractiveViewer |
| **PNG** (`.png`) | `image/png` | ✅ Verified | 🔲 Not tested | ❌ Unsupported | 🔲 Not tested | 🔲 Not tested | Android BitmapFactory / Flutter Image & InteractiveViewer |
| **TIFF** (`.tiff`, `.tif`) | `image/tiff` | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | 🔲 Not tested | Native LibTIFF / ImageDecoder |
| **BMP** (`.bmp`) | `image/bmp` | ✅ Verified | 🔲 Not tested | ❌ Unsupported | 🔲 Not tested | 🔲 Not tested | Android BitmapFactory / Flutter Image & InteractiveViewer |
| **WEBP** (`.webp`) | `image/webp` | ✅ Verified | 🔲 Not tested | ❌ Unsupported | 🔲 Not tested | 🔲 Not tested | Android BitmapFactory / Flutter Image & InteractiveViewer |
| **Backup Archive** (`.drbackup`) | `application/octet-stream` | ✅ Verified | ❌ Unsupported | ✅ Verified | ❌ Unsupported | ❌ Unsupported | Custom Encrypted/Unencrypted JSON & Tarball Archive (`BackupService`: PBKDF2 + AES-256 CTR) |

---

## 3. Status Legend

- **🔲 Not tested**: The capability is scoped and planned, but has not completed formal test execution or the Edit Verification Cycle.
- **✅ Verified**: Comprehensive automated and manual test suites pass without regression or file corruption.
- **⚠️ Partial / Experimental**: Functional with known limitations (e.g., read-only formatting variances, formula calculation subsets).
- **❌ Unsupported**: Explicitly out of scope or technically non-applicable for this format (e.g., spreadsheet cell editing on a raw JPEG).

---

## 4. The Edit Verification Cycle Requirement

Any feature that performs write or modification operations on existing documents (particularly complex structured files like PDF, DOCX, and XLSX) must enforce the **Edit Verification Cycle**. 

### 4.1 Core Verification Rules
1. **Pre-Edit Snapshot**: Prior to initiating any edit session, the original file is hashed (`SHA-256`) and cloned into an isolated sandboxed working directory.
2. **Intermediate Serialization**: All mutations occur within the working copy. The original source document remains untouched.
3. **Format Integrity Validation**:
   - **PDF**: The generated PDF must pass structural parsing (valid xref table, matching object count, trailer dictionary intact, and no orphaned root nodes).
   - **DOCX / XLSX (OpenXML)**:
     - The output ZIP archive must be fully readable with uncorrupted CRC-32 checksums.
     - Critical XML components (`[Content_Types].xml`, `_rels/.rels`, `word/document.xml`, `xl/workbook.xml`) must validate against their respective schemas.
     - Document DOM must open cleanly in third-party reference parsers without triggering "File is damaged and needs repair" warnings.
   - **Plain Text / CSV**: Verify character encoding integrity (ensure no silent conversion from UTF-8 to ASCII that drops non-Latin glyphs).
4. **Atomic Commit**:
   - The verified output is written to the target SAF URI using an atomic write stream.
   - If an error or system kill occurs at any point before completion, the destination file remains uncorrupted.
5. **Rollback & Diagnostic Fallback**:
   - If structural validation fails, the write operation is aborted immediately.
   - The user is notified with an explicit error description, and the pristine original file is preserved.
   - A diagnostic dump of the failed working copy is retained in the private cache for debugging.
