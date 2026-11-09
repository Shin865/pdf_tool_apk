import 'package:document_reviewer/app/providers.dart';
import 'package:document_reviewer/core/constants/app_constants.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/features/backup_restore/ui/backup_restore_screen.dart';
import 'package:document_reviewer/features/onboarding/onboarding_screen.dart';
import 'package:document_reviewer/features/security/services/app_lock_service.dart';
import 'package:document_reviewer/features/security/ui/app_lock_screen.dart';
import 'package:document_reviewer/features/settings/about_screen.dart';
import 'package:document_reviewer/features/settings/settings_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const securityChannel =
      MethodChannel('com.example.documentreviewer/security');

  late AppDatabase db;
  late AppLockService lockService;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(securityChannel, (call) async {
      switch (call.method) {
        case 'security_setSecure':
          return true;
        case 'security_canAuthenticate':
          return true;
        case 'security_authenticate':
          return true;
        default:
          return null;
      }
    });

    db = AppDatabase.forTesting(NativeDatabase.memory());
    lockService = AppLockService(securityChannel: securityChannel);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(securityChannel, null);
    await db.close();
  });

  Widget createTestWidget(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        appLockServiceProvider.overrideWithValue(lockService),
        ...overrides,
      ],
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

  group('OnboardingScreen Widget Tests', () {
    testWidgets('Renders slides and triggers onFinished on Mulai Sekarang',
        (tester) async {
      var finished = false;

      await tester.pumpWidget(
        createTestWidget(
          OnboardingScreen(onFinished: () => finished = true),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Privasi Mutlak & 100% Offline'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);
      expect(find.text('Lewati'), findsOneWidget);

      // Slide 1 -> Slide 2
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Pembaca & Editor Dokumen Lengkap'), findsOneWidget);

      // Slide 2 -> Slide 3
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Pindai Dokumen & OCR Lokal'), findsOneWidget);
      expect(find.text('Mulai Sekarang'), findsOneWidget);

      // Finish
      await tester.tap(find.text('Mulai Sekarang'));
      await tester.pumpAndSettle();
      expect(finished, isTrue);
    });

    testWidgets('Lewati button immediately finishes onboarding',
        (tester) async {
      var finished = false;

      await tester.pumpWidget(
        createTestWidget(
          OnboardingScreen(onFinished: () => finished = true),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
    });
  });

  group('AppLockScreen Widget Tests', () {
    testWidgets('Entering correct PIN unlocks app', (tester) async {
      lockService.setPin('1234');
      var unlocked = false;

      await tester.pumpWidget(
        createTestWidget(
          AppLockScreen(
            lockService: lockService,
            onUnlocked: () => unlocked = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aplikasi Terkunci'), findsOneWidget);

      // Enter digits 1, 2, 3, 4
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      expect(unlocked, isTrue);
    });

    testWidgets('Entering wrong PIN shows error feedback', (tester) async {
      lockService.setPin('1234');
      var unlocked = false;

      await tester.pumpWidget(
        createTestWidget(
          AppLockScreen(
            lockService: lockService,
            onUnlocked: () => unlocked = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter digits 9, 8, 7, 6, 5, 4
      for (final d in ['9', '8', '7', '6', '5', '4']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(unlocked, isFalse);
      expect(find.text('PIN salah. Coba lagi.'), findsOneWidget);
    });
  });

  group('BackupRestoreScreen Widget Tests', () {
    testWidgets('Renders Export and Restore cards', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const BackupRestoreScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cadangan & Pemulihan'), findsOneWidget);
      expect(find.text('Buat Cadangan (Export)'), findsOneWidget);
      expect(find.text('Pulihkan Cadangan (Restore)'), findsOneWidget);
      expect(find.text('Sertakan salinan berkas dokumen'), findsOneWidget);
      expect(find.text('Enkripsi dengan kata sandi'), findsOneWidget);
      expect(find.text('Pilih Berkas Cadangan'), findsOneWidget);
    });
  });

  group('AboutScreen Widget Tests', () {
    testWidgets('Renders version, privacy policy, and licenses tile',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AboutScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tentang Aplikasi'), findsAtLeast(1));
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text('100% Offline-First'), findsOneWidget);
      expect(find.text('Kebijakan Privasi'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Lisensi Perangkat Lunak Pihak Ketiga'),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Lisensi Perangkat Lunak Pihak Ketiga'), findsOneWidget);
    });
  });

  group('SettingsScreen Tahap 7 Widget Tests', () {
    testWidgets('Renders App Lock, Backup, Secure Wipe, and About tiles',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Keamanan & Kunci Aplikasi'), findsOneWidget);
      expect(find.text('Kunci PIN & Biometrik'), findsOneWidget);
      expect(find.text('Blokir Tangkapan Layar (FLAG_SECURE)'), findsOneWidget);
      expect(find.text('Cadangan & Pemulihan Data'), findsOneWidget);
      expect(find.text('Pembersihan & Hapus Aman'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Bersihkan Berkas Sementara & Cache'),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Bersihkan Berkas Sementara & Cache'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Hapus Semua Data Aplikasi'),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Hapus Semua Data Aplikasi'), findsOneWidget);
      expect(find.text('Panduan Pengenalan Aplikasi'), findsOneWidget);
      expect(find.text('Tentang Aplikasi'), findsOneWidget);
    });
  });
}
