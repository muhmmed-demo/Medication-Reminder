import '../entities/dose_log.dart';
import '../enums/dose_status.dart';
import '../repositories/dose_log_repository.dart';

import '../repositories/medication_repository.dart';
import '../../services/notification_service.dart';

class MarkDoseTakenUseCase {
  final DoseLogRepository repository;
  final MedicationRepository medicationRepository;
  final NotificationService notificationService;

  MarkDoseTakenUseCase({
    required this.repository,
    required this.medicationRepository,
    required this.notificationService,
  });

  Future<void> call({
    required int doseScheduleId,
    required DateTime scheduledDateTime,
    int? logId,
    int snoozeCount = 0,
  }) async {
    final now = DateTime.now();
    
    // 1. Log the dose
    if (logId != null) {
      await repository.updateDoseLogStatus(logId, DoseStatus.taken, now, snoozeCount);
    } else {
      await repository.insertDoseLog(
        DoseLog(
          doseScheduleId: doseScheduleId,
          scheduledDateTime: scheduledDateTime,
          actualDateTime: now,
          status: DoseStatus.taken,
          snoozeCount: snoozeCount,
          createdAt: now,
        ),
      );
    }

    // 2. Handle Inventory Deduction (Phase 1 logic)
    final schedule = await medicationRepository.getScheduleById(doseScheduleId);
    if (schedule != null) {
      final medication = await medicationRepository.getMedicationById(schedule.medicationId);
      if (medication != null && medication.inventoryCount != null) {
        final newInventory = medication.inventoryCount! - 1;
        
        // Update medication in DB
        await medicationRepository.updateMedication(
          medication.copyWith(inventoryCount: newInventory < 0 ? 0 : newInventory),
        );

        // Check if we hit the refill threshold
        final threshold = medication.refillThreshold ?? 3; // Default to 3 if not set but inventory is tracked
        if (newInventory == threshold || newInventory == 0) {
          await notificationService.showWarningNotification(
            id: medication.id! * 1000, // Unique ID for inventory warnings
            title: '⚠️ تنبيه انخفاض الدواء',
            body: newInventory == 0 
                ? 'لقد نفد دواء "${medication.name}" تماماً! يرجى شراء علبة جديدة فوراً.'
                : 'دواء "${medication.name}" أوشك على النفاد. المتبقي $newInventory حبة فقط.',
          );
        }
      }
    }
  }
}
