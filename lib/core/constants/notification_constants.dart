class NotificationConstants {
  static const String alarmChannelId = 'medication_alarm_channel_v3';
  static const String alarmChannelName = 'تنبيهات الأدوية العاجلة';
  static const String alarmChannelDescription =
      'منبهات عالية الأولوية لشاشة القفل تضمن عدم تفويت الجرعة';

  static const String systemSoundChannelId = 'medication_system_alarm_channel_v3';
  static const String systemSoundChannelName = 'تنبيهات بصوت النظام';
  static const String systemSoundChannelDescription =
      'منبهات عالية الأولوية باستخدام نغمة النظام الافتراضية';

  /// قناة التذكيرات الخفيفة — للإشعارات غير الحرجة (معلومات، تذكيرات)
  static const String reminderChannelId = 'medication_reminder_channel_v1';
  static const String reminderChannelName = 'تذكيرات معلومات';
  static const String reminderChannelDescription =
      'إشعارات خفيفة للمعلومات والتذكيرات غير العاجلة';
}
