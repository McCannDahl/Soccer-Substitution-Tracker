import 'package:flutter/services.dart';

class AlertService {
  static Future<void> notifyPeriodEnd({
    bool sound = true,
    bool vibration = true,
  }) async {
    if (vibration) {
      try {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 200));
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }
    if (sound) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  static Future<void> notifyBreakEnd({
    bool sound = true,
    bool vibration = true,
  }) async {
    if (vibration) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
    if (sound) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  static Future<void> notifySubSuggestion({
    bool sound = true,
    bool vibration = true,
  }) async {
    if (vibration) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
    if (sound) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  static Future<void> buttonTapFeedback() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }
}
