import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// نموذج بيانات يحمل حالة جميع الأذونات المطلوبة
class PermissionStatusModel {
  final bool notifications;
  final bool exactAlarm;
  final bool batteryOptimization;

  const PermissionStatusModel({
    required this.notifications,
    required this.exactAlarm,
    required this.batteryOptimization,
  });

  /// هل جميع الأذونات مُفعَّلة؟
  bool get allGranted => notifications && exactAlarm && batteryOptimization;

  /// هل الأذونات الحرجة (الإشعارات + المنبه الدقيق) مُفعَّلة؟
  bool get criticalGranted => notifications && exactAlarm;
}

class PermissionService {
  /// طلب جميع أذونات المنبه دفعة واحدة (للاستخدام الداخلي)
  Future<bool> requestAllAlarmPermissions() async {
    try {
      if (!await Permission.notification.isGranted) {
        await Permission.notification.request();
      }

      // SCHEDULE_EXACT_ALARM على Android 12+ لا يُمنح عبر request()
      // يحتاج فتح إعدادات النظام يدوياً
      if (!await Permission.scheduleExactAlarm.isGranted) {
        debugPrint('⚠️ scheduleExactAlarm not granted — opening system settings');
        await openAppSettings();
      }

      if (!await Permission.ignoreBatteryOptimizations.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
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

  /// طلب إذن الإشعارات فقط (للاستخدام في شاشة الإعداد خطوة بخطوة)
  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('⚠️ Notification permission error: $e');
      return false;
    }
  }

  /// فتح إعدادات المنبه الدقيق (Android 12+)
  Future<void> requestExactAlarmPermission() async {
    try {
      final status = await Permission.scheduleExactAlarm.request();
      if (!status.isGranted) {
        // Fallback to general settings if the direct intent fails
        await openAppSettings();
      }
    } catch (e) {
      debugPrint('❌ Could not open exact alarm settings: $e');
      await openAppSettings();
    }
  }

  /// طلب إعفاء تحسين البطارية
  Future<bool> requestBatteryOptimizationExemption() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('⚠️ Battery optimization permission error: $e');
      return false;
    }
  }

  /// يفتح إعدادات الأذونات الدقيقة للمنبهات مباشرةً (Android 12+)
  Future<void> openExactAlarmSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('❌ Could not open exact alarm settings: $e');
    }
  }

  /// فحص حالة الإشعارات فقط
  Future<bool> isNotificationPermissionGranted() async {
    return await Permission.notification.isGranted;
  }

  /// فحص حالة المنبه الدقيق
  Future<bool> isExactAlarmGranted() async {
    return await Permission.scheduleExactAlarm.isGranted ||
        await Permission.scheduleExactAlarm.isLimited;
  }

  /// فحص حالة تحسين البطارية
  Future<bool> isBatteryOptimizationIgnored() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// تقرير شامل لحالة جميع الأذونات — مُرجَع كـ PermissionStatusModel
  Future<PermissionStatusModel> checkAllPermissionsStatus() async {
    final notifications = await Permission.notification.isGranted;
    final exactAlarm = await Permission.scheduleExactAlarm.isGranted ||
        await Permission.scheduleExactAlarm.isLimited;
    final batteryOptimization = await Permission.ignoreBatteryOptimizations.isGranted;

    debugPrint(
      '🔍 Status Check — notifications: $notifications | '
      'exactAlarm: $exactAlarm | battery: $batteryOptimization',
    );

    return PermissionStatusModel(
      notifications: notifications,
      exactAlarm: exactAlarm,
      batteryOptimization: batteryOptimization,
    );
  }

  /// تقرير مبسط بصيغة Map — مفيد للتشخيص
  Future<Map<String, bool>> getPermissionsReport() async {
    return {
      'notifications': await Permission.notification.isGranted,
      'exactAlarm': await Permission.scheduleExactAlarm.isGranted,
      'batteryOptimization': await Permission.ignoreBatteryOptimizations.isGranted,
    };
  }
}
