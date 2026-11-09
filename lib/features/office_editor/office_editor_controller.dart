import 'dart:convert';
import 'dart:io';

import 'package:document_reviewer/core/engine/office_editor_engine.dart';
import 'package:document_reviewer/features/office_editor/models/office_models.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final _logger = Logger('OfficeEditorController');

/// Controller managing in-memory office document state, undo/redo,
/// dirty state, autosave drafts, and engine commits.
class OfficeEditorController extends ChangeNotifier {
  OfficeEditorController({
    required this.filePath,
    required this.documentType,
    this.sourceUri,
    this.draftsDirectory,
  });

  final String filePath;
  final OfficeDocumentType documentType;
  final String? sourceUri;
  final Directory? draftsDirectory;

  bool _isDirty = false;
  bool get isDirty => _isDirty;

  // Undo/Redo Stacks
  final List<OfficeEditAction> _undoStack = [];
  final List<OfficeEditAction> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // DOCX State
  List<DocxBlock> _docxBlocks = [];
  List<DocxBlock> get docxBlocks => List.unmodifiable(_docxBlocks);
  String _docxHeader = '';
  String get docxHeader => _docxHeader;
  String _docxFooter = '';
  String get docxFooter => _docxFooter;

  // XLSX State
  List<String> _xlsxSheetNames = ['Sheet1'];
  List<String> get xlsxSheetNames => List.unmodifiable(_xlsxSheetNames);
  int _activeSheetIndex = 0;
  int get activeSheetIndex => _activeSheetIndex;
  final Map<int, List<List<XlsxCell>>> _xlsxSheetsData = {};

  List<List<XlsxCell>> get activeSheetRows =>
      _xlsxSheetsData[_activeSheetIndex] ?? [];

  String get _draftFileName {
    final key = sourceUri ?? filePath;
    final hash = key.hashCode.abs().toRadixString(16);
    return 'draft_office_$hash.json';
  }

