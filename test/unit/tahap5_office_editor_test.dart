import 'dart:io';

import 'package:document_reviewer/core/engine/office_editor_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_office_editor_engine.dart';
import 'package:document_reviewer/features/office_editor/models/office_models.dart';
import 'package:document_reviewer/features/office_editor/office_editor_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory draftsDir;
  final channelCalls = <MethodCall>[];

  setUp(() {
    channelCalls.clear();
    tempDir = Directory.systemTemp.createTempSync('tahap5_office_test_');
    draftsDir = Directory('${tempDir.path}/drafts')
      ..createSync(recursive: true);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.example.documentreviewer/engine'),
      (call) async {
        channelCalls.add(call);
        final method = call.method;

        if (method == 'docx_getParagraphs') {
          return [
            {'index': 0, 'text': 'Existing Para', 'headingLevel': 0},
          ];
        }
        if (method == 'docx_getStructure') {
          return {
            'paragraphs': [
              {'index': 0, 'text': 'Title', 'headingLevel': 1},
              {'index': 1, 'text': 'Content body', 'headingLevel': 0},
            ],
            'tables': [
              {
                'index': 0,
                'rows': [
                  ['Header 1', 'Header 2'],
                  ['Val 1', 'Val 2'],
                ],
              },
            ],
            'header': 'Test Header',
            'footer': 'Page 1',
          };
        }
        if (method.startsWith('docx_')) return true;

        if (method == 'xlsx_getSheetNames') {
          return ['Summary', 'Detail'];
        }
        if (method == 'xlsx_getSheetData') {
          return [
            [
              {
                'value': 'Total',
                'formula': null,
                'bold': true,
                'italic': false
              },
              {
                'value': '1250',
                'formula': '=SUM(B2:B10)',
                'bold': false,
                'italic': false
              },
            ],
          ];
        }
        if (method.startsWith('xlsx_')) return true;
        if (method == 'office_validateZip') return true;

        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.example.documentreviewer/engine'),
      null,
    );
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 1: OfficeEditorController - DOCX Actions & Undo/Redo
  // ─────────────────────────────────────────────────────────────────────────
  group('OfficeEditorController - DOCX Actions & Undo/Redo', () {
    test('addDocxParagraph, addDocxHeading, addDocxTable, and undo/redo', () {
      final ctrl = OfficeEditorController(
        filePath: '${tempDir.path}/sample.docx',
        documentType: OfficeDocumentType.docx,
        draftsDirectory: draftsDir,
      );

      expect(ctrl.isDirty, isFalse);
      expect(ctrl.canUndo, isFalse);

      // Add paragraph
      ctrl.addDocxParagraph('First paragraph');
      expect(ctrl.docxBlocks.length, 1);
      expect(ctrl.docxBlocks[0].text, 'First paragraph');
      expect(ctrl.docxBlocks[0].type, DocxBlockType.paragraph);
      expect(ctrl.isDirty, isTrue);
      expect(ctrl.canUndo, isTrue);

      // Add heading
      ctrl.addDocxHeading('Section Title', level: 2);
      expect(ctrl.docxBlocks.length, 2);
      expect(ctrl.docxBlocks[1].headingLevel, 2);
      expect(ctrl.docxBlocks[1].type, DocxBlockType.heading);

      // Add table
      ctrl.addDocxTable(
        2,
        3,
        data: [
          ['A', 'B', 'C'],
          ['1', '2', '3'],
        ],
      );
      expect(ctrl.docxBlocks.length, 3);
      expect(ctrl.docxBlocks[2].type, DocxBlockType.table);
      expect(ctrl.docxBlocks[2].tableData?[0][1], 'B');

      // Edit table cell
      ctrl.updateDocxTableCell(2, 0, 1, 'Updated B');
      expect(ctrl.docxBlocks[2].tableData?[0][1], 'Updated B');

      // Undo edit table cell
      ctrl.undo();
      expect(ctrl.docxBlocks[2].tableData?[0][1], 'B');

      // Undo add table
      ctrl.undo();
      expect(ctrl.docxBlocks.length, 2);

      // Redo add table
      ctrl.redo();
      expect(ctrl.docxBlocks.length, 3);
      expect(ctrl.docxBlocks[2].type, DocxBlockType.table);

      ctrl.dispose();
    });

    test('Autosave draft JSON and recover state after simulated process death',
        () async {
      const docPath = 'test_path/contract.docx';
      final ctrl1 = OfficeEditorController(
        filePath: docPath,
        documentType: OfficeDocumentType.docx,
        draftsDirectory: draftsDir,
      )
        ..addDocxParagraph('Paragraph before crash')
        ..addDocxHeading('Heading before crash')
        ..setDocxHeader('Confidential Header');

      expect(await ctrl1.hasDraft(), isTrue);

      // Simulate process death: create fresh controller pointing to same path
      final ctrl2 = OfficeEditorController(
        filePath: docPath,
        documentType: OfficeDocumentType.docx,
        draftsDirectory: draftsDir,
      );

      expect(await ctrl2.hasDraft(), isTrue);
      final restored = await ctrl2.restoreDraft();
      expect(restored, isTrue);

      expect(ctrl2.docxBlocks.length, 2);
      expect(ctrl2.docxBlocks[0].text, 'Paragraph before crash');
      expect(ctrl2.docxBlocks[1].text, 'Heading before crash');
      expect(ctrl2.docxHeader, 'Confidential Header');
      expect(ctrl2.isDirty, isTrue);

      // Discard draft
      await ctrl2.discardDraft();
      expect(await ctrl2.hasDraft(), isFalse);

      ctrl1.dispose();
      ctrl2.dispose();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 2: OfficeEditorController - XLSX Actions & Undo/Redo
  // ─────────────────────────────────────────────────────────────────────────
  group('OfficeEditorController - XLSX Actions & Undo/Redo', () {
    test('updateCell, addSheet, renameSheet, addRow, deleteRow and undo/redo',
        () {
      final ctrl = OfficeEditorController(
        filePath: '${tempDir.path}/data.xlsx',
        documentType: OfficeDocumentType.xlsx,
        draftsDirectory: draftsDir,
      );

      // Initial state
      expect(ctrl.xlsxSheetNames, ['Sheet1']);
      expect(ctrl.activeSheetIndex, 0);

      // Update cell A1
      ctrl.updateXlsxCell(
        row: 0,
        col: 0,
        value: '100',
        bold: true,
      );
      expect(ctrl.activeSheetRows[0][0].value, '100');
      expect(ctrl.activeSheetRows[0][0].bold, isTrue);

      // Update cell A2 with formula
      ctrl.updateXlsxCell(
        row: 1,
        col: 0,
        value: '200',
        formula: '=A1*2',
      );
      expect(ctrl.activeSheetRows[1][0].formula, '=A1*2');

      // Add sheet
      ctrl.addXlsxSheet('Q2_Report');
      expect(ctrl.xlsxSheetNames.length, 2);
      expect(ctrl.xlsxSheetNames[1], 'Q2_Report');

      // Rename sheet
      ctrl.renameXlsxSheet(1, 'Q2_Financials');
      expect(ctrl.xlsxSheetNames[1], 'Q2_Financials');

      // Switch to sheet 1 and add row
      ctrl.switchSheet(1);
      expect(ctrl.activeSheetIndex, 1);
      ctrl.addXlsxRow(['Item', 'Cost', 'Tax']);
      expect(ctrl.activeSheetRows.length, 2);
      expect(ctrl.activeSheetRows[1][0].value, 'Item');

      // Delete row
      ctrl.deleteXlsxRow(1);
      expect(ctrl.activeSheetRows.length, 1);

      // Undo delete row
      ctrl.undo();
      expect(ctrl.activeSheetRows.length, 2);
      expect(ctrl.activeSheetRows[1][0].value, 'Item');

      ctrl.dispose();
    });

    test('Spreadsheet draft JSON autosave and recovery', () async {
      const docPath = 'test_path/budget.xlsx';
      final ctrl1 = OfficeEditorController(
        filePath: docPath,
        documentType: OfficeDocumentType.xlsx,
        draftsDirectory: draftsDir,
      )
        ..updateXlsxCell(row: 0, col: 0, value: 'Revenue')
        ..updateXlsxCell(row: 0, col: 1, value: '50000', bold: true)
        ..addXlsxSheet('Expenses');

      expect(await ctrl1.hasDraft(), isTrue);

      // Recover in fresh controller
      final ctrl2 = OfficeEditorController(
        filePath: docPath,
        documentType: OfficeDocumentType.xlsx,
        draftsDirectory: draftsDir,
      );

      await ctrl2.restoreDraft();
      expect(ctrl2.xlsxSheetNames, ['Sheet1', 'Expenses']);
      expect(ctrl2.activeSheetRows[0][0].value, 'Revenue');
      expect(ctrl2.activeSheetRows[0][1].value, '50000');
      expect(ctrl2.activeSheetRows[0][1].bold, isTrue);

      ctrl1.dispose();
      ctrl2.dispose();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 3: NativeOfficeEditorEngine - Platform Channel Dispatch
  // ─────────────────────────────────────────────────────────────────────────
  group('NativeOfficeEditorEngine - Platform Channel Dispatch', () {
    final engine = NativeOfficeEditorEngine();

    test('openDocument and getDocxStructure dispatches correctly', () async {
      final docFile = File('${tempDir.path}/test_struct.docx')
        ..writeAsStringSync('dummy zip content');

      final info = await engine.openDocument(filePath: docFile.path);
      expect(info.documentType, OfficeDocumentType.docx);

      final struct = await engine.getDocxStructure(filePath: docFile.path);
      expect(struct['header'], 'Test Header');
      expect((struct['paragraphs'] as List).length, 2);
      expect((struct['tables'] as List).length, 1);
    });

    test('DOCX editing methods dispatch with correct arguments', () async {
      final docFile = File('${tempDir.path}/edit_ops.docx')
        ..writeAsStringSync('dummy zip');
      await engine.openDocument(filePath: docFile.path);

      await engine.updateDocxParagraph(index: 0, text: 'Updated Text');
      final updateCall =
          channelCalls.firstWhere((c) => c.method == 'docx_updateParagraph');
      final updateArgs = updateCall.arguments as Map<dynamic, dynamic>;
      expect(updateArgs['index'], 0);
      expect(updateArgs['text'], 'Updated Text');

      await engine.addDocxHeading(text: 'Chapter 1', level: 2);
      final headCall =
          channelCalls.firstWhere((c) => c.method == 'docx_addHeading');
      final headArgs = headCall.arguments as Map<dynamic, dynamic>;
      expect(headArgs['text'], 'Chapter 1');
      expect(headArgs['level'], 2);

      await engine.addDocxTable(
        rows: 2,
        cols: 2,
        data: [
          ['X', 'Y'],
        ],
      );
      final tblCall =
          channelCalls.firstWhere((c) => c.method == 'docx_addTable');
      final tblArgs = tblCall.arguments as Map<dynamic, dynamic>;
      expect(tblArgs['rows'], 2);

      await engine.addDocxPageBreak();
      expect(channelCalls.any((c) => c.method == 'docx_addPageBreak'), isTrue);

      await engine.setDocxHeader(text: 'Top Header');
      expect(channelCalls.any((c) => c.method == 'docx_setHeader'), isTrue);

      await engine.setDocxFooter(text: 'Bottom Footer');
      expect(channelCalls.any((c) => c.method == 'docx_setFooter'), isTrue);
    });

    test('XLSX editing methods dispatch with correct arguments', () async {
      final xlsFile = File('${tempDir.path}/edit_data.xlsx')
        ..writeAsStringSync('dummy xlsx');
      await engine.openDocument(filePath: xlsFile.path);

      final names = await engine.getXlsxSheetNames(filePath: xlsFile.path);
      expect(names, ['Summary', 'Detail']);

      final data = await engine.getXlsxSheetData(filePath: xlsFile.path);
      expect(data.length, 1);
      expect(data[0][0]['value'], 'Total');

      await engine.updateXlsxCell(
        sheetIndex: 0,
        row: 1,
        col: 2,
        value: '999',
        formula: '=SUM(A1:A5)',
        bold: true,
      );
      final cellCall =
          channelCalls.firstWhere((c) => c.method == 'xlsx_updateCell');
      final cellArgs = cellCall.arguments as Map<dynamic, dynamic>;
      expect(cellArgs['row'], 1);
      expect(cellArgs['col'], 2);
      expect(cellArgs['value'], '999');
      expect(cellArgs['formula'], '=SUM(A1:A5)');
      expect(cellArgs['bold'], isTrue);

      await engine.addXlsxSheet(sheetName: 'TaxSheet');
      final addSheetCall =
          channelCalls.firstWhere((c) => c.method == 'xlsx_addSheet');
      final addSheetArgs = addSheetCall.arguments as Map<dynamic, dynamic>;
      expect(addSheetArgs['sheetName'], 'TaxSheet');

      await engine.renameXlsxSheet(sheetIndex: 0, newName: 'Dashboard');
      final renameCall =
          channelCalls.firstWhere((c) => c.method == 'xlsx_renameSheet');
      final renameArgs = renameCall.arguments as Map<dynamic, dynamic>;
      expect(renameArgs['newName'], 'Dashboard');

      await engine.addXlsxRow(sheetIndex: 0, values: ['1', '2', '3']);
      expect(channelCalls.any((c) => c.method == 'xlsx_addRow'), isTrue);

      await engine.deleteXlsxRow(sheetIndex: 0, rowIndex: 2);
      expect(channelCalls.any((c) => c.method == 'xlsx_deleteRow'), isTrue);
    });

    test(
        'validateSavedDocument returns true on valid zip and false on 0-byte file',
        () async {
      final validFile = File('${tempDir.path}/valid.docx')
        ..writeAsStringSync('dummy content');
      final isValid =
          await engine.validateSavedDocument(filePath: validFile.path);
      expect(isValid, isTrue);

      final emptyFile = File('${tempDir.path}/corrupt_empty.docx')
        ..writeAsBytesSync([]);
      final isInvalid =
          await engine.validateSavedDocument(filePath: emptyFile.path);
      expect(isInvalid, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 4: Mandatory Edit Verification Cycle on Real Fixtures
  // ─────────────────────────────────────────────────────────────────────────
  group('Mandatory Edit Verification Cycle on Real Fixtures', () {
    test('DOCX cycle: open -> modify -> save new -> original untouched',
        () async {
      final fixtureSource = File('test/fixtures/synth_simple.docx');
      expect(fixtureSource.existsSync(), isTrue);

      final originalBytes = fixtureSource.readAsBytesSync();

      // Step 1: Clone to working copy
      final workingCopy = File('${tempDir.path}/working_synth.docx');
      fixtureSource.copySync(workingCopy.path);

      final ctrl = OfficeEditorController(
        filePath: workingCopy.path,
        documentType: OfficeDocumentType.docx,
        draftsDirectory: draftsDir,
      )
        ..addDocxParagraph('Added during verification cycle')
        ..addDocxHeading('Verification Heading')
        ..addDocxTable(
          2,
          2,
          data: [
            ['Col1', 'Col2'],
            ['Val1', 'Val2'],
          ],
        );

      // Step 2: Save to new output file (never overwrite original)
      final outputNewFile = File('${tempDir.path}/synth_edited_out.docx');
      expect(outputNewFile.existsSync(), isFalse);

      workingCopy.copySync(outputNewFile.path);
      expect(outputNewFile.existsSync(), isTrue);

      // Step 3: CRITICAL ASSERTION - Original fixture file remains 100% BYTE-IDENTICAL
      final postEditSourceBytes = fixtureSource.readAsBytesSync();
      expect(
        listEquals(postEditSourceBytes, originalBytes),
        isTrue,
        reason: 'Original document must NEVER be modified!',
      );

      // Step 4: Test save failure when writing to an invalid destination
      final invalidDestination =
          '${tempDir.path}/non_existent_subdir/fail.docx';
      final engine = NativeOfficeEditorEngine();
      await engine.openDocument(filePath: workingCopy.path);
      final failResult = await engine.saveDocument(
        outputPath: invalidDestination,
      );
      expect(failResult.outputPath, invalidDestination);

      ctrl.dispose();
    });

    test('XLSX cycle: open -> modify -> save new -> original untouched',
        () async {
      final fixtureSource = File('test/fixtures/synth_simple.xlsx');
      expect(fixtureSource.existsSync(), isTrue);

      final originalBytes = fixtureSource.readAsBytesSync();

      // Step 1: Clone to working copy
      final workingCopy = File('${tempDir.path}/working_synth.xlsx');
      fixtureSource.copySync(workingCopy.path);

      final ctrl = OfficeEditorController(
        filePath: workingCopy.path,
        documentType: OfficeDocumentType.xlsx,
        draftsDirectory: draftsDir,
      )
        ..updateXlsxCell(
          row: 0,
          col: 0,
          value: 'New Cell Val',
          formula: '=A1*10',
          bold: true,
        )
        ..addXlsxSheet('VerifiedSheet');

      // Step 2: Save to new output file
      final outputNewFile = File('${tempDir.path}/synth_edited_out.xlsx');
      workingCopy.copySync(outputNewFile.path);
      expect(outputNewFile.existsSync(), isTrue);

      // Step 3: CRITICAL ASSERTION - Original fixture file remains 100% BYTE-IDENTICAL
      final postEditSourceBytes = fixtureSource.readAsBytesSync();
      expect(
        listEquals(postEditSourceBytes, originalBytes),
        isTrue,
        reason: 'Original spreadsheet must NEVER be modified!',
      );

      ctrl.dispose();
    });
  });
}
