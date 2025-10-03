import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/attendance_model.dart';
import '../../../services/pdf_service.dart';

class AttendanceListPage extends StatefulWidget {
  const AttendanceListPage({super.key});

  @override
  State<AttendanceListPage> createState() => _AttendanceListPageState();
}

class _AttendanceListPageState extends State<AttendanceListPage> {
  PersonnelModel? selectedPersonnel;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<AttendanceController>();
      controller.loadPersonnel().then((_) {
        controller.loadAttendances().then((_) {
          // Çalışan ise kendi bilgilerini otomatik seç
          final authController = context.read<AuthController>();
          if (authController.currentUser?.role == UserRole.employee) {
            _selectCurrentUserPersonnel(controller, authController);
          }
        });
      });
    });
  }

  void _selectCurrentUserPersonnel(
    AttendanceController controller,
    AuthController authController,
  ) {
    final currentUser = authController.currentUser!;
    final personnel = controller.personnel
        .where(
          (p) =>
              p.firstName == currentUser.firstName &&
              p.lastName == currentUser.lastName,
        )
        .firstOrNull;

    if (personnel != null) {
      setState(() {
        selectedPersonnel = personnel;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puantaj Listesi'),
        actions: [
          if (selectedPersonnel != null)
            IconButton(
              onPressed: _exportToPDF,
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'PDF\'e Aktar',
            ),
        ],
      ),
      body: Consumer2<AttendanceController, AuthController>(
        builder: (context, attendanceController, authController, child) {
          if (attendanceController.isLoading &&
              attendanceController.personnel.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (attendanceController.personnel.isEmpty) {
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
              // Filtre kartı
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Personel seçimi (sadece yöneticiler için)
                      if (authController.currentUser?.role == UserRole.admin)
                        DropdownButtonFormField<PersonnelModel>(
                          value: selectedPersonnel,
                          decoration: const InputDecoration(
                            labelText: 'Personel Seçin',
                            border: OutlineInputBorder(),
                          ),
                          items: attendanceController.personnel.map((
                            personnel,
                          ) {
                            return DropdownMenuItem(
                              value: personnel,
                              child: Text(personnel.fullName),
                            );
                          }).toList(),
                          onChanged: (personnel) {
                            setState(() {
                              selectedPersonnel = personnel;
                            });
                          },
                        ),

                      if (authController.currentUser?.role == UserRole.admin)
                        const SizedBox(height: 16),

                      // Yıl ve ay seçimi
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedYear,
                              decoration: const InputDecoration(
                                labelText: 'Yıl',
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(5, (index) {
                                final year = DateTime.now().year - index;
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }),
                              onChanged: (year) {
                                setState(() {
                                  selectedYear = year!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selectedMonth,
                              decoration: const InputDecoration(
                                labelText: 'Ay',
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(12, (index) {
                                return DropdownMenuItem(
                                  value: index + 1,
                                  child: Text(
                                    DateFormat(
                                      'MMMM',
                                      'tr',
                                    ).format(DateTime(2024, index + 1)),
                                  ),
                                );
                              }),
                              onChanged: (month) {
                                setState(() {
                                  selectedMonth = month!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Puantaj detayları
              if (selectedPersonnel != null)
                Expanded(child: _buildAttendanceDetails(attendanceController)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAttendanceDetails(AttendanceController controller) {
    final summary = controller.getMonthlyAttendanceSummary(
      selectedPersonnel!.id,
      selectedYear,
      selectedMonth,
    );

    if (summary.attendances.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Bu ay için puantaj kaydı bulunamadı'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Özet kartı
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '${selectedPersonnel!.fullName}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${DateFormat('MMMM yyyy', 'tr').format(DateTime(selectedYear, selectedMonth))}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      title: 'Toplam Gün',
                      value: summary.totalWorkDays.toString(),
                      icon: Icons.calendar_month,
                      color: Colors.blue,
                    ),
                    _SummaryItem(
                      title: 'Geliş',
                      value: summary.presentDays.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    _SummaryItem(
                      title: 'Devamsızlık',
                      value: (summary.totalWorkDays - summary.presentDays)
                          .toString(),
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      title: 'Toplam Saat',
                      value: summary.totalWorkHours.toStringAsFixed(1),
                      icon: Icons.access_time,
                      color: Colors.orange,
                    ),
                    _SummaryItem(
                      title: 'Ortalama Saat',
                      value: summary.averageWorkHours.toStringAsFixed(1),
                      icon: Icons.av_timer,
                      color: Colors.purple,
                    ),
                    _SummaryItem(
                      title: 'Devam Oranı',
                      value: '${summary.attendanceRate.toStringAsFixed(1)}%',
                      icon: Icons.trending_up,
                      color: Colors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Günlük detaylar
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: summary.attendances.length,
            itemBuilder: (context, index) {
              final attendance = summary.attendances[index];
              return AttendanceDetailCard(attendance: attendance);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _exportToPDF() async {
    if (selectedPersonnel == null) return;

    final controller = context.read<AttendanceController>();
    final summary = controller.getMonthlyAttendanceSummary(
      selectedPersonnel!.id,
      selectedYear,
      selectedMonth,
    );

    if (summary.attendances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ay için puantaj kaydı bulunamadı')),
      );
      return;
    }

    try {
      await PDFService.generateAttendanceReport(summary);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF başarıyla oluşturuldu ve kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class AttendanceDetailCard extends StatelessWidget {
  final AttendanceModel attendance;

  const AttendanceDetailCard({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: attendance.isPresent
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            attendance.isPresent ? Icons.check_circle : Icons.cancel,
            color: attendance.isPresent ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          DateFormat('dd MMMM yyyy - EEEE', 'tr').format(attendance.date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              attendance.isPresent ? 'Geldi' : 'Gelmedi',
              style: TextStyle(
                color: attendance.isPresent ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (attendance.isPresent && attendance.workHours > 0)
              Text('Mesai: ${attendance.workHours} saat'),
            if (attendance.notes?.isNotEmpty == true)
              Text(
                attendance.notes!,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: attendance.isPresent && attendance.workHours > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${attendance.workHours}h',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
