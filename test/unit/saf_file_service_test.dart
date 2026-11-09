import 'package:document_reviewer/data/saf/saf_file_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafPickResult', () {
    test('fromMap creates correct instance', () {
      final map = <String, dynamic>{
        'uri': 'content://com.example/test/doc.pdf',
        'displayName': 'doc.pdf',
        'mimeType': 'application/pdf',
        'size': 1024,
      };

      final result = SafPickResult.fromMap(map);

      expect(result.uri, 'content://com.example/test/doc.pdf');
      expect(result.displayName, 'doc.pdf');
      expect(result.mimeType, 'application/pdf');
      expect(result.size, 1024);
    });

    test('fromMap handles missing size', () {
      final map = <String, dynamic>{
        'uri': 'content://test',
        'displayName': 'test.txt',
        'mimeType': 'text/plain',
      };

      final result = SafPickResult.fromMap(map);
      expect(result.size, 0);
    });
  });
}
