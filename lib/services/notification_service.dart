import 'dart:convert';
import 'dart:typed_data';
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

  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async {
    return await _notificationsPlugin.getNotificationAppLaunchDetails();
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      NotificationConstants.alarmChannelId,
      NotificationConstants.alarmChannelName,
      description: NotificationConstants.alarmChannelDescription,
      importance: Importance.max,
      playSound: true,
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
      enableVibration: true,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
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

    final utcTime = scheduledDateTime.toUtc();
    final tzDateTime = tz.TZDateTime.utc(
      utcTime.year,
      utcTime.month,
      utcTime.day,
      utcTime.hour,
      utcTime.minute,
      utcTime.second,
    );

    try {
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
    } catch (e) {
      debugPrint('Failed to schedule exact alarm (Permission revoked?): $e');
      // Fallback to inexact alarm if exact alarms are heavily restricted by OS
      await _notificationsPlugin.zonedSchedule(
        id,
        '⏰ حان موعد علاجك!',
        '$medicationName - $dosageDescription',
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode(payloadMap),
      );
    }
  }

  Future<void> showWarningNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      NotificationConstants.systemSoundChannelId,
      NotificationConstants.systemSoundChannelName,
      channelDescription: NotificationConstants.systemSoundChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> cancelAlarm(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllAlarms() async {
    await _notificationsPlugin.cancelAll();
  }
}
