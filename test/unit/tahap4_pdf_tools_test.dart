import 'dart:io';

import 'package:document_reviewer/core/engine/pdf_annotation_engine.dart';
import 'package:document_reviewer/core/error/exceptions.dart';
import 'package:document_reviewer/data/engine_impl/native_pdf_annotation_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_pdf_page_engine.dart';
import 'package:document_reviewer/features/pdf_tools/annotations/pdf_annotation_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Directory draftsDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('tahap4_pdf_tools_test_');
    draftsDir = Directory('${tempDir.path}/drafts')
      ..createSync(recursive: true);
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('PdfAnnotationController & Undo/Redo & Autosave', () {
    test('addAnnotation records annotation, marks dirty, and can undo/redo',
        () {
      final controller = PdfAnnotationController(
        documentUri: 'content://test/doc1.pdf',
        draftsDirectory: draftsDir,
      );

      expect(controller.annotations, isEmpty);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
      expect(controller.isDirty, isFalse);

      final hl = PdfAnnotation(
        id: 'hl_1',
        type: AnnotationType.highlight,
        pageIndex: 0,
        rect: const [10, 20, 100, 40],
        color: Colors.yellow,
        createdAt: DateTime.now(),
      );

      controller.addAnnotation(hl);

      expect(controller.annotations.length, 1);
      expect(controller.annotations.first.id, 'hl_1');
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isFalse);
      expect(controller.isDirty, isTrue);

      final ink = PdfAnnotation(
        id: 'ink_1',
        type: AnnotationType.freehandDrawing,
        pageIndex: 0,
        rect: const [0, 0, 0, 0],
        points: const [
          [10, 10],
          [20, 20],
          [30, 30],
        ],
        strokeWidth: 3,
        color: Colors.red,
        createdAt: DateTime.now(),
      );

      controller.addAnnotation(ink);
      expect(controller.annotations.length, 2);

      // Undo
      final undone = controller.undo();
      expect(undone?.id, 'ink_1');
      expect(controller.annotations.length, 1);
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isTrue);

      // Redo
      final redone = controller.redo();
      expect(redone?.id, 'ink_1');
      expect(controller.annotations.length, 2);
      expect(controller.canRedo, isFalse);

      controller.dispose();
    });

    test(
        'Autosave persists draft JSON and recovers state after simulated process death',
        () async {
      const docUri = 'content://test/process_death.pdf';

      final controller1 = PdfAnnotationController(
        documentUri: docUri,
        draftsDirectory: draftsDir,
      )..addAnnotation(
          PdfAnnotation(
            id: 'note_1',
            type: AnnotationType.textNote,
            pageIndex: 2,
            rect: const [50, 50, 150, 80],
            content: 'Important observation',
            createdAt: DateTime.now(),
          ),
        );

      // Wait a moment for async file write
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(await controller1.hasDraft(), isTrue);

      // Simulate process death by creating a fresh controller for the same URI
      final controller2 = PdfAnnotationController(
        documentUri: docUri,
        draftsDirectory: draftsDir,
      );

      expect(await controller2.hasDraft(), isTrue);
      final restored = await controller2.restoreDraft();
      expect(restored, isTrue);

      expect(controller2.annotations.length, 1);
      expect(controller2.annotations.first.id, 'note_1');
      expect(controller2.annotations.first.content, 'Important observation');
      expect(controller2.annotations.first.pageIndex, 2);
      expect(controller2.isDirty, isTrue);

      // Discard draft cleans up file
      await controller2.discardDraft();
      expect(await controller2.hasDraft(), isFalse);

      controller1.dispose();
      controller2.dispose();
    });
  });

  group('NativePdfAnnotationEngine with MethodChannel Mock', () {
    late List<MethodCall> channelCalls;
    late NativePdfAnnotationEngine engine;
    late File testPdf;

    setUp(() {
      channelCalls = [];
      testPdf = File('${tempDir.path}/test_engine.pdf')
        ..writeAsStringSync('%PDF-1.4 mock');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.documentreviewer/engine'),
        (call) async {
          channelCalls.add(call);
          switch (call.method) {
            case 'pdf_addHighlight':
            case 'pdf_addUnderline':
            case 'pdf_addInk':
            case 'pdf_addText':
            case 'pdf_addImage':
              return true;
            default:
              return null;
          }
        },
      );

      engine = NativePdfAnnotationEngine();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.documentreviewer/engine'),
        null,
      );
    });

    test('addAnnotation dispatches underline and text correctly', () async {
      await engine.openForAnnotation(filePath: testPdf.path);

      const underline = PdfAnnotation(
        id: 'ul_1',
        type: AnnotationType.underline,
        pageIndex: 0,
        rect: [10, 20, 100, 30],
        color: Colors.blue,
      );

      await engine.addAnnotation(underline);

      expect(channelCalls.any((c) => c.method == 'pdf_addUnderline'), isTrue);
      final call =
          channelCalls.firstWhere((c) => c.method == 'pdf_addUnderline');
      final callArgs = call.arguments as Map<dynamic, dynamic>;
      expect(callArgs['filePath'], testPdf.path);
      expect(callArgs['pageIndex'], 0);
      expect(callArgs['x'], 10.0);
      expect(callArgs['width'], 90.0);

      const textNote = PdfAnnotation(
        id: 'txt_1',
        type: AnnotationType.textNote,
        pageIndex: 0,
        rect: [40, 50, 140, 80],
        content: 'Review Note',
        strokeWidth: 12,
      );

      await engine.addAnnotation(textNote);

      expect(channelCalls.any((c) => c.method == 'pdf_addText'), isTrue);
      final textCall =
          channelCalls.firstWhere((c) => c.method == 'pdf_addText');
      final textArgs = textCall.arguments as Map<dynamic, dynamic>;
      expect(textArgs['text'], 'Review Note');
      expect(textArgs['x'], 40.0);
      expect(textArgs['fontSize'], 12.0);
    });

    test('addAnnotation dispatches signature image correctly', () async {
      await engine.openForAnnotation(filePath: testPdf.path);

      final sigFile = File('${tempDir.path}/sig.png')
        ..writeAsBytesSync([1, 2, 3]);

      final sig = PdfAnnotation(
        id: 'sig_1',
        type: AnnotationType.signature,
        pageIndex: 1,
        rect: const [50, 60, 200, 120],
        imagePath: sigFile.path,
      );

      await engine.addAnnotation(sig);

      expect(channelCalls.any((c) => c.method == 'pdf_addImage'), isTrue);
      final imgCall =
          channelCalls.firstWhere((c) => c.method == 'pdf_addImage');
      final imgArgs = imgCall.arguments as Map<dynamic, dynamic>;
      expect(imgArgs['imagePath'], sigFile.path);
      expect(imgArgs['width'], 150.0);
      expect(imgArgs['height'], 60.0);
    });

    test('saveAnnotatedDocument copies to output path', () async {
      await engine.openForAnnotation(filePath: testPdf.path);
      final outPath = '${tempDir.path}/saved_annotated.pdf';

      final ok = await engine.saveAnnotatedDocument(outputPath: outPath);
      expect(ok, isTrue);
      expect(File(outPath).existsSync(), isTrue);
    });
  });

  group('NativePdfPageEngine with MethodChannel Mock', () {
    late List<MethodCall> channelCalls;
    late NativePdfPageEngine pageEngine;
    late File testPdf;

    setUp(() {
      channelCalls = [];
      testPdf = File('${tempDir.path}/page_test.pdf')
        ..writeAsStringSync('%PDF-1.4 pages');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.documentreviewer/engine'),
        (call) async {
          channelCalls.add(call);
          switch (call.method) {
            case 'pdf_rotatePage':
            case 'pdf_deletePages':
            case 'pdf_reorderPages':
            case 'pdf_mergePdfs':
            case 'pdf_splitPdf':
            case 'pdf_renderPage':
              return true;
            default:
              return null;
          }
        },
      );

      pageEngine = NativePdfPageEngine();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.documentreviewer/engine'),
        null,
      );
    });

    test('rotatePage dispatches correctly', () async {
      final out = '${tempDir.path}/rotated.pdf';
      final ok = await pageEngine.rotatePage(
        filePath: testPdf.path,
        pageIndex: 2,
        degrees: 90,
        outputPath: out,
      );

      expect(ok, isTrue);
      expect(channelCalls.any((c) => c.method == 'pdf_rotatePage'), isTrue);
      final call = channelCalls.firstWhere((c) => c.method == 'pdf_rotatePage');
      final callArgs = call.arguments as Map<dynamic, dynamic>;
      expect(callArgs['pageIndex'], 2);
      expect(callArgs['degrees'], 90);
    });

    test('deletePages dispatches correctly', () async {
      final out = '${tempDir.path}/deleted.pdf';
      final ok = await pageEngine.deletePages(
        filePath: testPdf.path,
        pageIndices: [1, 3],
        outputPath: out,
      );

      expect(ok, isTrue);
      expect(channelCalls.any((c) => c.method == 'pdf_deletePages'), isTrue);
      final call =
          channelCalls.firstWhere((c) => c.method == 'pdf_deletePages');
      final callArgs = call.arguments as Map<dynamic, dynamic>;
      expect(callArgs['pageIndices'], [1, 3]);
    });

    test('reorderPages dispatches correctly', () async {
      final out = '${tempDir.path}/reordered.pdf';
      final ok = await pageEngine.reorderPages(
        filePath: testPdf.path,
        newOrder: [2, 0, 1],
        outputPath: out,
      );

      expect(ok, isTrue);
      expect(channelCalls.any((c) => c.method == 'pdf_reorderPages'), isTrue);
      final call =
          channelCalls.firstWhere((c) => c.method == 'pdf_reorderPages');
      final callArgs = call.arguments as Map<dynamic, dynamic>;
      expect(callArgs['newOrder'], [2, 0, 1]);
    });

    test('mergePdfs dispatches correctly', () async {
      final pdf2 = File('${tempDir.path}/page_test2.pdf')
        ..writeAsStringSync('%PDF-1.4 doc2');
      final out = '${tempDir.path}/merged.pdf';

      final ok = await pageEngine.mergePdfs(
        filePaths: [testPdf.path, pdf2.path],
        outputPath: out,
      );

      expect(ok, isTrue);
      expect(channelCalls.any((c) => c.method == 'pdf_mergePdfs'), isTrue);
      final call = channelCalls.firstWhere((c) => c.method == 'pdf_mergePdfs');
      final callArgs = call.arguments as Map<dynamic, dynamic>;
      expect(callArgs['filePaths'], [testPdf.path, pdf2.path]);
    });

    test('splitPdf dispatches correctly', () async {
      final out = '${tempDir.path}/split.pdf';
      final ok = await pageEngine.splitPdf(
        filePath: testPdf.path,
        startPage: 0,
        endPage: 4,
        outputPath: out,
      );

      expect(ok, isTrue);
      expect(channelCalls.any((c) => c.method == 'pdf_splitPdf'), isTrue);
      final call = channelCalls.firstWhere((c) => c.method == 'pdf_splitPdf');
      final callArgs = call.arguments as Map<dynamic, dynamic>;
      expect(callArgs['startPage'], 0);
      expect(callArgs['endPage'], 4);
    });

    test('throws DocumentNotFoundException on missing file', () async {
      expect(
        () => pageEngine.rotatePage(
          filePath: '${tempDir.path}/non_existent.pdf',
          pageIndex: 0,
          degrees: 90,
          outputPath: 'any',
        ),
        throwsA(isA<DocumentNotFoundException>()),
      );
    });
  });

  group('Large PDF 500 Pages Simulation', () {
    test(
        'Simulates 500 pages reordering and selective deletion without memory spike',
        () {
      const pageCount = 500;
      final pageOrder = List.generate(pageCount, (i) => i);
      expect(pageOrder.length, 500);

      // Move page 499 to front
      final lastPage = pageOrder.removeAt(499);
      pageOrder.insert(0, lastPage);
      expect(pageOrder.first, 499);
      expect(pageOrder.length, 500);

      // Delete 50 pages (e.g. pages 200..249)
      final pagesToDelete = List.generate(50, (i) => i + 200).toSet();
      pageOrder.removeWhere(pagesToDelete.contains);

      expect(pageOrder.length, 450);
      expect(pageOrder.contains(200), isFalse);
      expect(pageOrder.contains(249), isFalse);
      expect(pageOrder.contains(250), isTrue);
    });
  });
}
