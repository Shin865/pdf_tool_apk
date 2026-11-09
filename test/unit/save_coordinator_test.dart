import 'dart:io';

import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/data/saf/saf_file_service.dart';
import 'package:document_reviewer/data/saf/storage_directory_manager.dart';
import 'package:document_reviewer/data/save/save_coordinator.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSafFileService implements SafFileService {
  bool copySuccess = true;
  bool writeBackSuccess = true;
  String? lastWrittenSourcePath;
  String? lastWrittenUri;

  @override
  Future<bool> copyToLocal({
    required String uri,
    required String destinationPath,
  }) async {
    if (!copySuccess) return false;
    File(destinationPath)
      ..createSync(recursive: true)
      ..writeAsStringSync('Initial content from $uri');
    return true;
  }

  @override
  Future<bool> writeBackToUri({
    required String sourcePath,
    required String uri,
  }) async {
    if (!writeBackSuccess) return false;
    lastWrittenSourcePath = sourcePath;
    lastWrittenUri = uri;
    return true;
  }

  @override
  Future<List<String>> getPersistedUris() async => [];

  @override
  Future<bool> hasPermission({required String uri}) async => true;

  @override
  Future<bool> isUriAccessible(String uri) async => true;

  @override
  Future<bool> shareFile({
    required String uri,
    required String mimeType,
    String? displayName,
  }) async =>
      true;

  @override
  Future<SafPickResult?> pickFile({
    List<String> mimeTypes = const ['*/*'],
  }) async =>
      null;

  @override
  Future<void> releasePermission({required String uri}) async {}
}

class FakeStorageDirectoryManager extends StorageDirectoryManager {
  FakeStorageDirectoryManager({
    required Directory supportDir,
    required Directory cacheDir,
    this.accessible = true,
  })  : _testSupportDir = supportDir,
        _testCacheDir = cacheDir,
        super(baseSupportDir: supportDir, baseCacheDir: cacheDir);

  final Directory _testSupportDir;
  final Directory _testCacheDir;
  bool accessible;

