import 'package:flutter/services.dart';

/// Centralized service for light, subtle haptic feedback.
class HapticsService {
  HapticsService._();

  static bool isEnabled = true;

  /// Trigger subtle selection click on button taps / tab switches
  static void selection() {
    if (!isEnabled) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Trigger very light impact on confirmations or actions
  static void lightImpact() {
    if (!isEnabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Trigger medium feedback on key transactions/saves
  static void mediumImpact() {
    if (!isEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
