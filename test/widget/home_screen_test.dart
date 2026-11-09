import 'package:document_reviewer/app/providers.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/features/home/home_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    late AppDatabase testDb;

    setUp(() {
      testDb = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await testDb.close();
    });

    Widget buildTestWidget({AppDatabase? db}) {
      return ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db ?? testDb),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(),
        ),
      );
    }

    testWidgets('shows app title in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Document Reviewer'), findsWidgets);
    });

    testWidgets('shows open file button and FAB', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Open Document'), findsWidgets);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows section headers', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Recent Documents'), findsOneWidget);
    });

    testWidgets('shows empty states when no documents', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No favorite documents bookmarked'),
        findsOneWidget,
      );
      expect(
        find.textContaining('No recent documents found'),
        findsOneWidget,
      );
    });

    testWidgets('has settings button in app bar', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsWidgets);
    });
  });
}
