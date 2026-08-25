import 'package:drift/drift.dart';
import '../../domain/entities/medication.dart';
import '../local/database/app_database.dart';

class MedicationModel {
  static Medication fromData(MedicationData data) {
    return Medication(
      id: data.id,
      name: data.name,
      dosageDescription: data.dosageDescription,
      timesPerDay: data.timesPerDay,
      startDate: data.startDate,
      endDate: data.endDate,
      notes: data.notes,
      isActive: data.isActive,
      createdAt: data.createdAt,
    );
  }

  static MedicationsTableCompanion toCompanion(Medication entity) {
    return MedicationsTableCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      name: Value(entity.name),
      dosageDescription: Value(entity.dosageDescription),
      timesPerDay: Value(entity.timesPerDay),
      startDate: Value(entity.startDate),
      endDate: Value(entity.endDate),
      notes: Value(entity.notes),
      isActive: Value(entity.isActive),
      createdAt: Value(entity.createdAt),
    );
  }
}
