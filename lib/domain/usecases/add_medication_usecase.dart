import '../entities/medication.dart';
import '../entities/dose_schedule.dart';
import '../repositories/medication_repository.dart';

class AddMedicationUseCase {
  final MedicationRepository repository;

  AddMedicationUseCase(this.repository);

  Future<int> call({
    required Medication medication,
    required List<DoseSchedule> schedules,
  }) async {
    return await repository.insertMedication(medication, schedules);
  }
}
