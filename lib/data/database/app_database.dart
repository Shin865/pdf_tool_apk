/// Drift database definition with all initial tables.
///
/// Tables: DocumentRecord, RecentDocument, DocumentBookmark,
/// DocumentVersion, AppPreference.
///
/// URIs from SAF are stored as strings — never raw file paths.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

/// Core metadata for every document the app has opened.
class DocumentRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uri => text().unique()();
  TextColumn get displayName => text()();
  TextColumn get mimeType => text()();
  IntColumn get fileSizeBytes => integer().nullable()();
  IntColumn get pageCount => integer().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get firstOpenedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get tags => text().nullable()(); // JSON array
}

/// Tracks recently opened documents (ordered by timestamp).
class RecentDocuments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(DocumentRecords, #id)();
  DateTimeColumn get openedAt => dateTime()();
  IntColumn get lastPageIndex => integer().withDefault(const Constant(0))();
  RealColumn get lastScrollOffset => real().withDefault(const Constant(0))();
  RealColumn get lastZoomLevel => real().withDefault(const Constant(1))();
}

/// User-created bookmarks within a document.
class DocumentBookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(DocumentRecords, #id)();
  IntColumn get pageIndex => integer()();
  TextColumn get label => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Versioned copies of documents (for safe save workflow).
class DocumentVersions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get documentId => integer().references(DocumentRecords, #id)();

  /// Path to the local working copy (not the SAF URI).
  TextColumn get localCopyPath => text()();
  IntColumn get versionNumber => integer()();
  TextColumn get changeDescription => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isWrittenBack =>
      boolean().withDefault(const Constant(false))();
}

/// Key-value store for application preferences.
class AppPreferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

// ---------------------------------------------------------------------------
// Database class
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [
    DocumentRecords,
    RecentDocuments,
    DocumentBookmarks,
    DocumentVersions,
    AppPreferences,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for testing with a custom executor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
            'CREATE INDEX IF NOT EXISTS document_records_fav_idx '
            'ON document_records(is_favorite, last_opened_at);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS recent_documents_opened_at_idx '
            'ON recent_documents(opened_at DESC);',
          );
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS document_records_fav_idx '
              'ON document_records(is_favorite, last_opened_at);',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS recent_documents_opened_at_idx '
              'ON recent_documents(opened_at DESC);',
            );
          }
        },
      );

  // -----------------------------------------------------------------------
  // DocumentRecord queries
  // -----------------------------------------------------------------------

  Future<List<DocumentRecord>> getAllDocuments() =>
      select(documentRecords).get();

  Future<DocumentRecord?> getDocumentByUri(String uri) =>
      (select(documentRecords)..where((t) => t.uri.equals(uri)))
          .getSingleOrNull();

  Future<int> insertDocument(DocumentRecordsCompanion entry) =>
      into(documentRecords).insert(entry);

  Future<bool> updateDocument(DocumentRecord entry) =>
      update(documentRecords).replace(entry);

  Future<int> deleteDocument(int id) =>
      (delete(documentRecords)..where((t) => t.id.equals(id))).go();

  // -----------------------------------------------------------------------
  // RecentDocument queries
  // -----------------------------------------------------------------------

  Future<List<RecentDocument>> getRecentDocuments({int limit = 50}) =>
      (select(recentDocuments)
            ..orderBy([(t) => OrderingTerm.desc(t.openedAt)])
            ..limit(limit))
          .get();

  Future<int> insertRecentDocument(RecentDocumentsCompanion entry) =>
      into(recentDocuments).insert(entry);

  Future<bool> updateRecentDocument(RecentDocument entry) =>
      update(recentDocuments).replace(entry);

  Future<int> deleteRecentDocumentByDocumentId(int documentId) =>
      (delete(recentDocuments)..where((t) => t.documentId.equals(documentId)))
          .go();

  Future<RecentDocument?> getLatestRecentForDocument(int documentId) =>
      (select(recentDocuments)
            ..where((t) => t.documentId.equals(documentId))
            ..orderBy([(t) => OrderingTerm.desc(t.openedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> updateReadingPosition({
    required int documentId,
    required int pageIndex,
    double scrollOffset = 0.0,
    double zoomLevel = 1.0,
  }) async {
    final existing = await getLatestRecentForDocument(documentId);
    if (existing != null) {
      await updateRecentDocument(
        existing.copyWith(
          lastPageIndex: pageIndex,
          lastScrollOffset: scrollOffset,
          lastZoomLevel: zoomLevel,
          openedAt: DateTime.now(),
        ),
      );
    } else {
      await insertRecentDocument(
        RecentDocumentsCompanion.insert(
          documentId: documentId,
          openedAt: DateTime.now(),
          lastPageIndex: Value(pageIndex),
          lastScrollOffset: Value(scrollOffset),
          lastZoomLevel: Value(zoomLevel),
        ),
      );
    }
  }

  // -----------------------------------------------------------------------
  // Bookmark queries
  // -----------------------------------------------------------------------

  Future<List<DocumentBookmark>> getBookmarksForDocument(int documentId) =>
      (select(documentBookmarks)
            ..where((t) => t.documentId.equals(documentId))
            ..orderBy([(t) => OrderingTerm.asc(t.pageIndex)]))
          .get();

  Future<List<DocumentBookmark>> getAllFavoriteDocumentBookmarks() async {
    final query = select(documentBookmarks).join([
      innerJoin(
        documentRecords,
        documentRecords.id.equalsExp(documentBookmarks.documentId),
      ),
    ])
      ..where(documentRecords.isFavorite.equals(true));
    final rows = await query.get();
    return rows.map((row) => row.readTable(documentBookmarks)).toList();
  }

  Future<int> insertBookmark(DocumentBookmarksCompanion entry) =>
      into(documentBookmarks).insert(entry);

  Future<int> deleteBookmark(int id) =>
      (delete(documentBookmarks)..where((t) => t.id.equals(id))).go();

  // -----------------------------------------------------------------------
  // DocumentVersion queries
  // -----------------------------------------------------------------------

  Future<List<DocumentVersion>> getVersionsForDocument(int documentId) =>
      (select(documentVersions)
            ..where((t) => t.documentId.equals(documentId))
            ..orderBy([(t) => OrderingTerm.desc(t.versionNumber)]))
          .get();

  Future<int> insertVersion(DocumentVersionsCompanion entry) =>
      into(documentVersions).insert(entry);

  Future<int> createVersion({
    required int documentId,
    required String localCopyPath,
    required int versionNumber,
    String? changeDescription,
  }) =>
      insertVersion(
        DocumentVersionsCompanion.insert(
          documentId: documentId,
          versionNumber: versionNumber,
          localCopyPath: localCopyPath,
          createdAt: DateTime.now(),
          changeDescription: Value(changeDescription),
        ),
      );

  // -----------------------------------------------------------------------
  // AppPreference queries
  // -----------------------------------------------------------------------

  Future<String?> getPreference(String key) async {
    final row = await (select(appPreferences)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setPreference(String key, String value) =>
      into(appPreferences).insertOnConflictUpdate(
        AppPreferencesCompanion.insert(
          key: key,
          value: value,
          updatedAt: DateTime.now(),
        ),
      );

  // -----------------------------------------------------------------------
  // Favorites (documents with isFavorite = true)
  // -----------------------------------------------------------------------

  Future<List<DocumentRecord>> getFavoriteDocuments() =>
      (select(documentRecords)
            ..where((t) => t.isFavorite.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.lastOpenedAt)]))
          .get();

  Future<void> toggleFavorite(int documentId, {required bool isFavorite}) =>
      (update(documentRecords)..where((t) => t.id.equals(documentId)))
          .write(DocumentRecordsCompanion(isFavorite: Value(isFavorite)));
}

// ---------------------------------------------------------------------------
// Connection helper
// ---------------------------------------------------------------------------

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'document_reviewer.db'));
    return NativeDatabase.createInBackground(file);
  });
}
