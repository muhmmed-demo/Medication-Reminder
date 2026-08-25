import '../entities/dose_log.dart';
import '../enums/dose_status.dart';
import '../repositories/dose_log_repository.dart';

class SnoozeDoseUseCase {
  final DoseLogRepository repository;

  SnoozeDoseUseCase(this.repository);

  Future<void> call({
    required int doseScheduleId,
    required DateTime scheduledDateTime,
    int? logId,
    required int newSnoozeCount,
  }) async {
    final now = DateTime.now();
    if (logId != null) {
      await repository.updateDoseLogStatus(logId, DoseStatus.snoozed, null, newSnoozeCount);
    } else {
      await repository.insertDoseLog(
        DoseLog(
          doseScheduleId: doseScheduleId,
          scheduledDateTime: scheduledDateTime,
          actualDateTime: null,
          status: DoseStatus.snoozed,
          snoozeCount: newSnoozeCount,
          createdAt: now,
        ),
      );
    }
  }
}
