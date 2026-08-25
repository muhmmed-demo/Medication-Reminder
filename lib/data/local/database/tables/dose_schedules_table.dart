import 'package:drift/drift.dart';
import 'medications_table.dart';

@DataClassName('DoseScheduleData')
class DoseSchedulesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicationId => integer().references(MedicationsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get scheduledTime => text()(); // "HH:mm"
  TextColumn get repeatType => text().withDefault(const Constant('daily'))(); // 'daily', 'specificDays', 'custom'
  TextColumn get repeatDays => text().nullable()(); // JSON string like "[1,2,3,4,5,6,7]"
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
