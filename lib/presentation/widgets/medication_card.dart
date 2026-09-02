import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/dose_schedule.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final List<DoseSchedule> schedules;
  final VoidCallback? onDelete;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.schedules,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medication_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الجرعة: ${medication.dosageDescription}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (medication.inventoryCount != null || medication.mealTiming != null) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (medication.inventoryCount != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (medication.inventoryCount! <= 3)
                                      ? Colors.red.withAlpha(30)
                                      : Colors.blue.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (medication.inventoryCount! <= 3)
                                        ? Colors.redAccent
                                        : Colors.blueAccent.withAlpha(100),
                                  ),
                                ),
                                child: Text(
                                  'المتبقي: ${medication.inventoryCount} حبة',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: (medication.inventoryCount! <= 3)
                                        ? Colors.redAccent
                                        : Colors.blueAccent,
                                  ),
                                ),
                              ),
                            if (medication.mealTiming != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  medication.mealTiming == 'before'
                                      ? 'قبل الأكل 🍽️'
                                      : medication.mealTiming == 'after'
                                          ? 'بعد الأكل 🥣'
                                          : 'مع الأكل 🥪',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'المواعيد (${schedules.length}): ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: schedules.map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.scheduledTime,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            if (medication.notes != null && medication.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'ملاحظات: ${medication.notes}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
