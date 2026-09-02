import 'package:flutter/foundation.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/dose_schedule.dart';
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
      final activeSchedules = await medicationRepository.getAllActiveSchedules();
      final medications = await medicationRepository.getAllMedications();
      final medMap = {for (var m in medications) m.id: m};

      final now = DateTime.now();

      for (final schedule in activeSchedules) {
        final med = medMap[schedule.medicationId];
        if (med == null || !med.isActive) continue;

        // Check if medication period ended
        if (med.endDate != null && med.endDate!.isBefore(now)) continue;

        final nextDoseTime = _calculateNextDoseDateTime(schedule, now);

        // Deterministic unique ID for notification
        final notificationId = schedule.id ?? (schedule.medicationId * 100 + schedule.hour * 10 + schedule.minute);

        await notificationService.scheduleAlarm(
          id: notificationId,
          medicationName: med.name,
          dosageDescription: med.dosageDescription,
          scheduledDateTime: nextDoseTime,
          medicationId: med.id ?? 0,
          doseScheduleId: schedule.id ?? 0,
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

    // If time has passed today, start checking from tomorrow
    if (candidate.isBefore(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    // Handle repeat logic
    if (schedule.repeatType == RepeatType.specificDays && schedule.repeatDays != null && schedule.repeatDays!.isNotEmpty) {
      // Find the next available day in the repeatDays list
      // repeatDays contains integers 1-7 (Monday=1, Sunday=7)
      while (!schedule.repeatDays!.contains(candidate.weekday)) {
        candidate = candidate.add(const Duration(days: 1));
      }
    } else if (schedule.repeatType == RepeatType.custom && schedule.cycleOnDays != null && schedule.cycleOffDays != null) {
      // Basic cycle logic: this requires tracking the cycle start date (Phase 1)
      // For now, if custom but not specificDays, we just do daily.
      // Full cycle logic will be implemented when UI is ready.
    }

    return candidate;
  }
}
