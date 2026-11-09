import 'package:document_reviewer/core/constants/app_constants.dart';

/// Schema version for backup archives.
const int currentBackupSchemaVersion = 1;

/// Manifest header for backup archive verification.
class BackupManifest {
  const BackupManifest({
    required this.createdAt,
    required this.documentsCount,
    this.version = currentBackupSchemaVersion,
    this.appName = AppConstants.appName,
    this.appVersion = AppConstants.appVersion,
    this.includeDocuments = false,
    this.isEncrypted = false,
    this.salt,
    this.iv,
  });

  factory BackupManifest.fromMap(Map<String, dynamic> map) {
    return BackupManifest(
      version: (map['version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      appName: map['appName']?.toString() ?? AppConstants.appName,
      appVersion: map['appVersion']?.toString() ?? AppConstants.appVersion,
      documentsCount: (map['documentsCount'] as num?)?.toInt() ?? 0,
      includeDocuments: map['includeDocuments'] as bool? ?? false,
      isEncrypted: map['isEncrypted'] as bool? ?? false,
      salt: map['salt']?.toString(),
      iv: map['iv']?.toString(),
    );
  }

  final int version;
  final DateTime createdAt;
  final String appName;
  final String appVersion;
  final int documentsCount;
  final bool includeDocuments;
  final bool isEncrypted;
  final String? salt;
  final String? iv;

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'appName': appName,
      'appVersion': appVersion,
      'documentsCount': documentsCount,
      'includeDocuments': includeDocuments,
      'isEncrypted': isEncrypted,
      if (salt != null) 'salt': salt,
      if (iv != null) 'iv': iv,
    };
  }
}

/// Preview of a backup archive prior to performing a restore.
class BackupPreview {
  const BackupPreview({
    required this.manifest,
    required this.documentCount,
    required this.documentNames,
    required this.fileSizeBytes,
    required this.isEncrypted,
  });

  final BackupManifest manifest;
  final int documentCount;
  final List<String> documentNames;
  final int fileSizeBytes;
  final bool isEncrypted;
}

/// Result of a backup restoration operation.
class RestoreResult {
  const RestoreResult({
    required this.success,
    required this.restoredDocuments,
    this.message,
  });

  final bool success;
  final int restoredDocuments;
  final String? message;
}
