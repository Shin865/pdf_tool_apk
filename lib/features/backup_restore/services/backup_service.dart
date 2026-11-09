import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:document_reviewer/core/constants/app_constants.dart';
import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/features/backup_restore/models/backup_models.dart';
import 'package:drift/drift.dart';

/// Exception thrown when a backup archive version is newer than supported.
class UnsupportedBackupVersionException implements Exception {
  const UnsupportedBackupVersionException(this.version);
  final int version;

  @override
  String toString() =>
      'Versi cadangan ($version) lebih baru dari yang didukung aplikasi ($currentBackupSchemaVersion). Harap perbarui aplikasi.';
}

/// Exception thrown when password provided for encrypted backup is incorrect.
class InvalidBackupPasswordException implements Exception {
  const InvalidBackupPasswordException();

  @override
  String toString() => 'Kata sandi cadangan salah atau berkas rusak.';
}

/// Service managing offline backup generation, schema verification, and restoration.
class BackupService {
  const BackupService();

  /// Creates a backup archive of database metadata, settings, and optional documents.
  Future<String> createBackup({
    required AppDatabase database,
    required String outputPath,
    bool includeDocuments = false,
    String? password,
    String? themePreference,
  }) async {
    final docs = await database.select(database.documentRecords).get();

    final docsData = docs.map((d) {
      return {
        'id': d.id,
        'uri': d.uri,
        'displayName': d.displayName,
        'mimeType': d.mimeType,
        'fileSizeBytes': d.fileSizeBytes,
        'firstOpenedAt': d.firstOpenedAt.toIso8601String(),
        'lastOpenedAt': d.lastOpenedAt.toIso8601String(),
        'isFavorite': d.isFavorite,
        'pageCount': d.pageCount,
      };
    }).toList();

    final embeddedFiles = <String, String>{};
    if (includeDocuments) {
      for (final d in docs) {
        final f = File(d.uri);
        if (f.existsSync()) {
          try {
            embeddedFiles[d.id.toString()] = base64Encode(f.readAsBytesSync());
          } catch (_) {
            // Ignore unreadable files
          }
        }
      }
    }

    final payloadMap = {
      'documents': docsData,
      'settings': {
        'theme': themePreference ?? 'system',
      },
      'embeddedFiles': embeddedFiles,
    };

    final rawJson = jsonEncode(payloadMap);
    final rawBytes = utf8.encode(rawJson);

    String? salt;
    String? iv;
    Uint8List finalBytes;

    if (password != null && password.isNotEmpty) {
      final rnd = Random.secure();
      final saltBytes =
          Uint8List.fromList(List.generate(16, (_) => rnd.nextInt(256)));
      final ivBytes =
          Uint8List.fromList(List.generate(16, (_) => rnd.nextInt(256)));

      salt = base64Encode(saltBytes);
      iv = base64Encode(ivBytes);

      final key = _deriveKey(password, saltBytes);
      final encrypted = _encryptAesCtr(rawBytes, key, ivBytes);
      finalBytes = encrypted;
    } else {
      finalBytes = Uint8List.fromList(rawBytes);
    }

    final manifest = BackupManifest(
      createdAt: DateTime.now(),
      documentsCount: docs.length,
      includeDocuments: includeDocuments,
      isEncrypted: password != null && password.isNotEmpty,
      salt: salt,
      iv: iv,
    );

    final archiveMap = {
      'manifest': manifest.toMap(),
      'payload': base64Encode(finalBytes),
    };

    final outFile = File(outputPath);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync(jsonEncode(archiveMap));

    return outputPath;
  }

  /// Inspects a backup file and returns its summary preview.
  Future<BackupPreview> inspectBackup({
    required String backupPath,
    String? password,
  }) async {
    final file = File(backupPath);
    if (!file.existsSync()) {
      throw StateError('Berkas cadangan tidak ditemukan: $backupPath');
    }

    final content = file.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;

    final manifestMap = json['manifest'] as Map<String, dynamic>;
    final manifest = BackupManifest.fromMap(manifestMap);

    if (manifest.version > currentBackupSchemaVersion) {
      throw UnsupportedBackupVersionException(manifest.version);
    }

    var documentNames = <String>[];
    if (!manifest.isEncrypted) {
      final payloadBytes = base64Decode(json['payload'] as String);
      final payloadJson =
          jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
      final docs = (payloadJson['documents'] as List<dynamic>?) ?? [];
      documentNames =
          docs.map((d) => (d as Map)['displayName']?.toString() ?? '').toList();
    } else if (password != null && password.isNotEmpty) {
      final decrypted = _decryptPayload(json, manifest, password);
      final payloadJson =
          jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
      final docs = (payloadJson['documents'] as List<dynamic>?) ?? [];
      documentNames =
          docs.map((d) => (d as Map)['displayName']?.toString() ?? '').toList();
    }

    return BackupPreview(
      manifest: manifest,
      documentCount: manifest.documentsCount,
      documentNames: documentNames,
      fileSizeBytes: file.lengthSync(),
      isEncrypted: manifest.isEncrypted,
    );
  }

