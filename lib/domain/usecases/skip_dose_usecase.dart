import '../entities/dose_log.dart';
import '../enums/dose_status.dart';
import '../repositories/dose_log_repository.dart';

class SkipDoseUseCase {
  final DoseLogRepository repository;

  SkipDoseUseCase(this.repository);

  Future<void> call({
    required int doseScheduleId,
    required DateTime scheduledDateTime,
    int? logId,
    int snoozeCount = 0,
  }) async {
    final now = DateTime.now();
    if (logId != null) {
      await repository.updateDoseLogStatus(logId, DoseStatus.missed, now, snoozeCount);
    } else {
      final existingLog =
          await repository.getLatestLogForSchedule(doseScheduleId, scheduledDateTime);
      if (existingLog != null && existingLog.id != null) {
        await repository.updateDoseLogStatus(
            existingLog.id!, DoseStatus.missed, now, snoozeCount);
      } else {
        await repository.insertDoseLog(
          DoseLog(
            doseScheduleId: doseScheduleId,
            scheduledDateTime: scheduledDateTime,
            actualDateTime: now,
            status: DoseStatus.missed,
            snoozeCount: snoozeCount,
            createdAt: now,
          ),
        );
      }
    }
  }
}
