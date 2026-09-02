import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestAllAlarmPermissions() async {
    try {
      // 1. Notification Permission (Android 13+)
      if (!await Permission.notification.isGranted) {
        await Permission.notification.request();
      }

      // 2. Exact Alarm Permission (Android 12+)
      if (!await Permission.scheduleExactAlarm.isGranted) {
        await Permission.scheduleExactAlarm.request();
      }

      // 3. Request exemption from Battery Optimizations (if not yet ignored)
      if (!await Permission.ignoreBatteryOptimizations.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (_) {
      // Ignore unsupported permission errors on older Android versions or OEM variants
    }

    final notif = await Permission.notification.isGranted;
    final exact = await Permission.scheduleExactAlarm.isGranted ||
        await Permission.scheduleExactAlarm.isLimited;

    return notif && exact;
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
