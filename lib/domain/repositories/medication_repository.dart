import '../entities/medication.dart';
import '../entities/dose_schedule.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getAllMedications();
  Stream<List<Medication>> watchAllMedications();
  Future<Medication?> getMedicationById(int id);
  Future<int> insertMedication(Medication medication, List<DoseSchedule> schedules);
  Future<bool> updateMedication(Medication medication);
  Future<int> deleteMedication(int id);
  
  Future<int> insertSchedule(DoseSchedule schedule);
  Future<List<DoseSchedule>> getSchedulesForMedication(int medicationId);
  Future<List<DoseSchedule>> getAllActiveSchedules();
  Future<List<DoseSchedule>> getAllSchedules();
  Stream<List<DoseSchedule>> watchAllActiveSchedules();
  Future<DoseSchedule?> getScheduleById(int scheduleId);
  Future<void> updateSchedule(DoseSchedule schedule);
}
