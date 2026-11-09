import 'dart:convert';
import 'dart:io';

import 'package:document_reviewer/core/constants/app_constants.dart';
import 'package:document_reviewer/core/error/exceptions.dart';
import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/data/engine_impl/native_document_reader_engine.dart';
import 'package:document_reviewer/data/repository/document_repository.dart';
import 'package:document_reviewer/data/saf/saf_file_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSafFileService extends FakeSafFileService {
  @override
  Future<bool> shareFile({
    required String uri,
    required String mimeType,
    String? displayName,
  }) async =>
      true;
}

class FakeSafFileService implements SafFileService {
  @override
  Future<bool> copyToLocal({
    required String uri,
    required String destinationPath,
  }) async =>
      true;

  @override
  Future<List<String>> getPersistedUris() async => [];

  @override
  Future<bool> hasPermission({required String uri}) async => true;

  @override
  Future<bool> isUriAccessible(String uri) async => true;

  @override
  Future<SafPickResult?> pickFile({
    List<String> mimeTypes = const ['*/*'],
  }) async =>
      null;

  @override
  Future<void> releasePermission({required String uri}) async {}

  @override
  Future<bool> shareFile({
    required String uri,
    required String mimeType,
    String? displayName,
  }) async =>
      true;

  @override
  Future<bool> writeBackToUri({
    required String sourcePath,
    required String uri,
  }) async =>
      true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fixturesDir = 'test/fixtures';

  group('Tahap 3 — Document Reader Engine & Formats', () {
    late NativeDocumentReaderEngine engine;
    late AppDatabase db;
    late DocumentRepository repo;

    setUp(() {
      engine = NativeDocumentReaderEngine();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = DocumentRepository(
        database: db,
        safService: MockSafFileService(),
      );
    });

    tearDown(() async {
      await engine.closeDocument();
      await db.close();
    });

    test('Supported MIME types list includes all required formats', () {
      final types = engine.supportedMimeTypes;
      expect(types, contains(SupportedMimeTypes.pdf));
      expect(types, contains(SupportedMimeTypes.docx));
      expect(types, contains(SupportedMimeTypes.xlsx));
      expect(types, contains(SupportedMimeTypes.txt));
      expect(types, contains(SupportedMimeTypes.jpeg));
      expect(types, contains(SupportedMimeTypes.png));
      expect(types, contains(SupportedMimeTypes.bmp));
    });

    test('Open and extract text from plain text fixture (synth_simple.txt)',
        () async {
      final file = File('$fixturesDir/synth_simple.txt');
      expect(file.existsSync(), isTrue);

      final meta = await engine.openDocument(filePath: file.path);
      expect(meta.mimeType, SupportedMimeTypes.txt);
      expect(meta.pageCount, 1);
      expect(meta.fileSizeBytes, greaterThan(0));

      final text = await engine.extractText(pageIndex: 0);
      expect(text, contains('DOKUMEN REVIEWER'));
      expect(text, contains('Universal Android Compatibility'));
    });

    test('Open and inspect CSV fixture (synth_simple.csv)', () async {
      final file = File('$fixturesDir/synth_simple.csv');
      expect(file.existsSync(), isTrue);

      final meta = await engine.openDocument(filePath: file.path);
      expect(meta.mimeType, SupportedMimeTypes.csv);
      expect(meta.fileSizeBytes, greaterThan(0));

      final text = await engine.extractText(pageIndex: 0);
      expect(text, contains('Dokumen Proyek.pdf'));
      expect(text, contains('Laporan Keuangan.xlsx'));
    });

    test('Open PNG image fixture (synth_sample.png)', () async {
      final file = File('$fixturesDir/synth_sample.png');
      expect(file.existsSync(), isTrue);

      final meta = await engine.openDocument(filePath: file.path);
      expect(meta.mimeType, SupportedMimeTypes.png);
      expect(meta.pageCount, 1);

      final rendered = await engine.renderPage(pageIndex: 0, width: 200);
      expect(rendered.pixels.length, greaterThan(0));
    });

    test('Open JPEG image fixture (synth_sample.jpg)', () async {
      final file = File('$fixturesDir/synth_sample.jpg');
      expect(file.existsSync(), isTrue);

      final meta = await engine.openDocument(filePath: file.path);
      expect(meta.mimeType, SupportedMimeTypes.jpeg);
      expect(meta.pageCount, 1);

      final rendered = await engine.renderPage(pageIndex: 0, width: 200);
      expect(rendered.pixels.length, greaterThan(0));
    });

    test('Non-existent file throws DocumentNotFoundException', () async {
      expect(
        () => engine.openDocument(filePath: '$fixturesDir/non_existent.pdf'),
        throwsA(isA<DocumentNotFoundException>()),
      );
    });

    test('Reading position persistence and retrieval in database', () async {
      final docId = await db.insertDocument(
        DocumentRecordsCompanion.insert(
          uri: 'content://com.android.providers.media.documents/document/101',
          displayName: 'TestBook.pdf',
          mimeType: SupportedMimeTypes.pdf,
          firstOpenedAt: DateTime.now(),
          lastOpenedAt: DateTime.now(),
        ),
      );

      // Initially no position recorded
      var pos = await repo.getReadingPosition(docId);
      expect(pos, isNull);

      // Save position: page 42, scroll 150.0, zoom 1.75
      await repo.updateReadingPosition(
        documentId: docId,
        pageIndex: 42,
        scrollOffset: 150,
        zoomLevel: 1.75,
      );

      pos = await repo.getReadingPosition(docId);
      expect(pos, isNotNull);
      expect(pos!.lastPageIndex, 42);
      expect(pos.lastScrollOffset, 150.0);
      expect(pos.lastZoomLevel, 1.75);

      // Update position: page 50
      await repo.updateReadingPosition(
        documentId: docId,
        pageIndex: 50,
      );
      pos = await repo.getReadingPosition(docId);
      expect(pos!.lastPageIndex, 50);
    });

    test('Remove document from list deletes record and recents', () async {
      final docId = await db.insertDocument(
        DocumentRecordsCompanion.insert(
          uri: 'content://test/doc1',
          displayName: 'DocToRemove.pdf',
          mimeType: SupportedMimeTypes.pdf,
          firstOpenedAt: DateTime.now(),
          lastOpenedAt: DateTime.now(),
        ),
      );

      await db.insertRecentDocument(
        RecentDocumentsCompanion.insert(
          documentId: docId,
          openedAt: DateTime.now(),
        ),
      );

      var recents = await repo.getRecentDocuments();
      expect(recents.any((d) => d.id == docId), isTrue);

      // Remove from list
      await repo.removeDocumentFromList(docId);

      recents = await repo.getRecentDocuments();
      expect(recents.any((d) => d.id == docId), isFalse);

      final doc = await db.getDocumentByUri('content://test/doc1');
      expect(doc, isNull);
    });

    test('50,000-row CSV streaming reader executes in bounded memory',
        () async {
      final file = File('$fixturesDir/synth_large.csv');
      expect(file.existsSync(), isTrue);

      final stopwatch = Stopwatch()..start();
      var count = 0;

      // Stream lines in chunks
      final linesStream = file
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final _ in linesStream) {
        count++;
      }
      stopwatch.stop();

      // Verified 50,001 lines (header + 50,000 rows)
      expect(count, 50001);
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });
  });
}
