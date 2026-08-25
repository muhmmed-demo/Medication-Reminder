import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/medications_table.dart';
import '../tables/dose_schedules_table.dart';

part 'medication_dao.g.dart';

@DriftAccessor(tables: [MedicationsTable, DoseSchedulesTable])
class MedicationDao extends DatabaseAccessor<AppDatabase> with _$MedicationDaoMixin {
  MedicationDao(super.db);

  Future<List<MedicationData>> getAllMedications() => select(medicationsTable).get();

  Stream<List<MedicationData>> watchAllMedications() => select(medicationsTable).watch();

  Future<MedicationData?> getMedicationById(int id) =>
      (select(medicationsTable)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<int> insertMedication(MedicationsTableCompanion medication) =>
      into(medicationsTable).insert(medication);

  Future<bool> updateMedication(MedicationsTableCompanion medication) =>
      update(medicationsTable).replace(medication);

  Future<int> deleteMedication(int id) =>
      (delete(medicationsTable)..where((tbl) => tbl.id.equals(id))).go();
}
