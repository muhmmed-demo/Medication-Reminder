import '../entities/medication.dart';
import '../repositories/medication_repository.dart';

class GetMedicationsUseCase {
  final MedicationRepository repository;

  GetMedicationsUseCase(this.repository);

  Future<List<Medication>> call() async {
    return await repository.getAllMedications();
  }

  Stream<List<Medication>> watch() {
    return repository.watchAllMedications();
  }
}
