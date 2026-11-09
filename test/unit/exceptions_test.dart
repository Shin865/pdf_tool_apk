import 'package:document_reviewer/core/error/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentEngineException hierarchy', () {
    test('DocumentNotFoundException has correct message', () {
      const exception = DocumentNotFoundException('File not found');
      expect(exception.message, 'File not found');
      expect(exception.cause, isNull);
      expect(exception.toString(), contains('DocumentNotFoundException'));
    });

    test('DocumentEncryptedException with cause', () {
      final cause = Exception('wrong password');
      final exception = DocumentEncryptedException('Encrypted', cause);
      expect(exception.message, 'Encrypted');
      expect(exception.cause, cause);
    });

    test('all exception types are sealed under DocumentEngineException', () {
      const exceptions = <DocumentEngineException>[
        DocumentNotFoundException('test'),
        DocumentEncryptedException('test'),
        DocumentCorruptedException('test'),
        UnsupportedFormatException('test'),
        DocumentSaveException('test'),
        EngineNotInitializedException('test'),
        ResourceLimitException('test'),
        DocumentRenderException('test'),
        StoragePermissionException('test'),
      ];

      expect(exceptions.length, 9);
      for (final e in exceptions) {
        expect(e, isA<DocumentEngineException>());
        expect(e.message, 'test');
      }
    });

    test('sealed class exhaustive switch works', () {
      const DocumentEngineException ex = DocumentNotFoundException('test');

      final result = switch (ex) {
        DocumentNotFoundException() => 'not_found',
        DocumentEncryptedException() => 'encrypted',
        DocumentCorruptedException() => 'corrupted',
        UnsupportedFormatException() => 'unsupported',
        DocumentSaveException() => 'save_error',
        EngineNotInitializedException() => 'not_initialized',
        ResourceLimitException() => 'resource_limit',
        DocumentRenderException() => 'render_error',
        StoragePermissionException() => 'permission_denied',
      };

      expect(result, 'not_found');
    });
  });
}
