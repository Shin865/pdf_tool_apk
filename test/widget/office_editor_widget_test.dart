import 'dart:io';

import 'package:document_reviewer/core/engine/office_editor_engine.dart';
import 'package:document_reviewer/features/office_editor/office_editor_controller.dart';
import 'package:document_reviewer/features/office_editor/ui/docx_editor_widget.dart';
import 'package:document_reviewer/features/office_editor/ui/office_adaptive_toolbar.dart';
import 'package:document_reviewer/features/office_editor/ui/xlsx_editor_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory draftsDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('tahap5_widget_test_');
    draftsDir = Directory('${tempDir.path}/drafts')
      ..createSync(recursive: true);
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('DocxEditorWidget Widget Tests', () {
    testWidgets('Renders headings, paragraphs, tables and add block buttons',
        (tester) async {
      final ctrl = OfficeEditorController(
        filePath: '${tempDir.path}/test.docx',
        documentType: OfficeDocumentType.docx,
        draftsDirectory: draftsDir,
      )
        ..addDocxHeading('Main Title')
        ..addDocxParagraph('Introductory paragraph text')
        ..addDocxTable(
          2,
          2,
          data: [
            ['Header A', 'Header B'],
            ['Row 1A', 'Row 1B'],
          ],
        );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DocxEditorWidget(controller: ctrl),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Main Title'), findsOneWidget);
      expect(find.text('Introductory paragraph text'), findsOneWidget);
      expect(find.text('Header A'), findsOneWidget);
      expect(find.text('Row 1A'), findsOneWidget);

      // Verify Add Block buttons exist
      expect(find.text('+ Paragraf'), findsOneWidget);
      expect(find.text('+ Heading'), findsOneWidget);
      expect(find.text('+ Tabel'), findsOneWidget);
      expect(find.text('+ Page Break'), findsOneWidget);

      ctrl.dispose();
    });
  });

  group('XlsxEditorWidget Widget Tests', () {
    testWidgets('Renders sheet tabs, formula bar, and spreadsheet cells',
        (tester) async {
      final ctrl = OfficeEditorController(
        filePath: '${tempDir.path}/test.xlsx',
        documentType: OfficeDocumentType.xlsx,
        draftsDirectory: draftsDir,
      )
        ..updateXlsxCell(
          row: 0,
          col: 0,
          value: 'Revenue',
          formula: '=SUM(A1:A10)',
          bold: true,
        )
        ..addXlsxSheet('Expenses');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: XlsxEditorWidget(controller: ctrl),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check sheet tabs
      expect(find.text('Sheet1'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);

      // Check formula bar
      expect(find.text('fx'), findsOneWidget);
      expect(find.text('A1'), findsOneWidget);
      expect(find.text('=SUM(A1:A10)'), findsOneWidget);

      // Check cell value
      expect(find.text('Revenue'), findsOneWidget);

      // Check row action buttons
      expect(find.text('Baris / + Row'), findsOneWidget);

      ctrl.dispose();
    });
  });

  group('OfficeAdaptiveToolbar Widget Tests', () {
    testWidgets('Displays tablet ribbon on width >= 600', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctrl = OfficeEditorController(
        filePath: '${tempDir.path}/tablet.docx',
        documentType: OfficeDocumentType.docx,
        draftsDirectory: draftsDir,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfficeAdaptiveToolbar(
              controller: ctrl,
              onSaveAs: () {},
              onOverwrite: () {},
              onAddParagraph: () {},
              onAddHeading: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Simpan Baru / Save As'), findsOneWidget);
      expect(find.text('Timpa / Overwrite'), findsOneWidget);
      expect(find.text('Paragraf'), findsOneWidget);
      expect(find.text('Heading'), findsOneWidget);

      ctrl.dispose();
    });

    testWidgets('Displays mobile bottom bar on width < 600', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ctrl = OfficeEditorController(
        filePath: '${tempDir.path}/phone.docx',
        documentType: OfficeDocumentType.docx,
        draftsDirectory: draftsDir,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfficeAdaptiveToolbar(
              controller: ctrl,
              onSaveAs: () {},
              onOverwrite: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Simpan'), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);

      ctrl.dispose();
    });
  });

  group('OfficeKeyboardShortcuts Widget Tests', () {
    testWidgets('Keyboard shortcuts trigger undo and redo', (tester) async {
      final ctrl = OfficeEditorController(
        filePath: '${tempDir.path}/shortcuts.docx',
        documentType: OfficeDocumentType.docx,
        draftsDirectory: draftsDir,
      )..addDocxParagraph('P1');

      expect(ctrl.docxBlocks.length, 1);
      expect(ctrl.canUndo, isTrue);

      var saveCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfficeKeyboardShortcuts(
              controller: ctrl,
              onSave: () => saveCalled = true,
              child: const Text('Editor Child'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger Ctrl+Z (Undo)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      expect(ctrl.docxBlocks.length, 0);
      expect(ctrl.canRedo, isTrue);

      // Trigger Ctrl+Y (Redo)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      expect(ctrl.docxBlocks.length, 1);

      // Trigger Ctrl+S (Save)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      expect(saveCalled, isTrue);

      ctrl.dispose();
    });
  });
}
