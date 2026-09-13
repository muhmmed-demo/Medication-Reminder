import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/dose_schedule.dart';
import '../../domain/enums/repeat_type.dart';

/// دوال مساعدة لتنسيق الوقت وحساب موعد الجرعات
class DoseTimeHelper {
  /// تحويل صيغة 24 ساعة (مثلاً "20:30") إلى صيغة 12 ساعة بالعربية (مثلاً "08:30 م")
  static String formatTimeTo12Hour(String scheduledTime) {
    if (scheduledTime.isEmpty || scheduledTime == 'عند اللزوم') {
      return scheduledTime;
    }
    final parts = scheduledTime.split(':');
    if (parts.length < 2) return scheduledTime;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return scheduledTime;

    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  /// تحويل TimeOfDay إلى صيغة 12 ساعة بالعربية
  static String formatTimeOfDayTo12Hour(TimeOfDay time) {
    final period = time.hour >= 12 ? 'م' : 'ص';
    final displayHour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final displayMinute = time.minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  /// حساب الموعد القادم بدقة لجدول محدد
  static DateTime? getNextOccurrenceForSchedule({
    required DoseSchedule schedule,
    required Medication medication,
    required DateTime now,
  }) {
    if (!schedule.isActive || !medication.isActive) return null;
    if (schedule.scheduledTime == 'عند اللزوم') return null;

    // التحقق من تاريخ انتهاء الدواء
    if (medication.endDate != null) {
      final endOfDay = DateTime(
        medication.endDate!.year,
        medication.endDate!.month,
        medication.endDate!.day,
        23,
        59,
        59,
      );
      if (now.isAfter(endOfDay)) return null;
    }

    // إذا كان تاريخ البدء مستقبلياً، نبدأ الحساب منه
    final baseDate = medication.startDate.isAfter(now)
        ? DateTime(medication.startDate.year, medication.startDate.month, medication.startDate.day, 0, 0, 0)
        : now;

    var candidate = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      schedule.hour,
      schedule.minute,
      0,
    );

    // إذا فات وقت اليوم، الانتقال لليوم التالي
    if (candidate.isBefore(now)) {
      candidate = DateTime(
        candidate.year,
        candidate.month,
        candidate.day + 1,
        schedule.hour,
        schedule.minute,
        0,
      );
    }

    // التعامل مع الأيام المحددة أسبوعياً
    if (schedule.repeatType == RepeatType.specificDays &&
        schedule.repeatDays != null &&
        schedule.repeatDays!.isNotEmpty) {
      int safety = 0;
      while (!schedule.repeatDays!.contains(candidate.weekday) && safety < 8) {
        candidate = DateTime(
          candidate.year,
          candidate.month,
          candidate.day + 1,
          schedule.hour,
          schedule.minute,
          0,
        );
        safety++;
      }
    }

    // التحقق مرة أخرى من تاريخ الانتهاء
    if (medication.endDate != null) {
      final endOfDay = DateTime(
        medication.endDate!.year,
        medication.endDate!.month,
        medication.endDate!.day,
        23,
        59,
        59,
      );
      if (candidate.isAfter(endOfDay)) return null;
    }

    return candidate;
  }

  /// حساب أقرب موعد قادم بين جميع مواعيد الدواء
  static ({DateTime? nextTime, DoseSchedule? schedule}) getNextDose(
    Medication medication,
    List<DoseSchedule> schedules,
    DateTime now,
  ) {
    if (!medication.isActive || medication.isPRN || schedules.isEmpty) {
      return (nextTime: null, schedule: null);
    }

    DateTime? nearestTime;
    DoseSchedule? nearestSchedule;

    for (final s in schedules) {
      final occ = getNextOccurrenceForSchedule(
        schedule: s,
        medication: medication,
        now: now,
      );
      if (occ == null) continue;

      if (nearestTime == null || occ.isBefore(nearestTime)) {
        nearestTime = occ;
        nearestSchedule = s;
      }
    }

    return (nextTime: nearestTime, schedule: nearestSchedule);
  }

  /// حساب موعد قادم لـ TimeOfDay مباشرة
  static DateTime getNextOccurrenceForTimeOfDay(TimeOfDay time, DateTime now) {
    var candidate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      0,
    );
    if (candidate.isBefore(now)) {
      candidate = DateTime(
        candidate.year,
        candidate.month,
        candidate.day + 1,
        time.hour,
        time.minute,
        0,
      );
    }
    return candidate;
  }

  /// تنسيق الفارق الزمني بصيغة رقمية حية
  static String formatDurationDigital(Duration diff) {
    if (diff.isNegative || diff.inSeconds <= 0) {
      return '00:00:00';
    }
    final days = diff.inDays;
    final hours = (diff.inHours % 24).toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    if (days > 0) {
      return '$days يوم و $hours:$minutes:$seconds';
    }
    return '$hours:$minutes:$seconds';
  }
}

