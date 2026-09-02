import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/medications_table.dart';
import 'tables/dose_schedules_table.dart';
import 'tables/dose_logs_table.dart';
import 'daos/medication_dao.dart';
import 'daos/dose_schedule_dao.dart';
import 'daos/dose_log_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    MedicationsTable,
    DoseSchedulesTable,
    DoseLogsTable,
  ],
  daos: [
    MedicationDao,
    DoseScheduleDao,
    DoseLogDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Add columns introduced in Phase 1
            await m.addColumn(medicationsTable, medicationsTable.inventoryCount);
            await m.addColumn(medicationsTable, medicationsTable.refillThreshold);
            await m.addColumn(medicationsTable, medicationsTable.isPRN);
            await m.addColumn(medicationsTable, medicationsTable.minHoursBetweenDoses);
            await m.addColumn(medicationsTable, medicationsTable.mealTiming);
            await m.addColumn(medicationsTable, medicationsTable.imagePath);
            await m.addColumn(medicationsTable, medicationsTable.customSoundPath);
            await m.addColumn(doseSchedulesTable, doseSchedulesTable.cycleOnDays);
            await m.addColumn(doseSchedulesTable, doseSchedulesTable.cycleOffDays);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'medication_reminder_db',
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
    );
  }
}
