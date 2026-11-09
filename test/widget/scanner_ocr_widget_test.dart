import 'dart:io';

import 'package:document_reviewer/app/providers.dart';
import 'package:document_reviewer/core/engine/document_scanner_engine.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:document_reviewer/data/engine_impl/native_ocr_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_scanner_engine.dart';
import 'package:document_reviewer/features/ocr/ocr_result_sheet.dart';
import 'package:document_reviewer/features/scanner/document_scanner_screen.dart';
import 'package:document_reviewer/features/scanner/scanner_controller.dart';
import 'package:document_reviewer/features/scanner/widgets/filter_selector_bar.dart';
import 'package:document_reviewer/features/scanner/widgets/quad_crop_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const engineChannel = MethodChannel('com.example.documentreviewer/engine');
  final testImageFile = File('test/fixtures/synth_scan_clean.bmp');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            SystemChannels.platform, (call) async => null);
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
          f.writeAsStringSync('MOCK_WARPED_IMAGE');
          return {
            'outputPath': out,
            'width': 720,
            'height': 900,
          };
        case 'scanner_applyFilter':
          return args['outputPath'] as String;
        case 'scanner_rotateImage':
          return args['outputPath'] as String;
        case 'scanner_combineToPdf':
          return args['outputPath'] as String;
        case 'ocr_recognize':
          return {
            'fullText': 'KEMENTERIAN PENDIDIKAN\nREPUBLIK INDONESIA',
            'blocks': [
              {
                'text': 'KEMENTERIAN PENDIDIKAN',
                'confidence': 97.0,
                'boundingBox': [20.0, 20.0, 780.0, 60.0],
              },
            ],
            'imageWidth': 800,
            'imageHeight': 1000,
            'processingTimeMs': 120,
          };
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(engineChannel, null);
  });

  Widget createTestWidget(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('id'),
        home: Scaffold(body: child),
      ),
    );
  }

  group('QuadCropOverlay Widget Tests', () {
    testWidgets('Renders image and 4 draggable corner handles', (tester) async {
      List<List<double>>? updatedCorners;

      final initialCorners = [
        [40.0, 50.0],
        [760.0, 50.0],
        [760.0, 950.0],
        [40.0, 950.0],
      ];

      await tester.pumpWidget(
        createTestWidget(
          SizedBox(
            width: 800,
            height: 1000,
            child: QuadCropOverlay(
              imagePath: testImageFile.path,
              corners: initialCorners,
              imageWidth: 800,
              imageHeight: 1000,
              onCornersChanged: (corners) {
                updatedCorners = corners;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find 4 corner semantics handles
      expect(find.bySemanticsLabel('Corner Handle 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Corner Handle 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Corner Handle 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Corner Handle 4'), findsOneWidget);

      // Drag Top-Left handle
      await tester.drag(
          find.bySemanticsLabel('Corner Handle 1'), const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(updatedCorners, isNotNull);
      expect(updatedCorners!.length, equals(4));
    });
  });

  group('FilterSelectorBar Widget Tests', () {
    testWidgets(
        'Displays all 4 filter chips and fires onFilterSelected callback',
        (tester) async {
      var selected = ScanFilterMode.original;

      await tester.pumpWidget(
        createTestWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return FilterSelectorBar(
                selectedFilter: selected,
                onFilterSelected: (mode) {
                  setState(() => selected = mode);
                },
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Asli'), findsOneWidget);
      expect(find.text('Warna Ajaib'), findsOneWidget);
      expect(find.text('Skala Abu'), findsOneWidget);
      expect(find.text('Hitam Putih'), findsOneWidget);

      // Tap Warna Ajaib
      await tester.tap(find.text('Warna Ajaib'));
      await tester.pumpAndSettle();

      expect(selected, equals(ScanFilterMode.magicColor));
    });
  });

  group('DocumentScannerScreen Widget Tests', () {
    testWidgets('Empty state renders scan action buttons', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const DocumentScannerScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pindai Dokumen'), findsAtLeast(1));
      expect(find.text('Ambil Foto / Kamera'), findsOneWidget);
      expect(find.text('Impor dari Galeri'), findsOneWidget);
    });

    testWidgets(
        'Screen with initial image shows tools, filters, and export button',
        (tester) async {
      final mockScanner =
          NativeDocumentScannerEngine(engineChannel: engineChannel);
      final mockOcr = NativeOcrEngine(engineChannel: engineChannel);

      await tester.pumpWidget(
        createTestWidget(
          DocumentScannerScreen(
            initialImagePath: testImageFile.path,
          ),
          overrides: [
            documentScannerEngineProvider.overrideWithValue(mockScanner),
            ocrEngineProvider.overrideWithValue(mockOcr),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Top action buttons: Crop toggle, OCR, Export PDF
      expect(find.byIcon(Icons.crop), findsOneWidget);
      expect(find.byIcon(Icons.document_scanner), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);

      // Control actions: Rotate, Delete, Add
      expect(find.text('Putar'), findsOneWidget);
      expect(find.text('Hapus Halaman'), findsOneWidget);
      expect(find.text('Tambah Halaman'), findsOneWidget);

      // Tap Export button to open Export Dialog
      await tester.tap(find.byIcon(Icons.picture_as_pdf));
      await tester.pumpAndSettle();

      expect(find.text('Ekspor Dokumen'), findsOneWidget);
      expect(find.text('Sedang (Standar)'), findsOneWidget);
      expect(find.text('Tinggi (Kualitas penuh)'), findsOneWidget);
      expect(find.text('Ekspor sebagai PDF'), findsOneWidget);
    });
  });

  group('OcrResultSheet Widget Tests', () {
    testWidgets('Displays OCR result, language selector, and copy button',
        (tester) async {
      final mockScanner =
          NativeDocumentScannerEngine(engineChannel: engineChannel);
      final mockOcr = NativeOcrEngine(engineChannel: engineChannel);

      final container = ProviderContainer(
        overrides: [
          documentScannerEngineProvider.overrideWithValue(mockScanner),
          ocrEngineProvider.overrideWithValue(mockOcr),
        ],
      );

      // Keep listener alive so provider is retained
      final sub = container.listen(scannerControllerProvider, (_, __) {});

      // Initialize a page first
      final controller = container.read(scannerControllerProvider.notifier);
      await controller.addPage(testImageFile.path);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('id'),
            home: Scaffold(
              body: OcrResultSheet(pageIndex: 0),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text('Hasil OCR'), findsOneWidget);
      expect(find.text('Bahasa OCR: '), findsOneWidget);
      expect(find.text('Salin Teks'), findsOneWidget);
      expect(find.text('Simpan Searchable PDF'), findsOneWidget);
      expect(find.textContaining('KEMENTERIAN PENDIDIKAN'), findsOneWidget);

      // Tap Salin Teks
      await tester.tap(find.text('Salin Teks'));
      await tester.pump();

      expect(find.text('Teks disalin ke papan klip'), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
          .clearSnackBars();
      await tester.pump();
      sub.close();
    });
  });
}
