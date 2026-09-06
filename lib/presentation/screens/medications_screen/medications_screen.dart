import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/medication_card.dart';
import '../../widgets/permission_status_card.dart';
import 'bloc/medications_bloc.dart';
import 'bloc/medications_event.dart';
import 'bloc/medications_state.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/router/app_router.dart';
import '../../../services/notification_service.dart';
import '../../../services/permission_service.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MedicationsBloc>().add(LoadMedicationsEvent());

    // طلب أذونات الإشعارات عبر شاشة الإعداد الجديدة إذا لم تكن مُفعَّلة
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndPromptPermissions();
    });
  }

  Future<void> _checkAndPromptPermissions() async {
    if (!mounted) return;
    // نتحقق أولاً — نفتح شاشة الإعداد فقط إذا كانت الأذونات الحرجة ناقصة
    final permService = sl<PermissionService>();
    final status = await permService.checkAllPermissionsStatus();
    if (!status.criticalGranted && mounted) {
      await Navigator.pushNamed(context, AppRouter.notificationSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.medication_rounded),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'حارس الدواء',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          // زر إعداد الإشعارات في الـ AppBar
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'إعداد التنبيهات',
            onPressed: () async {
              await Navigator.pushNamed(context, AppRouter.notificationSetup);
              // إعادة تحميل حالة البطاقة بعد العودة
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'سجل الجرعات',
            onPressed: () {
              Navigator.pushNamed(context, '/dose_log');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_medication');
          if (result == true && mounted) {
            context.read<MedicationsBloc>().add(LoadMedicationsEvent());
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة دواء'),
      ),
      body: Column(
        children: [
          // ═══ بطاقة حالة الأذونات الذكية ═══
          // تظهر فقط إذا كانت الأذونات الحرجة غير مُفعَّلة
          PermissionStatusCard(
            onFixPressed: () async {
              await Navigator.pushNamed(context, AppRouter.notificationSetup);
              setState(() {});
            },
          ),

          // ═══ زر اختبار المنبه الكبير ═══
          _buildTestAlarmBanner(context),

          Expanded(
            child: BlocBuilder<MedicationsBloc, MedicationsState>(
              builder: (context, state) {
                if (state is MedicationsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is MedicationsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                } else if (state is MedicationsLoaded) {
                  if (state.medications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_liquid_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد أدوية مضافة حالياً',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط على زر الإضافة بالأسفل لجدولة جرعاتك',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: state.medications.length,
                    itemBuilder: (context, index) {
                      final med = state.medications[index];
                      final schedules = state.schedulesMap[med.id] ?? [];

                      return MedicationCard(
                        medication: med,
                        schedules: schedules,
                        onToggleActive: () {
                          context.read<MedicationsBloc>().add(ToggleMedicationActiveEvent(med));
                        },
                        onTakePrnDose: () {
                          if (med.id != null) {
                            context.read<MedicationsBloc>().add(RecordPrnDoseEvent(med.id!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم تسجيل أخذ جرعة من "${med.name}" بنجاح ✅'),
                                backgroundColor: const Color(0xFF10B981),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        onDelete: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: const Text('تأكيد الحذف'),
                              content: Text('هل تريد بالتأكيد حذف دواء "${med.name}"؟'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    if (med.id != null) {
                                      context
                                          .read<MedicationsBloc>()
                                          .add(DeleteMedicationEvent(med.id!));
                                    }
                                  },
                                  child: const Text('حذف',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// زر اختبار المنبه — واضح وكبير لكبار السن
  Widget _buildTestAlarmBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await sl<NotificationService>().showTestNotification();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔔 تم إرسال إشعار تجريبي — تأكد من وصول التنبيه!'),
                  backgroundColor: Color(0xFF2563EB),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.volume_up_rounded, color: Colors.white, size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختبر المنبه الآن 🔔',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'اضغط للتأكد من أن التنبيهات تصلك',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
