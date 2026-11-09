import 'dart:async';
import 'dart:io';

import 'package:document_reviewer/app/providers.dart';
import 'package:document_reviewer/core/engine/document_scanner_engine.dart';
import 'package:document_reviewer/core/engine/ocr_engine.dart';
import 'package:document_reviewer/features/scanner/models/scanned_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scanner viewing mode for active page.
enum ScannerViewMode {
  cropAdjust,
  filterPreview,
}

/// State of the Document Scanner feature.
class ScannerState {
  const ScannerState({
    this.pages = const [],
    this.currentPageIndex = 0,
    this.viewMode = ScannerViewMode.filterPreview,
    this.isProcessing = false,
    this.ocrProgress,
    this.isOcrCancelled = false,
    this.activeOcrResult,
    this.errorMessage,
  });

  final List<ScannedPage> pages;
  final int currentPageIndex;
  final ScannerViewMode viewMode;
  final bool isProcessing;
  final double? ocrProgress;
  final bool isOcrCancelled;
  final OcrResult? activeOcrResult;
  final String? errorMessage;

  ScannedPage? get currentPage => pages.isNotEmpty &&
          currentPageIndex >= 0 &&
          currentPageIndex < pages.length
      ? pages[currentPageIndex]
      : null;

  ScannerState copyWith({
    List<ScannedPage>? pages,
    int? currentPageIndex,
    ScannerViewMode? viewMode,
    bool? isProcessing,
    double? ocrProgress,
    bool clearOcrProgress = false,
    bool? isOcrCancelled,
    OcrResult? activeOcrResult,
    bool clearActiveOcr = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ScannerState(
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      viewMode: viewMode ?? this.viewMode,
      isProcessing: isProcessing ?? this.isProcessing,
      ocrProgress: clearOcrProgress ? null : (ocrProgress ?? this.ocrProgress),
      isOcrCancelled: isOcrCancelled ?? this.isOcrCancelled,
      activeOcrResult:
          clearActiveOcr ? null : (activeOcrResult ?? this.activeOcrResult),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// State notifier managing the multi-page scanner and OCR pipeline.
class ScannerController extends StateNotifier<ScannerState> {
  ScannerController({
    required DocumentScannerEngine scannerEngine,
    required OcrEngine ocrEngine,
  })  : _scannerEngine = scannerEngine,
        _ocrEngine = ocrEngine,
        super(const ScannerState());

  final DocumentScannerEngine _scannerEngine;
  final OcrEngine _ocrEngine;

  void setViewMode(ScannerViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void setCurrentPageIndex(int index) {
    if (index >= 0 && index < state.pages.length) {
      state = state.copyWith(currentPageIndex: index);
    }
  }

  /// Adds a new page from an image file path.
  /// Automatically runs edge detection and initial perspective warping.
  Future<void> addPage(
    String originalImagePath, {
    List<List<double>>? customCorners,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      final detected = customCorners != null
          ? DetectedEdge(corners: customCorners, confidence: 1)
          : await _scannerEngine.detectEdges(imagePath: originalImagePath);

      final corners = detected?.corners ??
          [
            [0.0, 0.0],
            [800.0, 0.0],
            [800.0, 1000.0],
            [0.0, 1000.0],
          ];

      final tempDir = Directory.systemTemp.path;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final warpedPath = '$tempDir/warped_$timestamp.jpg';

      final warpedResultPath = await _scannerEngine.warpPerspective(
        imagePath: originalImagePath,
        corners: corners,
        outputPath: warpedPath,
      );

      final newPage = ScannedPage(
        id: timestamp.toString(),
        originalImagePath: originalImagePath,
        corners: corners,
        warpedImagePath: warpedResultPath,
        filteredImagePath: warpedResultPath,
        width: 800,
        height: 1000,
      );

      final updatedPages = [...state.pages, newPage];
      state = state.copyWith(
        pages: updatedPages,
        currentPageIndex: updatedPages.length - 1,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Gagal memproses gambar: $e',
      );
    }
  }

  /// Updates quad corners for page at [index] and re-warps perspective.
  Future<void> updateCorners(int index, List<List<double>> newCorners) async {
    if (index < 0 || index >= state.pages.length) return;

    final targetPage = state.pages[index];
    state = state.copyWith(isProcessing: true);

    try {
      final tempDir = Directory.systemTemp.path;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final warpedPath = '$tempDir/warped_${timestamp}_$index.jpg';

      final warpedResultPath = await _scannerEngine.warpPerspective(
        imagePath: targetPage.originalImagePath,
        corners: newCorners,
        outputPath: warpedPath,
      );

      // Re-apply filter if active
      var finalPath = warpedResultPath;
      if (targetPage.filterMode != ScanFilterMode.original) {
        final filterPath = '$tempDir/filtered_${timestamp}_$index.jpg';
        finalPath = await _scannerEngine.applyFilter(
          imagePath: warpedResultPath,
          filter: targetPage.filterMode,
          outputPath: filterPath,
        );
      }

      final updated = targetPage.copyWith(
        corners: newCorners,
        warpedImagePath: warpedResultPath,
        filteredImagePath: finalPath,
      );

      final updatedPages = List<ScannedPage>.from(state.pages)
        ..[index] = updated;
      state = state.copyWith(
        pages: updatedPages,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Gagal memperbarui sudut: $e',
      );
    }
  }

  /// Applies document filter (Original, Magic Color, Grayscale, B&W) to page at [index].
  Future<void> applyFilter(int index, ScanFilterMode filter) async {
    if (index < 0 || index >= state.pages.length) return;

    final targetPage = state.pages[index];
    state = state.copyWith(isProcessing: true);

    try {
      final tempDir = Directory.systemTemp.path;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '$tempDir/filter_${timestamp}_$index.jpg';

      final resultPath = await _scannerEngine.applyFilter(
        imagePath: (targetPage.warpedImagePath != null &&
                targetPage.warpedImagePath!.isNotEmpty)
            ? targetPage.warpedImagePath!
            : targetPage.originalImagePath,
        filter: filter,
        outputPath: outputPath,
      );

      final updated = targetPage.copyWith(
        filterMode: filter,
        filteredImagePath: resultPath,
      );

      final updatedPages = List<ScannedPage>.from(state.pages)
        ..[index] = updated;
      state = state.copyWith(
        pages: updatedPages,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Gagal menerapkan filter: $e',
      );
    }
  }

  /// Rotates image of page at [index] by 90 degrees clockwise.
  Future<void> rotatePage(int index, {int degrees = 90}) async {
    if (index < 0 || index >= state.pages.length) return;

    final targetPage = state.pages[index];
    state = state.copyWith(isProcessing: true);

    try {
      final currentDisplay = targetPage.displayPath;
      final tempDir = Directory.systemTemp.path;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '$tempDir/rotated_${timestamp}_$index.jpg';

      final resultPath = await _scannerEngine.rotateImage(
        imagePath: currentDisplay,
        degrees: degrees,
        outputPath: outputPath,
      );

      final newDegrees = (targetPage.rotationDegrees + degrees) % 360;
      final updated = targetPage.copyWith(
        rotationDegrees: newDegrees,
        filteredImagePath: resultPath,
      );

      final updatedPages = List<ScannedPage>.from(state.pages)
        ..[index] = updated;
      state = state.copyWith(
        pages: updatedPages,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Gagal memutar gambar: $e',
      );
    }
  }

  /// Reorders pages in the document.
  void reorderPages(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= state.pages.length ||
        newIndex < 0 ||
        newIndex > state.pages.length) {
      return;
    }

    final pages = List<ScannedPage>.from(state.pages);
    var targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }
    final item = pages.removeAt(oldIndex);
    pages.insert(targetIndex, item);

    state = state.copyWith(
      pages: pages,
      currentPageIndex: targetIndex,
    );
  }

  /// Removes page at [index].
  void removePage(int index) {
    if (index < 0 || index >= state.pages.length) return;

    final pages = List<ScannedPage>.from(state.pages)..removeAt(index);
    final nextIndex = pages.isEmpty
        ? 0
        : (state.currentPageIndex >= pages.length
            ? pages.length - 1
            : state.currentPageIndex);

    state = state.copyWith(
      pages: pages,
      currentPageIndex: nextIndex,
    );
  }

  /// Exports all pages to a single PDF document.
  Future<String?> exportToPdf({
    required String outputPath,
    ScanExportQuality quality = ScanExportQuality.medium,
  }) async {
    if (state.pages.isEmpty) return null;

    state = state.copyWith(isProcessing: true);
    try {
      final imagePaths = state.pages.map((p) => p.displayPath).toList();
      final result = await _scannerEngine.combineToPdf(
        imagePaths: imagePaths,
        outputPath: outputPath,
        quality: quality,
      );
      state = state.copyWith(isProcessing: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Gagal mengekspor PDF: $e',
      );
      return null;
    }
  }

  /// Runs OCR text recognition on page at [index].
  Future<OcrResult?> runOcr({
    required int index,
    OcrLanguage language = OcrLanguage.indonesianAndEnglish,
  }) async {
    if (index < 0 || index >= state.pages.length) return null;

    final targetPage = state.pages[index];
    state = state.copyWith(
      ocrProgress: 0.1,
      isOcrCancelled: false,
      clearActiveOcr: true,
    );

    try {
      if (state.isOcrCancelled) {
        state = state.copyWith(clearOcrProgress: true);
        return null;
      }

      state = state.copyWith(ocrProgress: 0.5);

      final result = await _ocrEngine.recognizeFromFile(
        imagePath: targetPage.displayPath,
        language: language,
      );

      if (state.isOcrCancelled) {
        state = state.copyWith(clearOcrProgress: true);
        return null;
      }

      final updated = targetPage.copyWith(ocrResult: result);
      final updatedPages = List<ScannedPage>.from(state.pages)
        ..[index] = updated;

      state = state.copyWith(
        pages: updatedPages,
        ocrProgress: 1,
        activeOcrResult: result,
      );

      return result;
    } catch (e) {
      state = state.copyWith(
        clearOcrProgress: true,
        errorMessage: 'Gagal menjalankan OCR: $e',
      );
      return null;
    } finally {
      state = state.copyWith(clearOcrProgress: true);
    }
  }

  /// Runs batch OCR across all scanned pages.
  Future<void> runBatchOcr({
    OcrLanguage language = OcrLanguage.indonesianAndEnglish,
    void Function(double progress)? onProgress,
  }) async {
    if (state.pages.isEmpty) return;

    state = state.copyWith(isOcrCancelled: false);
    final total = state.pages.length;

    for (var i = 0; i < total; i++) {
      if (state.isOcrCancelled) break;

      final progress = i / total;
      state = state.copyWith(ocrProgress: progress);
      onProgress?.call(progress);

      await runOcr(index: i, language: language);
    }

    state = state.copyWith(clearOcrProgress: true);
    onProgress?.call(1);
  }

  /// Cancels ongoing OCR execution.
  void cancelOcr() {
    state = state.copyWith(isOcrCancelled: true, clearOcrProgress: true);
  }

  /// Creates a searchable PDF for page at [index].
  Future<String?> createSearchablePdf({
    required int index,
    required String outputPath,
  }) async {
    if (index < 0 || index >= state.pages.length) return null;

    final targetPage = state.pages[index];
    final ocr = targetPage.ocrResult ?? await runOcr(index: index);
    if (ocr == null) return null;

    state = state.copyWith(isProcessing: true);
    try {
      final res = await _ocrEngine.createSearchablePdf(
        imagePath: targetPage.displayPath,
        ocrResult: ocr,
        outputPath: outputPath,
      );
      state = state.copyWith(isProcessing: false);
      return res;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Gagal membuat Searchable PDF: $e',
      );
      return null;
    }
  }
}

/// Provider for scanner controller.
final scannerControllerProvider =
    StateNotifierProvider<ScannerController, ScannerState>((ref) {
  return ScannerController(
    scannerEngine: ref.watch(documentScannerEngineProvider),
    ocrEngine: ref.watch(ocrEngineProvider),
  );
});
