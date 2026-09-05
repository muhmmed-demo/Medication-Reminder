import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/medication_card.dart';
import 'bloc/medications_bloc.dart';
import 'bloc/medications_event.dart';
import 'bloc/medications_state.dart';

import '../../../core/di/injection_container.dart';
import '../../../services/permission_service.dart';
import '../../../services/notification_service.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  bool _showOemWarning = false;
  String _deviceManufacturer = '';

  @override
  void initState() {
    super.initState();
    context.read<MedicationsBloc>().add(LoadMedicationsEvent());

    // Request permissions and check for aggressive OEM battery killer devices
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await sl<NotificationService>().requestPermissions();
      await sl<PermissionService>().requestAllAlarmPermissions();
      await _checkOemDevice();
    });
  }

  Future<void> _checkOemDevice() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final m = androidInfo.manufacturer.toLowerCase();
      _deviceManufacturer = androidInfo.manufacturer;

      if (m.contains('xiaomi') ||
          m.contains('redmi') ||
          m.contains('poco') ||
          m.contains('huawei') ||
          m.contains('honor') ||
          m.contains('oppo') ||
          m.contains('vivo') ||
          m.contains('samsung') ||
          m.contains('realme')) {
        final isIgnored = await sl<PermissionService>().isBatteryOptimizationIgnored();
        if (!isIgnored && mounted) {
          setState(() {
            _showOemWarning = true;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('أدويتي 💊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'تجربة الإشعار',
            onPressed: () async {
              await sl<NotificationService>().showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال إشعار تجريبي 🔔')),
                );
              }
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
          // OEM Battery Optimization Alert Banner (Xiaomi, Samsung, Huawei, etc.)
          if (_showOemWarning)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.battery_alert_rounded, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تنبيه مهم لجهازك ($_deviceManufacturer)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'لضمان استيقاظ المنبه على شاشة القفل دون أن يوقفه نظام توفير الطاقة، يرجى السماح بالتطبيق في الخلفية.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            await openAppSettings();
                          },
                          child: const Text('فتح الإعدادات وضبط البطارية ⚙️',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => setState(() => _showOemWarning = false),
                  ),
                ],
              ),
            ),

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
                                  child: const Text('حذف', style: TextStyle(color: Colors.red)),
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
}
