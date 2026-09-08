import '../entities/medication.dart';
import '../entities/dose_schedule.dart';
import '../repositories/medication_repository.dart';

class AddMedicationUseCase {
  final MedicationRepository repository;

  AddMedicationUseCase(this.repository);

  Future<void> call({
    required Medication medication,
    required List<DoseSchedule> schedules,
  }) async {
    if (medication.id != null) {
      await repository.updateMedicationWithSchedules(medication, schedules);
    } else {
      await repository.insertMedication(medication, schedules);
    }
  }
}
