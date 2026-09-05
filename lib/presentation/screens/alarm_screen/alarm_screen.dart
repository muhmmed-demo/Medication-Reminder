import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/alarm_action_button.dart';
import 'bloc/alarm_bloc.dart';
import 'bloc/alarm_event.dart';
import 'bloc/alarm_state.dart';

class AlarmScreen extends StatelessWidget {
  final Map<String, dynamic>? initialPayload;

  const AlarmScreen({super.key, this.initialPayload});

  void _closeScreen(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent dismissing by back button without explicit user action
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Full-screen dark slate focus background
        body: BlocConsumer<AlarmBloc, AlarmState>(
          listener: (context, state) {
            if (state is AlarmTakenSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('أحسنت! تم تسجيل أخذ الجرعة ✅'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
              _closeScreen(context);
            } else if (state is AlarmSkippedSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تخطي الجرعة وتسجيلها في السجل ⏭️'),
                  backgroundColor: Color(0xFF64748B),
                ),
              );
              _closeScreen(context);
            } else if (state is AlarmSnoozedSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم تأجيل المنبه ${state.nextSnoozeMinutes} دقائق ⏰',
                  ),
                  backgroundColor: const Color(0xFFF59E0B),
                ),
              );
              _closeScreen(context);
            }
          },
          builder: (context, state) {
            if (state is AlarmInitial) {
              if (initialPayload != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  List<Map<String, dynamic>>? extraMeds;
                  final rawExtra = initialPayload!['extraMedications'];
                  if (rawExtra is List) {
                    extraMeds = rawExtra
                        .map((item) => Map<String, dynamic>.from(item as Map))
                        .toList();
                  }

                  context.read<AlarmBloc>().add(
                        StartAlarmEvent(
                          medicationId: initialPayload!['medicationId'] as int? ?? 0,
                          doseScheduleId: initialPayload!['doseScheduleId'] as int? ?? 0,
                          medicationName: initialPayload!['medicationName'] as String? ?? 'دواء',
                          dosageDescription: initialPayload!['dosageDescription'] as String? ?? '',
                          scheduledDateTime: DateTime.tryParse(
                                  initialPayload!['scheduledDateTime'] as String? ?? '') ??
                              DateTime.now(),
                          snoozeCount: initialPayload!['snoozeCount'] as int? ?? 0,
                          useCustomSound: initialPayload!['useCustomSound'] as bool? ?? true,
                          imagePath: initialPayload!['imagePath'] as String?,
                          extraMedications: extraMeds,
                        ),
                      );
                });
              }
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (state is AlarmRinging) {
              final hasValidImage = state.imagePath != null &&
                  state.imagePath!.isNotEmpty &&
                  File(state.imagePath!).existsSync();

              final hasMultipleMeds =
                  state.extraMedications != null && state.extraMedications!.isNotEmpty;

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        // Header Alarm Icon & Status
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEF4444).withAlpha(40),
                            border: Border.all(
                              color: const Color(0xFFEF4444),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.alarm_on_rounded,
                            size: 60,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasMultipleMeds
                              ? '⏰ حان موعد أدويتك (${state.extraMedications!.length + 1} أدوية)!'
                              : '⏰ حان موعد جرعة العلاج الآن!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Arabic Voice Announcement Badge (Elderly Assistance)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF38BDF8).withAlpha(100)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.volume_up_rounded, color: Color(0xFF38BDF8), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'يتم نطق اسم الدواء بصوت واضح 🗣️',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Primary Medication Card
                        _buildMedicationCard(
                          name: state.medicationName,
                          dosage: state.dosageDescription,
                          imagePath: state.imagePath,
                          hasValidImage: hasValidImage,
                        ),

                        // If multiple medications share this exact time, display each one!
                        if (hasMultipleMeds) ...[
                          const SizedBox(height: 12),
                          for (final extra in state.extraMedications!) ...[
                            _buildMedicationCard(
                              name: extra['medicationName'] as String? ?? '',
                              dosage: extra['dosageDescription'] as String? ?? '',
                              imagePath: extra['imagePath'] as String?,
                              hasValidImage: extra['imagePath'] != null &&
                                  (extra['imagePath'] as String).isNotEmpty &&
                                  File(extra['imagePath'] as String).existsSync(),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],

                        if (state.snoozeCount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'تم التأجيل مسبقاً (${state.snoozeCount}/${state.maxSnoozeCount}) مرات',
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Giant Elderly-Accessible Action Buttons
                        SizedBox(
                          width: double.infinity,
                          child: AlarmActionButton(
                            label: hasMultipleMeds
                                ? 'تم أخذ جميع الأدوية الآن ✅'
                                : 'تم أخذ الجرعة الآن ✅',
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF10B981),
                            isPrimary: true,
                            onPressed: () {
                              context.read<AlarmBloc>().add(TakeMedicationEvent());
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: state.canSnooze
                              ? AlarmActionButton(
                                  label: 'تأجيل 10 دقائق ⏰ (${state.snoozeCount}/${state.maxSnoozeCount})',
                                  icon: Icons.snooze_rounded,
                                  color: const Color(0xFF475569),
                                  onPressed: () {
                                    context.read<AlarmBloc>().add(SnoozeMedicationEvent());
                                  },
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(30),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.redAccent.withAlpha(60)),
                                  ),
                                  child: const Text(
                                    'وصلت للحد الأقصى للتأجيل (3 مرات)\nيجب أخذ الجرعة الآن للحفاظ على صحتك',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),

                        // Skip Dose Action (Safe Medical Dismissal)
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade400,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.skip_next_rounded, size: 22),
                            label: const Text(
                              'تخطي هذه الجرعة (للصيام أو استشارة الطبيب) ⏭️',
                              style: TextStyle(fontSize: 14),
                            ),
                            onPressed: () {
                              _confirmSkipDose(context);
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildMedicationCard({
    required String name,
    required String dosage,
    String? imagePath,
    required bool hasValidImage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF38BDF8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'الجرعة المطلوبة: $dosage',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE2E8F0),
            ),
          ),
          if (hasValidImage && imagePath != null) ...[
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(imagePath),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmSkipDose(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تأكيد تخطي الجرعة', style: TextStyle(color: Colors.white)),
        content: const Text(
          'هل تريد بالتأكيد تخطي هذه الجرعة؟ سيتم تسجيلها كجرعة فائتة في السجل الطبي ولن يتم خصمها من المخزون.',
          style: TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AlarmBloc>().add(SkipMedicationEvent());
            },
            child: const Text('تخطي الآن', style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }
}
