import 'dart:io';

import 'package:document_reviewer/core/constants/app_constants.dart';
import 'package:document_reviewer/core/engine/document_reader_engine.dart';
import 'package:document_reviewer/core/error/exceptions.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Implementation of [DocumentReaderEngine] delegating to native Android
/// engines (PdfRenderer, PdfBox-Android, and Apache POI) via platform channels.
class NativeDocumentReaderEngine implements DocumentReaderEngine {
  NativeDocumentReaderEngine({
    MethodChannel? engineChannel,
  }) : _channel = engineChannel ??
            const MethodChannel('com.example.documentreviewer/engine');

  final MethodChannel _channel;
  String? _currentFilePath;
  DocumentMetadata? _currentMetadata;

  @override
  List<String> get supportedMimeTypes => [
        SupportedMimeTypes.pdf,
        SupportedMimeTypes.docx,
        SupportedMimeTypes.xlsx,
        SupportedMimeTypes.txt,
        SupportedMimeTypes.csv,
        SupportedMimeTypes.jpeg,
        SupportedMimeTypes.png,
        SupportedMimeTypes.bmp,
      ];

  @override
  Future<DocumentMetadata> openDocument({
    required String filePath,
    String? password,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentNotFoundException(filePath);
    }

    _currentFilePath = filePath;
    final ext = p.extension(filePath).toLowerCase();
    final fileSize = file.lengthSync();
    final title = p.basenameWithoutExtension(filePath);

    try {
      if (ext == '.pdf') {
        final count = await _channel.invokeMethod<int>('pdf_getPageCount', {
          'filePath': filePath,
          if (password != null) 'password': password,
        });

        _currentMetadata = DocumentMetadata(
          title: title,
          pageCount: count ?? 1,
          mimeType: SupportedMimeTypes.pdf,
          fileSizeBytes: fileSize,
          modificationDate: file.lastModifiedSync(),
        );
        return _currentMetadata!;
      } else if (ext == '.docx') {
        final paragraphs = await _channel.invokeMethod<List<dynamic>>(
          'docx_getParagraphs',
          {'filePath': filePath},
        );
        _currentMetadata = DocumentMetadata(
          title: title,
          pageCount: (paragraphs?.length ?? 1) > 0 ? 1 : 0,
          mimeType: SupportedMimeTypes.docx,
          fileSizeBytes: fileSize,
          modificationDate: file.lastModifiedSync(),
        );
        return _currentMetadata!;
      } else if (ext == '.xlsx') {
        final sheets = await _channel.invokeMethod<List<dynamic>>(
          'xlsx_getSheetNames',
          {'filePath': filePath},
        );
        _currentMetadata = DocumentMetadata(
          title: title,
          pageCount: sheets?.length ?? 1,
          mimeType: SupportedMimeTypes.xlsx,
          fileSizeBytes: fileSize,
          modificationDate: file.lastModifiedSync(),
        );
        return _currentMetadata!;
      } else if (ext == '.txt' ||
          ext == '.md' ||
          ext == '.log' ||
          ext == '.csv') {
        _currentMetadata = DocumentMetadata(
          title: title,
          pageCount: 1,
          mimeType:
              ext == '.csv' ? SupportedMimeTypes.csv : SupportedMimeTypes.txt,
          fileSizeBytes: fileSize,
          modificationDate: file.lastModifiedSync(),
        );
        return _currentMetadata!;
      } else {
        // Image formats
        _currentMetadata = DocumentMetadata(
          title: title,
          pageCount: 1,
          mimeType: ext == '.png'
              ? SupportedMimeTypes.png
              : ext == '.bmp'
                  ? SupportedMimeTypes.bmp
                  : SupportedMimeTypes.jpeg,
          fileSizeBytes: fileSize,
          modificationDate: file.lastModifiedSync(),
        );
        return _currentMetadata!;
      }
    } on PlatformException catch (e) {
      if (e.code == 'PASSWORD_REQUIRED' || e.code == 'INVALID_PASSWORD') {
        throw DocumentEncryptedException(filePath);
      }
      throw DocumentCorruptedException(filePath, e.message ?? 'Unknown error');
    }
  }

