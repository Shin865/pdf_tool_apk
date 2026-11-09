import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

/// Dialog prompting the user for a document password.
/// Passwords are kept in memory only and never stored in the database or written to disk.
class PasswordDialog extends StatefulWidget {
  const PasswordDialog({
    this.errorMessage,
    super.key,
  });

  final String? errorMessage;

  /// Shows the password dialog and returns the entered password, or null if cancelled.
  static Future<String?> show(
    BuildContext context, {
    String? errorMessage,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordDialog(errorMessage: errorMessage),
    );
  }

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _controller = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(loc.passwordProtected)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.passwordPrompt, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscureText,
            autofocus: true,
            decoration: InputDecoration(
              labelText: loc.passwordLabel,
              border: const OutlineInputBorder(),
              errorText: widget.errorMessage,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                tooltip: _obscureText ? 'Show password' : 'Hide password',
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text;
            if (text.isNotEmpty) {
              Navigator.of(context).pop(text);
            }
          },
          child: Text(loc.openFile),
        ),
      ],
    );
  }
}
