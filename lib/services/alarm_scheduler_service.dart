import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/dose_schedule.dart';
import '../../domain/enums/repeat_type.dart';
import '../../domain/repositories/medication_repository.dart';
import 'notification_service.dart';

class AlarmSchedulerService {
  final MedicationRepository medicationRepository;
  final NotificationService notificationService;

  AlarmSchedulerService({
    required this.medicationRepository,
    required this.notificationService,
  });

  Future<void> scheduleAllActiveAlarms() async {
    try {
      // 1. Cancel existing alarms so deleted or inactive medication alarms do not persist
      await notificationService.cancelAllAlarms();

      final activeSchedules = await medicationRepository.getAllActiveSchedules();
      final medications = await medicationRepository.getAllMedications();
      final medMap = {for (var m in medications) m.id: m};

      final now = DateTime.now();

      // Group active doses that fall on the exact same DateTime to avoid notification collision
      // Map key: "YYYY-MM-DD HH:MM"
      final Map<String, List<Map<String, dynamic>>> timeGroups = {};

      for (final schedule in activeSchedules) {
        final med = medMap[schedule.medicationId];
        if (med == null || !med.isActive) continue;

        // Check if medication period ended (inclusive until end of day 23:59:59)
        DateTime? endOfDay;
        if (med.endDate != null) {
          endOfDay = DateTime(
            med.endDate!.year,
            med.endDate!.month,
            med.endDate!.day,
            23,
            59,
            59,
          );
          if (endOfDay.isBefore(now)) continue;
        }

        final nextDoseTime = _calculateNextDoseDateTime(schedule, now);

        // Do not schedule if next dose falls after the medication end date
        if (endOfDay != null && nextDoseTime.isAfter(endOfDay)) continue;

        final timeKey =
            '${nextDoseTime.year}-${nextDoseTime.month.toString().padLeft(2, '0')}-${nextDoseTime.day.toString().padLeft(2, '0')} ${nextDoseTime.hour.toString().padLeft(2, '0')}:${nextDoseTime.minute.toString().padLeft(2, '0')}';

        timeGroups.putIfAbsent(timeKey, () => []).add({
          'schedule': schedule,
          'medication': med,
          'doseTime': nextDoseTime,
        });
      }

      // Schedule each group (unified alarm if multiple medications share the exact same time)
      for (final group in timeGroups.values) {
        if (group.isEmpty) continue;

        final primary = group.first;
        final primarySchedule = primary['schedule'] as DoseSchedule;
        final primaryMed = primary['medication'] as Medication;
        final doseTime = primary['doseTime'] as DateTime;

        final extraMedications = group.skip(1).map((item) {
          final s = item['schedule'] as DoseSchedule;
          final m = item['medication'] as Medication;
          return {
            'medicationId': m.id ?? 0,
            'doseScheduleId': s.id ?? 0,
            'medicationName': m.name,
            'dosageDescription': m.dosageDescription,
            'imagePath': m.imagePath,
          };
        }).toList();

        // Determine repeating components so alarms survive missed days without app opening
        DateTimeComponents? matchComponents;
        if (primarySchedule.repeatType == RepeatType.daily) {
          matchComponents = DateTimeComponents.time;
        } else if (primarySchedule.repeatType == RepeatType.specificDays) {
          matchComponents = DateTimeComponents.dayOfWeekAndTime;
        }

        final notificationId = primarySchedule.id ??
            (primarySchedule.medicationId * 100 +
                primarySchedule.hour * 10 +
                primarySchedule.minute);

        await notificationService.scheduleAlarm(
          id: notificationId,
          medicationName: primaryMed.name,
          dosageDescription: primaryMed.dosageDescription,
          scheduledDateTime: doseTime,
          medicationId: primaryMed.id ?? 0,
          doseScheduleId: primarySchedule.id ?? 0,
          imagePath: primaryMed.imagePath,
          matchDateTimeComponents: matchComponents,
          extraMedications: extraMedications.isNotEmpty ? extraMedications : null,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling all active alarms: $e');
    }
  }

  DateTime _calculateNextDoseDateTime(DoseSchedule schedule, DateTime now) {
    var candidate = DateTime(
      now.year,
      now.month,
      now.day,
      schedule.hour,
      schedule.minute,
      0,
    );

    // If time has passed today, advance to the next calendar day preserving exact hour and minute (DST Safe)
    if (candidate.isBefore(now)) {
      candidate = DateTime(
        candidate.year,
        candidate.month,
        candidate.day + 1,
        schedule.hour,
        schedule.minute,
        0,
      );
    }

    // Handle repeat logic
    if (schedule.repeatType == RepeatType.specificDays &&
        schedule.repeatDays != null &&
        schedule.repeatDays!.isNotEmpty) {
      // Advance day by day until a matching weekday is found (DST Safe)
      while (!schedule.repeatDays!.contains(candidate.weekday)) {
        candidate = DateTime(
          candidate.year,
          candidate.month,
          candidate.day + 1,
          schedule.hour,
          schedule.minute,
          0,
        );
      }
    }

    return candidate;
  }
}