/// ويدجت مؤقت العد التنازلي الحي لبطاقة الدواء في شاشة العرض
class DoseCountdownTimerWidget extends StatefulWidget {
  final Medication medication;
  final List<DoseSchedule> schedules;
  final VoidCallback? onTap;

  const DoseCountdownTimerWidget({
    super.key,
    required this.medication,
    required this.schedules,
    this.onTap,
  });

  @override
  State<DoseCountdownTimerWidget> createState() => _DoseCountdownTimerWidgetState();
}

class _DoseCountdownTimerWidgetState extends State<DoseCountdownTimerWidget> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!widget.medication.isActive || widget.medication.isPRN) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant DoseCountdownTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.medication.isActive != widget.medication.isActive ||
        oldWidget.schedules != widget.schedules) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. الدواء متوقف مؤقتاً
    if (!widget.medication.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_circle_outline_rounded, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              'المنبه موقوف مؤقتاً',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // 2. دواء عند اللزوم
    if (widget.medication.isPRN || widget.schedules.isEmpty) {
      return const SizedBox.shrink();
    }

    // 3. حساب أقرب جرعة
    final nextInfo = DoseTimeHelper.getNextDose(widget.medication, widget.schedules, _now);
    final nextTime = nextInfo.nextTime;
    final nextSchedule = nextInfo.schedule;

    if (nextTime == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'انتهت فترة العلاج',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      );
    }

    final diff = nextTime.difference(_now);
    final isDueNow = diff.inSeconds <= 0;
    final isImminent = !isDueNow && diff.inMinutes < 15;

    // ألوان الحالة
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;

    if (isDueNow) {
      bgColor = const Color(0xFF10B981).withAlpha(30);
      borderColor = const Color(0xFF10B981);
      textColor = const Color(0xFF047857);
      icon = Icons.notifications_active_rounded;
    } else if (isImminent) {
      bgColor = Colors.orange.withAlpha(25);
      borderColor = Colors.orange.shade400;
      textColor = Colors.orange.shade900;
      icon = Icons.hourglass_top_rounded;
    } else {
      bgColor = const Color(0xFF0EA5E9).withAlpha(20);
      borderColor = const Color(0xFF0EA5E9).withAlpha(80);
      textColor = const Color(0xFF0284C7);
      icon = Icons.timer_outlined;
    }

    final formattedTime12 = nextSchedule != null
        ? DoseTimeHelper.formatTimeTo12Hour(nextSchedule.scheduledTime)
        : '';
    final digitalTimer = DoseTimeHelper.formatDurationDigital(diff);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
            if (isDueNow) ...[
              Text(
                'حان موعد الجرعة ($formattedTime12) 🔔',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ] else ...[
              Text(
                'باقي: ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  digitalTimer,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (formattedTime12.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  '($formattedTime12)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textColor.withAlpha(200),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// شارة مؤقت العد التنازلي المخصصة لعرض الوقت المتبقي بجانب زر "اختيار الساعة"
class SingleDoseRemainingTimerChip extends StatefulWidget {
  final TimeOfDay time;
  final VoidCallback? onTap;

  const SingleDoseRemainingTimerChip({
    super.key,
    required this.time,
    this.onTap,
  });

  @override
  State<SingleDoseRemainingTimerChip> createState() => _SingleDoseRemainingTimerChipState();
}

class _SingleDoseRemainingTimerChipState extends State<SingleDoseRemainingTimerChip> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant SingleDoseRemainingTimerChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.time != widget.time) {
      setState(() {
        _now = DateTime.now();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextTime = DoseTimeHelper.getNextOccurrenceForTimeOfDay(widget.time, _now);
    final diff = nextTime.difference(_now);
    final isDueNow = diff.inSeconds <= 0;
    final isImminent = !isDueNow && diff.inMinutes < 15;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isDueNow) {
      bgColor = const Color(0xFF10B981).withAlpha(25);
      borderColor = const Color(0xFF10B981);
      textColor = const Color(0xFF047857);
    } else if (isImminent) {
      bgColor = Colors.orange.withAlpha(25);
      borderColor = Colors.orange.shade400;
      textColor = Colors.orange.shade900;
    } else {
      bgColor = const Color(0xFF6366F1).withAlpha(20);
      borderColor = const Color(0xFF6366F1).withAlpha(70);
      textColor = const Color(0xFF4F46E5);
    }

    final digitalTimer = DoseTimeHelper.formatDurationDigital(diff);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDueNow ? Icons.alarm_on_rounded : Icons.hourglass_bottom_rounded,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 4),
            Text(
              isDueNow ? 'الآن' : 'باقي: ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (!isDueNow)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  digitalTimer,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
