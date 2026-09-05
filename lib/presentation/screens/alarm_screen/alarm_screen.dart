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
      Navigator.of(context).popUntil((route) => route.isFirst);
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

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        // Header Alarm Icon & Status
                        Container(
                          padding: const EdgeInsets.all(22),
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
                            size: 64,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          '⏰ حان موعد جرعة العلاج الآن!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),

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
                        const SizedBox(height: 20),

                        // Large High-Contrast Medication Details Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFF334155), width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Text(
                                state.medicationName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'الجرعة المطلوبة: ${state.dosageDescription}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),

                              // Real Pill / Box Photo (Elderly Visual Aid)
                              if (hasValidImage) ...[
                                const SizedBox(height: 16),
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
                                      File(state.imagePath!),
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ],

                              if (state.snoozeCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 14),
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
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Giant Elderly-Accessible Action Buttons
                        SizedBox(
                          width: double.infinity,
                          child: AlarmActionButton(
                            label: 'تم أخذ الجرعة الآن ✅',
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF10B981),
                            isPrimary: true,
                            onPressed: () {
                              context.read<AlarmBloc>().add(TakeMedicationEvent());
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
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
}
