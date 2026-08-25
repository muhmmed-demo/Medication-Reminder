import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

class VibrationService {
  bool _isVibrating = false;

  Future<void> startAlarmVibration() async {
    if (_isVibrating) return;

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        final hasCustomVibrations = await Vibration.hasCustomVibrationsSupport();
        if (hasCustomVibrations == true) {
          // Pattern: wait 500ms, vibrate 1000ms, wait 500ms, vibrate 1000ms...
          // repeat: 0 means repeat indefinitely from index 0
          await Vibration.vibrate(
            pattern: [500, 1000, 500, 1000],
            repeat: 0,
          );
        } else {
          await Vibration.vibrate(duration: 2000);
        }
        _isVibrating = true;
      }
    } catch (e) {
      debugPrint('Error starting vibration: $e');
    }
  }

  Future<void> stopVibration() async {
    if (!_isVibrating) return;
    try {
      await Vibration.cancel();
      _isVibrating = false;
    } catch (e) {
      debugPrint('Error stopping vibration: $e');
    }
  }
}
