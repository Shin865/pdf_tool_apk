import 'package:document_reviewer/app/providers.dart';
import 'package:document_reviewer/core/constants/app_constants.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/data/repository/document_repository.dart';
import 'package:document_reviewer/data/saf/saf_file_service.dart';
import 'package:document_reviewer/features/home/home_screen.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

Widget createHomeScreen({
  required AppDatabase db,
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(400, 800),
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      safServiceProvider.overrideWithValue(FakeSafFileService()),
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
      home: MediaQuery(
        data: MediaQueryData(size: surfaceSize),
        child: const HomeScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    // Insert sample documents
    final doc1 = await db.insertDocument(
      DocumentRecordsCompanion.insert(
        uri: 'content://test/pdf1',
        displayName: 'Annual Report.pdf',
        mimeType: SupportedMimeTypes.pdf,
        fileSizeBytes: const Value(500000),
        firstOpenedAt: DateTime(2024, 1, 5),
        lastOpenedAt: DateTime(2024, 1, 10),
      ),
    );

    final doc2 = await db.insertDocument(
      DocumentRecordsCompanion.insert(
        uri: 'content://test/docx1',
        displayName: 'Project Brief.docx',
        mimeType: SupportedMimeTypes.docx,
        fileSizeBytes: const Value(120000),
        firstOpenedAt: DateTime(2024, 1, 2),
        lastOpenedAt: DateTime(2024, 1, 12),
        isFavorite: const Value(true),
      ),
    );

    final doc3 = await db.insertDocument(
      DocumentRecordsCompanion.insert(
        uri: 'content://test/img1',
        displayName: 'Architecture Diagram.png',
        mimeType: SupportedMimeTypes.png,
        fileSizeBytes: const Value(800000),
        firstOpenedAt: DateTime(2024, 1, 3),
        lastOpenedAt: DateTime(2024, 1, 15),
      ),
    );

    // Insert recents
    await db.insertRecentDocument(
      RecentDocumentsCompanion.insert(
        documentId: doc1,
        openedAt: DateTime(2024, 1, 10),
      ),
    );
    await db.insertRecentDocument(
      RecentDocumentsCompanion.insert(
        documentId: doc2,
        openedAt: DateTime(2024, 1, 12),
      ),
    );
    await db.insertRecentDocument(
      RecentDocumentsCompanion.insert(
        documentId: doc3,
        openedAt: DateTime(2024, 1, 15),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('HomeScreen Tahap 3 Widget Tests', () {
    testWidgets('Displays search bar and category filter chips',
        (tester) async {
      await tester.pumpWidget(createHomeScreen(db: db));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search documents...'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Images'), findsOneWidget);
      expect(find.text('Text / CSV'), findsOneWidget);
    });

    testWidgets('Filtering by search query displays matching documents',
        (tester) async {
      await tester.pumpWidget(createHomeScreen(db: db));
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField), 'Annual');
      await tester.pumpAndSettle();

      expect(find.text('Annual Report.pdf'), findsOneWidget);
      expect(find.text('Architecture Diagram.png'), findsNothing);
      expect(find.text('Project Brief.docx'), findsNothing);
    });

    testWidgets('Category chip filter selects only PDF documents',
        (tester) async {
      await tester.pumpWidget(createHomeScreen(db: db));
      await tester.pumpAndSettle();

      // Tap PDF filter chip
      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();

      expect(find.text('Annual Report.pdf'), findsOneWidget);
      expect(find.text('Architecture Diagram.png'), findsNothing);
      expect(find.text('Project Brief.docx'), findsNothing);
    });

    testWidgets('Category chip filter selects only Images', (tester) async {
      await tester.pumpWidget(createHomeScreen(db: db));
      await tester.pumpAndSettle();

      // Scroll chip into view and tap
      await tester.ensureVisible(find.text('Images'));
      await tester.tap(find.text('Images'));
      await tester.pumpAndSettle();

      expect(find.text('Architecture Diagram.png'), findsOneWidget);
      expect(find.text('Annual Report.pdf'), findsNothing);
    });

    testWidgets('Sort popup menu exists and opens sort options',
        (tester) async {
      await tester.pumpWidget(createHomeScreen(db: db));
      await tester.pumpAndSettle();

      final sortButton = find.byTooltip('Sort by');
      expect(sortButton, findsOneWidget);

      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      expect(find.text('Name (A-Z)'), findsOneWidget);
      expect(find.text('Name (Z-A)'), findsOneWidget);
      expect(find.text('Date (Newest)'), findsOneWidget);
      expect(find.text('Size (Largest)'), findsOneWidget);
    });

    testWidgets(
        'Remove from list shows confirmation dialog with safe deletion notice',
        (tester) async {
      await tester.pumpWidget(createHomeScreen(db: db));
      await tester.pumpAndSettle();

      // Tap more options on first tile
      final moreButtons = find.byTooltip('Options');
      expect(moreButtons, findsWidgets);

      await tester.tap(moreButtons.first);
      await tester.pumpAndSettle();

      // Tap Remove from list
      final removeOption = find.text('Remove from list');
      expect(removeOption, findsOneWidget);

      await tester.tap(removeOption);
      await tester.pumpAndSettle();

      // Verify safe confirmation dialog
      expect(find.text('Remove from List'), findsOneWidget);
      expect(
        find.text(
          'Remove this document from the list? The original file will not be deleted.',
        ),
        findsOneWidget,
      );

      // Confirm removal
      await tester.tap(find.widgetWithText(FilledButton, 'Remove'));
      await tester.pumpAndSettle();

      // Document removed from UI
      expect(find.text('Architecture Diagram.png'), findsNothing);
    });

    testWidgets('Two-panel adaptive layout on tablet width >= 600',
        (tester) async {
      // Simulate tablet screen width 1024
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      await tester.pumpWidget(
        createHomeScreen(
          db: db,
          surfaceSize: const Size(1024, 768),
        ),
      );
      await tester.pumpAndSettle();

      // Split view elements (NavigationRail divider + master-detail divider)
      expect(find.byType(VerticalDivider), findsNWidgets(2));
      expect(find.text('Select a document to preview'), findsOneWidget);

      // Reset surface size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Indonesian localization displays translated UI strings',
        (tester) async {
      await tester.pumpWidget(
        createHomeScreen(
          db: db,
          locale: const Locale('id'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cari dokumen...'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Gambar'), findsOneWidget);
      expect(find.text('Dokumen Terbaru'), findsOneWidget);
      expect(find.text('Favorit'), findsOneWidget);
    });
  });
}
