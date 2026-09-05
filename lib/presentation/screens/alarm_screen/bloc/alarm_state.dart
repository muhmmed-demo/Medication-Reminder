import 'package:equatable/equatable.dart';

abstract class AlarmState extends Equatable {
  const AlarmState();

  @override
  List<Object?> get props => [];
}

class AlarmInitial extends AlarmState {}

class AlarmRinging extends AlarmState {
  final int medicationId;
  final int doseScheduleId;
  final String medicationName;
  final String dosageDescription;
  final DateTime scheduledDateTime;
  final int snoozeCount;
  final int maxSnoozeCount;
  final bool canSnooze;
  final String? imagePath;

  const AlarmRinging({
    required this.medicationId,
    required this.doseScheduleId,
    required this.medicationName,
    required this.dosageDescription,
    required this.scheduledDateTime,
    required this.snoozeCount,
    required this.maxSnoozeCount,
    required this.canSnooze,
    this.imagePath,
  });

  @override
  List<Object?> get props => [
        medicationId,
        doseScheduleId,
        medicationName,
        dosageDescription,
        scheduledDateTime,
        snoozeCount,
        maxSnoozeCount,
        canSnooze,
        imagePath,
      ];
}

class AlarmTakenSuccess extends AlarmState {}

class AlarmSnoozedSuccess extends AlarmState {
  final int nextSnoozeMinutes;
  const AlarmSnoozedSuccess({required this.nextSnoozeMinutes});

  @override
  List<Object?> get props => [nextSnoozeMinutes];
}
