import 'package:drift/drift.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/dose_schedule.dart';
import '../../domain/repositories/medication_repository.dart';
import '../local/database/app_database.dart';
import '../models/medication_model.dart';
import '../models/dose_schedule_model.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final AppDatabase database;

  MedicationRepositoryImpl(this.database);

  @override
  Future<List<Medication>> getAllMedications() async {
    final list = await database.medicationDao.getAllMedications();
    return list.map(MedicationModel.fromData).toList();
  }

  @override
  Stream<List<Medication>> watchAllMedications() {
    return database.medicationDao
        .watchAllMedications()
        .map((list) => list.map(MedicationModel.fromData).toList());
  }

  @override
  Future<Medication?> getMedicationById(int id) async {
    final data = await database.medicationDao.getMedicationById(id);
    return data != null ? MedicationModel.fromData(data) : null;
  }

  @override
  Future<int> insertMedication(Medication medication, List<DoseSchedule> schedules) async {
    final medId = await database.medicationDao.insertMedication(
      MedicationModel.toCompanion(medication),
    );

    final companions = schedules.map((s) {
      final updated = s.copyWith(medicationId: medId);
      return DoseScheduleModel.toCompanion(updated);
    }).toList();

    await database.doseScheduleDao.insertSchedules(companions);
    return medId;
  }

  @override
  Future<bool> updateMedication(Medication medication) async {
    return await database.medicationDao.updateMedication(
      MedicationModel.toCompanion(medication),
    );
  }

  @override
  Future<int> deleteMedication(int id) async {
    return await database.medicationDao.deleteMedication(id);
  }

  @override
  Future<int> insertSchedule(DoseSchedule schedule) async {
    return await database.doseScheduleDao.insertSchedule(
      DoseScheduleModel.toCompanion(schedule),
    );
  }

  @override
  Future<List<DoseSchedule>> getSchedulesForMedication(int medicationId) async {
    final list = await database.doseScheduleDao.getSchedulesForMedication(medicationId);
    return list.map(DoseScheduleModel.fromData).toList();
  }

  @override
  Future<List<DoseSchedule>> getAllActiveSchedules() async {
    final list = await database.doseScheduleDao.getAllActiveSchedules();
    return list.map(DoseScheduleModel.fromData).toList();
  }

  @override
  Future<List<DoseSchedule>> getAllSchedules() async {
    final list = await database.doseScheduleDao.getAllSchedules();
    return list.map(DoseScheduleModel.fromData).toList();
  }

  @override
  Stream<List<DoseSchedule>> watchAllActiveSchedules() {
    return database.doseScheduleDao
        .watchAllActiveSchedules()
        .map((list) => list.map(DoseScheduleModel.fromData).toList());
  }

  @override
  Future<DoseSchedule?> getScheduleById(int scheduleId) async {
    final data = await database.doseScheduleDao.getScheduleById(scheduleId);
    return data != null ? DoseScheduleModel.fromData(data) : null;
  }

  @override
  Future<void> updateSchedule(DoseSchedule schedule) async {
    await database.doseScheduleDao.updateSchedule(
      DoseScheduleModel.toCompanion(schedule),
    );
  }
}
