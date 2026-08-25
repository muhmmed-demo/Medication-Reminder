import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/constants/app_constants.dart';
import '../core/constants/notification_constants.dart';

typedef NotificationCallback = void Function(Map<String, dynamic> payload);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationCallback? onAlarmTriggered;

  Future<void> initialize({NotificationCallback? onNotificationTapped}) async {
    onAlarmTriggered = onNotificationTapped;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            onAlarmTriggered?.call(data);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      NotificationConstants.alarmChannelId,
      NotificationConstants.alarmChannelName,
      description: NotificationConstants.alarmChannelDescription,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(AppConstants.customAlarmSoundAndroidRaw),
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
      NotificationConstants.systemSoundChannelId,
      NotificationConstants.systemSoundChannelName,
      description: NotificationConstants.systemSoundChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(alarmChannel);
      await androidImplementation.createNotificationChannel(systemChannel);
    }
  }

  Future<void> scheduleAlarm({
    required int id,
    required String medicationName,
    required String dosageDescription,
    required DateTime scheduledDateTime,
    required int medicationId,
    required int doseScheduleId,
    int snoozeCount = 0,
    bool useCustomSound = true,
  }) async {
    final channelId = useCustomSound
        ? NotificationConstants.alarmChannelId
        : NotificationConstants.systemSoundChannelId;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      useCustomSound
          ? NotificationConstants.alarmChannelName
          : NotificationConstants.systemSoundChannelName,
      channelDescription: NotificationConstants.alarmChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      sound: useCustomSound
          ? const RawResourceAndroidNotificationSound(AppConstants.customAlarmSoundAndroidRaw)
          : null,
      enableVibration: true,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'action_take',
          'تم أخذ الجرعة ✅',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'action_snooze',
          'تأجيل 10 دقائق ⏰',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    final NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    final payloadMap = {
      'medicationId': medicationId,
      'doseScheduleId': doseScheduleId,
      'medicationName': medicationName,
      'dosageDescription': dosageDescription,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'snoozeCount': snoozeCount,
      'useCustomSound': useCustomSound,
    };

    final tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      '⏰ حان موعد علاجك!',
      '$medicationName - $dosageDescription',
      tzDateTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode(payloadMap),
    );
  }

  Future<void> cancelAlarm(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllAlarms() async {
    await _notificationsPlugin.cancelAll();
  }
}
