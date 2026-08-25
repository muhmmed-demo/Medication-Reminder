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

  const StartAlarmEvent({
    required this.medicationId,
    required this.doseScheduleId,
    required this.medicationName,
    required this.dosageDescription,
    required this.scheduledDateTime,
    this.snoozeCount = 0,
    this.useCustomSound = true,
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
      ];
}

class TakeMedicationEvent extends AlarmEvent {}

class SnoozeMedicationEvent extends AlarmEvent {}
