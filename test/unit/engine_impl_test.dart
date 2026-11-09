import 'dart:io';

import 'package:document_reviewer/core/engine/ocr_engine.dart';
import 'package:document_reviewer/core/engine/office_editor_engine.dart';
import 'package:document_reviewer/core/engine/pdf_annotation_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_document_reader_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_ocr_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_office_editor_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_pdf_annotation_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_scanner_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.documentreviewer/engine');
  final log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      log.add(call);
      switch (call.method) {
        case 'pdf_getPageCount':
          return 5;
        case 'pdf_renderPage':
          final out = (call.arguments as Map?)?['outputPath'] as String?;
          if (out != null) {
            File(out).writeAsBytesSync([137, 80, 78, 71]);
          }
          return {
            'width': 200,
            'height': 300,
          };
        case 'pdf_searchText':
          return [
            {
              'pageIndex': 0,
              'snippet': 'hello',
              'text': 'hello',
              'rects': [
                [10.0, 20.0, 40.0, 60.0],
              ],
            },
          ];
        case 'pdf_addHighlight':
          return true;
        case 'docx_getParagraphs':
          return [
            {'index': 0, 'text': 'Hello world'},
            {'index': 1, 'text': 'Second line'},
          ];
        case 'docx_updateParagraph':
          return true;
        case 'docx_appendParagraph':
          return true;
        case 'xlsx_getSheetNames':
          return ['Sheet1', 'Summary'];
        case 'xlsx_updateCell':
          return true;
        case 'scanner_detectEdges':
          return {
            'corners': [
              {'x': 10.0, 'y': 10.0},
              {'x': 100.0, 'y': 10.0},
              {'x': 100.0, 'y': 200.0},
              {'x': 10.0, 'y': 200.0},
            ],
            'confidence': 0.95,
          };
        case 'scanner_warpPerspective':
          return {
            'outputPath': 'warped.jpg',
            'width': 800,
            'height': 600,
          };
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('Engine Implementations Unit Tests', () {
    late File dummyPdf;
    late File dummyDocx;
    late File dummyXlsx;
    late File dummyImg;

    setUp(() {
      final tmp = Directory.systemTemp.path;
      dummyPdf = File('$tmp/test_engine.pdf')..writeAsStringSync('dummy pdf');
      dummyDocx = File('$tmp/test_engine.docx')
        ..writeAsStringSync('dummy docx');
      dummyXlsx = File('$tmp/test_engine.xlsx')
        ..writeAsStringSync('dummy xlsx');
      dummyImg = File('$tmp/test_engine.png')..writeAsStringSync('dummy img');
    });

    tearDown(() {
      if (dummyPdf.existsSync()) dummyPdf.deleteSync();
      if (dummyDocx.existsSync()) dummyDocx.deleteSync();
      if (dummyXlsx.existsSync()) dummyXlsx.deleteSync();
      if (dummyImg.existsSync()) dummyImg.deleteSync();
    });

    test('NativeDocumentReaderEngine opens PDF and delegates to channel',
        () async {
      final engine = NativeDocumentReaderEngine();
      final meta = await engine.openDocument(filePath: dummyPdf.path);

      expect(meta.pageCount, 5);
      expect(meta.title, 'test_engine');
      expect(log.any((call) => call.method == 'pdf_getPageCount'), isTrue);

      final rendered = await engine.renderPage(pageIndex: 0, width: 200);
      expect(rendered, isNotNull);

      final searchResults = await engine.searchText(query: 'hello');
      expect(searchResults.length, 1);
      expect(searchResults.first.text, 'hello');
      expect(searchResults.first.pageIndex, 0);
    });

    test('NativeOfficeEditorEngine interacts with DOCX and XLSX', () async {
      final engine = NativeOfficeEditorEngine();

      final docxInfo = await engine.openDocument(filePath: dummyDocx.path);
      expect(docxInfo.documentType, OfficeDocumentType.docx);

      final updated = await engine.updateDocxParagraph(
        index: 0,
        text: 'New Paragraph Text',
      );
      expect(updated, isTrue);

      final xlsxInfo = await engine.openDocument(filePath: dummyXlsx.path);
      expect(xlsxInfo.documentType, OfficeDocumentType.xlsx);
      expect(xlsxInfo.sheetNames, contains('Sheet1'));

      final cellUpdated = await engine.updateXlsxCell(
        sheetIndex: 0,
        row: 1,
        col: 1,
        value: 'New Cell Val',
      );
      expect(cellUpdated, isTrue);
    });

    test('NativePdfAnnotationEngine saves highlight annotation', () async {
      final engine = NativePdfAnnotationEngine();
      await engine.openForAnnotation(filePath: dummyPdf.path);

      final addedId = await engine.addAnnotation(
        PdfAnnotation(
          id: 'hl-1',
          type: AnnotationType.highlight,
          pageIndex: 0,
          rect: const [10, 20, 30, 40],
          createdAt: DateTime.now(),
        ),
      );
      expect(addedId, 'hl-1');
      expect(log.any((call) => call.method == 'pdf_addHighlight'), isTrue);
    });

    test('NativeDocumentScannerEngine detects quad and processes scan',
        () async {
      final engine = NativeDocumentScannerEngine();
      await engine.initialize();
      expect(engine.isInitialized, isTrue);

      final edge = await engine.detectEdges(imagePath: dummyImg.path);
      expect(edge, isNotNull);
      expect(edge!.confidence, 0.95);
      expect(edge.corners.length, 4);

      final scanResult = await engine.processImage(imagePath: dummyImg.path);
      expect(scanResult.processedImagePath, isNotEmpty);
    });

    test('NativeOcrEngine processes offline OCR with Indonesian and English',
        () async {
      final engine = NativeOcrEngine();
      await engine.initialize(
        tessdataPath: '/fake/path',
        languages: [OcrLanguage.indonesian, OcrLanguage.english],
      );

      expect(engine.isInitialized, isTrue);
      expect(engine.loadedLanguages, contains(OcrLanguage.indonesian));

      final result = await engine.recognizeFromFile(imagePath: dummyImg.path);
      expect(result.fullText, contains('Offline OCR'));
      expect(result.blocks.first.confidence, greaterThan(90));
    });
  });
}
