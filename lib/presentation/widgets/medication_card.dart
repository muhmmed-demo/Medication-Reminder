import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/dose_schedule.dart';

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final List<DoseSchedule> schedules;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;
  final VoidCallback? onTakePrnDose;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.schedules,
    this.onDelete,
    this.onToggleActive,
    this.onTakePrnDose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = medication.imagePath != null &&
        medication.imagePath!.isNotEmpty &&
        File(medication.imagePath!).existsSync();
    final isPaused = !medication.isActive;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isPaused ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPaused
            ? BorderSide(color: Colors.grey.shade400, width: 1)
            : BorderSide.none,
      ),
      color: isPaused ? Colors.grey.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(medication.imagePath!),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isPaused
                          ? Colors.grey.shade300
                          : theme.colorScheme.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.medication_rounded,
                      color: isPaused ? Colors.grey.shade600 : theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              medication.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: isPaused ? TextDecoration.lineThrough : null,
                                color: isPaused ? Colors.grey.shade600 : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الجرعة: ${medication.dosageDescription}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isPaused ? Colors.grey.shade500 : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    tooltip: 'حذف الدواء',
                    onPressed: onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Badges wrap
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: medication.isActive
                        ? const Color(0xFF10B981).withAlpha(30)
                        : Colors.amber.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: medication.isActive
                          ? const Color(0xFF10B981)
                          : Colors.amber.shade700,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    medication.isActive ? 'مفعل 🟢' : 'موقوف مؤقتاً ⏸️',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: medication.isActive
                          ? const Color(0xFF059669)
                          : Colors.amber.shade900,
                    ),
                  ),
                ),
                // PRN badge
                if (medication.isPRN)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.purple.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.purple.shade300),
                    ),
                    child: const Text(
                      'عند اللزوم / مسكن 💊',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                // Inventory badge
                if (medication.inventoryCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                // Meal timing badge
                if (medication.mealTiming != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(25),
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

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // PRN Quick Action Button vs Regular Schedules
            if (medication.isPRN) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'دواء مسكن يؤخذ عند الشعور بالحاجة أو الألم',
                      style: TextStyle(fontSize: 13, color: Colors.purple),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: onTakePrnDose,
                        icon: const Icon(Icons.check_circle_rounded, size: 22),
                        label: const Text(
                          'أخذ جرعة الآن 💊',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
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
                            color: isPaused
                                ? Colors.grey.shade200
                                : theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.scheduledTime,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isPaused
                                  ? Colors.grey.shade600
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],

            // Active / Pause Switch row
            if (onToggleActive != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    medication.isActive ? 'إيقاف المنبه مؤقتاً' : 'إعادة تفعيل المنبه',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: medication.isActive ? Colors.grey.shade700 : Colors.teal.shade700,
                    ),
                  ),
                  Switch.adaptive(
                    value: medication.isActive,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (_) => onToggleActive?.call(),
                  ),
                ],
              ),
            ],

            if (medication.notes != null && medication.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
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
