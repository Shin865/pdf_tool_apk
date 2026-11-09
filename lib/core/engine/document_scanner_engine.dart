/// Abstract interface for document scanning via camera.
///
/// Implementations use OpenCV or similar for edge detection,
/// perspective correction, and image enhancement.
library;

import 'dart:typed_data';

/// Filter modes for scanned documents.
enum ScanFilterMode {
  original,
  magicColor,
  grayscale,
  blackWhite,
}

/// Export quality for generated PDFs.
enum ScanExportQuality {
  low,
  medium,
  high,
}

/// Parameters for scan post-processing.
class ScanProcessingOptions {
  const ScanProcessingOptions({
    this.autoDetectEdges = true,
    this.perspectiveCorrection = true,
    this.enhanceContrast = true,
    this.convertToGrayscale = false,
    this.adaptiveThreshold = false,
    this.denoise = true,
    this.targetDpi = 300,
  });

  final bool autoDetectEdges;
  final bool perspectiveCorrection;
  final bool enhanceContrast;
  final bool convertToGrayscale;
  final bool adaptiveThreshold;
  final bool denoise;

  /// Target DPI for the output image.
  final int targetDpi;
}

/// A detected document edge/contour in an image.
class DetectedEdge {
  const DetectedEdge({
    required this.corners,
    required this.confidence,
  });

  /// Four corner points [[x,y], ...] in clockwise order from top-left.
  final List<List<double>> corners;

  /// Detection confidence (0.0 to 1.0).
  final double confidence;
}

/// Result of a scan processing operation.
class ScanResult {
  const ScanResult({
    required this.processedImagePath,
    required this.originalImagePath,
    required this.processingTimeMs,
    this.detectedEdge,
    this.width,
    this.height,
  });

  final String processedImagePath;
  final String originalImagePath;

  /// Time taken to process in milliseconds.
  final int processingTimeMs;

  final DetectedEdge? detectedEdge;
  final int? width;
  final int? height;
}

/// Abstract engine for document scanning operations.
///
/// All processing must run off the main thread.
abstract class DocumentScannerEngine {
  /// Initializes the scanner engine (loads native libraries, etc.).
  Future<void> initialize();

  /// Detects document edges in the image at [imagePath].
  ///
  /// Returns null if no document boundary is detected.
  Future<DetectedEdge?> detectEdges({required String imagePath});

  /// Detects document edges in raw image bytes (for live camera preview).
  Future<DetectedEdge?> detectEdgesFromBytes({
    required Uint8List imageBytes,
    required int width,
    required int height,
  });

  /// Processes a captured image: edge detection, perspective correction,
  /// contrast enhancement, etc.
  Future<ScanResult> processImage({
    required String imagePath,
    ScanProcessingOptions options = const ScanProcessingOptions(),
    DetectedEdge? manualEdge,
  });

  /// Warps perspective using 4 corner coordinates and writes to [outputPath].
  Future<String> warpPerspective({
    required String imagePath,
    required List<List<double>> corners,
    required String outputPath,
  });

  /// Applies document enhancement filter to image.
  Future<String> applyFilter({
    required String imagePath,
    required ScanFilterMode filter,
    required String outputPath,
  });

  /// Rotates image by [degrees] (90, 180, 270) and writes to [outputPath].
  Future<String> rotateImage({
    required String imagePath,
    required int degrees,
    required String outputPath,
  });

  /// Combines multiple scanned pages into a single PDF with [quality].
  Future<String> combineToPdf({
    required List<String> imagePaths,
    required String outputPath,
    ScanExportQuality quality = ScanExportQuality.medium,
  });

  /// Returns whether the engine is initialized.
  bool get isInitialized;

  /// Releases all native resources.
  Future<void> dispose();
}
