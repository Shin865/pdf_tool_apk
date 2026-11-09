import 'dart:io';

import 'package:document_reviewer/core/constants/app_constants.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages private sandboxed directories for Document Reviewer:
/// - Working copy directory for active edit sessions
/// - Temporary cache directory for transient renders / previews
/// - Export directory for verified output documents
class StorageDirectoryManager {
  StorageDirectoryManager({
    MethodChannel? safChannel,
    Directory? baseSupportDir,
    Directory? baseCacheDir,
  })  : _channel = safChannel ??
            const MethodChannel('com.example.documentreviewer/saf'),
        _injectedSupportDir = baseSupportDir,
        _injectedCacheDir = baseCacheDir;

  final MethodChannel _channel;
  final Directory? _injectedSupportDir;
  final Directory? _injectedCacheDir;

  Future<Directory> get workingDirectory async {
    final base = _injectedSupportDir ?? await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, AppConstants.workingCopyDirName));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<Directory> get tempDirectory async {
    final base = _injectedCacheDir ?? await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, 'temp'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<Directory> get exportDirectory async {
    final base = _injectedSupportDir ?? await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'export'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Returns a deterministic working copy path for the given document [uri] and [displayName].
  Future<String> getWorkingCopyPath(String uri, String displayName) async {
    final workDir = await workingDirectory;
    final sanitizedName = displayName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final hash = uri.hashCode.toRadixString(16);
    return p.join(workDir.path, '${hash}_$sanitizedName');
  }

  /// Cleans up temporary rendered tiles or cache files older than [maxAge].
  Future<int> cleanupOldTempFiles({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    var deletedCount = 0;
    try {
      final tempDir = await tempDirectory;
      final now = DateTime.now();
      for (final entity in tempDir.listSync()) {
        if (entity is File) {
          final stat = entity.statSync();
          if (now.difference(stat.modified) > maxAge) {
            try {
              entity.deleteSync();
              deletedCount++;
            } on Exception {
              // Ignore failure to delete locked files
            }
          }
        }
      }
    } on Exception {
      // Ignored
    }
    return deletedCount;
  }

  /// Verifies whether the given SAF [uri] is still accessible (permission intact and file exists).
  Future<bool> isUriAccessible(String uri) async {
    try {
      final accessible =
          await _channel.invokeMethod<bool>('isUriAccessible', {'uri': uri});
      return accessible ?? false;
    } on PlatformException {
      return false;
    }
  }
}
