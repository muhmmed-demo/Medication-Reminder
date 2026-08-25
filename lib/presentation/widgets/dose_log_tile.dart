import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/dose_log.dart';
import '../../domain/enums/dose_status.dart';

class DoseLogTile extends StatelessWidget {
  final DoseLog log;
  final String? medicationName;
  final String? dosageDescription;

  const DoseLogTile({
    super.key,
    required this.log,
    this.medicationName,
    this.dosageDescription,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('hh:mm a', 'ar');
    final dateFormat = DateFormat('yyyy/MM/dd');

    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (log.status) {
      case DoseStatus.taken:
        statusIcon = Icons.check_circle_rounded;
        statusColor = const Color(0xFF10B981);
        statusText = 'تم الأخذ';
        break;
      case DoseStatus.snoozed:
        statusIcon = Icons.snooze_rounded;
        statusColor = const Color(0xFFF59E0B);
        statusText = 'مؤجل (${log.snoozeCount})';
        break;
      case DoseStatus.missed:
        statusIcon = Icons.cancel_rounded;
        statusColor = const Color(0xFFEF4444);
        statusText = 'فاتت الجرعة';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withAlpha(30),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          medicationName ?? 'دواء',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dosageDescription != null)
              Text('الجرعة: $dosageDescription'),
            Text(
              'الموعد: ${timeFormat.format(log.scheduledDateTime)} - ${dateFormat.format(log.scheduledDateTime)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withAlpha(60)),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
