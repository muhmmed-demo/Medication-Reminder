import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/di/injection_container.dart';
import 'presentation/screens/medications_screen/bloc/medications_bloc.dart';
import 'presentation/screens/add_medication_screen/bloc/add_medication_bloc.dart';
import 'presentation/screens/dose_log_screen/bloc/dose_log_bloc.dart';
import 'presentation/screens/alarm_screen/bloc/alarm_bloc.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class MedicationApp extends StatelessWidget {
  final String initialRoute;
  final Object? initialArguments;

  const MedicationApp({
    super.key,
    this.initialRoute = AppRouter.home,
    this.initialArguments,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MedicationsBloc>(
          create: (_) => sl<MedicationsBloc>(),
        ),
        BlocProvider<AddMedicationBloc>(
          create: (_) => sl<AddMedicationBloc>(),
        ),
        BlocProvider<DoseLogBloc>(
          create: (_) => sl<DoseLogBloc>(),
        ),
        BlocProvider<AlarmBloc>(
          create: (_) => sl<AlarmBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'حارس الدواء',
        navigatorKey: rootNavigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: initialRoute,
        onGenerateInitialRoutes: (String initialRouteName) {
          if (initialRouteName == AppRouter.alarm) {
            return [
              AppRouter.onGenerateRoute(const RouteSettings(name: AppRouter.home))!,
              AppRouter.onGenerateRoute(
                RouteSettings(
                  name: AppRouter.alarm,
                  arguments: initialArguments,
                ),
              )!,
            ];
          }
          return [
            AppRouter.onGenerateRoute(
              RouteSettings(
                name: initialRouteName,
                arguments: initialArguments,
              ),
            )!
          ];
        },
      ),
    );
  }
}
