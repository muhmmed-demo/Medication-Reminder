import '../entities/dose_schedule.dart';
import '../repositories/medication_repository.dart';

class ScheduleDoseUseCase {
  final MedicationRepository repository;

  ScheduleDoseUseCase(this.repository);

  Future<List<DoseSchedule>> getAllActiveSchedules() async {
    return await repository.getAllActiveSchedules();
  }

  Stream<List<DoseSchedule>> watchAllActiveSchedules() {
    return repository.watchAllActiveSchedules();
  }

  Future<List<DoseSchedule>> getSchedulesForMedication(int medicationId) async {
    return await repository.getSchedulesForMedication(medicationId);
  }
}
