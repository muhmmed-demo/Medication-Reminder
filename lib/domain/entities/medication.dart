import 'package:equatable/equatable.dart';

class Medication extends Equatable {
  final int? id;
  final String name;
  final String dosageDescription;
  final int timesPerDay;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  
  // Phase 1: Advanced Features
  final int? inventoryCount;
  final int? refillThreshold;
  final bool isPRN;
  final int? minHoursBetweenDoses;
  final String? mealTiming;
  final String? imagePath;
  final String? customSoundPath;

  const Medication({
    this.id,
    required this.name,
    required this.dosageDescription,
    required this.timesPerDay,
    required this.startDate,
    this.endDate,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.inventoryCount,
    this.refillThreshold,
    this.isPRN = false,
    this.minHoursBetweenDoses,
    this.mealTiming,
    this.imagePath,
    this.customSoundPath,
  });

  bool get isContinuous => endDate == null;

  Medication copyWith({
    int? id,
    String? name,
    String? dosageDescription,
    int? timesPerDay,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    int? inventoryCount,
    int? refillThreshold,
    bool? isPRN,
    int? minHoursBetweenDoses,
    String? mealTiming,
    String? imagePath,
    String? customSoundPath,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosageDescription: dosageDescription ?? this.dosageDescription,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      inventoryCount: inventoryCount ?? this.inventoryCount,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      isPRN: isPRN ?? this.isPRN,
      minHoursBetweenDoses: minHoursBetweenDoses ?? this.minHoursBetweenDoses,
      mealTiming: mealTiming ?? this.mealTiming,
      imagePath: imagePath ?? this.imagePath,
      customSoundPath: customSoundPath ?? this.customSoundPath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        dosageDescription,
        timesPerDay,
        startDate,
        endDate,
        notes,
        isActive,
        createdAt,
        inventoryCount,
        refillThreshold,
        isPRN,
        minHoursBetweenDoses,
        mealTiming,
        imagePath,
        customSoundPath,
      ];
}
