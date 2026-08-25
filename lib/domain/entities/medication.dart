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
      ];
}
