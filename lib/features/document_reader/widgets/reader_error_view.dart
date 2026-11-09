import 'package:document_reviewer/core/error/exceptions.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

/// Friendly error state widget for the reader screen.
class ReaderErrorView extends StatelessWidget {
  const ReaderErrorView({
    required this.error,
    this.onRetry,
    this.onUnlock,
    this.onClose,
    super.key,
  });

  final Object error;
  final VoidCallback? onRetry;
  final VoidCallback? onUnlock;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final (String title, String message, IconData icon, Color color) =
        switch (error) {
      DocumentEncryptedException() => (
          loc.passwordProtected,
          loc.passwordPrompt,
          Icons.lock_clock_outlined,
          Colors.orange,
        ),
      DocumentCorruptedException() => (
          loc.corruptedTitle,
          loc.corruptedMessage,
          Icons.broken_image_outlined,
          Colors.red,
        ),
      DocumentNotFoundException() => (
          loc.inaccessibleTitle,
          loc.inaccessibleMessage,
          Icons.folder_off_outlined,
          Colors.amber,
        ),
      UnsupportedFormatException() => (
          loc.unsupportedTitle,
          loc.unsupportedMessage,
          Icons.help_outline,
          Colors.blueGrey,
        ),
      ResourceLimitException() => (
          loc.lowMemory,
          error.toString(),
          Icons.memory_outlined,
          Colors.deepOrange,
        ),
      _ => (
          loc.error,
          error.toString(),
          Icons.error_outline,
          theme.colorScheme.error,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: color.withAlpha(30),
                    child: Icon(icon, size: 40, color: color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (error is DocumentEncryptedException &&
                          onUnlock != null)
                        FilledButton.icon(
                          onPressed: onUnlock,
                          icon: const Icon(Icons.key),
                          label: Text(loc.openFile),
                        )
                      else if (onRetry != null)
                        FilledButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh),
                          label: Text(loc.retry),
                        ),
                      if (onClose != null)
                        OutlinedButton(
                          onPressed: onClose,
                          child: Text(loc.close),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
