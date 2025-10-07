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

class _AttendancePageState extends State<AttendancePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  DateTime selectedDate = DateTime.now();
  Map<String, Map<String, dynamic>> attendanceData = {};

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
          _loadAttendanceForDate();
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

  void _loadAttendanceForDate() {
    final controller = context.read<AttendanceController>();
    final existingAttendances = controller.getAttendancesByDate(selectedDate);

    for (var personnel in controller.personnel) {
      if (attendanceData.containsKey(personnel.id)) {
        continue;
      }

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
                painter: AttendancePatternPainter(),
              ),
            ),

            // Ana içerik
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Consumer<AttendanceController>(
                  builder: (context, controller, child) {
                    if (controller.isLoading && controller.personnel.isEmpty) {
                      return _buildLoadingState();
                    }

                    if (controller.errorMessage != null) {
                      return _buildErrorState(controller);
                    }

                    if (controller.personnel.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildMainContent(controller);
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
          'Puantaj Sistemi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1DE9B6).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _saveAttendances,
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Kaydet',
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
              'Personel listesi yükleniyor...',
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

  Widget _buildErrorState(AttendanceController controller) {
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
              child:
                  const Icon(Icons.error_outline, color: Colors.red, size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              'Hata Oluştu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage ?? 'Bilinmeyen hata',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.loadPersonnel(),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'Tekrar Dene',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
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
              'Henüz Personel Yok',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Puantaj girişi yapabilmek için önce personel eklemelisiniz',
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

  Widget _buildMainContent(AttendanceController controller) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Header
        _buildHeader(context, controller),

        const SizedBox(height: 24),

        // Tarih seçici
        _buildDateSelector(),

        const SizedBox(height: 16),

        // Puantaj listesi
        Expanded(
          child: _buildAttendanceList(controller),
        ),

        // Kaydet butonu
        _buildSaveButton(controller),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AttendanceController controller) {
    final presentCount =
        attendanceData.values.where((data) => data['isPresent'] == true).length;
    final totalCount = controller.personnel.length;

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
              Icons.access_time,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Puantaj Sistemi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$presentCount/$totalCount personel geldi',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: presentCount == totalCount
                  ? const LinearGradient(
                      colors: [Colors.green, Colors.lightGreen])
                  : const LinearGradient(
                      colors: [Color(0xFFFF8A65), Color(0xFFFF5722)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${((presentCount / totalCount) * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seçili Tarih',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMMM yyyy', 'tr').format(selectedDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1DE9B6).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Tarih Seç',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(AttendanceController controller) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: controller.personnel.length,
      itemBuilder: (context, index) {
        final personnel = controller.personnel[index];
        final attendance = attendanceData[personnel.id] ??
            {'isPresent': false, 'workHours': 0.0, 'notes': ''};

        return AttendanceCard(
          key: ValueKey('${personnel.id}_${selectedDate.toString()}'),
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
    );
  }

  Widget _buildSaveButton(AttendanceController controller) {
    return Container(
      margin: const EdgeInsets.all(24),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: controller.isLoading
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [const Color(0xFF1DE9B6), const Color(0xFF26A69A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1DE9B6).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: controller.isLoading ? null : _saveAttendances,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: controller.isLoading
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Kaydediliyor...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Puantajları Kaydet',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ),
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
      _loadAttendanceForDateOnDateChange();
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Puantajlar başarıyla kaydedildi'),
            ],
          ),
          backgroundColor: const Color(0xFF26A69A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Kayıt başarısız'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

class _AttendanceCardState extends State<AttendanceCard>
    with SingleTickerProviderStateMixin {
  late bool isPresent;
  late TextEditingController workHoursController;
  late TextEditingController notesController;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    isPresent = widget.isPresent;
    workHoursController = TextEditingController(
      text: widget.workHours > 0 ? widget.workHours.toString() : '',
    );
    notesController = TextEditingController(text: widget.notes);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    workHoursController.addListener(_updateAttendance);
    notesController.addListener(_updateAttendance);
  }

  @override
  void didUpdateWidget(AttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _controller.dispose();
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
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            widget.personnel.firstName.isNotEmpty
                                ? widget.personnel.firstName[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.personnel.fullName,
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
                                color: const Color(0xFF1DE9B6).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.personnel.title,
                                style: const TextStyle(
                                  color: Color(0xFF1DE9B6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Switch(
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
                          activeColor: const Color(0xFF1DE9B6),
                          activeTrackColor:
                              const Color(0xFF1DE9B6).withOpacity(0.3),
                          inactiveThumbColor: Colors.white.withOpacity(0.6),
                          inactiveTrackColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                  if (isPresent) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCustomTextField(
                            controller: workHoursController,
                            label: 'Mesai Saati',
                            icon: Icons.access_time,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () {
                              workHoursController.text = '8';
                              _updateAttendance();
                            },
                            icon: const Icon(Icons.update, color: Colors.white),
                            tooltip: '8 saat',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCustomTextField(
                      controller: notesController,
                      label: 'Not (Opsiyonel)',
                      icon: Icons.note,
                      maxLines: 2,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: isPresent
                                ? const LinearGradient(
                                    colors: [Colors.green, Colors.lightGreen])
                                : const LinearGradient(
                                    colors: [Colors.red, Colors.redAccent]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            isPresent ? Icons.check_circle : Icons.cancel,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isPresent ? 'Geldi' : 'Gelmedi',
                          style: TextStyle(
                            color: isPresent ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (isPresent &&
                            workHoursController.text.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.access_time,
                                color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${workHoursController.text} saat',
                            style: const TextStyle(
                              color: Color(0xFF1DE9B6),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1DE9B6).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF1DE9B6), size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// Attendance sayfası için pattern painter
class AttendancePatternPainter extends CustomPainter {
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

    // Clock patterns
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 6; j++) {
        final x = (size.width / 4) * i + (size.width / 8);
        final y = (size.height / 6) * j + (size.height / 12);

        // Clock circle
        canvas.drawCircle(
          Offset(x, y),
          15,
          (i + j) % 2 == 0 ? paint : accentPaint,
        );

        // Clock hands
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y - 8),
          paint,
        );
        canvas.drawLine(
          Offset(x, y),
          Offset(x + 6, y),
          paint,
        );
      }
    }

    // Attendance check marks pattern
    for (int i = 0; i < 6; i++) {
      final x = (size.width / 6) * i + (size.width / 12);
      final y = size.height * 0.85;

      // Check mark
      final path = Path();
      path.moveTo(x - 6, y);
      path.lineTo(x - 2, y + 4);
      path.lineTo(x + 6, y - 4);

      canvas.drawPath(path, i % 2 == 0 ? accentPaint : paint);
    }

    // Grid lines
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.25 + i * 0.25);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
