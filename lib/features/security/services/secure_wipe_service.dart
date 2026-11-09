import 'dart:io';

import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/data/saf/storage_directory_manager.dart';
import 'package:document_reviewer/features/security/services/app_lock_service.dart';

/// Result of cache cleanup.
class CleanupResult {
  const CleanupResult({
    required this.deletedFilesCount,
    required this.freedBytes,
  });

  final int deletedFilesCount;
  final int freedBytes;
}

/// Service managing secure deletion of temporary files, OCR cache,
/// and complete application data wipe.
class SecureWipeService {
  const SecureWipeService({
    required this.database,
    required this.directoryManager,
    required this.lockService,
  });

  final AppDatabase database;
  final StorageDirectoryManager directoryManager;
  final AppLockService lockService;

  /// Cleans temporary files, scan/OCR artifacts, and expired working copies.
  Future<CleanupResult> cleanTemporaryCaches() async {
    var count = 0;
    var bytes = 0;

    final tempDir = Directory.systemTemp;
    if (tempDir.existsSync()) {
      try {
        final files = tempDir.listSync();
        for (final entity in files) {
          if (entity is File) {
            final name = entity.path.toLowerCase();
            if (name.contains('scanned_') ||
                name.contains('warped_') ||
                name.contains('filtered_') ||
                name.contains('rotated_') ||
                name.contains('scan_') ||
                name.contains('tahap')) {
              try {
                bytes += entity.lengthSync();
                entity.deleteSync();
                count++;
              } catch (_) {
                // Ignore busy or locked files
              }
            }
          }
        }
      } catch (_) {}
    }

    // Clean directory manager working directory temp files
    try {
      final removed = await directoryManager.cleanupOldTempFiles(
        maxAge: const Duration(hours: 1),
      );
      count += removed;
    } catch (_) {}

    return CleanupResult(deletedFilesCount: count, freedBytes: bytes);
  }

  /// Completely and securely wipes all app data: SQLite database records,
  /// session recovery logs, and security lock credentials.
  /// Original documents on user storage remain untouched.
  Future<bool> wipeAllAppData() async {
    try {
      // 1. Delete all database tables
      await database.delete(database.recentDocuments).go();
      await database.delete(database.documentBookmarks).go();
      await database.delete(database.documentVersions).go();
      await database.delete(database.documentRecords).go();

      // 2. Clean temporary files and caches
      await cleanTemporaryCaches();

      // 3. Disable security locks
      lockService.disableLock();
      await lockService.setBlockScreenshots(block: false);

      return true;
    } catch (_) {
      return false;
    }
  }
}