  @override
  Future<Directory> get workingDirectory async {
    final dir = Directory('${_testSupportDir.path}/working');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  @override
  Future<Directory> get tempDirectory async {
    final dir = Directory('${_testCacheDir.path}/temp');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  @override
  Future<Directory> get exportDirectory async {
    final dir = Directory('${_testSupportDir.path}/export');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  @override
  Future<String> getWorkingCopyPath(String uri, String displayName) async {
    final dir = await workingDirectory;
    return '${dir.path}/${uri.hashCode}_$displayName';
  }

  @override
  Future<bool> isUriAccessible(String uri) async => accessible;
}

void main() {
  group('SaveCoordinator Unit Tests', () {
    late Directory tempSupportDir;
    late Directory tempCacheDir;
    late FakeSafFileService fakeSaf;
    late FakeStorageDirectoryManager fakeDirs;
    late AppDatabase testDb;
    late SaveCoordinator coordinator;

    setUp(() async {
      tempSupportDir = Directory.systemTemp.createTempSync('coord_support_');
      tempCacheDir = Directory.systemTemp.createTempSync('coord_cache_');
      fakeSaf = FakeSafFileService();
      fakeDirs = FakeStorageDirectoryManager(
        supportDir: tempSupportDir,
        cacheDir: tempCacheDir,
      );
      testDb = AppDatabase.forTesting(NativeDatabase.memory());
      coordinator = SaveCoordinator(
        safService: fakeSaf,
        directoryManager: fakeDirs,
        database: testDb,
      );
    });

    tearDown(() async {
      await testDb.close();
      if (tempSupportDir.existsSync()) {
        tempSupportDir.deleteSync(recursive: true);
      }
      if (tempCacheDir.existsSync()) {
        tempCacheDir.deleteSync(recursive: true);
      }
    });

    test('startSession creates isolated working copy and manifest', () async {
      final session = await coordinator.startSession(
        documentId: 1,
        sourceUri: 'content://docs/sample.docx',
        displayName: 'sample.docx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      );

      expect(File(session.workingCopyPath).existsSync(), isTrue);
      expect(File(session.manifestPath).existsSync(), isTrue);
      expect(session.isDirty, isFalse);
    });

    test('markDirty updates in-memory and persisted manifest', () async {
      final session = await coordinator.startSession(
        documentId: 1,
        sourceUri: 'content://docs/sample.docx',
        displayName: 'sample.docx',
        mimeType: 'application/docx',
      );

      coordinator.markDirty(session, dirty: true);
      expect(session.isDirty, isTrue);

      // Verify persisted manifest
      final manifestJson = File(session.manifestPath).readAsStringSync();
      expect(manifestJson, contains('"isDirty":true'));
    });

    test('save writes atomically to destination and logs version', () async {
      final session = await coordinator.startSession(
        documentId: 10,
        sourceUri: 'content://docs/invoice.xlsx',
        displayName: 'invoice.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      // Mutate working copy
      File(session.workingCopyPath).writeAsStringSync('Updated table content');
      coordinator.markDirty(session, dirty: true);

      final result = await coordinator.save(session);
      expect(result.success, isTrue);
      expect(result.writtenBackBytes, greaterThan(0));
      expect(fakeSaf.lastWrittenUri, 'content://docs/invoice.xlsx');
      expect(session.isDirty, isFalse);

      // Verify version in database
      final versions = await testDb.getVersionsForDocument(10);
      expect(versions.length, 1);
      expect(versions.first.versionNumber, 1);
    });

    test('save failure: fails if working copy is missing', () async {
      final session = await coordinator.startSession(
        documentId: 2,
        sourceUri: 'content://docs/missing.pdf',
        displayName: 'missing.pdf',
        mimeType: 'application/pdf',
      );

      // Delete file to simulate missing working file
      File(session.workingCopyPath).deleteSync();

      final result = await coordinator.save(session);
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('does not exist'));
    });

    test('save failure: fails if working copy is 0-bytes (corrupt)', () async {
      final session = await coordinator.startSession(
        documentId: 3,
        sourceUri: 'content://docs/zero.pdf',
        displayName: 'zero.pdf',
        mimeType: 'application/pdf',
      );

      // Truncate to 0 bytes
      File(session.workingCopyPath).writeAsBytesSync([]);

      final result = await coordinator.save(session);
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('0 bytes'));
    });

    test('save failure: fails if destination URI permission revoked', () async {
      final session = await coordinator.startSession(
        documentId: 4,
        sourceUri: 'content://docs/revoked.pdf',
        displayName: 'revoked.pdf',
        mimeType: 'application/pdf',
      );

      fakeDirs.accessible = false; // Revoke permission

      final result = await coordinator.save(session);
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('access denied'));
    });

    test('save failure: write back failure leaves session dirty', () async {
      final session = await coordinator.startSession(
        documentId: 5,
        sourceUri: 'content://docs/diskfull.pdf',
        displayName: 'diskfull.pdf',
        mimeType: 'application/pdf',
      );

      coordinator.markDirty(session, dirty: true);
      fakeSaf.writeBackSuccess = false; // SAF write fails (e.g. disk full)

      final result = await coordinator.save(session);
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Failed to write back'));
      expect(session.isDirty, isTrue); // dirty flag retained for retry
    });

    test('saveAs saves to new URI and updates target', () async {
      final session = await coordinator.startSession(
        documentId: 6,
        sourceUri: 'content://docs/original.pdf',
        displayName: 'original.pdf',
        mimeType: 'application/pdf',
      );

      final result = await coordinator.saveAs(
        session: session,
        newTargetUri: 'content://docs/backup.pdf',
        newDisplayName: 'backup.pdf',
      );

      expect(result.success, isTrue);
      expect(session.sourceUri, 'content://docs/backup.pdf');
      expect(fakeSaf.lastWrittenUri, 'content://docs/backup.pdf');
    });

    test('process death recovery finds uncommitted dirty sessions', () async {
      final session = await coordinator.startSession(
        documentId: 7,
        sourceUri: 'content://docs/crash.docx',
        displayName: 'crash.docx',
        mimeType: 'application/docx',
      );

      // Simulate crash with unsaved edits
      File(session.workingCopyPath).writeAsStringSync('Unsaved crash text');
      coordinator.markDirty(session, dirty: true);

      // Create new coordinator instance as on app restart
      final restartedCoordinator = SaveCoordinator(
        safService: fakeSaf,
        directoryManager: fakeDirs,
        database: testDb,
      );

      final recoverable = await restartedCoordinator.checkForPendingRecovery();
      expect(recoverable.length, 1);
      expect(recoverable.first.displayName, 'crash.docx');
      expect(recoverable.first.isDirty, isTrue);

      // Discarding removes the temporary files
      await restartedCoordinator.discardSession(recoverable.first);
      expect(File(session.workingCopyPath).existsSync(), isFalse);
      expect(File(session.manifestPath).existsSync(), isFalse);
    });
  });
}
