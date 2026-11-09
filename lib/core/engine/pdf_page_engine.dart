/// Abstract interface for PDF page operations.
///
/// Supports rotating, deleting, reordering, merging, splitting,
/// and exporting pages as images.
library;

abstract class PdfPageEngine {
  /// Rotates the page at [pageIndex] by [degrees] (e.g. 90, 180, 270).
  ///
  /// Output is written to [outputPath].
  Future<bool> rotatePage({
    required String filePath,
    required int pageIndex,
    required int degrees,
    required String outputPath,
  });

  /// Deletes pages at the given [pageIndices].
  ///
  /// Output is written to [outputPath].
  Future<bool> deletePages({
    required String filePath,
    required List<int> pageIndices,
    required String outputPath,
  });

  /// Reorders pages according to [newOrder], a list of 0-based page indices.
  ///
  /// Output is written to [outputPath].
  Future<bool> reorderPages({
    required String filePath,
    required List<int> newOrder,
    required String outputPath,
  });

  /// Merges multiple PDF files [filePaths] into a single output at [outputPath].
  Future<bool> mergePdfs({
    required List<String> filePaths,
    required String outputPath,
  });

  /// Splits [filePath] extracting pages from [startPage] to [endPage] (inclusive)
  /// into [outputPath].
  Future<bool> splitPdf({
    required String filePath,
    required int startPage,
    required int endPage,
    required String outputPath,
  });

  /// Renders and exports [pageIndex] as an image (PNG) to [outputPath].
  Future<bool> exportPageToImage({
    required String filePath,
    required int pageIndex,
    required String outputPath,
    double scale = 2.0,
  });
}
