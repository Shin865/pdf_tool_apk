import 'dart:io';

import 'package:document_reviewer/core/engine/office_editor_engine.dart';
import 'package:document_reviewer/core/error/exceptions.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Implementation of [OfficeEditorEngine] backed by Apache POI 5.3.0
/// via native Android platform channels.
class NativeOfficeEditorEngine implements OfficeEditorEngine {
  NativeOfficeEditorEngine({
    MethodChannel? engineChannel,
  }) : _channel = engineChannel ??
            const MethodChannel('com.example.documentreviewer/engine');

  final MethodChannel _channel;
  String? _workingFilePath;
  OfficeDocumentType? _currentType;

  /// Returns the type of the currently open office document, if any.
  OfficeDocumentType? get currentDocumentType => _currentType;

  @override
  List<OfficeDocumentType> get supportedTypes => [
        OfficeDocumentType.docx,
        OfficeDocumentType.xlsx,
      ];

  @override
  bool supportsEditing(OfficeDocumentType documentType) {
    return documentType == OfficeDocumentType.docx ||
        documentType == OfficeDocumentType.xlsx;
  }

  @override
  Future<OfficeDocumentInfo> openDocument({required String filePath}) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw DocumentNotFoundException(filePath);
    }

    _workingFilePath = filePath;
    final ext = p.extension(filePath).toLowerCase();

    if (ext == '.docx') {
      _currentType = OfficeDocumentType.docx;
      final paragraphs = await _channel.invokeListMethod<dynamic>(
        'docx_getParagraphs',
        {'filePath': filePath},
      );
      return OfficeDocumentInfo(
        documentType: OfficeDocumentType.docx,
        title: p.basenameWithoutExtension(filePath),
        pageCount: (paragraphs?.length ?? 1) > 0 ? 1 : 0,
      );
    } else if (ext == '.xlsx') {
      _currentType = OfficeDocumentType.xlsx;
      final sheets = await getXlsxSheetNames(filePath: filePath);
      return OfficeDocumentInfo(
        documentType: OfficeDocumentType.xlsx,
        title: p.basenameWithoutExtension(filePath),
        pageCount: sheets.length,
        sheetNames: sheets,
      );
    }

    throw UnsupportedFormatException(ext, 'Only DOCX and XLSX are supported');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DOCX Methods
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getDocxStructure({
    required String filePath,
  }) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'docx_getStructure',
      {'filePath': filePath},
    );
    return result ?? {};
  }

  @override
  Future<bool> updateDocxParagraph({
    required int index,
    required String text,
    String? outputPath,
  }) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('docx_updateParagraph', {
      'filePath': _workingFilePath,
      'index': index,
      'text': text,
      'outputPath': path,
    });
    return ok ?? false;
  }

  @override
  Future<bool> appendDocxParagraph({
    required String text,
    String? outputPath,
  }) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('docx_appendParagraph', {
      'filePath': _workingFilePath,
      'text': text,
      'outputPath': path,
    });
    return ok ?? false;
  }

  @override
  Future<bool> addDocxHeading({
    required String text,
    int level = 1,
    String? outputPath,
  }) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('docx_addHeading', {
      'filePath': _workingFilePath,
      'text': text,
      'level': level,
      'outputPath': path,
    });
    return ok ?? false;
  }

  @override
  Future<bool> addDocxTable({
    required int rows,
    required int cols,
    List<List<String>>? data,
    String? outputPath,
  }) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('docx_addTable', {
      'filePath': _workingFilePath,
      'rows': rows,
      'cols': cols,
      'data': data,
      'outputPath': path,
    });
    return ok ?? false;
  }

  @override
  Future<bool> updateDocxTableCell({
    required int tableIndex,
    required int row,
    required int col,
    required String text,
    String? outputPath,
  }) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('docx_updateTableCell', {
      'filePath': _workingFilePath,
      'tableIndex': tableIndex,
      'row': row,
      'col': col,
      'text': text,
      'outputPath': path,
    });
    return ok ?? false;
  }

  @override
  Future<bool> addDocxPageBreak({String? outputPath}) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('docx_addPageBreak', {
      'filePath': _workingFilePath,
      'outputPath': path,
    });
    return ok ?? false;
  }

  @override
  Future<bool> setDocxHeader({
    required String text,
    String? outputPath,
  }) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('docx_setHeader', {
      'filePath': _workingFilePath,
      'text': text,
      'outputPath': path,
    });
    return ok ?? false;
  }

  @override
  Future<bool> setDocxFooter({
    required String text,
    String? outputPath,
  }) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('docx_setFooter', {
      'filePath': _workingFilePath,
      'text': text,
      'outputPath': path,
    });
    return ok ?? false;
  }

  @override
  Future<bool> insertDocxImage({
    required String imagePath,
    int width = 300,
    int height = 200,
    String? outputPath,
  }) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('docx_insertImage', {
      'filePath': _workingFilePath,
      'imagePath': imagePath,
      'width': width,
      'height': height,
      'outputPath': path,
    });
    return ok ?? false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // XLSX Methods
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<List<String>> getXlsxSheetNames({required String filePath}) async {
    final sheets = await _channel.invokeListMethod<dynamic>(
      'xlsx_getSheetNames',
      {'filePath': filePath},
    );
    return sheets?.map((s) => s.toString()).toList() ?? [];
  }

  @override
  Future<List<List<Map<String, dynamic>>>> getXlsxSheetData({
    required String filePath,
    int sheetIndex = 0,
  }) async {
    final rawRows = await _channel.invokeListMethod<dynamic>(
      'xlsx_getSheetData',
      {
        'filePath': filePath,
        'sheetIndex': sheetIndex,
      },
    );
    if (rawRows == null) return [];

    final result = <List<Map<String, dynamic>>>[];
    for (final r in rawRows) {
      if (r is List) {
        final rowList = <Map<String, dynamic>>[];
        for (final cell in r) {
          if (cell is Map) {
            rowList.add(Map<String, dynamic>.from(cell));
          } else {
            rowList.add({'value': cell.toString()});
          }
        }
        result.add(rowList);
      }
    }
    return result;
  }

  @override
  Future<bool> updateXlsxCell({
    required int sheetIndex,
    required int row,
    required int col,
    required String value,
    String? formula,
    bool bold = false,
    bool italic = false,
    String? outputPath,
  }) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('xlsx_updateCell', {
      'filePath': _workingFilePath,
      'sheetIndex': sheetIndex,
      'row': row,
      'col': col,
      'value': value,
      'formula': formula,
      'bold': bold,
      'italic': italic,
      'outputPath': path,
    });
    return ok ?? false;
  }

  @override
  Future<bool> addXlsxSheet({
    required String sheetName,
    String? outputPath,
  }) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('xlsx_addSheet', {
      'filePath': _workingFilePath,
      'sheetName': sheetName,
      'outputPath': path,
    });
    return ok ?? false;
  }

  @override
  Future<bool> renameXlsxSheet({
    required int sheetIndex,
    required String newName,
    String? outputPath,
  }) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('xlsx_renameSheet', {
      'filePath': _workingFilePath,
      'sheetIndex': sheetIndex,
      'newName': newName,
      'outputPath': path,
    });
    return ok ?? false;
  }

  @override
  Future<bool> addXlsxRow({
    required int sheetIndex,
    required List<String> values,
    String? outputPath,
  }) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('xlsx_addRow', {
      'filePath': _workingFilePath,
      'sheetIndex': sheetIndex,
      'values': values,
      'outputPath': path,
    });
    return ok ?? false;
  }

  @override
  Future<bool> deleteXlsxRow({
    required int sheetIndex,
    required int rowIndex,
    String? outputPath,
  }) async {
    final path = outputPath ?? _workingFilePath;
    if (path == null) throw StateError('No document is open');
    final ok = await _channel.invokeMethod<bool>('xlsx_deleteRow', {
      'filePath': _workingFilePath,
      'sheetIndex': sheetIndex,
      'rowIndex': rowIndex,
      'outputPath': path,
    });
    return ok ?? false;
  }

  @override
  Future<List<int>> renderPreview({
    required int pageIndex,
    required int width,
  }) async {
    return const [];
  }

  @override
  Future<OfficeSaveResult> saveDocument({required String outputPath}) async {
    final path = _workingFilePath;
    if (path == null) {
      return const OfficeSaveResult(
        success: false,
        outputPath: '',
        errors: ['No working document open'],
      );
    }

    try {
      if (path != outputPath) {
        final src = File(path);
        final dest = File(outputPath);
        dest.parent.createSync(recursive: true);
        src.copySync(dest.path);
      }

      final valid = await validateSavedDocument(filePath: outputPath);
      return OfficeSaveResult(
        success: true,
        outputPath: outputPath,
        validationPassed: valid,
      );
    } on Exception catch (e) {
      return OfficeSaveResult(
        success: false,
        outputPath: outputPath,
        errors: [e.toString()],
      );
    }
  }

  @override
  Future<bool> validateSavedDocument({required String filePath}) async {
    final file = File(filePath);
    if (!file.existsSync() || file.lengthSync() == 0) return false;

    try {
      final zipValid = await _channel.invokeMethod<bool>(
        'office_validateZip',
        {'filePath': filePath},
      );
      if (zipValid != null) return zipValid;

      final ext = p.extension(filePath).toLowerCase();
      if (ext == '.docx') {
        final paragraphs = await _channel.invokeListMethod<dynamic>(
          'docx_getParagraphs',
          {'filePath': filePath},
        );
        return paragraphs != null;
      } else if (ext == '.xlsx') {
        final sheets = await getXlsxSheetNames(filePath: filePath);
        return sheets.isNotEmpty;
      }
    } on Exception {
      return false;
    }
    return true;
  }

  @override
  Future<void> closeDocument() async {
    _workingFilePath = null;
    _currentType = null;
  }
}
