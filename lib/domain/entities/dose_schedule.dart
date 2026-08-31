import 'package:equatable/equatable.dart';
import '../enums/repeat_type.dart';

class DoseSchedule extends Equatable {
  final int? id;
  final int medicationId;
  final String scheduledTime; // "HH:mm" e.g. "08:00"
  final RepeatType repeatType;
  final List<int>? repeatDays; // e.g. [1, 2, 3, 4, 5, 6, 7] (Monday=1, Sunday=7)
  final bool isActive;
  
  // Phase 1: Cycle-based medications
  final int? cycleOnDays;
  final int? cycleOffDays;

  const DoseSchedule({
    this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.repeatType = RepeatType.daily,
    this.repeatDays,
    this.isActive = true,
    this.cycleOnDays,
    this.cycleOffDays,
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
    int? cycleOnDays,
    int? cycleOffDays,
  }) {
    return DoseSchedule(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      isActive: isActive ?? this.isActive,
      cycleOnDays: cycleOnDays ?? this.cycleOnDays,
      cycleOffDays: cycleOffDays ?? this.cycleOffDays,
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
        cycleOnDays,
        cycleOffDays,
      ];
}
