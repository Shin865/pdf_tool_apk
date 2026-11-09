/// Application entry point and root widget.
library;

import 'package:document_reviewer/app/providers.dart';
import 'package:document_reviewer/app/router.dart';
import 'package:document_reviewer/app/theme.dart';
import 'package:document_reviewer/core/error/global_error_boundary.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _logger = Logger('DocumentReviewerApp');

/// Root application widget.
class DocumentReviewerApp extends ConsumerStatefulWidget {
  const DocumentReviewerApp({super.key});

  @override
  ConsumerState<DocumentReviewerApp> createState() =>
      _DocumentReviewerAppState();
}

class _DocumentReviewerAppState extends ConsumerState<DocumentReviewerApp> {
  static const _intentChannel =
      MethodChannel('com.example.documentreviewer/intent');

  @override
  void initState() {
    super.initState();
    _setupIntentHandling();
  }

  void _setupIntentHandling() {
    // 1. Listen for new intents while running
    _intentChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNewIntent') {
        final data = call.arguments as Map<dynamic, dynamic>?;
        if (data != null) {
          _handleIntentData(data);
        }
      }
    });

    // 2. Check for initial launch intent
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final initialIntent =
            await _intentChannel.invokeMethod<Map<dynamic, dynamic>>(
          'getInitialIntent',
        );
        if (initialIntent != null) {
          _handleIntentData(initialIntent);
        }
      } catch (e, st) {
        _logger.warning('Failed to query initial intent', e, st);
      }
    });
  }

  void _handleIntentData(Map<dynamic, dynamic> data) {
    final uri = data['uri']?.toString();
    if (uri != null && uri.isNotEmpty) {
      final displayName = data['displayName']?.toString() ?? 'Document';
      final mimeType =
          data['mimeType']?.toString() ?? 'application/octet-stream';
      _logger.info('Handling intent for URI: $uri');

      appRouter.push(
        Uri(
          path: AppRoutes.reader,
          queryParameters: {
            'uri': uri,
            'displayName': displayName,
            'mimeType': mimeType,
          },
        ).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Document Reviewer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (themeMode) {
        ThemeModePreference.light => ThemeMode.light,
        ThemeModePreference.dark => ThemeMode.dark,
        ThemeModePreference.system => ThemeMode.system,
      },
      routerConfig: appRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

/// Application main entry point.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GlobalErrorBoundary.initialize(
    runAppCallback: () {
      runApp(
        const ProviderScope(
          child: DocumentReviewerApp(),
        ),
      );
    },
  );
}
