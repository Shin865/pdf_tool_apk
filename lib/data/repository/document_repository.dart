/// Repository for document CRUD operations.
///
/// Coordinates between SAF (file access), Drift (metadata), and
/// the local working copy filesystem.
library;

import 'dart:io';

import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/data/saf/saf_file_service.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _log = Logger('DocumentRepository');

class DocumentRepository {
  DocumentRepository({
    required AppDatabase database,
    required SafFileService safService,
  })  : _db = database,
        _saf = safService;

  final AppDatabase _db;
  final SafFileService _saf;

  // -----------------------------------------------------------------------
  // Open a file from SAF
  // -----------------------------------------------------------------------

  /// Opens a SAF file picker, copies the file locally, and records it
  /// in the database. Returns the document record, or null if cancelled.
  Future<DocumentRecord?> pickAndOpenDocument({
    List<String> mimeTypes = const ['*/*'],
  }) async {
    final pick = await _saf.pickFile(mimeTypes: mimeTypes);
    if (pick == null) return null;

    // Check if we already have this URI
    final existing = await _db.getDocumentByUri(pick.uri);
    if (existing != null) {
      // Update last opened timestamp
      await _db.updateDocument(
        existing.copyWith(lastOpenedAt: DateTime.now()),
      );
      await _recordRecentOpen(existing.id);
      return existing.copyWith(lastOpenedAt: DateTime.now());
    }

    // Create local working copy
    final workDir = await _getWorkingDirectory();
    final localPath = p.join(workDir, pick.displayName);
    final copied = await _saf.copyToLocal(
      uri: pick.uri,
      destinationPath: localPath,
    );
    if (!copied) {
      _log.severe('Failed to copy file from SAF: ${pick.uri}');
      return null;
    }

    // Insert into database
    final now = DateTime.now();
    await _db.insertDocument(
      DocumentRecordsCompanion.insert(
        uri: pick.uri,
        displayName: pick.displayName,
        mimeType: pick.mimeType,
        fileSizeBytes: Value(pick.size),
        firstOpenedAt: now,
        lastOpenedAt: now,
      ),
    );

    final record = await _db.getDocumentByUri(pick.uri);
    if (record != null) {
      await _recordRecentOpen(record.id);
    }
    _log.info('Opened document: ${pick.displayName}');
    return record;
  }

  /// Creates a local working copy for a document already in the database.
  Future<String?> getWorkingCopy(DocumentRecord document) async {
    final workDir = await _getWorkingDirectory();
    final localPath = p.join(workDir, document.displayName);
    final file = File(localPath);

    if (file.existsSync()) return localPath;

    final copied = await _saf.copyToLocal(
      uri: document.uri,
      destinationPath: localPath,
    );
    return copied ? localPath : null;
  }

  /// Writes the working copy back to the original SAF URI atomically.
  Future<bool> saveBackToOriginal({
    required String localPath,
    required String uri,
  }) async {
    return _saf.writeBackToUri(sourcePath: localPath, uri: uri);
  }

  // -----------------------------------------------------------------------
  // Database delegates
  // -----------------------------------------------------------------------

  Future<List<DocumentRecord>> getRecentDocuments({int limit = 20}) async {
    final recents = await _db.getRecentDocuments(limit: limit);
    final allDocs = await _db.getAllDocuments();
    final results = <DocumentRecord>[];
    for (final recent in recents) {
      final match = allDocs.where((d) => d.id == recent.documentId).firstOrNull;
      if (match != null && !results.any((r) => r.id == match.id)) {
        results.add(match);
      }
    }
    return results;
  }

  Future<List<DocumentRecord>> getAllDocuments() => _db.getAllDocuments();

  Future<DocumentRecord?> getDocumentByUri(String uri) =>
      _db.getDocumentByUri(uri);

  Future<List<DocumentRecord>> getFavorites() => _db.getFavoriteDocuments();

  Future<void> toggleFavorite(int documentId, {required bool isFavorite}) =>
      _db.toggleFavorite(documentId, isFavorite: isFavorite);

  /// Removes a document from the recents list and database.
  /// Does NOT delete the original file on storage.
  Future<void> removeDocumentFromList(int documentId) async {
    await _db.deleteRecentDocumentByDocumentId(documentId);
    await _db.deleteDocument(documentId);
    _log.info('Removed document $documentId from list');
  }

  /// Updates the saved reading position for a document.
  Future<void> updateReadingPosition({
    required int documentId,
    required int pageIndex,
    double scrollOffset = 0.0,
    double zoomLevel = 1.0,
  }) =>
      _db.updateReadingPosition(
        documentId: documentId,
        pageIndex: pageIndex,
        scrollOffset: scrollOffset,
        zoomLevel: zoomLevel,
      );

  /// Retrieves the last reading position for a document.
  Future<RecentDocument?> getReadingPosition(int documentId) =>
      _db.getLatestRecentForDocument(documentId);

  /// Shares a document via Android Intent.
  Future<bool> shareDocument(DocumentRecord document) => _saf.shareFile(
        uri: document.uri,
        mimeType: document.mimeType,
        displayName: document.displayName,
      );

  // -----------------------------------------------------------------------
  // Private helpers
  // -----------------------------------------------------------------------

  Future<void> _recordRecentOpen(int documentId) async {
    await _db.insertRecentDocument(
      RecentDocumentsCompanion.insert(
        documentId: documentId,
        openedAt: DateTime.now(),
      ),
    );
  }

  Future<String> _getWorkingDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final workDir = Directory(p.join(appDir.path, 'working_copies'));
    if (!workDir.existsSync()) {
      await workDir.create(recursive: true);
    }
    return workDir.path;
  }
}
