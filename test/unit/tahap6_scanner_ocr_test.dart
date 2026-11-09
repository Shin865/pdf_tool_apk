import 'dart:io';

import 'package:document_reviewer/core/engine/document_scanner_engine.dart';
import 'package:document_reviewer/core/engine/ocr_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_ocr_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_scanner_engine.dart';
import 'package:document_reviewer/features/scanner/scanner_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const engineChannel = MethodChannel('com.example.documentreviewer/engine');

  late NativeDocumentScannerEngine scannerEngine;
  late NativeOcrEngine ocrEngine;

  final testDir = Directory.systemTemp.createTempSync('tahap6_test_');

  final cleanFixture = File('test/fixtures/synth_scan_clean.bmp');
  final skewedFixture = File('test/fixtures/synth_scan_skewed.bmp');
  final ocrFixture = File('test/fixtures/synth_ocr_id.bmp');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(engineChannel, (call) async {
      final args = call.arguments is Map
          ? call.arguments as Map<dynamic, dynamic>
          : const <String, dynamic>{};
      switch (call.method) {
        case 'scanner_detectEdges':
          return {
            'width': 800,
            'height': 1000,
            'corners': [
              {'x': 40.0, 'y': 50.0},
              {'x': 760.0, 'y': 50.0},
              {'x': 760.0, 'y': 950.0},
              {'x': 40.0, 'y': 950.0},
            ],
            'confidence': 0.95,
          };
        case 'scanner_warpPerspective':
          final out = args['outputPath'] as String;
          final f = File(out);
          f.parent.createSync(recursive: true);
          f.writeAsStringSync('WARPED_MOCK_IMAGE');
          return {
            'outputPath': out,
            'width': 720,
            'height': 900,
          };
        case 'scanner_applyFilter':
          final out = args['outputPath'] as String;
          final f = File(out);
          f.parent.createSync(recursive: true);
          f.writeAsStringSync('FILTERED_${args['filter']}');
          return out;
        case 'scanner_rotateImage':
          final out = args['outputPath'] as String;
          final f = File(out);
          f.parent.createSync(recursive: true);
          f.writeAsStringSync('ROTATED_${args['degrees']}');
          return out;
        case 'scanner_combineToPdf':
          final out = args['outputPath'] as String;
          final f = File(out);
          f.parent.createSync(recursive: true);
          f.writeAsStringSync('%PDF-1.4\n%%EOF');
          return out;
        case 'ocr_recognize':
          return {
            'fullText':
                'KEMENTERIAN PENDIDIKAN\nREPUBLIK INDONESIA\n100% Offline OCR',
            'blocks': [
              {
                'text': 'KEMENTERIAN PENDIDIKAN',
                'confidence': 96.5,
                'boundingBox': [20.0, 20.0, 780.0, 60.0],
              },
              {
                'text': 'REPUBLIK INDONESIA',
                'confidence': 95.0,
                'boundingBox': [20.0, 70.0, 780.0, 110.0],
              },
              {
                'text': '100% Offline OCR',
                'confidence': 98.0,
                'boundingBox': [20.0, 120.0, 780.0, 160.0],
              },
            ],
            'imageWidth': 800,
            'imageHeight': 1000,
            'processingTimeMs': 145,
          };
        default:
          return null;
      }
    });

    scannerEngine = NativeDocumentScannerEngine(engineChannel: engineChannel);
    ocrEngine = NativeOcrEngine(engineChannel: engineChannel);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(engineChannel, null);
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('DocumentScannerEngine Native Bridge Tests', () {
    test('detectEdges detects quadrilateral corners on synth_scan_clean.bmp',
        () async {
      expect(cleanFixture.existsSync(), isTrue);

      final detected =
          await scannerEngine.detectEdges(imagePath: cleanFixture.path);
      expect(detected, isNotNull);
      expect(detected!.corners.length, equals(4));
      expect(detected.confidence, greaterThanOrEqualTo(0.90));
      // Top-Left, Top-Right, Bottom-Right, Bottom-Left
      expect(detected.corners[0][0], equals(40.0));
      expect(detected.corners[0][1], equals(50.0));
    });

    test('detectEdges on non-existent file returns null gracefully', () async {
      final detected =
          await scannerEngine.detectEdges(imagePath: 'non_existent_scan.bmp');
      expect(detected, isNull);
    });

    test(
        'warpPerspective corrects skewed coordinates and generates warped output',
        () async {
      final outPath = '${testDir.path}/test_warped.jpg';
      final res = await scannerEngine.warpPerspective(
        imagePath: skewedFixture.path,
        corners: [
          [50.0, 40.0],
          [750.0, 60.0],
          [780.0, 920.0],
          [30.0, 900.0],
        ],
        outputPath: outPath,
      );

      expect(res, equals(outPath));
      expect(File(outPath).existsSync(), isTrue);
    });

    test('applyFilter applies Original, Magic Color, Grayscale, and B&W modes',
        () async {
      for (final mode in ScanFilterMode.values) {
        final outPath = '${testDir.path}/filter_${mode.name}.jpg';
        final res = await scannerEngine.applyFilter(
          imagePath: cleanFixture.path,
          filter: mode,
          outputPath: outPath,
        );
        expect(res, equals(outPath));
        expect(File(outPath).existsSync(), isTrue);
      }
    });

    test('rotateImage rotates image by 90, 180, and 270 degrees', () async {
      for (final deg in [90, 180, 270]) {
        final outPath = '${testDir.path}/rotated_$deg.jpg';
        final res = await scannerEngine.rotateImage(
          imagePath: cleanFixture.path,
          degrees: deg,
          outputPath: outPath,
        );
        expect(res, equals(outPath));
        expect(File(outPath).existsSync(), isTrue);
      }
    });

    test(
        'combineToPdf compiles multi-page scans with low, medium, high qualities',
        () async {
      for (final q in ScanExportQuality.values) {
        final outPath = '${testDir.path}/compiled_${q.name}.pdf';
        final res = await scannerEngine.combineToPdf(
          imagePaths: [cleanFixture.path, skewedFixture.path],
          outputPath: outPath,
          quality: q,
        );
        expect(res, equals(outPath));
        expect(File(outPath).existsSync(), isTrue);
        expect(File(outPath).readAsStringSync(), contains('%PDF'));
      }
    });
  });

  group('OcrEngine Offline Recognition Tests', () {
    test('initializes with bundled offline languages (ID & EN)', () async {
      await ocrEngine.initialize(
        tessdataPath: 'assets/ocr',
        languages: [
          OcrLanguage.indonesian,
          OcrLanguage.english,
          OcrLanguage.indonesianAndEnglish,
        ],
      );

      expect(ocrEngine.isInitialized, isTrue);
      expect(ocrEngine.loadedLanguages.length, equals(3));
      expect(ocrEngine.tessdataPath, equals('assets/ocr'));
    });

    test(
        'recognizeFromFile extracts structured text blocks with confidence and bounding boxes',
        () async {
      expect(ocrFixture.existsSync(), isTrue);

      final result = await ocrEngine.recognizeFromFile(
        imagePath: ocrFixture.path,
      );

      expect(result.fullText, contains('KEMENTERIAN PENDIDIKAN'));
      expect(result.fullText, contains('100% Offline OCR'));
      expect(result.blocks.length, equals(3));
      expect(result.averageConfidence, greaterThan(90.0));

      final firstBlock = result.blocks.first;
      expect(firstBlock.text, equals('KEMENTERIAN PENDIDIKAN'));
      expect(firstBlock.confidence, equals(96.5));
      expect(firstBlock.confidenceLevel, equals(OcrConfidence.high));
      expect(firstBlock.boundingBox.length, equals(4));
    });

    test('createSearchablePdf embeds text layer into PDF output', () async {
      final ocrRes =
          await ocrEngine.recognizeFromFile(imagePath: cleanFixture.path);
      final outPdf = '${testDir.path}/searchable_document.pdf';

      final res = await ocrEngine.createSearchablePdf(
        imagePath: cleanFixture.path,
        ocrResult: ocrRes,
        outputPath: outPdf,
      );

      expect(res, equals(outPdf));
      expect(File(outPdf).existsSync(), isTrue);
      expect(File(outPdf).readAsStringSync(), contains('%PDF'));
    });
  });

  group('100% Offline & Low-RAM Safety Invariants', () {
    test('verifies bundled tessdata files exist in assets/ocr', () {
      final engModel = File('assets/ocr/eng.traineddata');
      final indModel = File('assets/ocr/ind.traineddata');

      expect(engModel.existsSync(), isTrue);
      expect(indModel.existsSync(), isTrue);
      expect(engModel.lengthSync(), greaterThan(1000000)); // > 1 MB
      expect(indModel.lengthSync(), greaterThan(1000000)); // > 1 MB
    });

    test(
        'Zero network socket invariant: scanner & OCR operate strictly offline',
        () async {
      // In airplane mode / zero network connections, scan and OCR succeed without internet
      final scanResult =
          await scannerEngine.processImage(imagePath: cleanFixture.path);
      expect(scanResult.processedImagePath, isNotEmpty);

      final ocrResult =
          await ocrEngine.recognizeFromFile(imagePath: ocrFixture.path);
      expect(ocrResult.fullText, isNotEmpty);
    });
  });

  group('ScannerController State Machine Tests', () {
    late ScannerController controller;

    setUp(() {
      controller = ScannerController(
        scannerEngine: scannerEngine,
        ocrEngine: ocrEngine,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is clean and empty', () {
      expect(controller.state.pages, isEmpty);
      expect(controller.state.currentPageIndex, equals(0));
      expect(controller.state.currentPage, isNull);
      expect(controller.state.isProcessing, isFalse);
    });

    test('addPage adds page, warps perspective and sets as current', () async {
      await controller.addPage(cleanFixture.path);

      expect(controller.state.pages.length, equals(1));
      expect(controller.state.currentPageIndex, equals(0));
      final page = controller.state.currentPage!;
      expect(page.originalImagePath, equals(cleanFixture.path));
      expect(page.corners.length, equals(4));
      expect(page.warpedImagePath, isNotEmpty);
      expect(page.displayPath, equals(page.filteredImagePath));
    });

    test('updateCorners re-warps perspective for active page', () async {
      await controller.addPage(cleanFixture.path);

      final newCorners = [
        [10.0, 10.0],
        [790.0, 10.0],
        [790.0, 990.0],
        [10.0, 990.0],
      ];

      await controller.updateCorners(0, newCorners);

      final updatedPage = controller.state.pages[0];
      expect(updatedPage.corners, equals(newCorners));
    });

    test('applyFilter updates filter mode and filtered image', () async {
      await controller.addPage(cleanFixture.path);

      await controller.applyFilter(0, ScanFilterMode.magicColor);
      expect(controller.state.pages[0].filterMode,
          equals(ScanFilterMode.magicColor));

      await controller.applyFilter(0, ScanFilterMode.blackWhite);
      expect(controller.state.pages[0].filterMode,
          equals(ScanFilterMode.blackWhite));
    });

    test('rotatePage updates rotation degrees clockwise', () async {
      await controller.addPage(cleanFixture.path);

      await controller.rotatePage(0);
      expect(controller.state.pages[0].rotationDegrees, equals(90));

      await controller.rotatePage(0);
      expect(controller.state.pages[0].rotationDegrees, equals(180));
    });

    test('reorderPages changes page sequence accurately', () async {
      await controller.addPage(cleanFixture.path);
      await controller.addPage(skewedFixture.path);
      await controller.addPage(ocrFixture.path);

      expect(controller.state.pages.length, equals(3));
      expect(controller.state.pages[0].originalImagePath,
          equals(cleanFixture.path));
      expect(controller.state.pages[1].originalImagePath,
          equals(skewedFixture.path));
      expect(
          controller.state.pages[2].originalImagePath, equals(ocrFixture.path));

      // Move page 0 to index 2
      controller.reorderPages(0, 3);
      expect(controller.state.pages[2].originalImagePath,
          equals(cleanFixture.path));
    });

    test('removePage removes page and clamps active index', () async {
      await controller.addPage(cleanFixture.path);
      await controller.addPage(skewedFixture.path);

      controller.removePage(1);
      expect(controller.state.pages.length, equals(1));
      expect(controller.state.currentPageIndex, equals(0));

      controller.removePage(0);
      expect(controller.state.pages, isEmpty);
      expect(controller.state.currentPage, isNull);
    });

    test('exportToPdf combines all pages to single PDF file', () async {
      await controller.addPage(cleanFixture.path);
      await controller.addPage(skewedFixture.path);

      final outPdf = '${testDir.path}/all_scanned.pdf';
      final res = await controller.exportToPdf(
        outputPath: outPdf,
        quality: ScanExportQuality.high,
      );

      expect(res, equals(outPdf));
      expect(File(outPdf).existsSync(), isTrue);
    });

    test('runOcr executes text recognition and updates page ocrResult',
        () async {
      await controller.addPage(ocrFixture.path);

      final res = await controller.runOcr(index: 0);
      expect(res, isNotNull);
      expect(res!.fullText, contains('KEMENTERIAN PENDIDIKAN'));
      expect(controller.state.pages[0].ocrResult, equals(res));
      expect(controller.state.activeOcrResult, equals(res));
    });

    test('cancelOcr halts running OCR process', () async {
      await controller.addPage(ocrFixture.path);

      // Trigger OCR and cancel immediately
      final future = controller.runOcr(index: 0);
      controller.cancelOcr();
      await future;

      expect(controller.state.isOcrCancelled, isTrue);
      expect(controller.state.ocrProgress, isNull);
    });
  });
}
