/// Abstract interface for Optical Character Recognition (OCR).
///
/// Implementations use Tesseract or native OCR engines with locally
/// bundled language data (no network calls).
library;

import 'dart:typed_data';

/// Supported OCR languages.
enum OcrLanguage {
  english('eng'),
  indonesian('ind'),
  indonesianAndEnglish('ind+eng');

  const OcrLanguage(this.tessCode);

  /// Tesseract language code.
  final String tessCode;
}

/// Confidence level for OCR results.
enum OcrConfidence {
  high, // > 90%
  medium, // 70-90%
  low, // < 70%
}

/// A recognized text block from OCR.
class OcrTextBlock {
  const OcrTextBlock({
    required this.text,
    required this.confidence,
    required this.boundingBox,
    this.language,
  });

  final String text;

  /// Confidence as a percentage (0-100).
  final double confidence;

  /// Bounding box [left, top, right, bottom] in image coordinates.
  final List<double> boundingBox;

  final OcrLanguage? language;

  OcrConfidence get confidenceLevel {
    if (confidence > 90) return OcrConfidence.high;
    if (confidence > 70) return OcrConfidence.medium;
    return OcrConfidence.low;
  }
}

/// Full OCR result for a single page/image.
class OcrResult {
  const OcrResult({
    required this.fullText,
    required this.blocks,
    required this.processingTimeMs,
    required this.imageWidth,
    required this.imageHeight,
  });

  final String fullText;
  final List<OcrTextBlock> blocks;

  /// Time taken to process this image in milliseconds.
  final int processingTimeMs;

  final int imageWidth;
  final int imageHeight;

  /// Average confidence across all blocks.
  double get averageConfidence {
    if (blocks.isEmpty) return 0;
    return blocks.map((b) => b.confidence).reduce((a, b) => a + b) /
        blocks.length;
  }
}

/// Abstract engine for OCR operations.
///
/// All processing must run off the main thread.
/// Language data (tessdata) is bundled in assets/ocr/.
abstract class OcrEngine {
  /// Initializes the engine with the specified [languages].
  ///
  /// [tessdataPath] points to the directory containing .traineddata files.
  Future<void> initialize({
    required String tessdataPath,
    required List<OcrLanguage> languages,
  });

  /// Performs OCR on the image at [imagePath].
  Future<OcrResult> recognizeFromFile({
    required String imagePath,
    OcrLanguage language = OcrLanguage.indonesianAndEnglish,
  });

  /// Performs OCR on raw image bytes.
  Future<OcrResult> recognizeFromBytes({
    required Uint8List imageBytes,
    required int width,
    required int height,
  });

  /// Performs OCR on a specific region of an image.
  Future<OcrResult> recognizeRegion({
    required String imagePath,
    required List<double> region, // [left, top, right, bottom]
  });

  /// Generates a Searchable PDF with invisible text layer atop the image.
  Future<String> createSearchablePdf({
    required String imagePath,
    required OcrResult ocrResult,
    required String outputPath,
  });

  /// Returns whether the engine is initialized and ready.
  bool get isInitialized;

  /// Returns the currently loaded languages.
  List<OcrLanguage> get loadedLanguages;

  /// Releases all native resources.
  Future<void> dispose();
}
