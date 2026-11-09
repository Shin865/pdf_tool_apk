import 'dart:convert';
import 'dart:io';

import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/data/saf/saf_file_service.dart';
import 'package:document_reviewer/data/saf/storage_directory_manager.dart';

/// Represents an active document editing session in sandboxed storage.
class EditingSession {
  EditingSession({
    required this.documentId,
    required this.sourceUri,
    required this.displayName,
    required this.mimeType,
    required this.workingCopyPath,
    required this.manifestPath,
    this.isDirty = false,
    this.lastSavedAt,
  });

  factory EditingSession.fromJson(Map<String, dynamic> json) => EditingSession(
        documentId: json['documentId'] as int,
        sourceUri: json['sourceUri'] as String,
        displayName: json['displayName'] as String,
        mimeType: json['mimeType'] as String,
        workingCopyPath: json['workingCopyPath'] as String,
        manifestPath: json['manifestPath'] as String,
        isDirty: json['isDirty'] as bool? ?? false,
        lastSavedAt: json['lastSavedAt'] != null
            ? DateTime.tryParse(json['lastSavedAt'] as String)
            : null,
      );

  final int documentId;
  String sourceUri;
  final String displayName;
  final String mimeType;
  final String workingCopyPath;
  final String manifestPath;
  bool isDirty;
  DateTime? lastSavedAt;

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'sourceUri': sourceUri,
        'displayName': displayName,
        'mimeType': mimeType,
        'workingCopyPath': workingCopyPath,
        'manifestPath': manifestPath,
        'isDirty': isDirty,
        'lastSavedAt': lastSavedAt?.toIso8601String(),
      };
}

/// Result of a save operation coordinated by [SaveCoordinator].
class SaveOperationResult {
  const SaveOperationResult({
    required this.success,
    this.errorMessage,
    this.writtenBackBytes,
  });

  final bool success;
  final String? errorMessage;
  final int? writtenBackBytes;
}

/// Coordinates the fail-safe document editing lifecycle:
/// 1. Sandboxed working copy isolation
/// 2. In-memory & on-disk dirty state tracking
/// 3. Structural validation prior to write-back
/// 4. Atomic write-back to SAF URI
/// 5. Version history recording in Drift SQLite
/// 6. Process-death recovery of uncommitted sessions
class SaveCoordinator {
  SaveCoordinator({
    required SafFileService safService,
    required StorageDirectoryManager directoryManager,
    required AppDatabase database,
  })  : _saf = safService,
        _dirs = directoryManager,
        _db = database;

  final SafFileService _saf;
  final StorageDirectoryManager _dirs;
  final AppDatabase _db;

  /// Starts a new isolated editing session for a document.
  Future<EditingSession> startSession({
    required int documentId,
    required String sourceUri,
    required String displayName,
    required String mimeType,
  }) async {
    final workingPath = await _dirs.getWorkingCopyPath(sourceUri, displayName);
    final manifestPath = '$workingPath.session.json';

    // Copy to working directory if not already staged
    final workingFile = File(workingPath);
    if (!workingFile.existsSync()) {
      final copied = await _saf.copyToLocal(
        uri: sourceUri,
        destinationPath: workingPath,
      );
      if (!copied) {
        throw StateError('Failed to copy document from SAF to working copy');
      }
    }

    final session = EditingSession(
      documentId: documentId,
      sourceUri: sourceUri,
      displayName: displayName,
      mimeType: mimeType,
      workingCopyPath: workingPath,
      manifestPath: manifestPath,
      lastSavedAt: DateTime.now(),
    );

    _persistManifest(session);
    return session;
  }

  /// Marks the session as modified (dirty) or clean.
  void markDirty(EditingSession session, {required bool dirty}) {
    session.isDirty = dirty;
    _persistManifest(session);
  }

