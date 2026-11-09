import 'dart:io';

import 'package:document_reviewer/core/constants/app_constants.dart';
import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/data/saf/storage_directory_manager.dart';
import 'package:document_reviewer/features/backup_restore/models/backup_models.dart';
import 'package:document_reviewer/features/backup_restore/services/backup_service.dart';
import 'package:document_reviewer/features/security/services/app_lock_service.dart';
import 'package:document_reviewer/features/security/services/secure_wipe_service.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const securityChannel =
      MethodChannel('com.example.documentreviewer/security');

  late AppDatabase db;
  late BackupService backupService;
  late AppLockService lockService;
  late SecureWipeService wipeService;
  late StorageDirectoryManager dirManager;
  late Directory testDir;

  setUp(() {
    testDir = Directory.systemTemp.createTempSync('tahap7_test_');
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
    backupService = const BackupService();
    lockService = AppLockService(securityChannel: securityChannel);
    dirManager = StorageDirectoryManager();
    wipeService = SecureWipeService(
      database: db,
      directoryManager: dirManager,
      lockService: lockService,
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(securityChannel, null);
    await db.close();
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('Backup & Restore Unit Tests', () {
    test('creates unencrypted backup archive and inspects manifest preview',
        () async {
      // Insert test document
      await db.into(db.documentRecords).insert(
            DocumentRecordsCompanion(
              id: const Value(101),
              uri: const Value('content://test/doc101'),
              displayName: const Value('Laporan_Tahunan.pdf'),
              mimeType: const Value(SupportedMimeTypes.pdf),
              firstOpenedAt: Value(DateTime.now()),
              lastOpenedAt: Value(DateTime.now()),
              isFavorite: const Value(true),
            ),
          );

      final outPath = '${testDir.path}/test_backup.drbackup';
      final resPath = await backupService.createBackup(
        database: db,
        outputPath: outPath,
      );

      expect(resPath, equals(outPath));
      expect(File(outPath).existsSync(), isTrue);

      final preview = await backupService.inspectBackup(backupPath: outPath);
      expect(preview.manifest.version, equals(currentBackupSchemaVersion));
      expect(preview.documentCount, equals(1));
      expect(preview.documentNames, contains('Laporan_Tahunan.pdf'));
      expect(preview.isEncrypted, isFalse);
    });

    test(
        'creates encrypted backup with password (PBKDF2 + AES) and verifies password validation',
        () async {
      await db.into(db.documentRecords).insert(
            DocumentRecordsCompanion(
              id: const Value(202),
              uri: const Value('content://test/doc202'),
              displayName: const Value('Rahasia_Negara.pdf'),
              mimeType: const Value(SupportedMimeTypes.pdf),
              firstOpenedAt: Value(DateTime.now()),
              lastOpenedAt: Value(DateTime.now()),
            ),
          );

      final outPath = '${testDir.path}/encrypted.drbackup';
      await backupService.createBackup(
        database: db,
        outputPath: outPath,
        password: 'KunciRahasia123!',
      );

      // Inspect without password shows manifest is encrypted
      final preview = await backupService.inspectBackup(backupPath: outPath);
      expect(preview.isEncrypted, isTrue);

      // Inspect with valid password decrypts document list
      final previewDecrypted = await backupService.inspectBackup(
        backupPath: outPath,
        password: 'KunciRahasia123!',
      );
      expect(previewDecrypted.documentNames, contains('Rahasia_Negara.pdf'));

      // Inspect with wrong password throws InvalidBackupPasswordException
      expect(
        () => backupService.inspectBackup(
          backupPath: outPath,
          password: 'SalahPassword!',
        ),
        throwsA(isA<InvalidBackupPasswordException>()),
      );
    });

    test('schema version check rejects backup with higher version', () async {
      final invalidFile = File('${testDir.path}/future_backup.drbackup')
        ..writeAsStringSync(
            '{"manifest": {"version": 999, "documentsCount": 0}}');

      expect(
        () => backupService.inspectBackup(backupPath: invalidFile.path),
        throwsA(isA<UnsupportedBackupVersionException>()),
      );
    });

    test('restores backup successfully into clean database installation',
        () async {
      // 1. Setup sample records in DB and backup
      await db.into(db.documentRecords).insert(
            DocumentRecordsCompanion(
              id: const Value(303),
              uri: const Value('content://test/restore1'),
              displayName: const Value('Arsip_Kontrak.docx'),
              mimeType: const Value(SupportedMimeTypes.docx),
              firstOpenedAt: Value(DateTime.now()),
              lastOpenedAt: Value(DateTime.now()),
              isFavorite: const Value(true),
            ),
          );

      final backupPath = '${testDir.path}/clean_install_backup.drbackup';
      await backupService.createBackup(
        database: db,
        outputPath: backupPath,
      );

      // 2. Open fresh empty database (clean install simulation)
      final cleanDb = AppDatabase.forTesting(NativeDatabase.memory());
      final existingDocs = await cleanDb.select(cleanDb.documentRecords).get();
      expect(existingDocs, isEmpty);

      // 3. Restore backup into clean database
      final restoreRes = await backupService.restoreBackup(
        database: cleanDb,
        backupPath: backupPath,
      );

      expect(restoreRes.success, isTrue);
      expect(restoreRes.restoredDocuments, equals(1));

      final restoredDocs = await cleanDb.select(cleanDb.documentRecords).get();
      expect(restoredDocs.length, equals(1));
      expect(restoredDocs.first.displayName, equals('Arsip_Kontrak.docx'));
      expect(restoredDocs.first.isFavorite, isTrue);

      await cleanDb.close();
    });
  });

  group('AppLockService & Security Tests', () {
    test('sets and verifies numeric PIN lock', () {
      expect(lockService.state.isLockEnabled, isFalse);

      lockService.setPin('1234');
      expect(lockService.state.isLockEnabled, isTrue);
      expect(lockService.state.hashedPin, isNotNull);

      // Verification
      expect(lockService.verifyPin('1234'), isTrue);
      expect(lockService.verifyPin('9999'), isFalse);

      lockService.disableLock();
      expect(lockService.state.isLockEnabled, isFalse);
      expect(lockService.state.hashedPin, isNull);
    });

    test('toggles biometrics, auto-lock on background, and screenshot blocking',
        () async {
      lockService.setUseBiometrics(enabled: true);
      expect(lockService.state.useBiometrics, isTrue);

      lockService.setAutoLockOnBackground(enabled: false);
      expect(lockService.state.autoLockOnBackground, isFalse);

      final blocked = await lockService.setBlockScreenshots(block: true);
      expect(blocked, isTrue);
      expect(lockService.state.blockScreenshots, isTrue);
    });

    test('lock and unlock transitions state', () {
      lockService
        ..setPin('5678')
        ..lockApp();
      expect(lockService.state.isCurrentlyLocked, isTrue);

      lockService.unlockApp();
      expect(lockService.state.isCurrentlyLocked, isFalse);
    });
  });

  group('SecureWipeService Tests', () {
    test('cleanTemporaryCaches removes temporary scan & OCR files', () async {
      final tempScan =
          File('${Directory.systemTemp.path}/scanned_test_tahap7.jpg')
            ..writeAsStringSync('TEMP_DATA');
      expect(tempScan.existsSync(), isTrue);

      final result = await wipeService.cleanTemporaryCaches();
      expect(result.deletedFilesCount, greaterThanOrEqualTo(1));
      expect(tempScan.existsSync(), isFalse);
    });

    test('wipeAllAppData wipes database tables, lock credentials, and caches',
        () async {
      // Seed data
      await db.into(db.documentRecords).insert(
            DocumentRecordsCompanion(
              id: const Value(242),
              uri: const Value('content://test/wipe'),
              displayName: const Value('WipeMe.pdf'),
              mimeType: const Value(SupportedMimeTypes.pdf),
              firstOpenedAt: Value(DateTime.now()),
              lastOpenedAt: Value(DateTime.now()),
            ),
          );
      lockService.setPin('4321');

      final ok = await wipeService.wipeAllAppData();
      expect(ok, isTrue);

      // Verify DB is empty
      final docs = await db.select(db.documentRecords).get();
      expect(docs, isEmpty);

      // Verify lock is disabled
      expect(lockService.state.isLockEnabled, isFalse);
    });
  });

  group('Permission & Privacy Audit Verification', () {
    test('Manifest verification: 100% offline, zero internet permissions', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);

      final content = manifestFile.readAsStringSync();

      // Negative check: No internet permission
      expect(
        content.contains(
            '<uses-permission android:name="android.permission.INTERNET"'),
        isFalse,
      );
      expect(
        content.contains(
            '<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"'),
        isFalse,
      );
      expect(
        content.contains(
            '<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"'),
        isFalse,
      );

      // Positive check: Documented biometric permission
      expect(content.contains('android.permission.USE_BIOMETRIC'), isTrue);
      expect(content.contains('PERMISSION AUDIT'), isTrue);
    });

    test('Audit report docs/PRIVACY_AUDIT.md exists and is documented', () {
      final auditFile = File('docs/PRIVACY_AUDIT.md');
      expect(auditFile.existsSync(), isTrue);
      expect(auditFile.readAsStringSync(),
          contains('Zero Network Connections Invariant'));
    });
  });
}
