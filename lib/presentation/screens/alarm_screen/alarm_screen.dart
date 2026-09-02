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
      canPop: false, // Prevent dismissing by back button without explicit action
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Dark slate focus background
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
                        ),
                      );
                });
              }
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (state is AlarmRinging) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
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
                              size: 72,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            '⏰ حان موعد جرعة العلاج الآن!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      // Medication Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              state.medicationName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'الجرعة المطلوبة: ${state.dosageDescription}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (state.snoozeCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withAlpha(40),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'تم التأجيل مسبقاً (${state.snoozeCount}/${state.maxSnoozeCount}) مرات',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Action Buttons
                      Column(
                        children: [
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
                          const SizedBox(height: 16),
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
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withAlpha(30),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Text(
                                      'وصلت للحد الأقصى للتأجيل (3 مرات)\nيجب أخذ الجرعة الآن للحفاظ على صحتك',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
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
