import 'package:equatable/equatable.dart';

abstract class DoseLogEvent extends Equatable {
  const DoseLogEvent();

  @override
  List<Object?> get props => [];
}

class LoadDoseLogsEvent extends DoseLogEvent {}
