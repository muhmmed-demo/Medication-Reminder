import '../entities/dose_log.dart';
import '../entities/dose_schedule.dart';
import '../enums/dose_status.dart';
import '../enums/repeat_type.dart';
import '../repositories/dose_log_repository.dart';
import '../repositories/medication_repository.dart';

class RecordPrnDoseUseCase {
  final DoseLogRepository doseLogRepository;
  final MedicationRepository medicationRepository;

  RecordPrnDoseUseCase({
    required this.doseLogRepository,
    required this.medicationRepository,
  });

  Future<void> call({required int medicationId}) async {
    final now = DateTime.now();
    final med = await medicationRepository.getMedicationById(medicationId);
    if (med == null) return;

    // Get any schedule for this medication, or create a placeholder schedule
    final schedules = await medicationRepository.getSchedulesForMedication(medicationId);
    int scheduleId;
    if (schedules.isNotEmpty && schedules.first.id != null) {
      scheduleId = schedules.first.id!;
    } else {
      scheduleId = await medicationRepository.insertSchedule(
        DoseSchedule(
          medicationId: medicationId,
          scheduledTime: 'عند اللزوم',
          repeatType: RepeatType.daily,
          isActive: false,
        ),
      );
    }

    await doseLogRepository.insertDoseLog(
      DoseLog(
        doseScheduleId: scheduleId,
        scheduledDateTime: now,
        actualDateTime: now,
        status: DoseStatus.taken,
        snoozeCount: 0,
        createdAt: now,
      ),
    );

    // Decrement inventory if tracked
    if (med.inventoryCount != null) {
      final newInventory = med.inventoryCount! - 1;
      await medicationRepository.updateMedication(
        med.copyWith(inventoryCount: newInventory < 0 ? 0 : newInventory),
      );
    }
  }
}
