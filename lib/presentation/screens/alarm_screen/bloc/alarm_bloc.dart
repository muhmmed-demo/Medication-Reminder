import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/usecases/mark_dose_taken_usecase.dart';
import '../../../../domain/usecases/snooze_dose_usecase.dart';
import '../../../../services/alarm_audio_service.dart';
import '../../../../services/vibration_service.dart';
import '../../../../services/notification_service.dart';
import 'alarm_event.dart';
import 'alarm_state.dart';

class AlarmBloc extends Bloc<AlarmEvent, AlarmState> {
  final MarkDoseTakenUseCase markDoseTakenUseCase;
  final SnoozeDoseUseCase snoozeDoseUseCase;
  final AlarmAudioService alarmAudioService;
  final VibrationService vibrationService;
  final NotificationService notificationService;

  AlarmBloc({
    required this.markDoseTakenUseCase,
    required this.snoozeDoseUseCase,
    required this.alarmAudioService,
    required this.vibrationService,
    required this.notificationService,
  }) : super(AlarmInitial()) {
    on<StartAlarmEvent>(_onStartAlarm);
    on<TakeMedicationEvent>(_onTakeMedication);
    on<SnoozeMedicationEvent>(_onSnoozeMedication);
  }

  Future<void> _onStartAlarm(
    StartAlarmEvent event,
    Emitter<AlarmState> emit,
  ) async {
    // Start audio loop & continuous vibration
    await alarmAudioService.startAlarmSound(useCustomSound: event.useCustomSound);
    await vibrationService.startAlarmVibration();

    final canSnooze = event.snoozeCount < AppConstants.maxSnoozeCount;

    emit(AlarmRinging(
      medicationId: event.medicationId,
      doseScheduleId: event.doseScheduleId,
      medicationName: event.medicationName,
      dosageDescription: event.dosageDescription,
      scheduledDateTime: event.scheduledDateTime,
      snoozeCount: event.snoozeCount,
      maxSnoozeCount: AppConstants.maxSnoozeCount,
      canSnooze: canSnooze,
    ));
  }

  Future<void> _onTakeMedication(
    TakeMedicationEvent event,
    Emitter<AlarmState> emit,
  ) async {
    if (state is! AlarmRinging) return;
    final ringingState = state as AlarmRinging;

    // Stop audio & vibration
    await alarmAudioService.stopAlarmSound();
    await vibrationService.stopVibration();

    // Cancel notification
    final notifId = ringingState.doseScheduleId;
    await notificationService.cancelAlarm(notifId);

    // Save dose log as Taken
    await markDoseTakenUseCase(
      doseScheduleId: ringingState.doseScheduleId,
      scheduledDateTime: ringingState.scheduledDateTime,
      snoozeCount: ringingState.snoozeCount,
    );

    emit(AlarmTakenSuccess());
  }

  Future<void> _onSnoozeMedication(
    SnoozeMedicationEvent event,
    Emitter<AlarmState> emit,
  ) async {
    if (state is! AlarmRinging) return;
    final ringingState = state as AlarmRinging;

    if (!ringingState.canSnooze) return;

    // Stop audio & vibration
    await alarmAudioService.stopAlarmSound();
    await vibrationService.stopVibration();

    final nextSnoozeCount = ringingState.snoozeCount + 1;
    final nextAlarmTime = DateTime.now().add(
      const Duration(minutes: AppConstants.snoozeDurationMinutes),
    );

    // Save dose log as Snoozed
    await snoozeDoseUseCase(
      doseScheduleId: ringingState.doseScheduleId,
      scheduledDateTime: ringingState.scheduledDateTime,
      newSnoozeCount: nextSnoozeCount,
    );

    // Schedule next snooze alarm
    final notifId = ringingState.doseScheduleId;
    await notificationService.scheduleAlarm(
      id: notifId,
      medicationName: ringingState.medicationName,
      dosageDescription: ringingState.dosageDescription,
      scheduledDateTime: nextAlarmTime,
      medicationId: ringingState.medicationId,
      doseScheduleId: ringingState.doseScheduleId,
      snoozeCount: nextSnoozeCount,
    );

    emit(AlarmSnoozedSuccess(
      nextSnoozeMinutes: AppConstants.snoozeDurationMinutes,
    ));
  }

  @override
  Future<void> close() async {
    await alarmAudioService.stopAlarmSound();
    await vibrationService.stopVibration();
    return super.close();
  }
}
