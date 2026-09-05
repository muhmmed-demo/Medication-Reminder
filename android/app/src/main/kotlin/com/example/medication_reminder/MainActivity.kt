package com.example.medication_reminder

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.medication_reminder/volume"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (audioManager == null) {
                result.success(1.0)
                return@setMethodCallHandler
            }

            when (call.method) {
                "getVolume" -> {
                    try {
                        val current = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
                        val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                        result.success(if (max > 0) current.toDouble() / max.toDouble() else 1.0)
                    } catch (e: Exception) {
                        result.success(1.0)
                    }
                }
                "setVolume" -> {
                    try {
                        val volume = call.argument<Double>("volume") ?: 1.0
                        val maxAlarm = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                        val targetAlarm = (volume * maxAlarm).toInt().coerceIn(0, maxAlarm)
                        audioManager.setStreamVolume(AudioManager.STREAM_ALARM, targetAlarm, 0)

                        val maxMusic = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        val targetMusic = (volume * maxMusic).toInt().coerceIn(0, maxMusic)
                        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, targetMusic, 0)

                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
