import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/attendance_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../../data/models/user_model.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  DateTime selectedDate = DateTime.now();
  Map<String, Map<String, dynamic>> attendanceData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<AttendanceController>();
      controller.loadPersonnel().then((_) {
        controller.loadAttendances().then((_) {
          _loadAttendanceForDate();
        });
      });
    });
  }

  void _loadAttendanceForDate() {
    final controller = context.read<AttendanceController>();
    final existingAttendances = controller.getAttendancesByDate(selectedDate);

    // Sadece yeni personeller için boş kayıt oluştur, mevcutları koru
    for (var personnel in controller.personnel) {
      // Eğer bu personel için zaten veri varsa, dokunma
      if (attendanceData.containsKey(personnel.id)) {
        continue;
      }

      // Sadece yeni personeller için veritabanından yükle
      final existingAttendance = existingAttendances
          .where((a) => a.personnelId == personnel.id)
          .firstOrNull;

      attendanceData[personnel.id] = {
        'isPresent': existingAttendance?.isPresent ?? false,
        'workHours': existingAttendance?.workHours ?? 0.0,
        'notes': existingAttendance?.notes ?? '',
      };
    }
    setState(() {});
  }

  void _loadAttendanceForDateOnDateChange() {
    final controller = context.read<AttendanceController>();
    final existingAttendances = controller.getAttendancesByDate(selectedDate);

    // Tarih değiştiğinde tamamen yeniden yükle
    attendanceData.clear();
    for (var personnel in controller.personnel) {
      final existingAttendance = existingAttendances
          .where((a) => a.personnelId == personnel.id)
          .firstOrNull;

      attendanceData[personnel.id] = {
        'isPresent': existingAttendance?.isPresent ?? false,
        'workHours': existingAttendance?.workHours ?? 0.0,
        'notes': existingAttendance?.notes ?? '',
      };
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puantaj'),
        actions: [
          IconButton(
            onPressed: _saveAttendances,
            icon: const Icon(Icons.save),
            tooltip: 'Kaydet',
          ),
        ],
      ),
      body: Consumer<AttendanceController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.personnel.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Hata: ${controller.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadPersonnel(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (controller.personnel.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz personel eklenmemiş'),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Tarih seçici
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tarih: ${DateFormat('dd MMMM yyyy', 'tr').format(selectedDate)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Tarih Seç'),
                      ),
                    ],
                  ),
                ),
              ),

              // Puantaj listesi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.personnel.length,
                  itemBuilder: (context, index) {
                    final personnel = controller.personnel[index];
                    final attendance = attendanceData[personnel.id] ??
                        {'isPresent': false, 'workHours': 0.0, 'notes': ''};

                    return AttendanceCard(
                      key: ValueKey(
                          '${personnel.id}_${selectedDate.toString()}'),
                      personnel: personnel,
                      isPresent: attendance['isPresent'],
                      workHours: attendance['workHours'],
                      notes: attendance['notes'],
                      onChanged: (isPresent, workHours, notes) {
                        setState(() {
                          attendanceData[personnel.id] = {
                            'isPresent': isPresent,
                            'workHours': workHours,
                            'notes': notes,
                          };
                        });
                      },
                    );
                  },
                ),
              ),

              // Kaydet butonu
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  onPressed: controller.isLoading ? null : _saveAttendances,
                  text: 'Puantajları Kaydet',
                  isLoading: controller.isLoading,
                  icon: Icons.save,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadAttendanceForDateOnDateChange(); // Tarih değiştiğinde farklı metod çağır
    }
  }

  Future<void> _saveAttendances() async {
    final controller = context.read<AttendanceController>();
    final success = await controller.saveAttendances(
      selectedDate,
      attendanceData,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Puantajlar başarıyla kaydedildi'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Kayıt başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class AttendanceCard extends StatefulWidget {
  final PersonnelModel personnel;
  final bool isPresent;
  final double workHours;
  final String notes;
  final Function(bool isPresent, double workHours, String notes) onChanged;

  const AttendanceCard({
    super.key,
    required this.personnel,
    required this.isPresent,
    required this.workHours,
    required this.notes,
    required this.onChanged,
  });

  @override
  State<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<AttendanceCard> {
  late bool isPresent;
  late TextEditingController workHoursController;
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    isPresent = widget.isPresent;
    workHoursController = TextEditingController(
      text: widget.workHours > 0 ? widget.workHours.toString() : '',
    );
    notesController = TextEditingController(text: widget.notes);

    // Listener'ları ekle
    workHoursController.addListener(_updateAttendance);
    notesController.addListener(_updateAttendance);
  }

  @override
  void didUpdateWidget(AttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Widget güncellendiğinde değerleri güncelle
    if (oldWidget.isPresent != widget.isPresent) {
      isPresent = widget.isPresent;
    }
    if (oldWidget.workHours != widget.workHours) {
      workHoursController.text =
          widget.workHours > 0 ? widget.workHours.toString() : '';
    }
    if (oldWidget.notes != widget.notes) {
      notesController.text = widget.notes;
    }
  }

  @override
  void dispose() {
    workHoursController.removeListener(_updateAttendance);
    notesController.removeListener(_updateAttendance);
    workHoursController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _updateAttendance() {
    final workHours = double.tryParse(workHoursController.text) ?? 0.0;
    widget.onChanged(isPresent, workHours, notesController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    widget.personnel.firstName[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.personnel.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.personnel.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isPresent,
                  onChanged: (value) {
                    setState(() {
                      isPresent = value;
                      if (!value) {
                        workHoursController.text = '0';
                      }
                    });
                    _updateAttendance();
                  },
                ),
              ],
            ),
            if (isPresent) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: workHoursController,
                      label: 'Mesai Saati',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.access_time,
                      validator: (value) {
                        if (value?.isEmpty == true && isPresent) {
                          return 'Mesai saati gerekli';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      workHoursController.text = '8';
                      _updateAttendance();
                    },
                    icon: const Icon(Icons.update),
                    tooltip: '8 saat',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: notesController,
                label: 'Not (Opsiyonel)',
                prefixIcon: Icons.note,
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPresent ? Icons.check_circle : Icons.cancel,
                  color: isPresent ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isPresent ? 'Geldi' : 'Gelmedi',
                  style: TextStyle(
                    color: isPresent ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isPresent && workHoursController.text.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${workHoursController.text} saat',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
