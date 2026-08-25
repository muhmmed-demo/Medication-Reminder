import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/medication.dart';
import '../../../../domain/entities/dose_schedule.dart';
import '../../../../domain/enums/repeat_type.dart';
import 'bloc/add_medication_bloc.dart';
import 'bloc/add_medication_event.dart';
import 'bloc/add_medication_state.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController(text: 'قرص واحد');
  final _notesController = TextEditingController();

  int _timesPerDay = 1;
  bool _isContinuous = true;
  DateTime? _endDate;
  List<TimeOfDay> _scheduleTimes = [const TimeOfDay(hour: 8, minute: 0)];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateTimesPerDay(int count) {
    setState(() {
      _timesPerDay = count;
      _scheduleTimes = _generateDefaultTimes(count);
    });
  }

  List<TimeOfDay> _generateDefaultTimes(int count) {
    if (count == 1) {
      return [const TimeOfDay(hour: 8, minute: 0)];
    } else if (count == 2) {
      return [
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 20, minute: 0),
      ];
    } else if (count == 3) {
      return [
        const TimeOfDay(hour: 8, minute: 0),
        const TimeOfDay(hour: 16, minute: 0),
        const TimeOfDay(hour: 0, minute: 0),
      ];
    } else {
      final interval = 24 ~/ count;
      return List.generate(
        count,
        (i) => TimeOfDay(hour: (8 + i * interval) % 24, minute: 0),
      );
    }
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduleTimes[index],
    );
    if (picked != null) {
      setState(() {
        _scheduleTimes[index] = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final now = DateTime.now();
      final med = Medication(
        name: _nameController.text.trim(),
        dosageDescription: _dosageController.text.trim(),
        timesPerDay: _timesPerDay,
        startDate: now,
        endDate: _isContinuous ? null : _endDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: now,
      );

      final schedules = _scheduleTimes.map((t) {
        return DoseSchedule(
          medicationId: 0, // Assigned by repository
          scheduledTime: _formatTimeOfDay(t),
          repeatType: RepeatType.daily,
        );
      }).toList();

      context.read<AddMedicationBloc>().add(
            SaveMedicationEvent(medication: med, schedules: schedules),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة دواء جديد'),
      ),
      body: BlocListener<AddMedicationBloc, AddMedicationState>(
        listener: (context, state) {
          if (state is AddMedicationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تمت جدولة الدواء والمنبهات بنجاح ✅')),
            );
            Navigator.pop(context, true);
          } else if (state is AddMedicationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بيانات الدواء الأساسية',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الدواء *',
                    hintText: 'مثلاً: كونكور 5 ملغ',
                    prefixIcon: Icon(Icons.medication_rounded),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'الرجاء إدخال اسم الدواء' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dosageController,
                  decoration: const InputDecoration(
                    labelText: 'الجرعة *',
                    hintText: 'مثلاً: قرص واحد، 5 مل',
                    prefixIcon: Icon(Icons.colorize_rounded),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'الرجاء إدخال وصف الجرعة' : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'عدد مرات الاستخدام يومياً',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [1, 2, 3, 4].map((count) {
                    final isSelected = _timesPerDay == count;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              '$count مرة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : null,
                              ),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          onSelected: (selected) {
                            if (selected) _updateTimesPerDay(count);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'مواعيد التنبيه (انقر لتعديل أي وقت)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_scheduleTimes.length, (i) {
                    final time = _scheduleTimes[i];
                    return ActionChip(
                      avatar: const Icon(Icons.access_alarm_rounded, size: 18),
                      label: Text(
                        'الجرعة ${i + 1}: ${_formatTimeOfDay(time)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _pickTime(i),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Text(
                  'مدة العلاج',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SwitchListTile(
                  title: const Text('علاج مستمر (بدون نهاية)'),
                  value: _isContinuous,
                  onChanged: (val) {
                    setState(() {
                      _isContinuous = val;
                      if (!val && _endDate == null) {
                        _endDate = DateTime.now().add(const Duration(days: 7));
                      }
                    });
                  },
                ),
                if (!_isContinuous) ...[
                  ListTile(
                    title: const Text('تاريخ انتهاء العلاج:'),
                    subtitle: Text(_endDate != null
                        ? '${_endDate!.year}/${_endDate!.month}/${_endDate!.day}'
                        : 'اختر تاريخاً'),
                    trailing: const Icon(Icons.calendar_month_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات إضافية (اختياري)',
                    hintText: 'مثلاً: يؤخذ بعد الأكل مباشرة مع كوب ماء',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 32),
                BlocBuilder<AddMedicationBloc, AddMedicationState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state is AddMedicationSaving ? null : _onSave,
                      child: state is AddMedicationSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('حفظ وجدولة المنبهات ⏰'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
