import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/medication_card.dart';
import 'bloc/medications_bloc.dart';
import 'bloc/medications_event.dart';
import 'bloc/medications_state.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('أدويتي 💊'),
        actions: [
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
      body: BlocBuilder<MedicationsBloc, MedicationsState>(
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
    );
  }
}
