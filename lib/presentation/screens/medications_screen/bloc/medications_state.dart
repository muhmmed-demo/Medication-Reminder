import 'package:equatable/equatable.dart';
import '../../../../domain/entities/medication.dart';
import '../../../../domain/entities/dose_schedule.dart';

abstract class MedicationsState extends Equatable {
  const MedicationsState();

  @override
  List<Object?> get props => [];
}

class MedicationsInitial extends MedicationsState {}

class MedicationsLoading extends MedicationsState {}

class MedicationsLoaded extends MedicationsState {
  final List<Medication> medications;
  final Map<int, List<DoseSchedule>> schedulesMap;

  const MedicationsLoaded({
    required this.medications,
    required this.schedulesMap,
  });

  @override
  List<Object?> get props => [medications, schedulesMap];
}

class MedicationsError extends MedicationsState {
  final String message;
  const MedicationsError(this.message);

  @override
  List<Object?> get props => [message];
}
