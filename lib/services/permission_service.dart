import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestAllAlarmPermissions() async {
    try {
      // 1. إذن الإشعارات (Android 13+) — يعمل بشكل طبيعي عبر request()
      if (!await Permission.notification.isGranted) {
        await Permission.notification.request();
      }

      // 2. BUGFIX: SCHEDULE_EXACT_ALARM على Android 12+ لا يُمنح عبر request()
      // بل يحتاج فتح إعدادات النظام يدوياً
      // نتحقق فقط من حالته هنا، وإذا لم يُمنح نفتح الإعدادات
      if (!await Permission.scheduleExactAlarm.isGranted) {
        debugPrint('⚠️ scheduleExactAlarm not granted — opening system settings');
        await openAppSettings();
      }

      // 3. إعفاء من تحسين البطارية
      if (!await Permission.ignoreBatteryOptimizations.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      // تجاهل أخطاء الأذونات غير المدعومة على إصدارات Android الأقدم
      debugPrint('⚠️ Permission request error: $e');
    }

    final notif = await Permission.notification.isGranted;
    final exact = await Permission.scheduleExactAlarm.isGranted ||
        await Permission.scheduleExactAlarm.isLimited;

    debugPrint(
      '🔐 Permissions — notifications: $notif | exactAlarm: $exact | '
      'batteryOptimization: ${await Permission.ignoreBatteryOptimizations.isGranted}',
    );

    return notif && exact;
  }

  /// يفتح إعدادات الأذونات الدقيقة للمنبهات مباشرةً (Android 12+)
  Future<void> openExactAlarmSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('❌ Could not open exact alarm settings: $e');
    }
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

  /// تقرير شامل بحالة جميع الأذونات — مفيد للتشخيص
  Future<Map<String, bool>> getPermissionsReport() async {
    return {
      'notifications': await Permission.notification.isGranted,
      'exactAlarm': await Permission.scheduleExactAlarm.isGranted,
      'batteryOptimization': await Permission.ignoreBatteryOptimizations.isGranted,
    };
  }
}
