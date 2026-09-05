import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/dose_schedule.dart';
import '../../../../domain/usecases/get_medications_usecase.dart';
import '../../../../domain/usecases/delete_medication_usecase.dart';
import '../../../../domain/usecases/schedule_dose_usecase.dart';
import '../../../../domain/usecases/update_medication_usecase.dart';
import '../../../../domain/usecases/record_prn_dose_usecase.dart';
import '../../../../services/alarm_scheduler_service.dart';
import 'medications_event.dart';
import 'medications_state.dart';

class MedicationsBloc extends Bloc<MedicationsEvent, MedicationsState> {
  final GetMedicationsUseCase getMedicationsUseCase;
  final DeleteMedicationUseCase deleteMedicationUseCase;
  final ScheduleDoseUseCase scheduleDoseUseCase;
  final AlarmSchedulerService alarmSchedulerService;
  final UpdateMedicationUseCase updateMedicationUseCase;
  final RecordPrnDoseUseCase recordPrnDoseUseCase;

  MedicationsBloc({
    required this.getMedicationsUseCase,
    required this.deleteMedicationUseCase,
    required this.scheduleDoseUseCase,
    required this.alarmSchedulerService,
    required this.updateMedicationUseCase,
    required this.recordPrnDoseUseCase,
  }) : super(MedicationsInitial()) {
    on<LoadMedicationsEvent>(_onLoadMedications);
    on<DeleteMedicationEvent>(_onDeleteMedication);
    on<ToggleMedicationActiveEvent>(_onToggleActive);
    on<RecordPrnDoseEvent>(_onRecordPrnDose);
  }

  Future<void> _onLoadMedications(
    LoadMedicationsEvent event,
    Emitter<MedicationsState> emit,
  ) async {
    emit(MedicationsLoading());
    try {
      final medications = await getMedicationsUseCase();
      final Map<int, List<DoseSchedule>> schedulesMap = {};

      for (final med in medications) {
        if (med.id != null) {
          final schedules = await scheduleDoseUseCase.getSchedulesForMedication(med.id!);
          schedulesMap[med.id!] = schedules;
        }
      }

      emit(MedicationsLoaded(medications: medications, schedulesMap: schedulesMap));
    } catch (e) {
      emit(MedicationsError('فشل تحميل قائمة الأدوية: $e'));
    }
  }

  Future<void> _onDeleteMedication(
    DeleteMedicationEvent event,
    Emitter<MedicationsState> emit,
  ) async {
    try {
      await deleteMedicationUseCase(event.medicationId);
      await alarmSchedulerService.scheduleAllActiveAlarms();
      add(LoadMedicationsEvent());
    } catch (e) {
      emit(MedicationsError('فشل حذف الدواء: $e'));
    }
  }

  Future<void> _onToggleActive(
    ToggleMedicationActiveEvent event,
    Emitter<MedicationsState> emit,
  ) async {
    try {
      final updated = event.medication.copyWith(isActive: !event.medication.isActive);
      await updateMedicationUseCase(updated);
      await alarmSchedulerService.scheduleAllActiveAlarms();
      add(LoadMedicationsEvent());
    } catch (e) {
      emit(MedicationsError('فشل تعديل حالة الدواء: $e'));
    }
  }

  Future<void> _onRecordPrnDose(
    RecordPrnDoseEvent event,
    Emitter<MedicationsState> emit,
  ) async {
    try {
      await recordPrnDoseUseCase(medicationId: event.medicationId);
      add(LoadMedicationsEvent());
    } catch (e) {
      emit(MedicationsError('فشل تسجيل الجرعة: $e'));
    }
  }
}
