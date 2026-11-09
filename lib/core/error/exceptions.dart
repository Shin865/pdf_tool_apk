/// Application-wide error types for the document engine layer.
library;

/// Base exception for all document engine errors.
sealed class DocumentEngineException implements Exception {
  const DocumentEngineException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => '$_typeName: $message';

  String get _typeName;
}

/// Thrown when a document file cannot be found or accessed.
class DocumentNotFoundException extends DocumentEngineException {
  const DocumentNotFoundException(super.message, [super.cause]);

  @override
  String get _typeName => 'DocumentNotFoundException';
}

/// Thrown when a document is encrypted and no/wrong password is provided.
class DocumentEncryptedException extends DocumentEngineException {
  const DocumentEncryptedException(super.message, [super.cause]);

  @override
  String get _typeName => 'DocumentEncryptedException';
}

/// Thrown when a document is corrupted or in an unsupported format.
class DocumentCorruptedException extends DocumentEngineException {
  const DocumentCorruptedException(super.message, [super.cause]);

  @override
  String get _typeName => 'DocumentCorruptedException';
}

/// Thrown when a document format is not supported by the current engine.
class UnsupportedFormatException extends DocumentEngineException {
  const UnsupportedFormatException(super.message, [super.cause]);

  @override
  String get _typeName => 'UnsupportedFormatException';
}

/// Thrown when a save operation fails.
class DocumentSaveException extends DocumentEngineException {
  const DocumentSaveException(super.message, [super.cause]);

  @override
  String get _typeName => 'DocumentSaveException';
}

/// Thrown when a native engine is not initialized.
class EngineNotInitializedException extends DocumentEngineException {
  const EngineNotInitializedException(super.message, [super.cause]);

  @override
  String get _typeName => 'EngineNotInitializedException';
}

/// Thrown when an operation exceeds resource limits (RAM, time, etc.).
class ResourceLimitException extends DocumentEngineException {
  const ResourceLimitException(super.message, [super.cause]);

  @override
  String get _typeName => 'ResourceLimitException';
}

/// Thrown when a page fails to render.
class DocumentRenderException extends DocumentEngineException {
  const DocumentRenderException(super.message, [super.cause]);

  @override
  String get _typeName => 'DocumentRenderException';
}

/// Thrown when storage permission is denied or revoked.
class StoragePermissionException extends DocumentEngineException {
  const StoragePermissionException(super.message, [super.cause]);

  @override
  String get _typeName => 'StoragePermissionException';
}
