import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/dose_schedule.dart';
import '../../../../domain/entities/medication.dart';
import '../../../../domain/usecases/get_dose_logs_usecase.dart';
import '../../../../domain/usecases/get_medications_usecase.dart';
import '../../../../domain/usecases/schedule_dose_usecase.dart';
import 'dose_log_event.dart';
import 'dose_log_state.dart';

class DoseLogBloc extends Bloc<DoseLogEvent, DoseLogState> {
  final GetDoseLogsUseCase getDoseLogsUseCase;
  final GetMedicationsUseCase getMedicationsUseCase;
  final ScheduleDoseUseCase scheduleDoseUseCase;

  DoseLogBloc({
    required this.getDoseLogsUseCase,
    required this.getMedicationsUseCase,
    required this.scheduleDoseUseCase,
  }) : super(DoseLogInitial()) {
    on<LoadDoseLogsEvent>(_onLoadDoseLogs);
  }

  Future<void> _onLoadDoseLogs(
    LoadDoseLogsEvent event,
    Emitter<DoseLogState> emit,
  ) async {
    emit(DoseLogLoading());
    try {
      final logs = await getDoseLogsUseCase();
      final medications = await getMedicationsUseCase();
      final medMap = {for (var m in medications) if (m.id != null) m.id!: m};

      // Load all schedules (active and past) so history is complete
      final allSchedules = await scheduleDoseUseCase.getAllSchedules();
      final scheduleMap = {for (var s in allSchedules) if (s.id != null) s.id!: s};

      emit(DoseLogLoaded(
        logs: logs,
        schedulesMap: scheduleMap,
        medicationsMap: medMap,
      ));
    } catch (e) {
      emit(DoseLogError('فشل تحميل سجل الجرعات: $e'));
    }
  }
}
