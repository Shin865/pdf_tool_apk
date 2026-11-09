import 'package:document_reviewer/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Database Schema and Migration Tests', () {
    test('fresh creation creates v2 indices', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      // Trigger table and index creation
      await db.customSelect('SELECT 1').get();

      // Verify indices exist in sqlite_master
      final indices = await db
          .customSelect(
            "SELECT name, tbl_name FROM sqlite_master WHERE type = 'index'",
          )
          .get();

      final indexNames =
          indices.map((row) => row.read<String>('name')).toList();
      expect(indexNames, contains('document_records_fav_idx'));
      expect(indexNames, contains('recent_documents_opened_at_idx'));
    });

    test('migration from v1 adds indices properly', () async {
      // Simulate raw database at schema v1 without indices
      final executor = NativeDatabase.memory();
      final rawDb = AppDatabase.forTesting(executor);

      // Ensure database is initialized
      await rawDb.customSelect('SELECT 1').get();

      // Drop indices to simulate v1 schema without indices
      await rawDb
          .customStatement('DROP INDEX IF EXISTS document_records_fav_idx;');
      await rawDb.customStatement(
        'DROP INDEX IF EXISTS recent_documents_opened_at_idx;',
      );

      // Verify indices are gone
      var indices = await rawDb
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index'",
          )
          .get();
      var indexNames = indices.map((row) => row.read<String>('name')).toList();
      expect(indexNames, isNot(contains('document_records_fav_idx')));
      expect(indexNames, isNot(contains('recent_documents_opened_at_idx')));

      // Run migration logic via onUpgrade
      final m = rawDb.createMigrator();
      await rawDb.migration.onUpgrade(m, 1, 2);

      indices = await rawDb
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index'",
          )
          .get();

      indexNames = indices.map((row) => row.read<String>('name')).toList();
      expect(indexNames, contains('document_records_fav_idx'));
      expect(indexNames, contains('recent_documents_opened_at_idx'));

      await rawDb.close();
    });
  });
}
