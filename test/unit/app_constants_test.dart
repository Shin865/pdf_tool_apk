import 'package:document_reviewer/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupportedMimeTypes', () {
    test('all list contains expected count', () {
      // 1 PDF + 3 MS Office + 3 ODF + 3 text + 5 image = 15
      expect(SupportedMimeTypes.all.length, 15);
    });

    test('documents list excludes images', () {
      for (final mime in SupportedMimeTypes.documents) {
        expect(
          mime.startsWith('image/'),
          isFalse,
          reason: '$mime should not be in documents list',
        );
      }
    });

    test('images list only contains image types', () {
      for (final mime in SupportedMimeTypes.images) {
        expect(
          mime.startsWith('image/'),
          isTrue,
          reason: '$mime should start with image/',
        );
      }
    });

    test('all = documents + images', () {
      final combined = [
        ...SupportedMimeTypes.documents,
        ...SupportedMimeTypes.images,
      ];
      expect(Set.of(combined), Set.of(SupportedMimeTypes.all));
    });
  });

  group('AppConstants', () {
    test('app name is set', () {
      expect(AppConstants.appName, isNotEmpty);
    });

    test('org name matches expected format', () {
      expect(
        AppConstants.orgName,
        matches(RegExp(r'^com\.\w+\.\w+$')),
      );
    });
  });
}
