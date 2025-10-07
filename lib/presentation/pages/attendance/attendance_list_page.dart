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

class _AttendanceListPageState extends State<AttendanceListPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  PersonnelModel? selectedPersonnel;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<AttendanceController>();
      controller.loadPersonnel().then((_) {
        controller.loadAttendances().then((_) {
          final authController = context.read<AuthController>();
          _selectCurrentUserPersonnel(controller, authController);
          _fadeController.forward();
        });
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _selectCurrentUserPersonnel(
    AttendanceController controller,
    AuthController authController,
  ) {
    final currentUser = authController.currentUser!;

    if (currentUser.role == UserRole.employee) {
      final personnel =
          controller.personnel.where((p) => p.id == currentUser.id).firstOrNull;

      if (personnel != null) {
        setState(() {
          selectedPersonnel = personnel;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1DE9B6), // Raneri yeşili
              Color(0xFF26A69A), // Orta teal
              Color(0xFF00ACC1), // Cyan-mavi
              Color(0xFF455A64), // Koyu gri-mavi
              Color(0xFF37474F), // Çok koyu gri
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Arka plan pattern
            Positioned.fill(
              child: CustomPaint(
                painter: AttendanceListPatternPainter(),
              ),
            ),

            // Ana içerik
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Consumer2<AttendanceController, AuthController>(
                  builder:
                      (context, attendanceController, authController, child) {
                    if (attendanceController.isLoading &&
                        attendanceController.personnel.isEmpty) {
                      return _buildLoadingState();
                    }

                    final filteredPersonnel =
                        attendanceController.getFilteredPersonnel(
                      authController.currentUser,
                    );

                    if (filteredPersonnel.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildMainContent(attendanceController,
                        authController, filteredPersonnel);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      centerTitle: true,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Text(
          'Puantaj Raporları',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      actions: [
        if (selectedPersonnel != null)
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE57373), Color(0xFFEF5350)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _exportToPDF,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              tooltip: 'PDF\'e Aktar',
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    color: Color(0xFF1DE9B6), strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Puantaj verileri yükleniyor...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.people_outline,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Puantaj Verisi Yok',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Puantaj takibi aktif personel bulunamadı',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    AttendanceController attendanceController,
    AuthController authController,
    List<PersonnelModel> filteredPersonnel,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Header
          _buildHeader(context, authController),

          const SizedBox(height: 24),

          // Filtre kartı
          _buildFilterCard(authController, filteredPersonnel),

          const SizedBox(height: 16),

          // Puantaj detayları
          if (selectedPersonnel != null)
            _buildAttendanceDetails(
                attendanceController, authController.currentUser),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthController authController) {
    final isEmployee = authController.currentUser?.role == UserRole.employee;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1DE9B6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.list_alt,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmployee ? 'Puantaj Bilgilerim' : 'Puantaj Raporları',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEmployee
                      ? 'Kendi puantaj bilgilerinizi görüntüleyin'
                      : 'Personel puantaj raporlarını inceleyin',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(
      AuthController authController, List<PersonnelModel> filteredPersonnel) {
    final isEmployee = authController.currentUser?.role == UserRole.employee;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
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
                child: const Icon(Icons.filter_list,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Filtreler',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Personel seçimi
          if (!isEmployee) ...[
            Text(
              'Personel Seç',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1DE9B6).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: DropdownButtonFormField<PersonnelModel>(
                value: selectedPersonnel,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person, color: Color(0xFF1DE9B6)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                hint: const Text('Personel seçin',
                    style: TextStyle(color: Colors.white70)),
                items: filteredPersonnel.map((personnel) {
                  return DropdownMenuItem(
                    value: personnel,
                    child: Text(personnel.fullName,
                        style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (personnel) {
                  setState(() {
                    selectedPersonnel = personnel;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
          ] else if (selectedPersonnel != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Puantaj Bilgileriniz: ${selectedPersonnel!.fullName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Yıl ve ay seçimi
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yıl',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1DE9B6).withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButtonFormField<int>(
                        value: selectedYear,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.calendar_today,
                              color: Color(0xFF1DE9B6)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        items: List.generate(5, (index) {
                          final year = DateTime.now().year - index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString(),
                                style: const TextStyle(color: Colors.black)),
                          );
                        }),
                        onChanged: (year) {
                          setState(() {
                            selectedYear = year!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ay',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1DE9B6).withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButtonFormField<int>(
                        value: selectedMonth,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          prefixIcon:
                              Icon(Icons.event, color: Color(0xFF1DE9B6)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(
                              DateFormat('MMMM', 'tr')
                                  .format(DateTime(2024, index + 1)),
                              style: const TextStyle(color: Colors.black),
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceDetails(
    AttendanceController controller,
    UserModel? currentUser,
  ) {
    final summary = controller.getMonthlyAttendanceSummaryFiltered(
      selectedPersonnel!.id,
      selectedYear,
      selectedMonth,
      currentUser,
    );

    if (summary == null) {
      return _buildAccessDenied();
    }

    if (summary.attendances.isEmpty) {
      return _buildNoData();
    }

    return Column(
      children: [
        // Özet kartı
        _buildSummaryCard(summary),

        const SizedBox(height: 16),

        // Günlük detaylar başlığı
        _buildDetailsHeader(),

        const SizedBox(height: 8),

        // Günlük detaylar
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: summary.attendances.length,
          itemBuilder: (context, index) {
            final attendance = summary.attendances[index];
            return AttendanceDetailCard(attendance: attendance);
          },
        ),
        const SizedBox(height: 24), // Bottom padding to prevent overflow
      ],
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.block, color: Colors.red, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Erişim Reddedildi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu bilgilere erişim yetkiniz bulunmamaktadır',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoData() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child:
                  const Icon(Icons.event_busy, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'Veri Bulunamadı',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu ay için puantaj kaydı bulunamadı',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(summary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedPersonnel!.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMMM yyyy', 'tr')
                          .format(DateTime(selectedYear, selectedMonth)),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // İstatistikler - Üst sıra
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  title: 'Toplam Gün',
                  value: summary.totalWorkDays.toString(),
                  icon: Icons.calendar_month,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryItem(
                  title: 'Geliş',
                  value: summary.presentDays.toString(),
                  icon: Icons.check_circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryItem(
                  title: 'Devamsızlık',
                  value:
                      (summary.totalWorkDays - summary.presentDays).toString(),
                  icon: Icons.cancel,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE57373), Color(0xFFEF5350)]),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // İstatistikler - Alt sıra
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  title: 'Toplam Saat',
                  value: summary.totalWorkHours.toStringAsFixed(1),
                  icon: Icons.access_time,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFFF5722)]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryItem(
                  title: 'Ortalama',
                  value: summary.averageWorkHours.toStringAsFixed(1),
                  icon: Icons.av_timer,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFAB47BC), Color(0xFF9C27B0)]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryItem(
                  title: 'Devam Oranı',
                  value: '${summary.attendanceRate.toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.list, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Günlük Detaylar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    if (selectedPersonnel == null) return;

    final controller = context.read<AttendanceController>();
    final authController = context.read<AuthController>();

    final summary = controller.getMonthlyAttendanceSummaryFiltered(
      selectedPersonnel!.id,
      selectedYear,
      selectedMonth,
      authController.currentUser,
    );

    if (summary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text('Bu bilgilere erişim yetkiniz yok'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (summary.attendances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bu ay için puantaj kaydı bulunamadı'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      await PDFService.generateAttendanceReport(summary);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('PDF başarıyla oluşturuldu ve kaydedildi'),
              ],
            ),
            backgroundColor: const Color(0xFF26A69A),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulamadı: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  final LinearGradient gradient;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceDetailCard extends StatefulWidget {
  final AttendanceModel attendance;

  const AttendanceDetailCard({super.key, required this.attendance});

  @override
  State<AttendanceDetailCard> createState() => _AttendanceDetailCardState();
}

class _AttendanceDetailCardState extends State<AttendanceDetailCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _controller.forward().then((_) => _controller.reverse());
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: widget.attendance.isPresent
                          ? const LinearGradient(
                              colors: [Colors.green, Colors.lightGreen])
                          : const LinearGradient(
                              colors: [Colors.red, Colors.redAccent]),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.attendance.isPresent
                                  ? Colors.green
                                  : Colors.red)
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.attendance.isPresent
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMMM yyyy - EEEE', 'tr')
                              .format(widget.attendance.date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: widget.attendance.isPresent
                                ? const LinearGradient(
                                    colors: [Colors.green, Colors.lightGreen])
                                : const LinearGradient(
                                    colors: [Colors.red, Colors.redAccent]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.attendance.isPresent ? 'Geldi' : 'Gelmedi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (widget.attendance.isPresent &&
                            widget.attendance.workHours > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.white.withOpacity(0.7),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Mesai: ${widget.attendance.workHours} saat',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (widget.attendance.notes?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.note,
                                color: Colors.white.withOpacity(0.7),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.attendance.notes!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.attendance.isPresent &&
                      widget.attendance.workHours > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.attendance.workHours}h',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Attendance list sayfası için pattern painter
class AttendanceListPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final accentPaint = Paint()
      ..color = const Color(0xFF1DE9B6).withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Report/list patterns
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 8; j++) {
        final x = (size.width / 6) * i + (size.width / 12);
        final y = (size.height / 8) * j + (size.height / 16);

        // List item rectangles
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 25, height: 8),
            const Radius.circular(2),
          ),
          (i + j) % 2 == 0 ? paint : accentPaint,
        );
      }
    }

    // Chart lines for statistics
    for (int i = 0; i < 4; i++) {
      final startX = size.width * 0.1;
      final endX = size.width * 0.9;
      final y = size.height * (0.2 + i * 0.2);

      final path = Path();
      path.moveTo(startX, y);

      for (double x = startX; x <= endX; x += 30) {
        final offsetY = y + (i % 2 == 0 ? 10 : -10) * (x % 60 == 0 ? 1 : 0);
        path.lineTo(x, offsetY);
      }

      canvas.drawPath(path, i % 2 == 0 ? paint : accentPaint);
    }

    // Percentage indicators
    for (int i = 0; i < 5; i++) {
      final x = (size.width / 5) * i + (size.width / 10);
      final y = size.height * 0.9;

      canvas.drawCircle(Offset(x, y), 10, i % 2 == 0 ? paint : accentPaint);

      // Percentage symbol
      canvas.drawLine(
        Offset(x - 3, y - 3),
        Offset(x + 3, y + 3),
        paint,
      );
      canvas.drawCircle(Offset(x - 2, y - 2), 1, paint);
      canvas.drawCircle(Offset(x + 2, y + 2), 1, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
