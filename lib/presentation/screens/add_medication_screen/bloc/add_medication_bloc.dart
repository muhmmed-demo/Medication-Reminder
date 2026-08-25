import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/usecases/add_medication_usecase.dart';
import '../../../../services/alarm_scheduler_service.dart';
import 'add_medication_event.dart';
import 'add_medication_state.dart';

class AddMedicationBloc extends Bloc<AddMedicationEvent, AddMedicationState> {
  final AddMedicationUseCase addMedicationUseCase;
  final AlarmSchedulerService alarmSchedulerService;

  AddMedicationBloc({
    required this.addMedicationUseCase,
    required this.alarmSchedulerService,
  }) : super(AddMedicationInitial()) {
    on<SaveMedicationEvent>(_onSaveMedication);
  }

  Future<void> _onSaveMedication(
    SaveMedicationEvent event,
    Emitter<AddMedicationState> emit,
  ) async {
    emit(AddMedicationSaving());
    try {
      await addMedicationUseCase(
        medication: event.medication,
        schedules: event.schedules,
      );
      await alarmSchedulerService.scheduleAllActiveAlarms();
      emit(AddMedicationSuccess());
    } catch (e) {
      emit(AddMedicationFailure('فشل حفظ الدواء: $e'));
    }
  }
}
