import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';

class AlarmAudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

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

  Future<void> startAlarmSound({bool useCustomSound = true}) async {
    if (_isPlaying) return;

    try {
      if (useCustomSound) {
        // Play bundled alarm sound in a continuous loop
        await _player.play(
          AssetSource(AppConstants.customAlarmSoundAsset.replaceFirst('assets/', '')),
          mode: PlayerMode.mediaPlayer,
        );
      } else {
        // Play sound
        await _player.play(
          AssetSource(AppConstants.customAlarmSoundAsset.replaceFirst('assets/', '')),
          mode: PlayerMode.mediaPlayer,
        );
      }
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
    }
  }

  Future<void> stopAlarmSound() async {
    if (!_isPlaying) return;
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error stopping alarm sound: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