  File? get _draftFile {
    if (draftsDirectory == null) return null;
    return File('${draftsDirectory!.path}/$_draftFileName');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Initialization & Loading
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadFromEngine(OfficeEditorEngine engine) async {
    if (await hasDraft()) {
      await restoreDraft();
      return;
    }

    if (documentType == OfficeDocumentType.docx) {
      final struct = await engine.getDocxStructure(filePath: filePath);
      _docxHeader = struct['header'] as String? ?? '';
      _docxFooter = struct['footer'] as String? ?? '';

      final rawParagraphs = struct['paragraphs'] as List<dynamic>? ?? [];
      final rawTables = struct['tables'] as List<dynamic>? ?? [];

      _docxBlocks = [];
      var pIdx = 0;
      for (final p in rawParagraphs) {
        final text = (p as Map<dynamic, dynamic>)['text']?.toString() ?? '';
        final headingLevel = p['headingLevel'] as int? ?? 0;
        _docxBlocks.add(
          DocxBlock(
            id: 'block_p_${pIdx++}',
            type: headingLevel > 0
                ? DocxBlockType.heading
                : DocxBlockType.paragraph,
            text: text,
            headingLevel: headingLevel > 0 ? headingLevel : 1,
          ),
        );
      }

      var tIdx = 0;
      for (final t in rawTables) {
        final rows = (t as Map<dynamic, dynamic>)['rows'] as List<dynamic>?;
        final tableData = rows
            ?.map((r) => (r as List<dynamic>).map((c) => c.toString()).toList())
            .toList();
        _docxBlocks.add(
          DocxBlock(
            id: 'block_tbl_${tIdx++}',
            type: DocxBlockType.table,
            tableData: tableData ??
                [
                  ['', ''],
                  ['', ''],
                ],
          ),
        );
      }

      if (_docxBlocks.isEmpty) {
        _docxBlocks.add(
          DocxBlock(
            id: 'block_initial',
            type: DocxBlockType.paragraph,
          ),
        );
      }
    } else if (documentType == OfficeDocumentType.xlsx) {
      final names = await engine.getXlsxSheetNames(filePath: filePath);
      _xlsxSheetNames = names.isNotEmpty ? names : ['Sheet1'];
      _activeSheetIndex = 0;

      for (var s = 0; s < _xlsxSheetNames.length; s++) {
        final rawRows = await engine.getXlsxSheetData(
          filePath: filePath,
          sheetIndex: s,
        );
        final sheetCells = <List<XlsxCell>>[];
        for (final r in rawRows) {
          final rowCells = <XlsxCell>[];
          for (final cell in r) {
            rowCells.add(
              XlsxCell(
                value: cell['value']?.toString() ?? '',
                formula: cell['formula']?.toString(),
                bold: cell['bold'] as bool? ?? false,
                italic: cell['italic'] as bool? ?? false,
              ),
            );
          }
          sheetCells.add(rowCells);
        }
        _xlsxSheetsData[s] = sheetCells;
      }
    }

    _isDirty = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Undo / Redo Mechanism
  // ─────────────────────────────────────────────────────────────────────────

  void _recordAction(OfficeEditAction action) {
    _undoStack.add(action);
    _redoStack.clear();
    _isDirty = true;
    _scheduleAutosave();
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    final action = _undoStack.removeLast();
    action.undo();
    _redoStack.add(action);
    _isDirty = true;
    _scheduleAutosave();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    final action = _redoStack.removeLast();
    action.redo();
    _undoStack.add(action);
    _isDirty = true;
    _scheduleAutosave();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DOCX Mutators
  // ─────────────────────────────────────────────────────────────────────────

  void updateDocxBlockText(int index, String newText) {
    if (index < 0 || index >= _docxBlocks.length) return;
    final oldText = _docxBlocks[index].text;
    if (oldText == newText) return;

    _docxBlocks[index].text = newText;
    _recordAction(
      OfficeEditAction(
        description: 'Edit text at block $index',
        undo: () {
          _docxBlocks[index].text = oldText;
        },
        redo: () {
          _docxBlocks[index].text = newText;
        },
      ),
    );
  }

  void addDocxParagraph(String text) {
    final block = DocxBlock(
      id: 'block_p_${DateTime.now().millisecondsSinceEpoch}',
      type: DocxBlockType.paragraph,
      text: text,
    );
    _docxBlocks.add(block);
    final idx = _docxBlocks.length - 1;

    _recordAction(
      OfficeEditAction(
        description: 'Add paragraph',
        undo: () {
          _docxBlocks.removeAt(idx);
        },
        redo: () {
          _docxBlocks.insert(idx, block);
        },
      ),
    );
  }

  void addDocxHeading(String text, {int level = 1}) {
    final block = DocxBlock(
      id: 'block_h_${DateTime.now().millisecondsSinceEpoch}',
      type: DocxBlockType.heading,
      text: text,
      headingLevel: level,
    );
    _docxBlocks.add(block);
    final idx = _docxBlocks.length - 1;

    _recordAction(
      OfficeEditAction(
        description: 'Add Heading $level',
        undo: () {
          _docxBlocks.removeAt(idx);
        },
        redo: () {
          _docxBlocks.insert(idx, block);
        },
      ),
    );
  }

  void addDocxTable(int rows, int cols, {List<List<String>>? data}) {
    final tableData =
        data ?? List.generate(rows, (_) => List.generate(cols, (_) => ''));
    final block = DocxBlock(
      id: 'block_t_${DateTime.now().millisecondsSinceEpoch}',
      type: DocxBlockType.table,
      tableData: tableData,
    );
    _docxBlocks.add(block);
    final idx = _docxBlocks.length - 1;

    _recordAction(
      OfficeEditAction(
        description: 'Add table',
        undo: () {
          _docxBlocks.removeAt(idx);
        },
        redo: () {
          _docxBlocks.insert(idx, block);
        },
      ),
    );
  }

  void updateDocxTableCell(
    int blockIndex,
    int row,
    int col,
    String text,
  ) {
    if (blockIndex < 0 || blockIndex >= _docxBlocks.length) return;
    final block = _docxBlocks[blockIndex];
    if (block.tableData == null) return;
    if (row >= block.tableData!.length || col >= block.tableData![row].length) {
      return;
    }

    final oldText = block.tableData![row][col];
    if (oldText == text) return;

    block.tableData![row][col] = text;
    _recordAction(
      OfficeEditAction(
        description: 'Edit table cell ($row, $col)',
        undo: () {
          block.tableData![row][col] = oldText;
        },
        redo: () {
          block.tableData![row][col] = text;
        },
      ),
    );
  }

  void addDocxPageBreak() {
    final block = DocxBlock(
      id: 'block_pb_${DateTime.now().millisecondsSinceEpoch}',
      type: DocxBlockType.pageBreak,
    );
    _docxBlocks.add(block);
    final idx = _docxBlocks.length - 1;

    _recordAction(
      OfficeEditAction(
        description: 'Add page break',
        undo: () {
          _docxBlocks.removeAt(idx);
        },
        redo: () {
          _docxBlocks.insert(idx, block);
        },
      ),
    );
  }

  void setDocxHeader(String text) {
    final old = _docxHeader;
    _docxHeader = text;
    _recordAction(
      OfficeEditAction(
        description: 'Set header',
        undo: () => _docxHeader = old,
        redo: () => _docxHeader = text,
      ),
    );
  }

  void setDocxFooter(String text) {
    final old = _docxFooter;
    _docxFooter = text;
    _recordAction(
      OfficeEditAction(
        description: 'Set footer',
        undo: () => _docxFooter = old,
        redo: () => _docxFooter = text,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // XLSX Mutators
  // ─────────────────────────────────────────────────────────────────────────

  void switchSheet(int index) {
    if (index >= 0 && index < _xlsxSheetNames.length) {
      _activeSheetIndex = index;
      notifyListeners();
    }
  }

  void updateXlsxCell({
    required int row,
    required int col,
    required String value,
    String? formula,
    bool? bold,
    bool? italic,
  }) {
    final sheetData = _xlsxSheetsData.putIfAbsent(_activeSheetIndex, () => []);
    while (sheetData.length <= row) {
      sheetData.add([]);
    }
    while (sheetData[row].length <= col) {
      sheetData[row].add(XlsxCell());
    }

    final targetCell = sheetData[row][col];
    final oldCell = targetCell.copy();

    targetCell.value = value;
    if (formula != null) targetCell.formula = formula;
    if (bold != null) targetCell.bold = bold;
    if (italic != null) targetCell.italic = italic;

    final sheetIdx = _activeSheetIndex;
    _recordAction(
      OfficeEditAction(
        description: 'Update cell ($row, $col)',
        undo: () {
          _xlsxSheetsData[sheetIdx]?[row][col] = oldCell;
        },
        redo: () {
          final c = _xlsxSheetsData[sheetIdx]?[row][col];
          if (c != null) {
            c.value = value;
            if (formula != null) c.formula = formula;
            if (bold != null) c.bold = bold;
            if (italic != null) c.italic = italic;
          }
        },
      ),
    );
  }

  void addXlsxSheet(String name) {
    final safeName =
        name.trim().isEmpty ? 'Sheet${_xlsxSheetNames.length + 1}' : name;
    _xlsxSheetNames.add(safeName);
    final newIdx = _xlsxSheetNames.length - 1;
    _xlsxSheetsData[newIdx] = [
      [XlsxCell()],
    ];

    _recordAction(
      OfficeEditAction(
        description: 'Add sheet $safeName',
        undo: () {
          _xlsxSheetNames.removeAt(newIdx);
          _xlsxSheetsData.remove(newIdx);
          if (_activeSheetIndex >= _xlsxSheetNames.length) {
            _activeSheetIndex = _xlsxSheetNames.length - 1;
          }
        },
        redo: () {
          _xlsxSheetNames.insert(newIdx, safeName);
          _xlsxSheetsData[newIdx] = [
            [XlsxCell()],
          ];
        },
      ),
    );
  }

  void renameXlsxSheet(int index, String newName) {
    if (index < 0 || index >= _xlsxSheetNames.length) return;
    final oldName = _xlsxSheetNames[index];
    _xlsxSheetNames[index] = newName;

    _recordAction(
      OfficeEditAction(
        description: 'Rename sheet to $newName',
        undo: () => _xlsxSheetNames[index] = oldName,
        redo: () => _xlsxSheetNames[index] = newName,
      ),
    );
  }

  void addXlsxRow(List<String> values) {
    final sheetData = _xlsxSheetsData.putIfAbsent(_activeSheetIndex, () => []);
    final rowCells = values.map((v) => XlsxCell(value: v)).toList();
    sheetData.add(rowCells);
    final rIdx = sheetData.length - 1;
    final sheetIdx = _activeSheetIndex;

    _recordAction(
      OfficeEditAction(
        description: 'Add row',
        undo: () {
          _xlsxSheetsData[sheetIdx]?.removeAt(rIdx);
        },
        redo: () {
          _xlsxSheetsData[sheetIdx]?.insert(rIdx, rowCells);
        },
      ),
    );
  }

  void deleteXlsxRow(int rowIndex) {
    final sheetData = _xlsxSheetsData[_activeSheetIndex];
    if (sheetData == null || rowIndex < 0 || rowIndex >= sheetData.length) {
      return;
    }

    final removed = sheetData.removeAt(rowIndex);
    final sheetIdx = _activeSheetIndex;

    _recordAction(
      OfficeEditAction(
        description: 'Delete row $rowIndex',
        undo: () {
          _xlsxSheetsData[sheetIdx]?.insert(rowIndex, removed);
        },
        redo: () {
          _xlsxSheetsData[sheetIdx]?.removeAt(rowIndex);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Autosave Draft & Crash Recovery
  // ─────────────────────────────────────────────────────────────────────────

  void _scheduleAutosave() {
    final file = _draftFile;
    if (file == null) return;

    final data = {
      'documentType': documentType.name,
      'sourceUri': sourceUri,
      'filePath': filePath,
      'savedAt': DateTime.now().toIso8601String(),
      'docxBlocks': _docxBlocks.map((b) => b.toJson()).toList(),
      'docxHeader': _docxHeader,
      'docxFooter': _docxFooter,
      'xlsxSheetNames': _xlsxSheetNames,
      'activeSheetIndex': _activeSheetIndex,
      'xlsxSheetsData': _xlsxSheetsData.map(
        (key, sheet) => MapEntry(
          key.toString(),
          sheet.map((r) => r.map((c) => c.toJson()).toList()).toList(),
        ),
      ),
    };

    try {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode(data));
    } on Exception catch (e) {
      _logger.warning('Autosave draft failed: $e');
    }
  }

  Future<bool> hasDraft() async {
    final file = _draftFile;
    return file != null && file.existsSync();
  }

  Future<bool> restoreDraft() async {
    final file = _draftFile;
    if (file == null || !file.existsSync()) return false;

    try {
      final jsonStr = file.readAsStringSync();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (documentType == OfficeDocumentType.docx) {
        final rawBlocks = map['docxBlocks'] as List<dynamic>? ?? [];
        _docxBlocks = rawBlocks
            .map((b) => DocxBlock.fromJson(b as Map<String, dynamic>))
            .toList();
        _docxHeader = map['docxHeader'] as String? ?? '';
        _docxFooter = map['docxFooter'] as String? ?? '';
      } else if (documentType == OfficeDocumentType.xlsx) {
        final rawSheets = map['xlsxSheetNames'] as List<dynamic>? ?? [];
        _xlsxSheetNames = rawSheets.map((s) => s.toString()).toList();
        _activeSheetIndex = map['activeSheetIndex'] as int? ?? 0;

        final rawSheetsData =
            map['xlsxSheetsData'] as Map<String, dynamic>? ?? {};
        _xlsxSheetsData.clear();
        rawSheetsData.forEach((sIdxStr, sheetRows) {
          final sIdx = int.tryParse(sIdxStr) ?? 0;
          final sheetList = <List<XlsxCell>>[];
          for (final row in sheetRows as List<dynamic>) {
            final rowList = <XlsxCell>[];
            for (final cell in row as List<dynamic>) {
              rowList.add(XlsxCell.fromJson(cell as Map<String, dynamic>));
            }
            sheetList.add(rowList);
          }
          _xlsxSheetsData[sIdx] = sheetList;
        });
      }

      _isDirty = true;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _logger.warning('Failed to restore draft: $e');
      return false;
    }
  }

  Future<void> discardDraft() async {
    final file = _draftFile;
    if (file != null && file.existsSync()) {
      try {
        file.deleteSync();
      } on Exception {
        // Ignored
      }
    }
    _isDirty = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Native Commit via OfficeEditorEngine
  // ─────────────────────────────────────────────────────────────────────────

  /// Writes all in-memory changes into the specified [targetPath]
  /// using the native POI [engine].
  Future<bool> commitToFile({
    required OfficeEditorEngine engine,
    String? targetPath,
  }) async {
    final dest = targetPath ?? filePath;

    if (documentType == OfficeDocumentType.docx) {
      var pCounter = 0;

      for (final block in _docxBlocks) {
        switch (block.type) {
          case DocxBlockType.heading:
            await engine.addDocxHeading(
              text: block.text,
              level: block.headingLevel,
              outputPath: dest,
            );
          case DocxBlockType.paragraph:
            if (pCounter == 0) {
              await engine.updateDocxParagraph(
                index: 0,
                text: block.text,
                outputPath: dest,
              );
            } else {
              await engine.appendDocxParagraph(
                text: block.text,
                outputPath: dest,
              );
            }
            pCounter++;
          case DocxBlockType.table:
            if (block.tableData != null && block.tableData!.isNotEmpty) {
              await engine.addDocxTable(
                rows: block.tableData!.length,
                cols: block.tableData![0].length,
                data: block.tableData,
                outputPath: dest,
              );
            }
          case DocxBlockType.pageBreak:
            await engine.addDocxPageBreak(outputPath: dest);
          case DocxBlockType.image:
            if (block.imagePath != null) {
              await engine.insertDocxImage(
                imagePath: block.imagePath!,
                outputPath: dest,
              );
            }
        }
      }

      if (_docxHeader.isNotEmpty) {
        await engine.setDocxHeader(text: _docxHeader, outputPath: dest);
      }
      if (_docxFooter.isNotEmpty) {
        await engine.setDocxFooter(text: _docxFooter, outputPath: dest);
      }
    } else if (documentType == OfficeDocumentType.xlsx) {
      for (var s = 0; s < _xlsxSheetNames.length; s++) {
        final rows = _xlsxSheetsData[s];
        if (rows != null) {
          for (var r = 0; r < rows.length; r++) {
            for (var c = 0; c < rows[r].length; c++) {
              final cell = rows[r][c];
              await engine.updateXlsxCell(
                sheetIndex: s,
                row: r,
                col: c,
                value: cell.value,
                formula: cell.formula,
                bold: cell.bold,
                italic: cell.italic,
                outputPath: dest,
              );
            }
          }
        }
      }
    }

    final valid = await engine.validateSavedDocument(filePath: dest);
    if (valid) {
      await discardDraft();
      _isDirty = false;
      notifyListeners();
    }
    return valid;
  }
}
