import 'package:equatable/equatable.dart';
import '../enums/repeat_type.dart';

class DoseSchedule extends Equatable {
  final int? id;
  final int medicationId;
  final String scheduledTime; // "HH:mm" e.g. "08:00"
  final RepeatType repeatType;
  final List<int>? repeatDays; // e.g. [1, 2, 3, 4, 5, 6, 7] (Monday=1, Sunday=7)
  final bool isActive;

  const DoseSchedule({
    this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.repeatType = RepeatType.daily,
    this.repeatDays,
    this.isActive = true,
  });

  int get hour {
    final parts = scheduledTime.split(':');
    return int.parse(parts[0]);
  }

  int get minute {
    final parts = scheduledTime.split(':');
    return int.parse(parts[1]);
  }

  DoseSchedule copyWith({
    int? id,
    int? medicationId,
    String? scheduledTime,
    RepeatType? repeatType,
    List<int>? repeatDays,
    bool? isActive,
  }) {
    return DoseSchedule(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        medicationId,
        scheduledTime,
        repeatType,
        repeatDays,
        isActive,
      ];
}
