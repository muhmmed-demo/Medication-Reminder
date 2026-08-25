import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/dose_logs_table.dart';

part 'dose_log_dao.g.dart';

@DriftAccessor(tables: [DoseLogsTable])
class DoseLogDao extends DatabaseAccessor<AppDatabase> with _$DoseLogDaoMixin {
  DoseLogDao(super.db);

  Future<List<DoseLogData>> getAllDoseLogs() =>
      (select(doseLogsTable)..orderBy([(tbl) => OrderingTerm.desc(tbl.scheduledDateTime)])).get();

  Stream<List<DoseLogData>> watchAllDoseLogs() =>
      (select(doseLogsTable)..orderBy([(tbl) => OrderingTerm.desc(tbl.scheduledDateTime)])).watch();

  Future<List<DoseLogData>> getLogsForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return (select(doseLogsTable)
          ..where((tbl) =>
              tbl.scheduledDateTime.isBiggerOrEqualValue(startOfDay) &
              tbl.scheduledDateTime.isSmallerOrEqualValue(endOfDay))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.scheduledDateTime)]))
        .get();
  }

  Future<DoseLogData?> getLatestLogForSchedule(int scheduleId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return (select(doseLogsTable)
          ..where((tbl) =>
              tbl.doseScheduleId.equals(scheduleId) &
              tbl.scheduledDateTime.isBiggerOrEqualValue(startOfDay) &
              tbl.scheduledDateTime.isSmallerOrEqualValue(endOfDay))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insertDoseLog(DoseLogsTableCompanion log) =>
      into(doseLogsTable).insert(log);

  Future<bool> updateDoseLog(DoseLogsTableCompanion log) =>
      update(doseLogsTable).replace(log);
}
