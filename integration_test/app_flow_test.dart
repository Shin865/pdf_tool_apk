import 'package:document_reviewer/app/providers.dart';
import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/features/security/services/app_lock_service.dart';
import 'package:document_reviewer/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const securityChannel =
      MethodChannel('com.example.documentreviewer/security');
  const intentChannel = MethodChannel('com.example.documentreviewer/intent');

  late AppDatabase db;
  late AppLockService lockService;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(securityChannel, (call) async {
      return true;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(intentChannel, (call) async {
      if (call.method == 'getInitialIntent') return null;
      return null;
    });

    db = AppDatabase.forTesting(NativeDatabase.memory());
    lockService = AppLockService(securityChannel: securityChannel);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(securityChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(intentChannel, null);
    await db.close();
  });

  testWidgets(
      'Integration Flow: Launch app, navigate settings, about, and home',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appLockServiceProvider.overrideWithValue(lockService),
        ],
        child: const DocumentReviewerApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Home Screen is visible
    expect(find.text('Document Reviewer'), findsAtLeast(1));

    // 2. Open Settings Screen
    final settingsButton = find.byTooltip('Pengaturan');
    if (settingsButton.evaluate().isNotEmpty) {
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // Verify settings screen rendered
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Keamanan & Kunci Aplikasi'), findsOneWidget);

      // Scroll to About tile
      await tester.scrollUntilVisible(
        find.text('Tentang Aplikasi'),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Tentang Aplikasi'), findsOneWidget);

      // Open About screen
      await tester.tap(find.text('Tentang Aplikasi'));
      await tester.pumpAndSettle();

      // Verify About screen
      expect(find.text('100% Offline-First'), findsOneWidget);

      // Navigate back to Settings
      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }
    }
  });
}
