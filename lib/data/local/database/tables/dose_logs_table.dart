import 'package:drift/drift.dart';
import 'dose_schedules_table.dart';

@DataClassName('DoseLogData')
class DoseLogsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get doseScheduleId => integer().references(DoseSchedulesTable, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scheduledDateTime => dateTime()();
  DateTimeColumn get actualDateTime => dateTime().nullable()();
  TextColumn get status => text()(); // 'taken', 'snoozed', 'missed'
  IntColumn get snoozeCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
