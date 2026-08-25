import '../repositories/medication_repository.dart';

class DeleteMedicationUseCase {
  final MedicationRepository repository;

  DeleteMedicationUseCase(this.repository);

  Future<int> call(int id) async {
    return await repository.deleteMedication(id);
  }
}
