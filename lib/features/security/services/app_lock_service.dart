import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

/// State of application security lock.
class AppLockState {
  const AppLockState({
    this.isLockEnabled = false,
    this.hashedPin,
    this.useBiometrics = false,
    this.autoLockOnBackground = true,
    this.blockScreenshots = false,
    this.isCurrentlyLocked = false,
  });

  final bool isLockEnabled;
  final String? hashedPin;
  final bool useBiometrics;
  final bool autoLockOnBackground;
  final bool blockScreenshots;
  final bool isCurrentlyLocked;

  AppLockState copyWith({
    bool? isLockEnabled,
    String? hashedPin,
    bool clearHashedPin = false,
    bool? useBiometrics,
    bool? autoLockOnBackground,
    bool? blockScreenshots,
    bool? isCurrentlyLocked,
  }) {
    return AppLockState(
      isLockEnabled: isLockEnabled ?? this.isLockEnabled,
      hashedPin: clearHashedPin ? null : (hashedPin ?? this.hashedPin),
      useBiometrics: useBiometrics ?? this.useBiometrics,
      autoLockOnBackground: autoLockOnBackground ?? this.autoLockOnBackground,
      blockScreenshots: blockScreenshots ?? this.blockScreenshots,
      isCurrentlyLocked: isCurrentlyLocked ?? this.isCurrentlyLocked,
    );
  }
}

/// Service managing PIN, Biometric Prompt, background auto-lock, and FLAG_SECURE.
class AppLockService {
  AppLockService({MethodChannel? securityChannel})
      : _channel = securityChannel ??
            const MethodChannel('com.example.documentreviewer/security');

  final MethodChannel _channel;
  AppLockState _state = const AppLockState();

  AppLockState get state => _state;

  static const String _pinSalt = 'dr_local_secure_salt_';

  /// Sets or updates the numeric PIN lock.
  void setPin(String pin) {
    final hash = sha256.convert(utf8.encode('$_pinSalt$pin')).toString();
    _state = _state.copyWith(
      isLockEnabled: true,
      hashedPin: hash,
      isCurrentlyLocked: false,
    );
  }

  /// Verifies the entered PIN against stored hash.
  bool verifyPin(String inputPin) {
    if (_state.hashedPin == null) return true;
    final hash = sha256.convert(utf8.encode('$_pinSalt$inputPin')).toString();
    if (hash == _state.hashedPin) {
      _state = _state.copyWith(isCurrentlyLocked: false);
      return true;
    }
    return false;
  }

  /// Disables app lock.
  void disableLock() {
    _state = _state.copyWith(
      isLockEnabled: false,
      clearHashedPin: true,
      isCurrentlyLocked: false,
    );
  }

  /// Sets whether biometrics should be used alongside PIN.
  void setUseBiometrics({required bool enabled}) {
    _state = _state.copyWith(useBiometrics: enabled);
  }

  /// Sets whether app locks automatically when backgrounded.
  void setAutoLockOnBackground({required bool enabled}) {
    _state = _state.copyWith(autoLockOnBackground: enabled);
  }

  /// Enables or disables screenshot blocking via native FLAG_SECURE.
  Future<bool> setBlockScreenshots({required bool block}) async {
    _state = _state.copyWith(blockScreenshots: block);
    try {
      final res = await _channel.invokeMethod<bool>(
        'security_setSecure',
        {'secure': block},
      );
      return res ?? true;
    } on PlatformException {
      return false;
    }
  }

  /// Checks if device has biometric or screen lock capability.
  Future<bool> canAuthenticateBiometric() async {
    try {
      final res = await _channel.invokeMethod<bool>('security_canAuthenticate');
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Prompts biometric / device credential authentication.
  Future<bool> authenticateBiometric() async {
    try {
      final res = await _channel.invokeMethod<bool>('security_authenticate');
      final ok = res ?? false;
      if (ok) {
        _state = _state.copyWith(isCurrentlyLocked: false);
      }
      return ok;
    } on PlatformException {
      return false;
    }
  }

  /// Manually locks the app.
  void lockApp() {
    if (_state.isLockEnabled) {
      _state = _state.copyWith(isCurrentlyLocked: true);
    }
  }

  /// Manually unlocks the app.
  void unlockApp() {
    _state = _state.copyWith(isCurrentlyLocked: false);
  }
}
