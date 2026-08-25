import 'package:equatable/equatable.dart';

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
