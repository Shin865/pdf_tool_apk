/// SAF (Storage Access Framework) service for file access on Android.
///
/// Uses platform channels to invoke Android's SAF picker and manage
/// persistable URI permissions. This ensures the app can reopen files
/// across restarts without re-picking.
library;

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('SafFileService');

/// Result from opening a file via SAF.
class SafPickResult {
  const SafPickResult({
    required this.uri,
    required this.displayName,
    required this.mimeType,
    required this.size,
  });

  factory SafPickResult.fromMap(Map<String, dynamic> map) {
    return SafPickResult(
      uri: map['uri'] as String,
      displayName: map['displayName'] as String,
      mimeType: map['mimeType'] as String,
      size: map['size'] as int? ?? 0,
    );
  }

  /// Content URI (content://...). Store this, NOT a file path.
  final String uri;
  final String displayName;
  final String mimeType;
  final int size;
}

/// Service wrapping SAF operations via a platform channel.
class SafFileService {
  SafFileService({MethodChannel? channel})
      : _channel =
            channel ?? const MethodChannel('com.example.documentreviewer/saf');

  final MethodChannel _channel;

  /// Opens the SAF file picker and returns the selected file info,
  /// or `null` if the user cancels.
  ///
  /// [mimeTypes] filters the picker to specific MIME types.
  /// The returned URI has persistable read/write permission.
  Future<SafPickResult?> pickFile({
    List<String> mimeTypes = const ['*/*'],
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'pickFile',
        {'mimeTypes': mimeTypes},
      );
      if (result == null) return null;
      return SafPickResult.fromMap(result);
    } on PlatformException catch (e) {
      _log.severe('SAF pickFile failed', e);
      return null;
    }
  }

  /// Copies the content at [uri] to a local [destinationPath].
  ///
  /// Use this to create a working copy before processing.
  Future<bool> copyToLocal({
    required String uri,
    required String destinationPath,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'copyToLocal',
        {'uri': uri, 'destinationPath': destinationPath},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.severe('SAF copyToLocal failed', e);
      return false;
    }
  }

  /// Writes the content from [sourcePath] back to the SAF [uri] atomically.
  ///
  /// The implementation writes to a temporary URI first, then replaces
  /// the target only on success.
  Future<bool> writeBackToUri({
    required String sourcePath,
    required String uri,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'writeBackToUri',
        {'sourcePath': sourcePath, 'uri': uri},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.severe('SAF writeBackToUri failed', e);
      return false;
    }
  }

  /// Releases the persistable URI permission for [uri].
  Future<void> releasePermission({required String uri}) async {
    try {
      await _channel.invokeMethod<void>(
        'releasePermission',
        {'uri': uri},
      );
    } on PlatformException catch (e) {
      _log.warning('SAF releasePermission failed', e);
    }
  }

  /// Returns the list of URIs with currently held persistable permissions.
  Future<List<String>> getPersistedUris() async {
    try {
      final result = await _channel.invokeListMethod<String>(
        'getPersistedUris',
      );
      return result ?? [];
    } on PlatformException catch (e) {
      _log.severe('SAF getPersistedUris failed', e);
      return [];
    }
  }

  /// Checks if the app still has permission to access [uri].
  Future<bool> hasPermission({required String uri}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'hasPermission',
        {'uri': uri},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('SAF hasPermission failed', e);
      return false;
    }
  }

  /// Verifies whether the given SAF [uri] is accessible (file exists and permission intact).
  Future<bool> isUriAccessible(String uri) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isUriAccessible',
        {'uri': uri},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      _log.warning('SAF isUriAccessible failed', e);
      return false;
    }
  }

  /// Shares a file via Android Intent.ACTION_SEND.
  Future<bool> shareFile({
    required String uri,
    required String mimeType,
    String? displayName,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('shareFile', {
        'uri': uri,
        'mimeType': mimeType,
        'displayName': displayName ?? 'Document',
      });
      return result ?? false;
    } on PlatformException catch (e) {
      _log.severe('SAF shareFile failed', e);
      return false;
    }
  }
}
