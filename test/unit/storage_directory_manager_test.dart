import 'dart:io';

import 'package:document_reviewer/data/saf/storage_directory_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageDirectoryManager', () {
    late Directory tempSupportDir;
    late Directory tempCacheDir;
    late StorageDirectoryManager manager;

    setUp(() {
      tempSupportDir = Directory.systemTemp.createTempSync('mgr_support_test_');
      tempCacheDir = Directory.systemTemp.createTempSync('mgr_cache_test_');
      manager = StorageDirectoryManager(
        baseSupportDir: tempSupportDir,
        baseCacheDir: tempCacheDir,
      );
    });

    tearDown(() {
      if (tempSupportDir.existsSync()) {
        tempSupportDir.deleteSync(recursive: true);
      }
      if (tempCacheDir.existsSync()) {
        tempCacheDir.deleteSync(recursive: true);
      }
    });

    test('creates and separates working, temp, and export directories',
        () async {
      final workDir = await manager.workingDirectory;
      final tempDir = await manager.tempDirectory;
      final exportDir = await manager.exportDirectory;

      expect(workDir.existsSync(), isTrue);
      expect(tempDir.existsSync(), isTrue);
      expect(exportDir.existsSync(), isTrue);

      expect(workDir.path, isNot(equals(tempDir.path)));
      expect(workDir.path, isNot(equals(exportDir.path)));
      expect(tempDir.path, isNot(equals(exportDir.path)));
    });

    test('deterministic working copy path sanitizes unsafe filenames',
        () async {
      final path = await manager.getWorkingCopyPath(
        'content://media/external/files/100',
        'report:annual/2026?*.docx',
      );
      final filename = path.split(Platform.pathSeparator).last;

      expect(filename, isNot(contains(':')));
      expect(filename, isNot(contains('?')));
      expect(filename, isNot(contains('*')));
      expect(filename.endsWith('.docx'), isTrue);
    });

    test('cleans up temporary files older than threshold', () async {
      final tempDir = await manager.tempDirectory;
      final oldFile = File('${tempDir.path}/old_preview.png')
        ..writeAsStringSync('old')
        ..setLastModifiedSync(
          DateTime.now().subtract(const Duration(hours: 48)),
        );

      final newFile = File('${tempDir.path}/new_preview.png')
        ..writeAsStringSync('new');

      final deleted = await manager.cleanupOldTempFiles();

      expect(deleted, 1);
      expect(oldFile.existsSync(), isFalse);
      expect(newFile.existsSync(), isTrue);
    });
  });
}
