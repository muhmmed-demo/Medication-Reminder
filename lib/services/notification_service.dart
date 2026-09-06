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
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            if (response.actionId != null) {
              data['actionId'] = response.actionId;
            }
            onAlarmTriggered?.call(data);
          } catch (e) {
            debugPrint('Error parsing notification payload: $e');
          }
        }
      },
    );

    await _createNotificationChannels();
  }

  // BUGFIX: إزالة requestExactAlarmsPermission() من هنا — تتم إدارة الأذونات
  // بشكل مركزي في PermissionService فقط لتجنب التعارض والطلب المزدوج
  Future<bool?> requestPermissions() async {
    final android = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final notif = await android.requestNotificationsPermission();
      return notif;
    }
    return true;
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
    String? imagePath,
    DateTimeComponents? matchDateTimeComponents,
    List<Map<String, dynamic>>? extraMedications,
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
      icon: 'ic_notification',
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_take',
          'تم الأخذ ✅',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_snooze',
          'تأجيل 10د ⏰',
          showsUserInterface: true,
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
      'imagePath': imagePath,
      'extraMedications': extraMedications,
    };

    final notifTitle = extraMedications != null && extraMedications.isNotEmpty
        ? '⏰ حان موعد أدويتك (${extraMedications.length + 1} أدوية)'
        : '⏰ حان موعد علاجك!';
    final notifBody = extraMedications != null && extraMedications.isNotEmpty
        ? '$medicationName + ${extraMedications.map((m) => m['medicationName']).join(' + ')}'
        : '$medicationName - $dosageDescription';

    var tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);
    final tzNow = tz.TZDateTime.now(tz.local);

    // BUGFIX: سجّل الوقت المجدول للتشخيص
    debugPrint(
      '📅 scheduleAlarm: id=$id | scheduled=${tzDateTime.toIso8601String()} | now=${tzNow.toIso8601String()} | tz=${tz.local.name}',
    );

    // BUGFIX: إذا كان الوقت في الماضي، هذا خطأ في الحساب — لا نُجدوله بعد 5 ثوانٍ
    // (السلوك السابق كان يُرنّ المنبه في وقت غير متوقع)
    // نتجاهل الجدولة ونُسجّل تحذيراً واضحاً
    if (tzDateTime.isBefore(tzNow)) {
      debugPrint(
        '⚠️ scheduleAlarm SKIPPED: computed time is in the past. '
        'Check timezone config. id=$id, scheduled=$scheduledDateTime',
      );
      return;
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        notifTitle,
        notifBody,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: jsonEncode(payloadMap),
      );
      debugPrint('✅ Alarm scheduled successfully: id=$id at ${tzDateTime.toIso8601String()}');
    } catch (e) {
      debugPrint('❌ Failed to schedule exact alarm: $e');
      // Fallback: نُحاول مرة أخيرة بـ inexact ولكن نُسجّل التحذير
      debugPrint('⚠️ Falling back to inexact alarm for id=$id — alarm may not ring precisely.');
      await _notificationsPlugin.zonedSchedule(
        id,
        notifTitle,
        notifBody,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: jsonEncode(payloadMap),
      );
    }
  }

  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      NotificationConstants.alarmChannelId,
      NotificationConstants.alarmChannelName,
      channelDescription: NotificationConstants.alarmChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      99999,
      '🔔 تجربة المنبه بنجاح!',
      'نظام الإشعارات يعمل بكفاءة على جهازك والمنبهات جاهزة للعمل.',
      notificationDetails,
    );
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
      icon: 'ic_notification',
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
