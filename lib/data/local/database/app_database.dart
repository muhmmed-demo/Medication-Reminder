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
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'medication_reminder_db',
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
    );
  }
}
