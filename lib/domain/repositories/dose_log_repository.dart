import '../entities/dose_log.dart';
import '../enums/dose_status.dart';

abstract class DoseLogRepository {
  Future<List<DoseLog>> getAllDoseLogs();
  Stream<List<DoseLog>> watchAllDoseLogs();
  Future<List<DoseLog>> getLogsForDate(DateTime date);
  Future<int> insertDoseLog(DoseLog log);
  Future<bool> updateDoseLogStatus(int logId, DoseStatus status, DateTime? actualTime, int snoozeCount);
  Future<DoseLog?> getLatestLogForSchedule(int scheduleId, DateTime date);
}
