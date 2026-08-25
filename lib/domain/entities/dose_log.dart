import 'package:equatable/equatable.dart';
import '../enums/dose_status.dart';

class DoseLog extends Equatable {
  final int? id;
  final int doseScheduleId;
  final DateTime scheduledDateTime;
  final DateTime? actualDateTime;
  final DoseStatus status;
  final int snoozeCount;
  final DateTime createdAt;

  const DoseLog({
    this.id,
    required this.doseScheduleId,
    required this.scheduledDateTime,
    this.actualDateTime,
    required this.status,
    this.snoozeCount = 0,
    required this.createdAt,
  });

  DoseLog copyWith({
    int? id,
    int? doseScheduleId,
    DateTime? scheduledDateTime,
    DateTime? actualDateTime,
    DoseStatus? status,
    int? snoozeCount,
    DateTime? createdAt,
  }) {
    return DoseLog(
      id: id ?? this.id,
      doseScheduleId: doseScheduleId ?? this.doseScheduleId,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      actualDateTime: actualDateTime ?? this.actualDateTime,
      status: status ?? this.status,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        doseScheduleId,
        scheduledDateTime,
        actualDateTime,
        status,
        snoozeCount,
        createdAt,
      ];
}
