import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/dose_log_tile.dart';
import 'bloc/dose_log_bloc.dart';
import 'bloc/dose_log_event.dart';
import 'bloc/dose_log_state.dart';

class DoseLogScreen extends StatefulWidget {
  const DoseLogScreen({super.key});

  @override
  State<DoseLogScreen> createState() => _DoseLogScreenState();
}

class _DoseLogScreenState extends State<DoseLogScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DoseLogBloc>().add(LoadDoseLogsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الالتزام بالجرعات 📋'),
      ),
      body: BlocBuilder<DoseLogBloc, DoseLogState>(
        builder: (context, state) {
          if (state is DoseLogLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DoseLogError) {
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
          } else if (state is DoseLogLoaded) {
            if (state.logs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد جرعات مسجلة حتى الآن',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ستظهر هنا كل الجرعات التي تتفاعل مع منبهاتها',
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
              itemCount: state.logs.length,
              itemBuilder: (context, index) {
                final log = state.logs[index];
                final schedule = state.schedulesMap[log.doseScheduleId];
                final medication =
                    schedule != null ? state.medicationsMap[schedule.medicationId] : null;

                return DoseLogTile(
                  log: log,
                  medicationName: medication?.name,
                  dosageDescription: medication?.dosageDescription,
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
