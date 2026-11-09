import 'package:document_reviewer/features/security/services/app_lock_service.dart';
import 'package:flutter/material.dart';

/// Screen displayed when the application is locked via PIN or Biometrics.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({
    required this.lockService,
    required this.onUnlocked,
    super.key,
  });

  final AppLockService lockService;
  final VoidCallback onUnlocked;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.lockService.state.useBiometrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerBiometric();
      });
    }
  }

  Future<void> _triggerBiometric() async {
    final ok = await widget.lockService.authenticateBiometric();
    if (ok && mounted) {
      widget.onUnlocked();
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length >= 4) {
        if (widget.lockService.verifyPin(_enteredPin)) {
          widget.onUnlocked();
        } else if (_enteredPin.length == 6) {
          setState(() {
            _errorMessage = 'PIN salah. Coba lagi.';
            _enteredPin = '';
          });
        }
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aplikasi Terkunci',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Masukkan PIN keamanan untuk melanjutkan',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PIN indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final filled = index < _enteredPin.length;
                      return Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          border: Border.all(
                            color: theme.colorScheme.outline,
                            width: 1.5,
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Numeric Keypad
                  for (var r = 0; r < 3; r++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var c = 1; c <= 3; c++)
                            _KeypadButton(
                              label: '${r * 3 + c}',
                              onTap: () => _onDigitPressed('${r * 3 + c}'),
                            ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Biometric button or blank
                        if (widget.lockService.state.useBiometrics)
                          IconButton(
                            iconSize: 32,
                            icon: const Icon(Icons.fingerprint),
                            onPressed: _triggerBiometric,
                          )
                        else
                          const SizedBox(width: 64, height: 64),

                        _KeypadButton(
                          label: '0',
                          onTap: () => _onDigitPressed('0'),
                        ),

                        IconButton(
                          iconSize: 28,
                          icon: const Icon(Icons.backspace_outlined),
                          onPressed: _onBackspace,
                        ),
                      ],
                    ),
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

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        ),
        child: Text(
          label,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
