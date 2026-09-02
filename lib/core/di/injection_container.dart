import 'package:get_it/get_it.dart';
import '../../data/local/database/app_database.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../data/repositories/dose_log_repository_impl.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/repositories/dose_log_repository.dart';
import '../../domain/usecases/add_medication_usecase.dart';
import '../../domain/usecases/get_medications_usecase.dart';
import '../../domain/usecases/delete_medication_usecase.dart';
import '../../domain/usecases/schedule_dose_usecase.dart';
import '../../domain/usecases/mark_dose_taken_usecase.dart';
import '../../domain/usecases/snooze_dose_usecase.dart';
import '../../domain/usecases/get_dose_logs_usecase.dart';
import '../../services/notification_service.dart';
import '../../services/alarm_audio_service.dart';
import '../../services/vibration_service.dart';
import '../../services/permission_service.dart';
import '../../services/alarm_scheduler_service.dart';
import '../../presentation/screens/medications_screen/bloc/medications_bloc.dart';
import '../../presentation/screens/add_medication_screen/bloc/add_medication_bloc.dart';
import '../../presentation/screens/dose_log_screen/bloc/dose_log_bloc.dart';
import '../../presentation/screens/alarm_screen/bloc/alarm_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // 1. Database
  final database = AppDatabase();
  sl.registerSingleton<AppDatabase>(database);

  // 2. Repositories
  sl.registerLazySingleton<MedicationRepository>(
    () => MedicationRepositoryImpl(sl<AppDatabase>()),
  );
  sl.registerLazySingleton<DoseLogRepository>(
    () => DoseLogRepositoryImpl(sl<AppDatabase>()),
  );

  // 3. Use Cases
  sl.registerLazySingleton(() => AddMedicationUseCase(sl<MedicationRepository>()));
  sl.registerLazySingleton(() => GetMedicationsUseCase(sl<MedicationRepository>()));
  sl.registerLazySingleton(() => DeleteMedicationUseCase(sl<MedicationRepository>()));
  sl.registerLazySingleton(() => ScheduleDoseUseCase(sl<MedicationRepository>()));
  sl.registerLazySingleton(() => MarkDoseTakenUseCase(
    repository: sl<DoseLogRepository>(),
    medicationRepository: sl<MedicationRepository>(),
    notificationService: sl<NotificationService>(),
  ));
  sl.registerLazySingleton(() => SnoozeDoseUseCase(sl<DoseLogRepository>()));
  sl.registerLazySingleton(() => GetDoseLogsUseCase(sl<DoseLogRepository>()));

  // 4. Services
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => AlarmAudioService());
  sl.registerLazySingleton(() => VibrationService());
  sl.registerLazySingleton(() => PermissionService());
  sl.registerLazySingleton(
    () => AlarmSchedulerService(
      medicationRepository: sl<MedicationRepository>(),
      notificationService: sl<NotificationService>(),
    ),
  );

  // 5. BLoCs
  sl.registerFactory(
    () => MedicationsBloc(
      getMedicationsUseCase: sl<GetMedicationsUseCase>(),
      deleteMedicationUseCase: sl<DeleteMedicationUseCase>(),
      scheduleDoseUseCase: sl<ScheduleDoseUseCase>(),
      alarmSchedulerService: sl<AlarmSchedulerService>(),
    ),
  );

  sl.registerFactory(
    () => AddMedicationBloc(
      addMedicationUseCase: sl<AddMedicationUseCase>(),
      alarmSchedulerService: sl<AlarmSchedulerService>(),
    ),
  );

  sl.registerFactory(
    () => DoseLogBloc(
      getDoseLogsUseCase: sl<GetDoseLogsUseCase>(),
      getMedicationsUseCase: sl<GetMedicationsUseCase>(),
      scheduleDoseUseCase: sl<ScheduleDoseUseCase>(),
    ),
  );

  sl.registerFactory(
    () => AlarmBloc(
      markDoseTakenUseCase: sl<MarkDoseTakenUseCase>(),
      snoozeDoseUseCase: sl<SnoozeDoseUseCase>(),
      alarmAudioService: sl<AlarmAudioService>(),
      vibrationService: sl<VibrationService>(),
      notificationService: sl<NotificationService>(),
      alarmSchedulerService: sl<AlarmSchedulerService>(),
    ),
  );
}
