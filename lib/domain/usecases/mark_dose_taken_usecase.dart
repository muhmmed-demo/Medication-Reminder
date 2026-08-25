import '../entities/dose_log.dart';
import '../enums/dose_status.dart';
import '../repositories/dose_log_repository.dart';

class MarkDoseTakenUseCase {
  final DoseLogRepository repository;

  MarkDoseTakenUseCase(this.repository);

  Future<void> call({
    required int doseScheduleId,
    required DateTime scheduledDateTime,
    int? logId,
    int snoozeCount = 0,
  }) async {
    final now = DateTime.now();
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
  }
}
