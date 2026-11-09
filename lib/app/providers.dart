import 'package:document_reviewer/core/engine/document_reader_engine.dart';
import 'package:document_reviewer/core/engine/document_scanner_engine.dart';
import 'package:document_reviewer/core/engine/ocr_engine.dart';
import 'package:document_reviewer/core/engine/office_editor_engine.dart';
import 'package:document_reviewer/core/engine/pdf_annotation_engine.dart';
import 'package:document_reviewer/core/engine/pdf_page_engine.dart';
import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/data/engine_impl/native_document_reader_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_ocr_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_office_editor_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_pdf_annotation_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_pdf_page_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_scanner_engine.dart';
import 'package:document_reviewer/data/repository/document_repository.dart';
import 'package:document_reviewer/data/saf/saf_file_service.dart';
import 'package:document_reviewer/data/saf/storage_directory_manager.dart';
import 'package:document_reviewer/data/save/save_coordinator.dart';
import 'package:document_reviewer/features/security/services/app_lock_service.dart';
import 'package:document_reviewer/features/security/services/secure_wipe_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// SAF file service.
final safServiceProvider = Provider<SafFileService>((ref) {
  return SafFileService();
});

/// Private storage directory manager.
final storageDirectoryManagerProvider =
    Provider<StorageDirectoryManager>((ref) {
  return StorageDirectoryManager();
});

/// Document repository.
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(
    database: ref.watch(databaseProvider),
    safService: ref.watch(safServiceProvider),
  );
});

/// Save coordinator for fail-safe atomic saves and session recovery.
final saveCoordinatorProvider = Provider<SaveCoordinator>((ref) {
  return SaveCoordinator(
    safService: ref.watch(safServiceProvider),
    directoryManager: ref.watch(storageDirectoryManagerProvider),
    database: ref.watch(databaseProvider),
  );
});

/// Document reader engine.
final documentReaderEngineProvider = Provider<DocumentReaderEngine>((ref) {
  return NativeDocumentReaderEngine();
});

/// PDF annotation engine.
final pdfAnnotationEngineProvider = Provider<PdfAnnotationEngine>((ref) {
  return NativePdfAnnotationEngine();
});

/// PDF page engine for operations like rotate, delete, reorder, merge, split.
final pdfPageEngineProvider = Provider<PdfPageEngine>((ref) {
  return NativePdfPageEngine();
});

/// Office editor engine.
final officeEditorEngineProvider = Provider<OfficeEditorEngine>((ref) {
  return NativeOfficeEditorEngine();
});

/// Document scanner engine.
final documentScannerEngineProvider = Provider<DocumentScannerEngine>((ref) {
  return NativeDocumentScannerEngine();
});

/// OCR engine.
final ocrEngineProvider = Provider<OcrEngine>((ref) {
  return NativeOcrEngine();
});

/// Security & App lock service.
final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService();
});

/// Secure wipe service for clearing caches and full application wipe.
final secureWipeServiceProvider = Provider<SecureWipeService>((ref) {
  return SecureWipeService(
    database: ref.watch(databaseProvider),
    directoryManager: ref.watch(storageDirectoryManagerProvider),
    lockService: ref.watch(appLockServiceProvider),
  );
});

/// Theme mode preference.
final themeModeProvider =
    StateProvider<ThemeModePreference>((ref) => ThemeModePreference.system);

/// Locale preference (null = follow system).
final localeProvider = StateProvider<Locale?>((ref) => null);

/// Enum for theme mode selection.
enum ThemeModePreference {
  light,
  dark,
  system,
}
