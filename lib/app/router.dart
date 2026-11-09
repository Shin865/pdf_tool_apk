import 'package:document_reviewer/features/backup_restore/ui/backup_restore_screen.dart';
import 'package:document_reviewer/features/document_reader/document_reader_screen.dart';
import 'package:document_reviewer/features/home/home_screen.dart';
import 'package:document_reviewer/features/onboarding/onboarding_screen.dart';
import 'package:document_reviewer/features/scanner/document_scanner_screen.dart';
import 'package:document_reviewer/features/settings/about_screen.dart';
import 'package:document_reviewer/features/settings/settings_screen.dart';
import 'package:go_router/go_router.dart';

/// Route path constants.
abstract final class AppRoutes {
  static const String home = '/';
  static const String reader = '/reader';
  static const String settings = '/settings';
  static const String scanner = '/scanner';
  static const String backup = '/backup';
  static const String about = '/about';
  static const String onboarding = '/onboarding';
}

/// Application router instance with deep link support.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.reader,
      builder: (context, state) {
        final uri = state.uri.queryParameters['uri'] ?? '';
        final displayName = state.uri.queryParameters['displayName'];
        final mimeType = state.uri.queryParameters['mimeType'];
        return DocumentReaderScreen(
          uri: uri,
          displayName: displayName,
          mimeType: mimeType,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.scanner,
      builder: (context, state) {
        final initialImagePath = state.uri.queryParameters['initialImagePath'];
        return DocumentScannerScreen(
          initialImagePath: initialImagePath,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.backup,
      builder: (context, state) => const BackupRestoreScreen(),
    ),
    GoRoute(
      path: AppRoutes.about,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => OnboardingScreen(
        onFinished: () => context.go(AppRoutes.home),
      ),
    ),
  ],
);
