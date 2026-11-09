import 'package:document_reviewer/core/engine/document_scanner_engine.dart';
import 'package:document_reviewer/core/engine/ocr_engine.dart';

/// Represents a scanned document page with its original and processed states.
class ScannedPage {
  const ScannedPage({
    required this.id,
    required this.originalImagePath,
    required this.corners,
    this.warpedImagePath,
    this.filteredImagePath,
    this.filterMode = ScanFilterMode.original,
    this.rotationDegrees = 0,
    this.width = 0,
    this.height = 0,
    this.ocrResult,
    this.isProcessing = false,
  });

  final String id;
  final String originalImagePath;
  final List<List<double>> corners;
  final String? warpedImagePath;
  final String? filteredImagePath;
  final ScanFilterMode filterMode;
  final int rotationDegrees;
  final int width;
  final int height;
  final OcrResult? ocrResult;
  final bool isProcessing;

  /// Effective image path to display (filtered > warped > original).
  String get displayPath =>
      filteredImagePath ?? warpedImagePath ?? originalImagePath;

  ScannedPage copyWith({
    String? id,
    String? originalImagePath,
    List<List<double>>? corners,
    String? warpedImagePath,
    String? filteredImagePath,
    ScanFilterMode? filterMode,
    int? rotationDegrees,
    int? width,
    int? height,
    OcrResult? ocrResult,
    bool? isProcessing,
  }) {
    return ScannedPage(
      id: id ?? this.id,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      corners: corners ?? this.corners,
      warpedImagePath: warpedImagePath ?? this.warpedImagePath,
      filteredImagePath: filteredImagePath ?? this.filteredImagePath,
      filterMode: filterMode ?? this.filterMode,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      width: width ?? this.width,
      height: height ?? this.height,
      ocrResult: ocrResult ?? this.ocrResult,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
