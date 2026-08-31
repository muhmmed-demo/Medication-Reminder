import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'services/notification_service.dart';
import 'services/alarm_audio_service.dart';
import 'services/permission_service.dart';
import 'services/alarm_scheduler_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Timezones for accurate zoned alarms
  tz.initializeTimeZones();

  // 2. Initialize Dependency Injection Container
  await initDependencies();

  // 3. Initialize Services
  final notificationService = sl<NotificationService>();
  final alarmAudioService = sl<AlarmAudioService>();
  final permissionService = sl<PermissionService>();
  final alarmSchedulerService = sl<AlarmSchedulerService>();

  await alarmAudioService.initialize();

  await notificationService.initialize(
    onNotificationTapped: (payload) {
      // Navigate directly to Alarm ringing screen when notification or full-screen intent triggers
      rootNavigatorKey.currentState?.pushNamed(
        AppRouter.alarm,
        arguments: payload,
      );
    },
  );

  // Permissions will be requested in the home screen after UI loads

  // 5. Ensure all active medication alarms are scheduled with AlarmManager
  await alarmSchedulerService.scheduleAllActiveAlarms();

  String initialRoute = AppRouter.home;
  Object? initialArguments;

  // 6. Check if app was launched via alarm notification
  final launchDetails = await notificationService.getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp ?? false) {
    if (launchDetails?.notificationResponse?.payload != null) {
      try {
        initialRoute = AppRouter.alarm;
        initialArguments = jsonDecode(launchDetails!.notificationResponse!.payload!);
      } catch (e) {
        debugPrint('Failed to parse launch payload: $e');
      }
    }
  }

  runApp(MedicationApp(
    initialRoute: initialRoute,
    initialArguments: initialArguments,
  ));
}
