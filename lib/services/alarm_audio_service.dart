import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';
import '../core/constants/app_constants.dart';

class AlarmAudioService {
  final AudioPlayer _player = AudioPlayer();
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
      PerfectVolumeControl.hideUI = true;
      _originalVolume ??= await PerfectVolumeControl.getVolume();
      await PerfectVolumeControl.setVolume(1.0);
    } catch (e) {
      debugPrint('Error setting volume to max: $e');
    }
  }

  /// Restores volume to the original level before the alarm started
  Future<void> restoreVolume() async {
    try {
      if (_originalVolume != null) {
        await PerfectVolumeControl.setVolume(_originalVolume!);
        _originalVolume = null;
      }
    } catch (e) {
      debugPrint('Error restoring volume: $e');
    }
  }

  Future<void> startAlarmSound({bool useCustomSound = true}) async {
    if (_isPlaying) return;

    try {
      await maximizeVolume();

      // Play bundled alarm sound in a continuous loop
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
