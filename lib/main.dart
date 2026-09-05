import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'services/notification_service.dart';
import 'services/alarm_audio_service.dart';
import 'services/permission_service.dart';
import 'services/alarm_scheduler_service.dart';
import 'domain/usecases/mark_dose_taken_usecase.dart';
import 'domain/usecases/snooze_dose_usecase.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Timezones for accurate zoned alarms
  tz.initializeTimeZones();
  try {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
  } catch (e) {
    debugPrint('Could not configure local timezone: $e');
  }

  // 2. Initialize Dependency Injection Container
  await initDependencies();

  // 3. Initialize Services
  final notificationService = sl<NotificationService>();
  final alarmAudioService = sl<AlarmAudioService>();
  final permissionService = sl<PermissionService>();
  final alarmSchedulerService = sl<AlarmSchedulerService>();

  await alarmAudioService.initialize();

  await notificationService.initialize(
    onNotificationTapped: (payload) async {
      final actionId = payload['actionId'] as String?;
      if (actionId == 'action_take') {
        final doseScheduleId = payload['doseScheduleId'] as int?;
        final scheduledStr = payload['scheduledDateTime'] as String?;
        if (doseScheduleId != null && scheduledStr != null) {
          final scheduledDate = DateTime.tryParse(scheduledStr) ?? DateTime.now();
          await sl<MarkDoseTakenUseCase>()(
            doseScheduleId: doseScheduleId,
            scheduledDateTime: scheduledDate,
          );
          final rawExtras = payload['extraMedications'];
          if (rawExtras is List) {
            for (final extra in rawExtras) {
              final extraScheduleId = (extra as Map)['doseScheduleId'] as int?;
              if (extraScheduleId != null) {
                await sl<MarkDoseTakenUseCase>()(
                  doseScheduleId: extraScheduleId,
                  scheduledDateTime: scheduledDate,
                );
              }
            }
          }
          await notificationService.cancelAlarm(doseScheduleId);
          await alarmSchedulerService.scheduleAllActiveAlarms();
          return;
        }
      } else if (actionId == 'action_snooze') {
        final doseScheduleId = payload['doseScheduleId'] as int?;
        final scheduledStr = payload['scheduledDateTime'] as String?;
        final snoozeCount = (payload['snoozeCount'] as int? ?? 0) + 1;
        if (doseScheduleId != null && scheduledStr != null) {
          final scheduledDate = DateTime.tryParse(scheduledStr) ?? DateTime.now();
          await sl<SnoozeDoseUseCase>()(
            doseScheduleId: doseScheduleId,
            scheduledDateTime: scheduledDate,
            newSnoozeCount: snoozeCount,
          );
          await notificationService.cancelAlarm(doseScheduleId);
          final nextTime = DateTime.now().add(const Duration(minutes: 10));
          await notificationService.scheduleAlarm(
            id: doseScheduleId,
            medicationName: payload['medicationName'] as String? ?? '',
            dosageDescription: payload['dosageDescription'] as String? ?? '',
            scheduledDateTime: nextTime,
            medicationId: payload['medicationId'] as int? ?? 0,
            doseScheduleId: doseScheduleId,
            snoozeCount: snoozeCount,
            imagePath: payload['imagePath'] as String?,
          );
          return;
        }
      }

      // Default: Navigate directly to Alarm ringing screen when notification or full-screen intent triggers
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
