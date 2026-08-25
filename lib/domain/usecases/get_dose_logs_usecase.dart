import '../entities/dose_log.dart';
import '../repositories/dose_log_repository.dart';

class GetDoseLogsUseCase {
  final DoseLogRepository repository;

  GetDoseLogsUseCase(this.repository);

  Future<List<DoseLog>> call() async {
    return await repository.getAllDoseLogs();
  }

  Stream<List<DoseLog>> watch() {
    return repository.watchAllDoseLogs();
  }

  Future<List<DoseLog>> getForDate(DateTime date) async {
    return await repository.getLogsForDate(date);
  }
}
