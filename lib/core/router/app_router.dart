import 'package:flutter/material.dart';
import '../../presentation/screens/medications_screen/medications_screen.dart';
import '../../presentation/screens/add_medication_screen/add_medication_screen.dart';
import '../../presentation/screens/dose_log_screen/dose_log_screen.dart';
import '../../presentation/screens/alarm_screen/alarm_screen.dart';
import '../../presentation/screens/notification_setup/notification_setup_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String addMedication = '/add_medication';
  static const String doseLog = '/dose_log';
  static const String alarm = '/alarm';
  static const String notificationSetup = '/notification_setup';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const MedicationsScreen());
      case addMedication:
        return MaterialPageRoute(builder: (_) => const AddMedicationScreen());
      case doseLog:
        return MaterialPageRoute(builder: (_) => const DoseLogScreen());
      case alarm:
        final payload = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => AlarmScreen(initialPayload: payload),
        );
      case notificationSetup:
        return MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const NotificationSetupScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('صفحة غير موجودة: ${settings.name}')),
          ),
        );
    }
  }
}
