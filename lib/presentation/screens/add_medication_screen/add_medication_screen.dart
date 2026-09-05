import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
  final _inventoryController = TextEditingController();

  int _timesPerDay = 1;
  bool _isContinuous = true;
  DateTime? _endDate;
  List<TimeOfDay> _scheduleTimes = [const TimeOfDay(hour: 8, minute: 0)];
  
  // Phase 1 advanced options
  bool _trackInventory = false;
  String _mealTiming = 'none'; // 'none', 'before', 'after', 'with'
  RepeatType _repeatType = RepeatType.daily;
  final List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];

  // Phase 2: Pill / Box image for elderly visual identification
  String? _imagePath;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'med_${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
        final saved = await File(picked.path).copy('${appDir.path}/$fileName');
        setState(() {
          _imagePath = saved.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    _inventoryController.dispose();
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
      if (!_isContinuous && _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تحديد تاريخ انتهاء العلاج'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_repeatType == RepeatType.specificDays && _selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء اختيار يوم واحد على الأقل في الأسبوع'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final now = DateTime.now();
      final inventory = _trackInventory ? int.tryParse(_inventoryController.text.trim()) : null;

      final med = Medication(
        name: _nameController.text.trim(),
        dosageDescription: _dosageController.text.trim(),
        timesPerDay: _timesPerDay,
        startDate: now,
        endDate: _isContinuous ? null : _endDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: now,
        inventoryCount: inventory,
        refillThreshold: inventory != null ? 3 : null,
        mealTiming: _mealTiming == 'none' ? null : _mealTiming,
        imagePath: _imagePath,
      );

      final schedules = _scheduleTimes.map((t) {
        return DoseSchedule(
          medicationId: 0, // Assigned by repository
          scheduledTime: _formatTimeOfDay(t),
          repeatType: _repeatType,
          repeatDays: _repeatType == RepeatType.specificDays ? List.from(_selectedDays) : null,
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
                const SizedBox(height: 20),

                // Phase 2: Medication / Box Picture for Elderly
                Text(
                  'صورة علبة الدواء أو الحبة 📸 (مخصص لكبار السن)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                if (_imagePath != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_imagePath!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withAlpha(160),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            tooltip: 'حذف الصورة',
                            onPressed: () => setState(() => _imagePath = null),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withAlpha(60),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'تساعد الصورة كبار السن على التعرف على الدواء الصحيح فوراً وقت الرنين',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.camera_alt_rounded),
                                label: const Text('تصوير بالكاميرا'),
                                onPressed: () => _pickImage(ImageSource.camera),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.photo_library_rounded),
                                label: const Text('من المعرض'),
                                onPressed: () => _pickImage(ImageSource.gallery),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                const SizedBox(height: 24),
                Text(
                  'التكرار وأيام الجرعات',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('يومياً')),
                        selected: _repeatType == RepeatType.daily,
                        selectedColor: theme.colorScheme.primary,
                        onSelected: (val) {
                          if (val) setState(() => _repeatType = RepeatType.daily);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('أيام محددة')),
                        selected: _repeatType == RepeatType.specificDays,
                        selectedColor: theme.colorScheme.primary,
                        onSelected: (val) {
                          if (val) setState(() => _repeatType = RepeatType.specificDays);
                        },
                      ),
                    ),
                  ],
                ),
                if (_repeatType == RepeatType.specificDays) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      {'name': 'السبت', 'day': 6},
                      {'name': 'الأحد', 'day': 7},
                      {'name': 'الإثنين', 'day': 1},
                      {'name': 'الثلاثاء', 'day': 2},
                      {'name': 'الأربعاء', 'day': 3},
                      {'name': 'الخميس', 'day': 4},
                      {'name': 'الجمعة', 'day': 5},
                    ].map((d) {
                      final dayNum = d['day'] as int;
                      final isSelected = _selectedDays.contains(dayNum);
                      return FilterChip(
                        label: Text(d['name'] as String),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDays.add(dayNum);
                            } else {
                              _selectedDays.remove(dayNum);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'الارتباط بالطعام',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    {'label': 'غير مرتبط', 'val': 'none'},
                    {'label': 'قبل الأكل 🍽️', 'val': 'before'},
                    {'label': 'بعد الأكل 🥣', 'val': 'after'},
                    {'label': 'مع الأكل 🥪', 'val': 'with'},
                  ].map((m) {
                    final val = m['val'] as String;
                    final isSel = _mealTiming == val;
                    return ChoiceChip(
                      label: Text(m['label'] as String),
                      selected: isSel,
                      onSelected: (selected) {
                        if (selected) setState(() => _mealTiming = val);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'إدارة المخزون والتنبيه بالنفاد',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SwitchListTile(
                  title: const Text('تتبع عدد الحبات المتبقية'),
                  subtitle: const Text('سيتم خصم حبة مع كل جرعة وتنبيهك قبل النفاد'),
                  value: _trackInventory,
                  onChanged: (val) {
                    setState(() => _trackInventory = val);
                  },
                ),
                if (_trackInventory) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _inventoryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'إجمالي الحبات المتوفرة حالياً *',
                      hintText: 'مثلاً: 20 أو 30',
                      prefixIcon: Icon(Icons.inventory_2_rounded),
                    ),
                    validator: (v) {
                      if (!_trackInventory) return null;
                      if (v == null || v.trim().isEmpty) return 'الرجاء إدخال عدد الحبات';
                      if (int.tryParse(v.trim()) == null) return 'أدخل رقماً صحيحاً';
                      return null;
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
