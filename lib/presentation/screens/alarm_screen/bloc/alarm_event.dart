import 'package:equatable/equatable.dart';

abstract class AlarmEvent extends Equatable {
  const AlarmEvent();

  @override
  List<Object?> get props => [];
}

class StartAlarmEvent extends AlarmEvent {
  final int medicationId;
  final int doseScheduleId;
  final String medicationName;
  final String dosageDescription;
  final DateTime scheduledDateTime;
  final int snoozeCount;
  final bool useCustomSound;
  final String? imagePath;
  final List<Map<String, dynamic>>? extraMedications;

  const StartAlarmEvent({
    required this.medicationId,
    required this.doseScheduleId,
    required this.medicationName,
    required this.dosageDescription,
    required this.scheduledDateTime,
    this.snoozeCount = 0,
    this.useCustomSound = true,
    this.imagePath,
    this.extraMedications,
  });

  @override
  List<Object?> get props => [
        medicationId,
        doseScheduleId,
        medicationName,
        dosageDescription,
        scheduledDateTime,
        snoozeCount,
        useCustomSound,
        imagePath,
        extraMedications,
      ];
}

class TakeMedicationEvent extends AlarmEvent {}

class SnoozeMedicationEvent extends AlarmEvent {}

class SkipMedicationEvent extends AlarmEvent {}
