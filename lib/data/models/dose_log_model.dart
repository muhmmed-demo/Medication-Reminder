import 'package:drift/drift.dart';
import '../../domain/entities/dose_log.dart';
import '../../domain/enums/dose_status.dart';
import '../local/database/app_database.dart';

class DoseLogModel {
  static DoseLog fromData(DoseLogData data) {
    DoseStatus parsedStatus;
    switch (data.status) {
      case 'snoozed':
        parsedStatus = DoseStatus.snoozed;
        break;
      case 'missed':
        parsedStatus = DoseStatus.missed;
        break;
      case 'taken':
      default:
        parsedStatus = DoseStatus.taken;
        break;
    }

    return DoseLog(
      id: data.id,
      doseScheduleId: data.doseScheduleId,
      scheduledDateTime: data.scheduledDateTime,
      actualDateTime: data.actualDateTime,
      status: parsedStatus,
      snoozeCount: data.snoozeCount,
      createdAt: data.createdAt,
    );
  }

  static DoseLogsTableCompanion toCompanion(DoseLog entity) {
    return DoseLogsTableCompanion(
      id: entity.id != null ? Value(entity.id!) : const Value.absent(),
      doseScheduleId: Value(entity.doseScheduleId),
      scheduledDateTime: Value(entity.scheduledDateTime),
      actualDateTime: Value(entity.actualDateTime),
      status: Value(entity.status.name),
      snoozeCount: Value(entity.snoozeCount),
      createdAt: Value(entity.createdAt),
    );
  }
}
