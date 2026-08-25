import 'package:drift/drift.dart';
import '../../domain/entities/dose_log.dart';
import '../../domain/enums/dose_status.dart';
import '../../domain/repositories/dose_log_repository.dart';
import '../local/database/app_database.dart';
import '../models/dose_log_model.dart';

class DoseLogRepositoryImpl implements DoseLogRepository {
  final AppDatabase database;

  DoseLogRepositoryImpl(this.database);

  @override
  Future<List<DoseLog>> getAllDoseLogs() async {
    final list = await database.doseLogDao.getAllDoseLogs();
    return list.map(DoseLogModel.fromData).toList();
  }

  @override
  Stream<List<DoseLog>> watchAllDoseLogs() {
    return database.doseLogDao
        .watchAllDoseLogs()
        .map((list) => list.map(DoseLogModel.fromData).toList());
  }

  @override
  Future<List<DoseLog>> getLogsForDate(DateTime date) async {
    final list = await database.doseLogDao.getLogsForDate(date);
    return list.map(DoseLogModel.fromData).toList();
  }

  @override
  Future<int> insertDoseLog(DoseLog log) async {
    return await database.doseLogDao.insertDoseLog(
      DoseLogModel.toCompanion(log),
    );
  }

  @override
  Future<bool> updateDoseLogStatus(
    int logId,
    DoseStatus status,
    DateTime? actualTime,
    int snoozeCount,
  ) async {
    return await database.doseLogDao.updateDoseLog(
      DoseLogsTableCompanion(
        id: Value(logId),
        status: Value(status.name),
        actualDateTime: Value(actualTime),
        snoozeCount: Value(snoozeCount),
      ),
    );
  }

  @override
  Future<DoseLog?> getLatestLogForSchedule(int scheduleId, DateTime date) async {
    final data = await database.doseLogDao.getLatestLogForSchedule(scheduleId, date);
    return data != null ? DoseLogModel.fromData(data) : null;
  }
}
