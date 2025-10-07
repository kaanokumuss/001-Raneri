// create_report_view.dart
class CreateReportView extends StatefulWidget {
  final DateTime date;

  const CreateReportView({super.key, required this.date});

  @override
  State<CreateReportView> createState() => _CreateReportViewState();
}

class _CreateReportViewState extends State<CreateReportView> {
  final _formKey = GlobalKey<FormState>();
  late DailyReportModel report;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Genel Bilgiler Kartı
            _buildGeneralInfoCard(),
            const SizedBox(height: 16),

            // Personel Durumu Kartı (Attendance'tan otomatik)
            _buildPersonnelStatusCard(),
            const SizedBox(height: 16),

            // Tamamlanan İşler
            _buildTasksCard(
              title: 'Bugün Tamamlanan İşler',
              tasks: report.completedTasks,
              onTasksChanged: (tasks) {
                setState(() {
                  report = report.copyWith(completedTasks: tasks);
                });
              },
            ),
            const SizedBox(height: 16),

            // Yarın Planlanacak İşler
            _buildTasksCard(
              title: 'Yarın Planlanacak İşler',
              tasks: report.plannedTasksForTomorrow,
              onTasksChanged: (tasks) {
                setState(() {
                  report = report.copyWith(plannedTasksForTomorrow: tasks);
                });
              },
            ),
            const SizedBox(height: 16),

            // Proje İlerlemesi
            _buildProgressCard(),
            const SizedBox(height: 16),

            // Malzeme Kullanımı
            _buildMaterialUsageCard(),
            const SizedBox(height: 16),

            // Sorunlar ve Notlar
            _buildIssuesCard(),
            const SizedBox(height: 16),

            // Güvenlik Raporu
            _buildSafetyCard(),
            const SizedBox(height: 16),

            // Hava Durumu
            _buildWeatherCard(),
            const SizedBox(height: 16),

            // Fotoğraflar
            _buildPhotosCard(),
            const SizedBox(height: 32),

            // Kaydet Butonu
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonnelStatusCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getAttendanceData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard('Personel verileri yükleniyor...');
        }

        final attendanceData = snapshot.data ?? {};

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.people, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Personel Durumu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // İstatistik Kartları
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Toplam',
                      value: '${attendanceData['total'] ?? 0}',
                      icon: Icons.groups,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Gelen',
                      value: '${attendanceData['present'] ?? 0}',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Gelmeyen',
                      value: '${attendanceData['absent'] ?? 0}',
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              // Detaylı Personel Listesi
              const SizedBox(height: 20),
              ExpansionTile(
                title: const Text(
                  'Detaylı Personel Listesi',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white70,
                children: [
                  ...((attendanceData['details'] as List?) ?? []).map<Widget>(
                    (worker) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            worker['isPresent'] ? Colors.green : Colors.red,
                        child: Icon(
                          worker['isPresent'] ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      title: Text(
                        worker['name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${worker['position']} - ${worker['workHours']}h',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      trailing: worker['overtimeHours'] > 0
                          ? Chip(
                              label: Text('+${worker['overtimeHours']}h'),
                              backgroundColor: Colors.orange.withOpacity(0.3),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Proje İlerlemesi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Genel İlerleme
          _buildProgressIndicator(
            label: 'Genel Proje İlerlemesi',
            progress: report.overallProgressPercentage,
            onChanged: (value) {
              setState(() {
                report = report.copyWith(overallProgressPercentage: value);
              });
            },
          ),

          const SizedBox(height: 20),

          // Alt Projeler
          ...report.projectProgress.map(
            (project) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.projectName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: project.currentProgress / 100,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF1DE9B6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${project.currentProgress.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Yeni Proje Ekleme
          TextButton.icon(
            onPressed: _addNewProject,
            icon: const Icon(Icons.add, color: Color(0xFF1DE9B6)),
            label: const Text(
              'Yeni Proje Ekle',
              style: TextStyle(color: Color(0xFF1DE9B6)),
            ),
          ),
        ],
      ),
    );
  }

  // Attendance verilerini çek
  Future<Map<String, dynamic>> _getAttendanceData() async {
    try {
      final attendanceController = context.read<AttendanceController>();
      final todayAttendances =
          attendanceController.getAttendancesByDate(widget.date);
      final allPersonnel = attendanceController.personnel;

      final present = todayAttendances.where((a) => a.isPresent).length;
      final total = allPersonnel.length;
      final absent = total - present;

      final details = allPersonnel.map((person) {
        final attendance = todayAttendances
            .where((a) => a.personnelId == person.id)
            .firstOrNull;

        return {
          'id': person.id,
          'name': person.fullName,
          'position': person.title,
          'isPresent': attendance?.isPresent ?? false,
          'workHours': attendance?.workHours ?? 0.0,
          'overtimeHours': (attendance?.workHours ?? 0.0) > 8
              ? (attendance!.workHours - 8)
              : 0.0,
        };
      }).toList();

      return {
        'total': total,
        'present': present,
        'absent': absent,
        'details': details,
      };
    } catch (e) {
      return {};
    }
  }
}
