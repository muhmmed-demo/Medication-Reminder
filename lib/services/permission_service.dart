import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestAllAlarmPermissions() async {
    // 1. Notification Permission (Android 13+)
    final notificationStatus = await Permission.notification.request();

    // 2. Exact Alarm Permission (Android 12+)
    final exactAlarmStatus = await Permission.scheduleExactAlarm.request();

    // 3. System Alert Window / Overlay (for displaying full-screen UI)
    final systemAlertStatus = await Permission.systemAlertWindow.request();

    // 4. Request exemption from Battery Optimizations
    final batteryOptStatus = await Permission.ignoreBatteryOptimizations.request();

    return notificationStatus.isGranted &&
        (exactAlarmStatus.isGranted || exactAlarmStatus.isLimited);
  }

  Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  Future<bool> isExactAlarmGranted() async {
    return await Permission.scheduleExactAlarm.isGranted;
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }
}
