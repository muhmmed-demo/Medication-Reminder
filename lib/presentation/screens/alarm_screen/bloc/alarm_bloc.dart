import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/usecases/mark_dose_taken_usecase.dart';
import '../../../../domain/usecases/snooze_dose_usecase.dart';
import '../../../../domain/usecases/skip_dose_usecase.dart';
import '../../../../services/alarm_audio_service.dart';
import '../../../../services/vibration_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/alarm_scheduler_service.dart';
import '../../../../services/tts_service.dart';
import 'alarm_event.dart';
import 'alarm_state.dart';

class AlarmBloc extends Bloc<AlarmEvent, AlarmState> {
  final MarkDoseTakenUseCase markDoseTakenUseCase;
  final SnoozeDoseUseCase snoozeDoseUseCase;
  final SkipDoseUseCase skipDoseUseCase;
  final AlarmAudioService alarmAudioService;
  final VibrationService vibrationService;
  final NotificationService notificationService;
  final AlarmSchedulerService alarmSchedulerService;
  final TtsService ttsService;

  AlarmBloc({
    required this.markDoseTakenUseCase,
    required this.snoozeDoseUseCase,
    required this.skipDoseUseCase,
    required this.alarmAudioService,
    required this.vibrationService,
    required this.notificationService,
    required this.alarmSchedulerService,
    required this.ttsService,
  }) : super(AlarmInitial()) {
    on<StartAlarmEvent>(_onStartAlarm);
    on<TakeMedicationEvent>(_onTakeMedication);
    on<SnoozeMedicationEvent>(_onSnoozeMedication);
    on<SkipMedicationEvent>(_onSkipMedication);
  }

  bool _isRinging = false;

  Future<void> _onStartAlarm(
    StartAlarmEvent event,
    Emitter<AlarmState> emit,
  ) async {
    final canSnooze = event.snoozeCount < AppConstants.maxSnoozeCount;

    // Speak medication name(s) in Arabic clearly for the elderly
    String speechText;
    if (event.extraMedications != null && event.extraMedications!.isNotEmpty) {
      final names = [
        event.medicationName,
        ...event.extraMedications!.map((m) => m['medicationName'] as String? ?? '')
      ].where((n) => n.isNotEmpty).join(' و ');
      speechText = 'تنبيه. حان موعد أدويتك: $names.';
    } else {
      speechText =
          'تنبيه. حان موعد أخذ دواء ${event.medicationName}. الجرعة المطلوبة: ${event.dosageDescription}.';
    }

    _isRinging = true;
    _runAlarmLoop(speechText, event.useCustomSound, event.customSoundPath);

    emit(AlarmRinging(
      medicationId: event.medicationId,
      doseScheduleId: event.doseScheduleId,
      medicationName: event.medicationName,
      dosageDescription: event.dosageDescription,
      scheduledDateTime: event.scheduledDateTime,
      snoozeCount: event.snoozeCount,
      maxSnoozeCount: AppConstants.maxSnoozeCount,
      canSnooze: canSnooze,
      imagePath: event.imagePath,
      customSoundPath: event.customSoundPath,
      extraMedications: event.extraMedications,
    ));
  }

  Future<void> _runAlarmLoop(String speechText, bool useCustomSound, String? customSoundPath) async {
    // Start vibration continuously
    await vibrationService.startAlarmVibration();

    while (_isRinging) {
      // 1. Speak the text (or skip if custom voice is used and preferred)
      // We'll speak it anyway as requested: "ينطق اسم الدواء ثم التنبيه"
      await alarmAudioService.stopAlarmSound(); // Ensure alarm sound is off
      
      await ttsService.speak(speechText).timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      );

      // Give a tiny pause
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRinging) break;

      // 2. Play Alarm (Default or Custom Voice) for 8 seconds
      await alarmAudioService.startAlarmSound(
        useCustomSound: useCustomSound,
        customSoundPath: customSoundPath,
        loop: false, // We handle loop
        initialVolume: 1.0, // Full volume for alarm portion
      );