  @override
  Future<RenderedPage> renderPage({
    required int pageIndex,
    required int width,
    double zoom = 1.0,
  }) async {
    final path = _currentFilePath;
    if (path == null) {
      throw StateError('No document is open');
    }

    final ext = p.extension(path).toLowerCase();
    if (ext == '.pdf') {
      final tempOut =
          '${Directory.systemTemp.path}/rendered_page_${pageIndex}_${DateTime.now().millisecondsSinceEpoch}.png';
      try {
        final res = await _channel.invokeMapMethod<String, dynamic>(
          'pdf_renderPage',
          {
            'filePath': path,
            'pageIndex': pageIndex,
            'scale': zoom,
            'outputPath': tempOut,
          },
        );
        final outFile = File(tempOut);
        final Uint8List bytes;
        if (outFile.existsSync()) {
          bytes = await outFile.readAsBytes();
          try {
            outFile.deleteSync();
          } on Exception {
            // Ignored
          }
        } else {
          bytes = Uint8List(0);
        }
        return RenderedPage(
          pageIndex: pageIndex,
          width: (res?['width'] as int?) ?? width,
          height: (res?['height'] as int?) ?? (width * 1.414).toInt(),
          pixels: bytes,
        );
      } on PlatformException catch (e) {
        throw DocumentRenderException(
          'Failed to render PDF page $pageIndex: ${e.message}',
        );
      }
    }

    // For non-PDF documents or fallback: return raw image bytes if available
    final file = File(path);
    final bytes = await file.readAsBytes();
    return RenderedPage(
      pageIndex: pageIndex,
      width: width,
      height: (width * 1.414).toInt(),
      pixels: bytes,
    );
  }

  @override
  Future<String> extractText({required int pageIndex}) async {
    final path = _currentFilePath;
    if (path == null) {
      throw StateError('No document is open');
    }

    final ext = p.extension(path).toLowerCase();
    if (ext == '.pdf') {
      final text = await _channel.invokeMethod<String>('pdf_extractText', {
        'filePath': path,
        'pageIndex': pageIndex,
      });
      return text ?? '';
    } else if (ext == '.docx') {
      final paragraphs = await _channel.invokeMethod<List<dynamic>>(
        'docx_getParagraphs',
        {'filePath': path},
      );
      if (paragraphs == null) return '';
      return paragraphs
          .map((p) => (p as Map<dynamic, dynamic>)['text']?.toString() ?? '')
          .join('\n');
    } else if (ext == '.xlsx') {
      final rows = await _channel.invokeMethod<List<dynamic>>(
        'xlsx_getSheetData',
        {'filePath': path, 'sheetIndex': pageIndex},
      );
      if (rows == null) return '';
      return rows.map((r) => (r as List<dynamic>).join('\t')).join('\n');
    } else if (ext == '.txt' ||
        ext == '.md' ||
        ext == '.log' ||
        ext == '.csv') {
      return File(path).readAsString();
    }
    return '';
  }

  @override
  Future<List<TextSearchResult>> searchText({
    required String query,
    List<int>? pageIndices,
    bool caseSensitive = false,
  }) async {
    final path = _currentFilePath;
    if (path == null) {
      throw StateError('No document is open');
    }

    final ext = p.extension(path).toLowerCase();
    if (ext == '.pdf') {
      final res = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'pdf_searchText',
        {
          'filePath': path,
          'query': query,
        },
      );
      if (res == null) return [];
      return res.map((m) {
        return TextSearchResult(
          pageIndex: (m['pageIndex'] as int?) ?? 0,
          text: (m['snippet'] as String?) ?? (m['text'] as String?) ?? '',
          rects: const [],
        );
      }).toList();
    }

    // Fallback: extract full text and search
    final fullText = await extractText(pageIndex: 0);
    final results = <TextSearchResult>[];
    var idx = caseSensitive
        ? fullText.indexOf(query)
        : fullText.toLowerCase().indexOf(query.toLowerCase());

    while (idx >= 0) {
      final start = (idx - 30).clamp(0, fullText.length);
      final end = (idx + query.length + 30).clamp(0, fullText.length);
      final snippet = fullText.substring(start, end).replaceAll('\n', ' ');
      results.add(
        TextSearchResult(
          pageIndex: 0,
          text: snippet,
          rects: const [],
        ),
      );
      idx = caseSensitive
          ? fullText.indexOf(query, idx + query.length)
          : fullText
              .toLowerCase()
              .indexOf(query.toLowerCase(), idx + query.length);
    }
    return results;
  }

  @override
  Future<List<DocumentOutlineEntry>> getOutline() async {
    return const [];
  }

  @override
  Future<void> closeDocument() async {
    final path = _currentFilePath;
    if (path != null && p.extension(path).toLowerCase() == '.pdf') {
      try {
        await _channel.invokeMethod<void>('pdf_close', {'filePath': path});
      } on Exception {
        // Ignored
      }
    }
    _currentFilePath = null;
    _currentMetadata = null;
  }
}