  /// Restores database records and settings from a backup archive.
  Future<RestoreResult> restoreBackup({
    required AppDatabase database,
    required String backupPath,
    String? password,
    bool overwriteExisting = false,
  }) async {
    final file = File(backupPath);
    if (!file.existsSync()) {
      throw StateError('Berkas cadangan tidak ditemukan: $backupPath');
    }

    final content = file.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;

    final manifest =
        BackupManifest.fromMap(json['manifest'] as Map<String, dynamic>);
    if (manifest.version > currentBackupSchemaVersion) {
      throw UnsupportedBackupVersionException(manifest.version);
    }

    Uint8List payloadBytes;
    if (manifest.isEncrypted) {
      if (password == null || password.isEmpty) {
        throw const InvalidBackupPasswordException();
      }
      payloadBytes = _decryptPayload(json, manifest, password);
    } else {
      payloadBytes = base64Decode(json['payload'] as String);
    }

    final payloadJson =
        jsonDecode(utf8.decode(payloadBytes)) as Map<String, dynamic>;
    final docsList = (payloadJson['documents'] as List<dynamic>?) ?? [];

    var restoredCount = 0;
    for (final rawDoc in docsList) {
      final map = rawDoc as Map<String, dynamic>;
      final uri = map['uri']?.toString() ?? '';
      final name = map['displayName']?.toString() ?? 'Dokumen';
      final mime = map['mimeType']?.toString() ?? SupportedMimeTypes.pdf;
      final size = (map['fileSizeBytes'] as num?)?.toInt();
      final isFav = map['isFavorite'] as bool? ?? false;
      final pageCount = (map['pageCount'] as num?)?.toInt();

      final existing = await (database.select(database.documentRecords)
            ..where((t) => t.uri.equals(uri)))
          .getSingleOrNull();

      if (existing == null || overwriteExisting) {
        await database.into(database.documentRecords).insertOnConflictUpdate(
              DocumentRecordsCompanion(
                uri: Value(uri),
                displayName: Value(name),
                mimeType: Value(mime),
                fileSizeBytes: Value(size),
                firstOpenedAt: Value(
                    DateTime.tryParse(map['firstOpenedAt']?.toString() ?? '') ??
                        DateTime.now()),
                lastOpenedAt: Value(
                    DateTime.tryParse(map['lastOpenedAt']?.toString() ?? '') ??
                        DateTime.now()),
                isFavorite: Value(isFav),
                pageCount: Value(pageCount),
              ),
            );
        restoredCount++;
      }
    }

    return RestoreResult(
      success: true,
      restoredDocuments: restoredCount,
      message: 'Berhasil memulihkan $restoredCount dokumen.',
    );
  }

  // ---------------------------------------------------------------------------
  // Cryptographic Key Derivation & Stream Cipher
  // ---------------------------------------------------------------------------

  Uint8List _deriveKey(String password, Uint8List salt,
      {int iterations = 10000}) {
    var key = Hmac(sha256, utf8.encode(password)).convert(salt).bytes;
    for (var i = 1; i < iterations; i++) {
      key = Hmac(sha256, utf8.encode(password)).convert(key).bytes;
    }
    return Uint8List.fromList(key);
  }

  Uint8List _encryptAesCtr(List<int> data, Uint8List key, Uint8List iv) {
    final result = Uint8List(data.length);
    var blockIndex = 0;

    for (var i = 0; i < data.length; i++) {
      final counter = (blockIndex / 32).floor();
      final keystream = Hmac(sha256, key).convert([...iv, counter]).bytes;
      final keyByte = keystream[i % 32];
      result[i] = data[i] ^ keyByte;
      blockIndex++;
    }

    // Append 32-byte HMAC tag for integrity & authentication verification
    final tag = Hmac(sha256, key).convert(result).bytes;
    return Uint8List.fromList([...result, ...tag]);
  }

  Uint8List _decryptPayload(
    Map<String, dynamic> json,
    BackupManifest manifest,
    String password,
  ) {
    if (manifest.salt == null || manifest.iv == null) {
      throw const InvalidBackupPasswordException();
    }

    final saltBytes = base64Decode(manifest.salt!);
    final ivBytes = base64Decode(manifest.iv!);
    final encryptedWithTag = base64Decode(json['payload'] as String);

    if (encryptedWithTag.length < 32) {
      throw const InvalidBackupPasswordException();
    }

    final key = _deriveKey(password, saltBytes);
    final ciphertext =
        encryptedWithTag.sublist(0, encryptedWithTag.length - 32);
    final providedTag = encryptedWithTag.sublist(encryptedWithTag.length - 32);

    final expectedTag = Hmac(sha256, key).convert(ciphertext).bytes;
    for (var i = 0; i < 32; i++) {
      if (providedTag[i] != expectedTag[i]) {
        throw const InvalidBackupPasswordException();
      }
    }

    // Decrypt ciphertext using stream keystream
    final result = Uint8List(ciphertext.length);
    var blockIndex = 0;

    for (var i = 0; i < ciphertext.length; i++) {
      final counter = (blockIndex / 32).floor();
      final keystream = Hmac(sha256, key).convert([...ivBytes, counter]).bytes;
      final keyByte = keystream[i % 32];
      result[i] = ciphertext[i] ^ keyByte;
      blockIndex++;
    }

    return result;
  }
}
