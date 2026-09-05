import 'dart:io';
import 'package:flutter/foundation.dart';
import '../repositories/medication_repository.dart';

class DeleteMedicationUseCase {
  final MedicationRepository repository;

  DeleteMedicationUseCase(this.repository);

  Future<int> call(int id) async {
    try {
      final medication = await repository.getMedicationById(id);
      if (medication?.imagePath != null && medication!.imagePath!.isNotEmpty) {
        final file = File(medication.imagePath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted orphan medication image: ${medication.imagePath}');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up medication image file: $e');
    }

    return await repository.deleteMedication(id);
  }
}
