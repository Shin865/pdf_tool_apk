import 'dart:io';
import 'dart:typed_data';

import 'package:document_reviewer/app/providers.dart';
import 'package:document_reviewer/core/constants/app_constants.dart';
import 'package:document_reviewer/core/engine/document_reader_engine.dart';
import 'package:document_reviewer/core/error/exceptions.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/data/repository/document_repository.dart';
import 'package:document_reviewer/data/saf/saf_file_service.dart';
import 'package:document_reviewer/features/document_reader/document_reader_screen.dart';
import 'package:document_reviewer/features/document_reader/viewers/image_reader_view.dart';
import 'package:document_reviewer/features/document_reader/viewers/pdf_reader_view.dart';
import 'package:document_reviewer/features/document_reader/viewers/text_csv_reader_view.dart';
import 'package:document_reviewer/features/document_reader/widgets/password_dialog.dart';
import 'package:document_reviewer/features/document_reader/widgets/reader_error_view.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockReaderEngine implements DocumentReaderEngine {
  MockReaderEngine({this.pageCount = 5});

  final int pageCount;
  int renderedPagesCount = 0;
  final List<int> renderedPageIndices = [];

  @override
  List<String> get supportedMimeTypes => [
        SupportedMimeTypes.pdf,
        SupportedMimeTypes.txt,
        SupportedMimeTypes.jpeg,
        SupportedMimeTypes.png,
      ];

  @override
  Future<void> closeDocument() async {}

  @override
  Future<String> extractText({required int pageIndex}) async {
    return 'Sample text for page $pageIndex';
  }

  @override
  Future<List<DocumentOutlineEntry>> getOutline() async => [];

  @override
  Future<DocumentMetadata> openDocument({
    required String filePath,
    String? password,
  }) async {
    if (filePath.contains('corrupted')) {
      throw DocumentCorruptedException(filePath, 'Invalid header');
    }
    if (filePath.contains('encrypted') && password != 'secret') {
      throw DocumentEncryptedException(filePath);
    }
    return DocumentMetadata(
      title: 'Mock Document',
      pageCount: pageCount,
      mimeType: SupportedMimeTypes.pdf,
      fileSizeBytes: 1024,
    );
  }

  @override
  Future<RenderedPage> renderPage({
    required int pageIndex,
    required int width,
    double zoom = 1.0,
  }) async {
    renderedPagesCount++;
    renderedPageIndices.add(pageIndex);
    // Return dummy 1x1 transparent PNG bytes
    return RenderedPage(
      pageIndex: pageIndex,
      width: width,
      height: (width * 1.4).toInt(),
      pixels: Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]),
    );
  }

  @override
  Future<List<TextSearchResult>> searchText({
    required String query,
    List<int>? pageIndices,
    bool caseSensitive = false,
  }) async {
    if (query == 'found') {
      return const [
        TextSearchResult(pageIndex: 2, text: 'found match here', rects: []),
        TextSearchResult(pageIndex: 4, text: 'found another match', rects: []),
      ];
    }
    return [];
  }
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

Widget createReaderScreen({
  required String uri,
  String? displayName,
  String? mimeType,
  DocumentReaderEngine? engine,
  AppDatabase? database,
  Locale locale = const Locale('en'),
}) {
  final db = database ?? AppDatabase.forTesting(NativeDatabase.memory());
  final eng = engine ?? MockReaderEngine();

  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      safServiceProvider.overrideWithValue(FakeSafFileService()),
      documentReaderEngineProvider.overrideWithValue(eng),
      documentRepositoryProvider.overrideWithValue(
        DocumentRepository(
          database: db,
          safService: FakeSafFileService(),
        ),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: DocumentReaderScreen(
        uri: uri,
        displayName: displayName,
        mimeType: mimeType,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fixturesDir = 'test/fixtures';

  group('DocumentReaderScreen & Viewers Widget Tests', () {
    testWidgets('PasswordDialog returns entered password', (tester) async {
      String? returnedPassword;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    returnedPassword = await PasswordDialog.show(context);
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Password Protected'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'secret123');
      await tester.tap(find.widgetWithText(FilledButton, 'Open Document'));
      await tester.pumpAndSettle();

      expect(returnedPassword, 'secret123');
    });

    testWidgets('ReaderErrorView renders for corrupted document with retry',
        (tester) async {
      var retryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: ReaderErrorView(
              error: const DocumentCorruptedException('test.pdf', 'Bad header'),
              onRetry: () {
                retryClicked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Document Corrupted'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryClicked, isTrue);
    });

    testWidgets('PdfReaderView navigates pages and handles LRU cache',
        (tester) async {
      final engine = MockReaderEngine(pageCount: 10);
      const meta = DocumentMetadata(
        title: 'Report.pdf',
        pageCount: 10,
        mimeType: SupportedMimeTypes.pdf,
      );

      int? changedPage;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: PdfReaderView(
              engine: engine,
              metadata: meta,
              maxCachePages: 3,
              onPageChanged: (page) {
                changedPage = page;
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Initially page 0 is rendered
      expect(find.text('1 / 10'), findsOneWidget);
      expect(engine.renderedPageIndices, contains(0));

      // Navigate to next page
      final nextBtn = find.byTooltip('Next page');
      expect(nextBtn, findsOneWidget);

      await tester.tap(nextBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('2 / 10'), findsOneWidget);
      expect(changedPage, 1);
      expect(engine.renderedPageIndices, contains(1));
    });

    testWidgets('PdfReaderView text search jumps to matching page',
        (tester) async {
      const meta = DocumentMetadata(
        title: 'Report.pdf',
        pageCount: 5,
        mimeType: SupportedMimeTypes.pdf,
      );

      final engine = MockReaderEngine();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: PdfReaderView(
              engine: engine,
              metadata: meta,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap search FAB
      final searchFab = find.byTooltip('Search in document');
      expect(searchFab, findsOneWidget);
      await tester.tap(searchFab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Search bar input
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'found');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Expect match found counter
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('TextCsvReaderView displays plain text lines and line numbers',
        (tester) async {
      final txtFile = File('$fixturesDir/synth_simple.txt');
      expect(txtFile.existsSync(), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: TextCsvReaderView(filePath: txtFile.path),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('DOKUMEN REVIEWER'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // Line 1
      expect(find.text('5 lines'), findsOneWidget);
    });

    testWidgets('TextCsvReaderView displays CSV data table with columns',
        (tester) async {
      final csvFile = File('$fixturesDir/synth_simple.csv');
      expect(csvFile.existsSync(), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: TextCsvReaderView(
              filePath: csvFile.path,
              isCsv: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nama'), findsOneWidget);
      expect(find.text('Format'), findsOneWidget);
      expect(find.text('Dokumen Proyek.pdf'), findsOneWidget);
      expect(find.text('Laporan Keuangan.xlsx'), findsOneWidget);
    });

    testWidgets('ImageReaderView renders image and rotates 90 degrees',
        (tester) async {
      final imgFile = File('$fixturesDir/synth_sample.png');
      expect(imgFile.existsSync(), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageReaderView(filePath: imgFile.path),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(RotatedBox), findsOneWidget);

      final rotBefore = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(rotBefore.quarterTurns, 0);

      // Tap rotate button
      final rotateBtn = find.byTooltip('Rotate 90°');
      expect(rotateBtn, findsOneWidget);
      await tester.tap(rotateBtn);
      await tester.pumpAndSettle();

      final rotAfter = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(rotAfter.quarterTurns, 1);
    });
  });
}
