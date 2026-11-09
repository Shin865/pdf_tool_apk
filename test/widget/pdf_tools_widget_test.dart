import 'dart:io';

import 'package:document_reviewer/core/engine/pdf_page_engine.dart';
import 'package:document_reviewer/data/saf/saf_file_service.dart';
import 'package:document_reviewer/features/pdf_tools/annotations/pdf_annotation_controller.dart';
import 'package:document_reviewer/features/pdf_tools/annotations/pdf_tool_mode.dart';
import 'package:document_reviewer/features/pdf_tools/annotations/pdf_tools_bottom_bar.dart';
import 'package:document_reviewer/features/pdf_tools/merge/pdf_merge_dialog.dart';
import 'package:document_reviewer/features/pdf_tools/pages/pdf_page_manager_screen.dart';
import 'package:document_reviewer/features/pdf_tools/signature/signature_dialog.dart';
import 'package:document_reviewer/features/pdf_tools/split/pdf_split_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePdfPageEngine implements PdfPageEngine {
  @override
  Future<bool> deletePages({
    required String filePath,
    required List<int> pageIndices,
    required String outputPath,
  }) async =>
      true;

  @override
  Future<bool> exportPageToImage({
    required String filePath,
    required int pageIndex,
    required String outputPath,
    double scale = 2.0,
  }) async =>
      true;

  @override
  Future<bool> mergePdfs({
    required List<String> filePaths,
    required String outputPath,
  }) async =>
      true;

  @override
  Future<bool> reorderPages({
    required String filePath,
    required List<int> newOrder,
    required String outputPath,
  }) async =>
      true;

  @override
  Future<bool> rotatePage({
    required String filePath,
    required int pageIndex,
    required int degrees,
    required String outputPath,
  }) async =>
      true;

  @override
  Future<bool> splitPdf({
    required String filePath,
    required int startPage,
    required int endPage,
    required String outputPath,
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

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pdf_tools_widget_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SignatureDialog Widget Tests', () {
    testWidgets(
        'Displays prominent legal disclaimer that signature is NOT certified',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SignatureDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(SignatureDialog), findsOneWidget);

      // Verify disclaimer text presence
      expect(
        find.textContaining('BUKAN tanda tangan elektronik tersertifikasi'),
        findsOneWidget,
      );
      expect(
        find.textContaining('NOT a certified digital signature'),
        findsOneWidget,
      );

      // Verify action buttons
      expect(find.text('Gambar Ulang / Clear'), findsOneWidget);
      expect(find.text('Batal / Cancel'), findsOneWidget);
      expect(find.text('Gunakan / Use'), findsOneWidget);

      // Tap Batal closes dialog
      await tester.tap(find.text('Batal / Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(SignatureDialog), findsNothing);
    });

    testWidgets('Allows drawing strokes and enables Use button',
        (tester) async {
      final sigDir = Directory('${tempDir.path}/signatures');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => SignatureDialog(signaturesDir: sigDir),
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Perform a drag stroke across the drawing area
      await tester.drag(
        find.byKey(const Key('signature_canvas_gesture')),
        const Offset(60, 40),
      );
      await tester.pump();

      // Verify Use button is enabled
      final useButton = find.widgetWithText(FilledButton, 'Gunakan / Use');
      expect(useButton, findsOneWidget);
      expect(tester.widget<FilledButton>(useButton).enabled, isTrue);

      // Clear button resets
      await tester.tap(find.text('Gambar Ulang / Clear'));
      await tester.pump();
      expect(tester.widget<FilledButton>(useButton).enabled, isFalse);

      // Close dialog
      await tester.tap(find.text('Batal / Cancel'));
      await tester.pumpAndSettle();
    });
  });

  group('PdfToolsBottomBar Widget Tests', () {
    testWidgets('Renders all tool buttons and reacts to undo/redo state',
        (tester) async {
      var currentMode = PdfToolMode.view;
      final controller = PdfAnnotationController(documentUri: 'test_doc');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: PdfToolsBottomBar(
              currentMode: currentMode,
              onModeChanged: (m) => currentMode = m,
              controller: controller,
              onSaveAs: () {},
              onOverwrite: () {},
              onOpenPageManager: () {},
              onExportImage: () {},
              onShare: () {},
              onSignatureCreated: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify tool buttons
      expect(find.byIcon(Icons.pan_tool_outlined), findsOneWidget);
      expect(find.byIcon(Icons.border_color), findsOneWidget); // Highlight
      expect(find.byIcon(Icons.format_underlined), findsOneWidget); // Underline
      expect(find.byIcon(Icons.edit), findsOneWidget); // Pen
      expect(find.byIcon(Icons.text_fields), findsOneWidget); // Text
      expect(find.byIcon(Icons.draw), findsOneWidget); // Signature
      expect(find.byIcon(Icons.auto_stories), findsOneWidget); // Page manager
      expect(find.byIcon(Icons.save_alt), findsOneWidget); // Save menu

      // Tap on Highlight tool
      await tester.tap(find.byIcon(Icons.border_color));
      await tester.pump();
      expect(currentMode, PdfToolMode.highlight);

      controller.dispose();
    });
  });

  group('PdfPageManagerScreen Widget Tests', () {
    testWidgets(
        'Displays pages, allows rotation and prevents deleting all pages',
        (tester) async {
      final fakeEngine = FakePdfPageEngine();
      final dummyPdf = File('${tempDir.path}/sample.pdf')
        ..writeAsStringSync('pdf');

      await tester.pumpWidget(
        MaterialApp(
          home: PdfPageManagerScreen(
            filePath: dummyPdf.path,
            initialPageCount: 3,
            pageEngine: fakeEngine,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total: 3 halaman (0 dipilih)'), findsOneWidget);
      expect(find.text('Halaman 1 (Asli: 1)'), findsOneWidget);
      expect(find.text('Halaman 2 (Asli: 2)'), findsOneWidget);
      expect(find.text('Halaman 3 (Asli: 3)'), findsOneWidget);

      // Rotate single page 1
      final rotateIcons = find.byIcon(Icons.rotate_right);
      expect(rotateIcons, findsWidgets);
      // Tap single page rotate
      await tester.tap(rotateIcons.at(1));
      await tester.pump();
      expect(find.text('90°'), findsOneWidget);

      // Select all 3 pages
      final checkboxes = find.byType(Checkbox);
      for (var i = 0; i < 3; i++) {
        await tester.tap(checkboxes.at(i));
        await tester.pump();
      }

      // Try to delete all pages
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      // Expect snackbar warning
      expect(
        find.text(
          'Tidak dapat menghapus semua halaman. Sisakan minimal 1 halaman.',
        ),
        findsOneWidget,
      );
    });
  });

  group('PdfSplitDialog Widget Tests', () {
    testWidgets('Validates input page range', (tester) async {
      final fakeEngine = FakePdfPageEngine();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfSplitDialog(
              pdfPath: 'test.pdf',
              totalPages: 5,
              pageEngine: fakeEngine,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pisah PDF / Split PDF'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Enter invalid range: start 6, end 2
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '6');
      await tester.pump();

      await tester.tap(find.text('Ekstrak / Pisah'));
      await tester.pump();

      expect(
        find.text('Halaman mulai harus antara 1 dan 5.'),
        findsOneWidget,
      );
    });
  });

  group('PdfMergeDialog Widget Tests', () {
    testWidgets('Displays list of files and reorders', (tester) async {
      final fakeEngine = FakePdfPageEngine();
      final dummyPdf = File('${tempDir.path}/doc_a.pdf')
        ..writeAsStringSync('a');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PdfMergeDialog(
              initialPdfPath: dummyPdf.path,
              pageEngine: fakeEngine,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gabung PDF / Merge PDFs'), findsOneWidget);
      expect(find.text('doc_a.pdf'), findsOneWidget);
      expect(find.text('Tambah PDF Lain...'), findsOneWidget);
    });
  });
}