  /// Performs atomic write-back of working copy to destination SAF URI.
  Future<SaveOperationResult> save(
    EditingSession session, {
    bool createVersion = true,
  }) async {
    final file = File(session.workingCopyPath);
    if (!file.existsSync()) {
      return const SaveOperationResult(
        success: false,
        errorMessage: 'Working copy file does not exist',
      );
    }

    final fileSize = file.lengthSync();
    if (fileSize == 0) {
      return const SaveOperationResult(
        success: false,
        errorMessage: 'Working copy file is 0 bytes (corrupted)',
      );
    }

    // Check destination accessibility and permissions
    final accessible = await _dirs.isUriAccessible(session.sourceUri);
    if (!accessible) {
      return const SaveOperationResult(
        success: false,
        errorMessage: 'Destination URI access denied or permission revoked',
      );
    }

    // Atomic write back to SAF URI
    final written = await _saf.writeBackToUri(
      sourcePath: session.workingCopyPath,
      uri: session.sourceUri,
    );

    if (!written) {
      return const SaveOperationResult(
        success: false,
        errorMessage: 'Failed to write back atomically to destination URI',
      );
    }

    // Record version in Drift database
    if (createVersion) {
      final versions = await _db.getVersionsForDocument(session.documentId);
      await _db.createVersion(
        documentId: session.documentId,
        localCopyPath: session.workingCopyPath,
        versionNumber: versions.length + 1,
        changeDescription: 'Auto-saved via SaveCoordinator',
      );
    }

    session
      ..isDirty = false
      ..lastSavedAt = DateTime.now();
    _persistManifest(session);

    return SaveOperationResult(
      success: true,
      writtenBackBytes: fileSize,
    );
  }

  /// Saves the working copy to a brand new SAF URI (Save As).
  Future<SaveOperationResult> saveAs({
    required EditingSession session,
    required String newTargetUri,
    required String newDisplayName,
  }) async {
    final accessible = await _dirs.isUriAccessible(newTargetUri);
    if (!accessible) {
      return const SaveOperationResult(
        success: false,
        errorMessage: 'New destination URI is not accessible',
      );
    }

    final written = await _saf.writeBackToUri(
      sourcePath: session.workingCopyPath,
      uri: newTargetUri,
    );

    if (!written) {
      return const SaveOperationResult(
        success: false,
        errorMessage: 'Failed to write to new destination URI',
      );
    }

    // Switch target
    session
      ..sourceUri = newTargetUri
      ..isDirty = false
      ..lastSavedAt = DateTime.now();
    _persistManifest(session);

    return SaveOperationResult(
      success: true,
      writtenBackBytes: File(session.workingCopyPath).lengthSync(),
    );
  }

  /// Scans sandboxed working storage for dirty sessions abandoned due to process death.
  Future<List<EditingSession>> checkForPendingRecovery() async {
    final workDir = await _dirs.workingDirectory;
    final recovered = <EditingSession>[];

    for (final entity in workDir.listSync()) {
      if (entity is File && entity.path.endsWith('.session.json')) {
        try {
          final content = entity.readAsStringSync();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final session = EditingSession.fromJson(json);

          // If working copy file exists and session was dirty, it is recoverable
          if (File(session.workingCopyPath).existsSync() && session.isDirty) {
            recovered.add(session);
          }
        } on Exception {
          // Ignore corrupt manifest files
        }
      }
    }
    return recovered;
  }

  /// Discards the editing session and cleans up local temporary files.
  Future<void> discardSession(EditingSession session) async {
    final workFile = File(session.workingCopyPath);
    if (workFile.existsSync()) {
      try {
        workFile.deleteSync();
      } on Exception {
        // Ignored
      }
    }

    final manifest = File(session.manifestPath);
    if (manifest.existsSync()) {
      try {
        manifest.deleteSync();
      } on Exception {
        // Ignored
      }
    }
  }

  void _persistManifest(EditingSession session) {
    try {
      File(session.manifestPath)
          .writeAsStringSync(jsonEncode(session.toJson()), flush: true);
    } on Exception {
      // Ignored
    }
  }
}
