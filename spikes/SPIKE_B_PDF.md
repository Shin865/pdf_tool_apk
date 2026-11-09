# Spike B — PDF Engine Evaluation

## Status: 🔲 Not started (Phase 1)

## Objective
Compare three PDF rendering approaches for quality, performance, and
feature completeness within the Flutter + Android stack.

## Pass/Fail Criteria (written BEFORE coding)
| Metric | Pass | Fail |
|---|---|---|
| Render time per page (1080p) | < 100 ms | ≥ 100 ms |
| Smooth zoom to 5× | 60 fps on Pixel 6 class | < 30 fps |
| Text search (100-page PDF) | < 500 ms | ≥ 500 ms |
| Highlight annotation survives save/reload | ✅ | ❌ |
| Signature overlay survives save/reload | ✅ | ❌ |
| Encrypted PDF (password-protected) | Opens with correct password | Crash/hang |
| Corrupted PDF | Graceful error | Crash |
| License | Apache-2.0 / BSD | GPL / AGPL |

## Candidates
| Candidate | Library | License | Notes |
|---|---|---|---|
| A — Android built-in | `PdfRenderer` (Android API) | Apache-2.0 | Baseline, no annotation |
| B — PDFium | `pdfrx` (Flutter plugin) | BSD-3 | Full-featured, ~8 MB |
| C — PdfBox | `pdfbox-android` | Apache-2.0 | Pure Java, annotation support |

## Procedure (to be executed)
1. Create `spikes/spike_b_pdf/` as minimal Flutter app
2. Load same 5 test PDFs (simple, complex, image-heavy, encrypted, corrupted)
3. Measure render, search, annotation round-trip for each candidate
4. Record results in table below

## Results
> 🔲 Not yet executed.

## Recommendation
> 🔲 Pending spike execution.

