import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class UpdateMedicationUseCase {
  final MedicationRepository repository;

  UpdateMedicationUseCase(this.repository);

  Future<bool> call(Medication medication) async {
    return await repository.updateMedication(medication);
  }
}
