import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';

class AlarmAudioService {
  final AudioPlayer _player = AudioPlayer();
  static const MethodChannel _volumeChannel =
      MethodChannel('com.example.medication_reminder/volume');
  bool _isPlaying = false;
  double? _originalVolume;

  bool get isPlaying => _isPlaying;

  Future<void> initialize() async {
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientExclusive,
          ),
        ),
      );
      await _player.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      debugPrint('Error configuring AudioContext: $e');
    }
  }

  /// Bypasses silent mode by saving current volume and setting device volume to 100%
  Future<void> maximizeVolume() async {
    try {
      _originalVolume ??= await _getDeviceVolume();
      await _setDeviceVolume(1.0);
    } catch (e) {
      debugPrint('Error setting volume to max: $e');
    }
  }

  /// Restores volume to the original level before the alarm started
  Future<void> restoreVolume() async {
    try {
      if (_originalVolume != null) {
        await _setDeviceVolume(_originalVolume!);
        _originalVolume = null;
      }
    } catch (e) {
      debugPrint('Error restoring volume: $e');
    }
  }

  Future<double> _getDeviceVolume() async {
    try {
      final double? vol = await _volumeChannel.invokeMethod<double>('getVolume');
      return vol ?? 1.0;
    } catch (e) {
      debugPrint('Error getting volume via method channel: $e');
      return 1.0;
    }
  }

  Future<void> _setDeviceVolume(double volume) async {
    try {
      await _volumeChannel.invokeMethod('setVolume', {'volume': volume});
    } catch (e) {
      debugPrint('Error setting volume via method channel: $e');
    }
  }

  /// Sets the in-app audio player volume (0.0 to 1.0)
  Future<void> setPlayerVolume(double volume) async {
    try {
      await _player.setVolume(volume);
    } catch (e) {
      debugPrint('Error setting player volume: $e');
    }
  }

  /// Dips alarm music to 15% so spoken TTS name is crisp and audible for the elderly
  Future<void> duckVolume() async {
    await setPlayerVolume(0.15);
  }

  /// Raises alarm music back to 100% after speech finishes
  Future<void> unduckVolume() async {
    await setPlayerVolume(1.0);
  }

  Future<void> startAlarmSound({bool useCustomSound = true, double initialVolume = 1.0}) async {
    if (_isPlaying) return;

    try {
      await maximizeVolume();

      await _player.setVolume(initialVolume);
      await _player.play(
        AssetSource(AppConstants.customAlarmSoundAsset.replaceFirst('assets/', '')),
        mode: PlayerMode.mediaPlayer,
      );
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
    }
  }

  Future<void> stopAlarmSound() async {
    try {
      if (_isPlaying) {
        await _player.stop();
        _isPlaying = false;
      }
      await restoreVolume();
    } catch (e) {
      debugPrint('Error stopping alarm sound: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
