import 'package:equatable/equatable.dart';
import '../../../../domain/entities/medication.dart';
import '../../../../domain/entities/dose_schedule.dart';

abstract class AddMedicationEvent extends Equatable {
  const AddMedicationEvent();

  @override
  List<Object?> get props => [];
}

class SaveMedicationEvent extends AddMedicationEvent {
  final Medication medication;
  final List<DoseSchedule> schedules;

  const SaveMedicationEvent({
    required this.medication,
    required this.schedules,
  });

  @override
  List<Object?> get props => [medication, schedules];
}
