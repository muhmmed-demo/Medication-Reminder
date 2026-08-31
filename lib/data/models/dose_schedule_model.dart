import 'dart:convert';
import 'package:drift/drift.dart';
import '../../domain/entities/dose_schedule.dart';
import '../../domain/enums/repeat_type.dart';
import '../local/database/app_database.dart';

class DoseScheduleModel {
  static DoseSchedule fromData(DoseScheduleData data) {
    List<int>? parsedDays;
    if (data.repeatDays != null) {
      try {
        final decoded = jsonDecode(data.repeatDays!) as List<dynamic>;
        parsedDays = decoded.map((e) => e as int).toList();
      } catch (_) {
        parsedDays = null;
      }
    }

    RepeatType parsedRepeatType;
    switch (data.repeatType) {
      case 'specificDays':
        parsedRepeatType = RepeatType.specificDays;
        break;
      case 'custom':
        parsedRepeatType = RepeatType.custom;
        break;
      case 'daily':
      default:
        parsedRepeatType = RepeatType.daily;
        break;
    }

    return DoseSchedule(
      id: data.id,
      medicationId: data.medicationId,
      scheduledTime: data.scheduledTime,
      repeatType: parsedRepeatType,
      repeatDays: parsedDays,
      isActive: data.isActive,
      cycleOnDays: data.cycleOnDays,
      cycleOffDays: data.cycleOffDays,
    );
  }

  static DoseSchedulesTableCompanion toCompanion(DoseSchedule entity) {
    String? encodedDays;
    if (entity.repeatDays != null) {
      encodedDays = jsonEncode(entity.repeatDays);
    }

    return DoseSchedulesTableCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      medicationId: Value(entity.medicationId),
      scheduledTime: Value(entity.scheduledTime),
      repeatType: Value(entity.repeatType.name),
      repeatDays: Value(encodedDays),
      isActive: Value(entity.isActive),
      cycleOnDays: Value(entity.cycleOnDays),
      cycleOffDays: Value(entity.cycleOffDays),
    );
  }
}
