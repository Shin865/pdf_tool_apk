/// Abstract interface for reading and rendering documents.
///
/// Implementations may use native Android APIs (PdfRenderer, PDFium, etc.)
/// via platform channels. UI code depends only on this interface.
library;

import 'dart:typed_data';

/// Metadata extracted from a document.
class DocumentMetadata {
  const DocumentMetadata({
    required this.title,
    required this.pageCount,
    required this.mimeType,
    this.author,
    this.creationDate,
    this.modificationDate,
    this.fileSizeBytes,
    this.isEncrypted = false,
    this.isCorrupted = false,
  });

  final String title;
  final int pageCount;
  final String mimeType;
  final String? author;
  final DateTime? creationDate;
  final DateTime? modificationDate;
  final int? fileSizeBytes;
  final bool isEncrypted;
  final bool isCorrupted;
}

/// A rendered page as raw pixel data.
class RenderedPage {
  const RenderedPage({
    required this.pageIndex,
    required this.width,
    required this.height,
    required this.pixels,
  });

  final int pageIndex;
  final int width;
  final int height;
  final Uint8List pixels;
}

/// Text search result within a document.
class TextSearchResult {
  const TextSearchResult({
    required this.pageIndex,
    required this.text,
    required this.rects,
  });

  final int pageIndex;
  final String text;

  /// Bounding rectangles for highlighted matches (left, top, right, bottom).
  final List<List<double>> rects;
}

/// Abstract engine for opening and rendering documents.
///
/// All methods are async to allow for platform channel communication
/// and background processing. Implementations must NOT run heavy work
/// on the main/UI thread.
abstract class DocumentReaderEngine {
  /// Opens a document from the given [filePath] (working copy, not SAF URI).
  ///
  /// If [password] is provided, attempts to decrypt the document.
  /// Throws an exception on failure.
  Future<DocumentMetadata> openDocument({
    required String filePath,
    String? password,
  });

  /// Renders the page at [pageIndex] at the given [width] and optional [zoom].
  ///
  /// Returns raw pixel data for display.
  Future<RenderedPage> renderPage({
    required int pageIndex,
    required int width,
    double zoom = 1.0,
  });

  /// Extracts plain text content from the page at [pageIndex].
  Future<String> extractText({required int pageIndex});

  /// Searches for [query] across all pages (or specific [pageIndices]).
  ///
  /// Returns results sorted by page index.
  Future<List<TextSearchResult>> searchText({
    required String query,
    List<int>? pageIndices,
    bool caseSensitive = false,
  });

  /// Returns a table of contents / outline, if available.
  Future<List<DocumentOutlineEntry>> getOutline();

  /// Closes the document and releases native resources.
  ///
  /// Must be called when the document is no longer needed.
  Future<void> closeDocument();

  /// Returns the list of MIME types this engine supports.
  List<String> get supportedMimeTypes;
}

/// An entry in the document's table of contents / outline.
class DocumentOutlineEntry {
  const DocumentOutlineEntry({
    required this.title,
    required this.pageIndex,
    this.children = const [],
  });

  final String title;
  final int pageIndex;
  final List<DocumentOutlineEntry> children;
}
