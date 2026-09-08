import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final String? initialAudioPath;
  final Function(String?) onAudioSaved;

  const VoiceRecorderWidget({
    Key? key,
    this.initialAudioPath,
    required this.onAudioSaved,
  }) : super(key: key);

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;
  
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    _audioPath = widget.initialAudioPath;

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/custom_alarm_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: filePath);
        setState(() {
          _isRecording = true;
          _audioPath = null;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الرجاء السماح بصلاحية الميكروفون')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
      widget.onAudioSaved(_audioPath);
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
  }

  Future<void> _playAudio() async {
    if (_audioPath != null) {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() => _isPlaying = false);
  }

  void _deleteAudio() {
    setState(() {
      _audioPath = null;
      _isPlaying = false;
    });
    widget.onAudioSaved(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isRecording ? Colors.red.shade50 : theme.colorScheme.surfaceVariant.withAlpha(60),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isRecording ? Colors.red.shade200 : Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            'التنبيه بصوت مألوف يساعد كبار السن على التذكر وعدم القلق من صوت المنبه',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          
          if (_audioPath != null) ...[
            // Has Audio File
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlaying ? Colors.orange : theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  label: Text(_isPlaying ? 'إيقاف الاستماع' : 'استماع للتسجيل'),
                  onPressed: _isPlaying ? _stopAudio : _playAudio,
                ),
                const SizedBox(width: 8),
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.red.shade50),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: _deleteAudio,
                  tooltip: 'مسح التسجيل',
                ),
              ],
            )
          ] else ...[
            // Recording logic
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(_isRecording ? 24 : 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : theme.colorScheme.primary,
                  boxShadow: _isRecording
                      ? [BoxShadow(color: Colors.red.withAlpha(100), blurRadius: 15, spreadRadius: 5)]
                      : [],
                ),
                child: Icon(
                  _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRecording ? 'جاري التسجيل... ارفع إصبعك للإيقاف' : 'اضغط مطولاً لتسجيل صوتك',
              style: TextStyle(
                color: _isRecording ? Colors.red : theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
