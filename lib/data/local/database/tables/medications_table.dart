import 'package:drift/drift.dart';

@DataClassName('MedicationData')
class MedicationsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get dosageDescription => text()();
  IntColumn get timesPerDay => integer()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  // Phase 1: Advanced Features
  IntColumn get inventoryCount => integer().nullable()();
  IntColumn get refillThreshold => integer().nullable()();
  BoolColumn get isPRN => boolean().withDefault(const Constant(false))();
  IntColumn get minHoursBetweenDoses => integer().nullable()();
  TextColumn get mealTiming => text().nullable()(); // 'before', 'after', 'with', 'none'
  TextColumn get imagePath => text().nullable()();
  TextColumn get customSoundPath => text().nullable()();
}
