import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage('ar');
      await _flutterTts.setSpeechRate(0.45); // Slower speech rate for elderly users
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(true);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing TTS Service: $e');
    }
  }

  Future<void> speakMedicationAlarm({
    required String medicationName,
    required String dosageDescription,
  }) async {
    try {
      await initialize();
      final speechText = 'تنبيه. حان موعد أخذ دواء $medicationName. الجرعة المطلوبة: $dosageDescription.';
      await _flutterTts.speak(speechText);
    } catch (e) {
      debugPrint('Error speaking medication alarm: $e');
    }
  }

  Future<void> speak(String text) async {
    try {
      await initialize();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }
}
