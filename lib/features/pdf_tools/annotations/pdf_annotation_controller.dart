import 'dart:convert';
import 'dart:io';

import 'package:document_reviewer/core/engine/pdf_annotation_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

final _logger = Logger('PdfAnnotationController');

/// Manages annotation state, undo/redo history, and autosave draft persistence.
class PdfAnnotationController extends ChangeNotifier {
  PdfAnnotationController({
    required this.documentUri,
    Directory? draftsDirectory,
  }) : _draftsDir = draftsDirectory;

  final String documentUri;
  final Directory? _draftsDir;

  final List<PdfAnnotation> _annotations = [];
  final List<PdfAnnotation> _undoStack = [];
  final List<PdfAnnotation> _redoStack = [];

  bool _isDirty = false;
  bool get isDirty => _isDirty;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  List<PdfAnnotation> get annotations => List.unmodifiable(_annotations);

  List<PdfAnnotation> getAnnotationsForPage(int pageIndex) {
    return _annotations.where((a) => a.pageIndex == pageIndex).toList();
  }

  /// Calculates a stable hash key for the document URI.
  String get _docHashKey {
    return documentUri.hashCode.abs().toRadixString(16);
  }

  Future<File> _getDraftFile() async {
    final dir = _draftsDir ??
        Directory('${(await getTemporaryDirectory()).path}/drafts');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return File('${dir.path}/draft_$_docHashKey.json');
  }

  /// Adds a new annotation to active document and undo history.
  void addAnnotation(PdfAnnotation annotation) {
    _annotations.add(annotation);
    _undoStack.add(annotation);
    _redoStack.clear();
    _isDirty = true;
    notifyListeners();
    _autosaveDraft();
  }

  /// Undoes the last annotation added.
  PdfAnnotation? undo() {
    if (_undoStack.isEmpty) return null;
    final last = _undoStack.removeLast();
    _annotations.removeWhere((a) => a.id == last.id);
    _redoStack.add(last);
    _isDirty = _undoStack.isNotEmpty;
    notifyListeners();
    _autosaveDraft();
    return last;
  }

  /// Redoes the last undone annotation.
  PdfAnnotation? redo() {
    if (_redoStack.isEmpty) return null;
    final item = _redoStack.removeLast();
    _annotations.add(item);
    _undoStack.add(item);
    _isDirty = true;
    notifyListeners();
    _autosaveDraft();
    return item;
  }

  /// Clears all annotations.
  void clearAll() {
    _annotations.clear();
    _undoStack.clear();
    _redoStack.clear();
    _isDirty = false;
    notifyListeners();
    _deleteDraft();
  }

  /// Autosaves draft annotations manifest to disk.
  Future<void> _autosaveDraft() async {
    try {
      final file = await _getDraftFile();
      if (_annotations.isEmpty) {
        if (file.existsSync()) file.deleteSync();
        return;
      }
      final payload = {
        'documentUri': documentUri,
        'savedAt': DateTime.now().toIso8601String(),
        'annotations': _annotations.map((a) => a.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (e) {
      _logger.warning('Autosave draft failed: $e');
    }
  }

  /// Checks if an uncommitted draft exists for this document.
  Future<bool> hasDraft() async {
    try {
      final file = await _getDraftFile();
      return file.existsSync() && file.lengthSync() > 0;
    } catch (_) {
      return false;
    }
  }

  /// Restores annotations from an autosaved draft (e.g. after process kill).
  Future<bool> restoreDraft() async {
    try {
      final file = await _getDraftFile();
      if (!file.existsSync()) return false;

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final list = (data['annotations'] as List)
          .map((item) => PdfAnnotation.fromJson(item as Map<String, dynamic>))
          .toList();

      _annotations.clear();
      _undoStack.clear();
      _redoStack.clear();

      for (final a in list) {
        _annotations.add(a);
        _undoStack.add(a);
      }

      _isDirty = _annotations.isNotEmpty;
      notifyListeners();
      return true;
    } catch (e) {
      _logger.warning('Restore draft failed: $e');
      return false;
    }
  }

  /// Deletes draft file when committed or discarded.
  Future<void> discardDraft() async {
    try {
      final file = await _getDraftFile();
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }

  Future<void> _deleteDraft() async {
    await discardDraft();
  }
}
