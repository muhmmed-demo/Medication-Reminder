import 'package:equatable/equatable.dart';

abstract class AddMedicationState extends Equatable {
  const AddMedicationState();

  @override
  List<Object?> get props => [];
}

class AddMedicationInitial extends AddMedicationState {}

class AddMedicationSaving extends AddMedicationState {}

class AddMedicationSuccess extends AddMedicationState {}

class AddMedicationFailure extends AddMedicationState {
  final String error;
  const AddMedicationFailure(this.error);

  @override
  List<Object?> get props => [error];
}
