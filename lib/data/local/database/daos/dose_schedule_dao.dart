import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/dose_schedules_table.dart';

part 'dose_schedule_dao.g.dart';

@DriftAccessor(tables: [DoseSchedulesTable])
class DoseScheduleDao extends DatabaseAccessor<AppDatabase> with _$DoseScheduleDaoMixin {
  DoseScheduleDao(super.db);

  Future<List<DoseScheduleData>> getSchedulesForMedication(int medicationId) =>
      (select(doseSchedulesTable)..where((tbl) => tbl.medicationId.equals(medicationId))).get();

  Future<List<DoseScheduleData>> getAllActiveSchedules() =>
      (select(doseSchedulesTable)..where((tbl) => tbl.isActive.equals(true))).get();

  Stream<List<DoseScheduleData>> watchAllActiveSchedules() =>
      (select(doseSchedulesTable)..where((tbl) => tbl.isActive.equals(true))).watch();

  Future<DoseScheduleData?> getScheduleById(int id) =>
      (select(doseSchedulesTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<int> insertSchedule(DoseSchedulesTableCompanion schedule) =>
      into(doseSchedulesTable).insert(schedule);

  Future<void> insertSchedules(List<DoseSchedulesTableCompanion> schedules) async {
    await batch((b) {
      b.insertAll(doseSchedulesTable, schedules);
    });
  }

  Future<bool> updateSchedule(DoseSchedulesTableCompanion schedule) =>
      update(doseSchedulesTable).replace(schedule);

  Future<int> deleteSchedulesForMedication(int medicationId) =>
      (delete(doseSchedulesTable)..where((tbl) => tbl.medicationId.equals(medicationId))).go();
}
