import 'package:equatable/equatable.dart';
import '../../../../domain/entities/medication.dart';

abstract class MedicationsEvent extends Equatable {
  const MedicationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMedicationsEvent extends MedicationsEvent {}

class DeleteMedicationEvent extends MedicationsEvent {
  final int medicationId;
  const DeleteMedicationEvent(this.medicationId);

  @override
  List<Object?> get props => [medicationId];
}

class ToggleMedicationActiveEvent extends MedicationsEvent {
  final Medication medication;
  const ToggleMedicationActiveEvent(this.medication);

  @override
  List<Object?> get props => [medication];
}

class RecordPrnDoseEvent extends MedicationsEvent {
  final int medicationId;
  const RecordPrnDoseEvent(this.medicationId);

  @override
  List<Object?> get props => [medicationId];
}
