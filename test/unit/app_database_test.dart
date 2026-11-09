import 'package:document_reviewer/data/database/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('DocumentRecords', () {
    test('insert and retrieve document', () async {
      final now = DateTime.now();
      final id = await db.insertDocument(
        DocumentRecordsCompanion.insert(
          uri: 'content://test/doc.pdf',
          displayName: 'doc.pdf',
          mimeType: 'application/pdf',
          firstOpenedAt: now,
          lastOpenedAt: now,
        ),
      );

      expect(id, greaterThan(0));

      final doc = await db.getDocumentByUri('content://test/doc.pdf');
      expect(doc, isNotNull);
      expect(doc!.displayName, 'doc.pdf');
      expect(doc.mimeType, 'application/pdf');
      expect(doc.isFavorite, isFalse);
    });

    test('toggle favorite', () async {
      final now = DateTime.now();
      final id = await db.insertDocument(
        DocumentRecordsCompanion.insert(
          uri: 'content://test/doc.pdf',
          displayName: 'doc.pdf',
          mimeType: 'application/pdf',
          firstOpenedAt: now,
          lastOpenedAt: now,
        ),
      );

      await db.toggleFavorite(id, isFavorite: true);
      var doc = await db.getDocumentByUri('content://test/doc.pdf');
      expect(doc!.isFavorite, isTrue);

      await db.toggleFavorite(id, isFavorite: false);
      doc = await db.getDocumentByUri('content://test/doc.pdf');
      expect(doc!.isFavorite, isFalse);
    });

    test('get favorites returns only favorited docs', () async {
      final now = DateTime.now();
      await db.insertDocument(
        DocumentRecordsCompanion.insert(
          uri: 'content://test/a.pdf',
          displayName: 'a.pdf',
          mimeType: 'application/pdf',
          firstOpenedAt: now,
          lastOpenedAt: now,
        ),
      );
      final id2 = await db.insertDocument(
        DocumentRecordsCompanion.insert(
          uri: 'content://test/b.pdf',
          displayName: 'b.pdf',
          mimeType: 'application/pdf',
          firstOpenedAt: now,
          lastOpenedAt: now,
        ),
      );

      await db.toggleFavorite(id2, isFavorite: true);

      final favorites = await db.getFavoriteDocuments();
      expect(favorites.length, 1);
      expect(favorites.first.displayName, 'b.pdf');
    });

    test('delete document', () async {
      final now = DateTime.now();
      final id = await db.insertDocument(
        DocumentRecordsCompanion.insert(
          uri: 'content://test/doc.pdf',
          displayName: 'doc.pdf',
          mimeType: 'application/pdf',
          firstOpenedAt: now,
          lastOpenedAt: now,
        ),
      );

      final deleted = await db.deleteDocument(id);
      expect(deleted, 1);

      final doc = await db.getDocumentByUri('content://test/doc.pdf');
      expect(doc, isNull);
    });

    test('unique URI constraint', () async {
      final now = DateTime.now();
      await db.insertDocument(
        DocumentRecordsCompanion.insert(
          uri: 'content://test/same.pdf',
          displayName: 'same.pdf',
          mimeType: 'application/pdf',
          firstOpenedAt: now,
          lastOpenedAt: now,
        ),
      );

      expect(
        () => db.insertDocument(
          DocumentRecordsCompanion.insert(
            uri: 'content://test/same.pdf',
            displayName: 'same.pdf',
            mimeType: 'application/pdf',
            firstOpenedAt: now,
            lastOpenedAt: now,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AppPreferences', () {
    test('set and get preference', () async {
      await db.setPreference('theme', 'dark');
      final value = await db.getPreference('theme');
      expect(value, 'dark');
    });

    test('update existing preference', () async {
      await db.setPreference('theme', 'dark');
      await db.setPreference('theme', 'light');
      final value = await db.getPreference('theme');
      expect(value, 'light');
    });

    test('get nonexistent preference returns null', () async {
      final value = await db.getPreference('nonexistent');
      expect(value, isNull);
    });
  });

  group('RecentDocuments', () {
    test('insert and retrieve recent documents ordered by date', () async {
      final now = DateTime.now();
      final id = await db.insertDocument(
        DocumentRecordsCompanion.insert(
          uri: 'content://test/doc.pdf',
          displayName: 'doc.pdf',
          mimeType: 'application/pdf',
          firstOpenedAt: now,
          lastOpenedAt: now,
        ),
      );

      await db.insertRecentDocument(
        RecentDocumentsCompanion.insert(
          documentId: id,
          openedAt: now,
        ),
      );

      final recents = await db.getRecentDocuments();
      expect(recents.length, 1);
      expect(recents.first.documentId, id);
    });
  });

  group('DocumentBookmarks', () {
    test('insert and retrieve bookmarks for document', () async {
      final now = DateTime.now();
      final docId = await db.insertDocument(
        DocumentRecordsCompanion.insert(
          uri: 'content://test/doc.pdf',
          displayName: 'doc.pdf',
          mimeType: 'application/pdf',
          firstOpenedAt: now,
          lastOpenedAt: now,
        ),
      );

      await db.insertBookmark(
        DocumentBookmarksCompanion.insert(
          documentId: docId,
          pageIndex: 5,
          createdAt: now,
          label: const Value('Chapter 1'),
        ),
      );

      await db.insertBookmark(
        DocumentBookmarksCompanion.insert(
          documentId: docId,
          pageIndex: 10,
          createdAt: now,
          label: const Value('Chapter 2'),
        ),
      );

      final bookmarks = await db.getBookmarksForDocument(docId);
      expect(bookmarks.length, 2);
      expect(bookmarks.first.pageIndex, 5); // Ordered by page index
      expect(bookmarks.last.pageIndex, 10);
    });
  });
}