      // Wait 8 seconds while alarm plays
      await Future.delayed(const Duration(seconds: 8));
      if (!_isRinging) break;
    }
  }

  Future<void> _stopRinging() async {
    _isRinging = false;
    await alarmAudioService.stopAlarmSound();
    await vibrationService.stopVibration();
    await ttsService.stop();
  }

  Future<void> _onTakeMedication(
    TakeMedicationEvent event,
    Emitter<AlarmState> emit,
  ) async {
    if (state is! AlarmRinging) return;
    final ringingState = state as AlarmRinging;

    await _stopRinging();

    // Cancel notification
    final notifId = ringingState.doseScheduleId;
    await notificationService.cancelAlarm(notifId);

    // Save dose log as Taken for primary medication
    await markDoseTakenUseCase(
      doseScheduleId: ringingState.doseScheduleId,
      scheduledDateTime: ringingState.scheduledDateTime,
      snoozeCount: ringingState.snoozeCount,
    );

    // Save dose log as Taken for all simultaneous extra medications
    if (ringingState.extraMedications != null) {
      for (final extra in ringingState.extraMedications!) {
        final extraScheduleId = extra['doseScheduleId'] as int?;
        if (extraScheduleId != null) {
          await markDoseTakenUseCase(
            doseScheduleId: extraScheduleId,
            scheduledDateTime: ringingState.scheduledDateTime,
            snoozeCount: ringingState.snoozeCount,
          );
        }
      }
    }

    // CRITICAL: Schedule the next occurrences of active alarms
    await alarmSchedulerService.scheduleAllActiveAlarms();

    emit(AlarmTakenSuccess());
  }

  Future<void> _onSkipMedication(
    SkipMedicationEvent event,
    Emitter<AlarmState> emit,
  ) async {
    if (state is! AlarmRinging) return;
    final ringingState = state as AlarmRinging;

    await _stopRinging();

    // Cancel notification
    final notifId = ringingState.doseScheduleId;
    await notificationService.cancelAlarm(notifId);

    // Record as missed/skipped (without deducting from inventory)
    await skipDoseUseCase(
      doseScheduleId: ringingState.doseScheduleId,
      scheduledDateTime: ringingState.scheduledDateTime,
      snoozeCount: ringingState.snoozeCount,
    );

    if (ringingState.extraMedications != null) {
      for (final extra in ringingState.extraMedications!) {
        final extraScheduleId = extra['doseScheduleId'] as int?;
        if (extraScheduleId != null) {
          await skipDoseUseCase(
            doseScheduleId: extraScheduleId,
            scheduledDateTime: ringingState.scheduledDateTime,
            snoozeCount: ringingState.snoozeCount,
          );
        }
      }
    }

    // Schedule next occurrences
    await alarmSchedulerService.scheduleAllActiveAlarms();

    emit(AlarmSkippedSuccess());
  }

  Future<void> _onSnoozeMedication(
    SnoozeMedicationEvent event,
    Emitter<AlarmState> emit,
  ) async {
    if (state is! AlarmRinging) return;
    final ringingState = state as AlarmRinging;

    if (!ringingState.canSnooze) return;

    await _stopRinging();

    // Cancel current notification to stop sound
    final notifId = ringingState.doseScheduleId;
    await notificationService.cancelAlarm(notifId);

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

    // Schedule next snooze alarm preserving imagePath and extraMedications
    await notificationService.scheduleAlarm(
      id: notifId,
      medicationName: ringingState.medicationName,
      dosageDescription: ringingState.dosageDescription,
      scheduledDateTime: nextAlarmTime,
      medicationId: ringingState.medicationId,
      doseScheduleId: ringingState.doseScheduleId,
      snoozeCount: nextSnoozeCount,
      imagePath: ringingState.imagePath,
      customSoundPath: ringingState.customSoundPath,
      extraMedications: ringingState.extraMedications,
    );

    // Also ensure all other alarms are properly scheduled
    await alarmSchedulerService.scheduleAllActiveAlarms();

    emit(AlarmSnoozedSuccess(
      nextSnoozeMinutes: AppConstants.snoozeDurationMinutes,
    ));
  }

  @override
  Future<void> close() async {
    await _stopRinging();
    return super.close();
  }
}
