import 'package:equatable/equatable.dart';
import '../../../../domain/entities/dose_log.dart';
import '../../../../domain/entities/medication.dart';
import '../../../../domain/entities/dose_schedule.dart';

abstract class DoseLogState extends Equatable {
  const DoseLogState();

  @override
  List<Object?> get props => [];
}

class DoseLogInitial extends DoseLogState {}

class DoseLogLoading extends DoseLogState {}

class DoseLogLoaded extends DoseLogState {
  final List<DoseLog> logs;
  final Map<int, DoseSchedule> schedulesMap;
  final Map<int, Medication> medicationsMap;

  const DoseLogLoaded({
    required this.logs,
    required this.schedulesMap,
    required this.medicationsMap,
  });

  @override
  List<Object?> get props => [logs, schedulesMap, medicationsMap];
}

class DoseLogError extends DoseLogState {
  final String message;
  const DoseLogError(this.message);

  @override
  List<Object?> get props => [message];
}
