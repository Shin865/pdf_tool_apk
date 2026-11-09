# Spike C — Scanner & OCR Evaluation

## Status: 🔲 Not started (Phase 1)

## Objective
Validate OpenCV-based document scanning and Tesseract OCR (Indonesian + English)
accuracy and performance on real-world mobile photos.

## Pass/Fail Criteria (written BEFORE coding)
| Metric | Pass | Fail |
|---|---|---|
| OCR accuracy — clean printed text | > 90% character accuracy | ≤ 90% |
| OCR accuracy — poor quality (shadow/skew) | > 75% character accuracy | ≤ 75% |
| Processing time per page (full pipeline) | < 5 s on mid-range device | ≥ 5 s |
| Edge detection success rate | > 85% on test set | ≤ 85% |
| Perspective correction quality | Visually acceptable | Visible distortion |
| APK size delta (OpenCV + tessdata) | < 30 MB | ≥ 30 MB |
| License | Apache-2.0 / BSD | GPL / AGPL |

## Candidates / Components
| Component | Version | License | Notes |
|---|---|---|---|
| OpenCV Android | 4.x | Apache-2.0 | Edge detection, warp perspective |
| Tesseract 5 (tess4j/tflite) | 5.x | Apache-2.0 | OCR engine |
| tessdata (eng) | Latest | Apache-2.0 | English language model |
| tessdata (ind) | Latest | Apache-2.0 | Indonesian language model |

## Test Image Set (to be created)
Place test images in `test/fixtures/scanner/`:
- `clean_portrait.jpg` — straight, good lighting
- `skewed_15deg.jpg` — 15° rotation
- `skewed_30deg.jpg` — 30° rotation
- `shadowed.jpg` — partial shadow
- `dim_light.jpg` — low exposure
- `crumpled.jpg` — wrinkled paper
- `handwritten.jpg` — handwritten text (OCR negative test)

## Procedure (to be executed)
1. Create `spikes/spike_c_scanner/` as minimal Flutter + Android app
2. Integrate OpenCV via `opencv_dart` or direct AAR
3. Integrate Tesseract via `flutter_tesseract_ocr` or JNI
4. Bundle tessdata for `eng` and `ind` in `assets/ocr/`
5. Run pipeline on all 7 test images
6. Measure and record character error rate (CER) and processing time

## Results
> 🔲 Not yet executed.

## Recommendation
> 🔲 Pending spike execution.

