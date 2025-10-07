import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/daily_report_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../data/models/daily_report_model.dart';

class AddDailyReportPage extends StatefulWidget {
  final DailyReportModel? existingReport;

  const AddDailyReportPage({super.key, this.existingReport});

  @override
  State<AddDailyReportPage> createState() => _AddDailyReportPageState();
}

class _AddDailyReportPageState extends State<AddDailyReportPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _generalNotesController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  List<TaskModel> todayTasks = [];
  List<TaskModel> tomorrowPlans = [];
  List<MaterialUsage> materialsUsed = [];
  List<SafetyIncident> safetyIncidents = [];
  List<String> photoUrls = [];

  WeatherCondition selectedWeather = WeatherCondition.sunny;
  double temperature = 25.0;
  String weatherDescription = '';
  bool weatherAffectedWork = false;
  String? workImpact;

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

    // Eğer düzenleme modundaysa verileri yükle
    if (widget.existingReport != null) {
      _loadExistingData();
    }

    _fadeController.forward();
  }

  void _loadExistingData() {
    final report = widget.existingReport!;
    _projectNameController.text = report.projectName;
    _generalNotesController.text = report.generalNotes;
    selectedDate = report.date;
    todayTasks = List.from(report.todayTasks);
    tomorrowPlans = List.from(report.tomorrowPlans);
    materialsUsed = List.from(report.materialsUsed);
    safetyIncidents = List.from(report.safetyIncidents);
    photoUrls = List.from(report.photoUrls);
    selectedWeather = report.weatherInfo.condition;
    temperature = report.weatherInfo.temperature;
    weatherDescription = report.weatherInfo.description;
    weatherAffectedWork = report.weatherInfo.affectedWork;
    workImpact = report.weatherInfo.workImpact;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _projectNameController.dispose();
    _generalNotesController.dispose();
    super.dispose();
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
              Color(0xFF1DE9B6),
              Color(0xFF26A69A),
              Color(0xFF00ACC1),
              Color(0xFF455A64),
              Color(0xFF37474F),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Arka plan pattern
            Positioned.fill(
              child: CustomPaint(
                painter: AddReportPatternPainter(),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              _buildBasicInfoCard(),
                              const SizedBox(height: 16),
                              _buildTodayTasksCard(),
                              const SizedBox(height: 16),
                              _buildTomorrowPlansCard(),
                              const SizedBox(height: 16),
                              _buildMaterialsCard(),
                              const SizedBox(height: 16),
                              _buildWeatherCard(),
                              const SizedBox(height: 16),
                              _buildSafetyCard(),
                              const SizedBox(height: 16),
                              _buildNotesCard(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Kaydet butonu
            Positioned(
              bottom: 20,
              left: 24,
              right: 24,
              child: _buildSaveButton(),
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
        child: Text(
          widget.existingReport != null
              ? 'Raporu Düzenle'
              : 'Yeni Günlük Rapor',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            ),
            child: const Icon(Icons.add_circle, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingReport != null
                      ? 'Rapor Düzenleme'
                      : 'Yeni Günlük Rapor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMMM yyyy', 'tr').format(selectedDate),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temel Bilgiler',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCustomTextField(
            controller: _projectNameController,
            label: 'Proje Adı',
            icon: Icons.business,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Proje adı gerekli';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTasksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bugün Yapılan İşler',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _addTask(true),
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (todayTasks.isEmpty)
            _buildEmptyTasksState('Bugün için henüz iş eklenmedi')
          else
            ...todayTasks
                .asMap()
                .entries
                .map((entry) => _buildTaskItem(entry.value, entry.key, true)),
        ],
      ),
    );
  }

  Widget _buildTomorrowPlansCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Yarın Planı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _addTask(false),
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tomorrowPlans.isEmpty)
            _buildEmptyTasksState('Yarın için henüz plan eklenmedi')
          else
            ...tomorrowPlans
                .asMap()
                .entries
                .map((entry) => _buildTaskItem(entry.value, entry.key, false)),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Malzeme Kullanımı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: _addMaterial,
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (materialsUsed.isEmpty)
            _buildEmptyMaterialsState()
          else
            ...materialsUsed
                .asMap()
                .entries
                .map((entry) => _buildMaterialItem(entry.value, entry.key)),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hava Durumu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1DE9B6).withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: DropdownButtonFormField<WeatherCondition>(
                    value: selectedWeather,
                    decoration: const InputDecoration(
                      prefixIcon:
                          Icon(Icons.wb_sunny, color: Color(0xFF1DE9B6)),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    items: WeatherCondition.values.map((condition) {
                      return DropdownMenuItem(
                        value: condition,
                        child: Text(_getWeatherText(condition),
                            style: const TextStyle(color: Colors.black)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedWeather = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1DE9B6).withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: TextFormField(
                  initialValue: temperature.toString(),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    suffixText: '°C',
                    suffixStyle: TextStyle(color: Colors.white),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  ),
                  onChanged: (value) {
                    temperature = double.tryParse(value) ?? 25.0;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCustomTextField(
            controller: TextEditingController(text: weatherDescription),
            label: 'Hava Durumu Açıklaması',
            icon: Icons.cloud,
            onChanged: (value) => weatherDescription = value,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: weatherAffectedWork,
                onChanged: (value) {
                  setState(() {
                    weatherAffectedWork = value ?? false;
                  });
                },
                activeColor: const Color(0xFF1DE9B6),
              ),
              const Expanded(
                child: Text(
                  'Hava durumu işleri etkiledi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          if (weatherAffectedWork) ...[
            const SizedBox(height: 8),
            _buildCustomTextField(
              controller: TextEditingController(text: workImpact ?? ''),
              label: 'İş Etkisi Açıklaması',
              icon: Icons.info,
              onChanged: (value) => workImpact = value,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSafetyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Güvenlik Olayları',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE57373), Color(0xFFEF5350)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: _addSafetyIncident,
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (safetyIncidents.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Text(
                    'Güvenlik olayı yaşanmadı',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          else
            ...safetyIncidents.asMap().entries.map(
                (entry) => _buildSafetyIncidentItem(entry.value, entry.key)),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Genel Notlar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildCustomTextField(
            controller: _generalNotesController,
            label: 'Günle ilgili genel notlarınız...',
            icon: Icons.note,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskModel task, int index, bool isToday) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              color: _getTaskStatusColor(task.status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getTaskStatusIcon(task.status),
              color: _getTaskStatusColor(task.status),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
                if (isToday) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${task.completionPercentage.toStringAsFixed(0)}% tamamlandı',
                    style: const TextStyle(
                      color: Color(0xFF1DE9B6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: Colors.white.withOpacity(0.7), size: 18),
            color: Colors.white,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    const Text('Düzenle'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: Colors.red[600])),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _editTask(task, index, isToday);
              } else if (value == 'delete') {
                _deleteTask(index, isToday);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialItem(MaterialUsage material, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.inventory, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.materialName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${material.quantity} ${material.unit} - ₺${material.totalCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteMaterial(index),
            icon: Icon(Icons.delete,
                color: Colors.red.withOpacity(0.7), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyIncidentItem(SafetyIncident incident, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              color: _getSeverityColor(incident.severity).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getSeverityIcon(incident.severity),
              color: _getSeverityColor(incident.severity),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  incident.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteSafetyIncident(index),
            icon: Icon(Icons.delete,
                color: Colors.red.withOpacity(0.7), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTasksState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildEmptyMaterialsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Henüz malzeme kullanımı eklenmedi',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    Function(String)? onChanged,
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
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            onChanged: onChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF1DE9B6), size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: label,
              hintStyle:
                  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Consumer<DailyReportController>(
      builder: (context, controller, child) {
        return Container(
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
              onTap: controller.isLoading ? null : _saveReport,
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
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.existingReport != null
                                ? Icons.update
                                : Icons.save,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.existingReport != null
                                ? 'Raporu Güncelle'
                                : 'Raporu Kaydet',
                            style: const TextStyle(
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
      },
    );
  }

  // Yardımcı metodlar
  String _getWeatherText(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return 'Güneşli';
      case WeatherCondition.rainy:
        return 'Yağmurlu';
      case WeatherCondition.cloudy:
        return 'Bulutlu';
      case WeatherCondition.stormy:
        return 'Fırtınalı';
      case WeatherCondition.snowy:
        return 'Karlı';
    }
  }

  Color _getTaskStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.delayed:
        return Colors.orange;
      case TaskStatus.cancelled:
        return Colors.red;
      case TaskStatus.notStarted:
        return Colors.grey;
    }
  }

  IconData _getTaskStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.delayed:
        return Icons.schedule;
      case TaskStatus.cancelled:
        return Icons.cancel;
      case TaskStatus.notStarted:
        return Icons.radio_button_unchecked;
    }
  }

  Color _getSeverityColor(SafetyLevel severity) {
    switch (severity) {
      case SafetyLevel.low:
        return Colors.green;
      case SafetyLevel.medium:
        return Colors.orange;
      case SafetyLevel.high:
        return Colors.red;
      case SafetyLevel.critical:
        return Colors.purple;
    }
  }

  IconData _getSeverityIcon(SafetyLevel severity) {
    switch (severity) {
      case SafetyLevel.low:
        return Icons.info;
      case SafetyLevel.medium:
        return Icons.warning;
      case SafetyLevel.high:
        return Icons.error;
      case SafetyLevel.critical:
        return Icons.dangerous;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _addTask(bool isToday) {
    _showTaskDialog(isToday: isToday);
  }

  void _editTask(TaskModel task, int index, bool isToday) {
    _showTaskDialog(isToday: isToday, existingTask: task, taskIndex: index);
  }

  void _deleteTask(int index, bool isToday) {
    setState(() {
      if (isToday) {
        todayTasks.removeAt(index);
      } else {
        tomorrowPlans.removeAt(index);
      }
    });
  }

  void _addMaterial() {
    _showMaterialDialog();
  }

  void _deleteMaterial(int index) {
    setState(() {
      materialsUsed.removeAt(index);
    });
  }

  void _addSafetyIncident() {
    _showSafetyIncidentDialog();
  }

  void _deleteSafetyIncident(int index) {
    setState(() {
      safetyIncidents.removeAt(index);
    });
  }

  void _showTaskDialog({
    required bool isToday,
    TaskModel? existingTask,
    int? taskIndex,
  }) {
    final titleController =
        TextEditingController(text: existingTask?.title ?? '');
    final descriptionController =
        TextEditingController(text: existingTask?.description ?? '');
    final workersController = TextEditingController(
        text: existingTask?.assignedWorkers.toString() ?? '');
    final notesController =
        TextEditingController(text: existingTask?.notes ?? '');

    TaskStatus selectedStatus = existingTask?.status ?? TaskStatus.notStarted;
    String selectedPriority = existingTask?.priority ?? 'medium';
    double completionPercentage = existingTask?.completionPercentage ?? 0.0;
    DateTime? startTime = existingTask?.startTime;
    DateTime? endTime = existingTask?.endTime;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isToday
                        ? [const Color(0xFF66BB6A), const Color(0xFF4CAF50)]
                        : [const Color(0xFF42A5F5), const Color(0xFF1E88E5)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isToday ? Icons.today : Icons.schedule,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                existingTask != null
                    ? 'İşi Düzenle'
                    : (isToday ? 'Bugünkü İş Ekle' : 'Yarınki Plan Ekle'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(
                    controller: titleController,
                    label: 'İş Başlığı',
                    icon: Icons.title,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'İş başlığı gerekli'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: descriptionController,
                    label: 'İş Açıklaması',
                    icon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),

                  // Durum seçimi (sadece bugün için)
                  if (isToday) ...[
                    DropdownButtonFormField<TaskStatus>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Durum',
                        prefixIcon: Icon(Icons.flag, color: Color(0xFF26A69A)),
                        border: OutlineInputBorder(),
                      ),
                      items: TaskStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(_getTaskStatusText(status)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedStatus = value!);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Tamamlanma yüzdesi
                    Text(
                        'Tamamlanma: ${completionPercentage.toStringAsFixed(0)}%'),
                    Slider(
                      value: completionPercentage,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: const Color(0xFF26A69A),
                      onChanged: (value) {
                        setDialogState(() => completionPercentage = value);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Öncelik
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Öncelik',
                      prefixIcon:
                          Icon(Icons.priority_high, color: Color(0xFF26A69A)),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Düşük')),
                      DropdownMenuItem(value: 'medium', child: Text('Orta')),
                      DropdownMenuItem(value: 'high', child: Text('Yüksek')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedPriority = value!);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Çalışan sayısı
                  _buildDialogTextField(
                    controller: workersController,
                    label: 'Atanan Çalışan Sayısı',
                    icon: Icons.people,
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Çalışan sayısı gerekli'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Zaman seçimi (sadece bugün için)
                  if (isToday) ...[
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: dialogContext,
                                initialTime: TimeOfDay.fromDateTime(
                                    startTime ?? DateTime.now()),
                              );
                              if (time != null) {
                                setDialogState(() {
                                  startTime = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: Color(0xFF26A69A)),
                                  const SizedBox(width: 8),
                                  Text(startTime != null
                                      ? DateFormat('HH:mm').format(startTime!)
                                      : 'Başlama Saati'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: dialogContext,
                                initialTime: TimeOfDay.fromDateTime(
                                    endTime ?? DateTime.now()),
                              );
                              if (time != null) {
                                setDialogState(() {
                                  endTime = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      color: Color(0xFF26A69A)),
                                  const SizedBox(width: 8),
                                  Text(endTime != null
                                      ? DateFormat('HH:mm').format(endTime!)
                                      : 'Bitiş Saati'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Notlar
                  _buildDialogTextField(
                    controller: notesController,
                    label: 'Notlar (Opsiyonel)',
                    icon: Icons.note,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (formKey.currentState!.validate()) {
                      final task = TaskModel(
                        id: existingTask?.id ?? const Uuid().v4(),
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        status: selectedStatus,
                        completionPercentage:
                            isToday ? completionPercentage : 0.0,
                        assignedWorkers:
                            int.parse(workersController.text.trim()),
                        priority: selectedPriority,
                        startTime: startTime,
                        endTime: endTime,
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      );

                      setState(() {
                        if (isToday) {
                          if (existingTask != null && taskIndex != null) {
                            todayTasks[taskIndex] = task;
                          } else {
                            todayTasks.add(task);
                          }
                        } else {
                          if (existingTask != null && taskIndex != null) {
                            tomorrowPlans[taskIndex] = task;
                          } else {
                            tomorrowPlans.add(task);
                          }
                        }
                      });

                      Navigator.pop(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      existingTask != null ? 'Güncelle' : 'Ekle',
                      style: const TextStyle(
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

  void _showMaterialDialog(
      [MaterialUsage? existingMaterial, int? materialIndex]) {
    final nameController =
        TextEditingController(text: existingMaterial?.materialName ?? '');
    final quantityController = TextEditingController(
        text: existingMaterial?.quantity.toString() ?? '');
    final priceController = TextEditingController(
        text: existingMaterial?.unitPrice.toString() ?? '');
    final supplierController =
        TextEditingController(text: existingMaterial?.supplier ?? '');
    final notesController =
        TextEditingController(text: existingMaterial?.notes ?? '');

    String selectedUnit = existingMaterial?.unit ?? 'kg';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.inventory, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                existingMaterial != null ? 'Malzemeyi Düzenle' : 'Malzeme Ekle',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(
                    controller: nameController,
                    label: 'Malzeme Adı',
                    icon: Icons.inventory_2,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Malzeme adı gerekli'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildDialogTextField(
                          controller: quantityController,
                          label: 'Miktar',
                          icon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Miktar gerekli'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Birim',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'm3', child: Text('m³')),
                            DropdownMenuItem(
                                value: 'adet', child: Text('adet')),
                            DropdownMenuItem(
                                value: 'litre', child: Text('litre')),
                            DropdownMenuItem(
                                value: 'metre', child: Text('metre')),
                          ],
                          onChanged: (value) {
                            setDialogState(() => selectedUnit = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: priceController,
                    label: 'Birim Fiyat (₺)',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Fiyat gerekli'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: supplierController,
                    label: 'Tedarikçi',
                    icon: Icons.store,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Tedarikçi gerekli'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: notesController,
                    label: 'Notlar',
                    icon: Icons.note,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (formKey.currentState!.validate()) {
                      final material = MaterialUsage(
                        id: existingMaterial?.id ?? const Uuid().v4(),
                        materialName: nameController.text.trim(),
                        unit: selectedUnit,
                        quantity: double.parse(quantityController.text.trim()),
                        unitPrice: double.parse(priceController.text.trim()),
                        supplier: supplierController.text.trim(),
                        notes: notesController.text.trim(),
                      );

                      setState(() {
                        if (existingMaterial != null && materialIndex != null) {
                          materialsUsed[materialIndex] = material;
                        } else {
                          materialsUsed.add(material);
                        }
                      });

                      Navigator.pop(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      existingMaterial != null ? 'Güncelle' : 'Ekle',
                      style: const TextStyle(
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

  void _showSafetyIncidentDialog(
      [SafetyIncident? existingIncident, int? incidentIndex]) {
    final titleController =
        TextEditingController(text: existingIncident?.title ?? '');
    final descriptionController =
        TextEditingController(text: existingIncident?.description ?? '');
    final personnelController =
        TextEditingController(text: existingIncident?.involvedPersonnel ?? '');
    final actionController =
        TextEditingController(text: existingIncident?.actionTaken ?? '');

    SafetyLevel selectedSeverity =
        existingIncident?.severity ?? SafetyLevel.low;
    DateTime incidentTime = existingIncident?.time ?? DateTime.now();
    bool isResolved = existingIncident?.resolved ?? false;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE57373), Color(0xFFEF5350)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                existingIncident != null
                    ? 'Olayı Düzenle'
                    : 'Güvenlik Olayı Ekle',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogTextField(
                    controller: titleController,
                    label: 'Olay Başlığı',
                    icon: Icons.title,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Başlık gerekli'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: descriptionController,
                    label: 'Olay Açıklaması',
                    icon: Icons.description,
                    maxLines: 3,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Açıklama gerekli'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Ciddiyet seviyesi
                  DropdownButtonFormField<SafetyLevel>(
                    value: selectedSeverity,
                    decoration: const InputDecoration(
                      labelText: 'Ciddiyet Seviyesi',
                      prefixIcon:
                          Icon(Icons.priority_high, color: Color(0xFF26A69A)),
                      border: OutlineInputBorder(),
                    ),
                    items: SafetyLevel.values.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(_getSeverityText(level)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedSeverity = value!);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Saat seçimi
                  InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.fromDateTime(incidentTime),
                      );
                      if (time != null) {
                        setDialogState(() {
                          incidentTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              color: Color(0xFF26A69A)),
                          const SizedBox(width: 8),
                          Text(
                              'Olay Saati: ${DateFormat('HH:mm').format(incidentTime)}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildDialogTextField(
                    controller: personnelController,
                    label: 'İlgili Personel',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _buildDialogTextField(
                    controller: actionController,
                    label: 'Alınan Aksiyon',
                    icon: Icons.build,
                    maxLines: 2,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Alınan aksiyon gerekli'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  CheckboxListTile(
                    title: const Text('Olay çözüldü'),
                    value: isResolved,
                    onChanged: (value) {
                      setDialogState(() => isResolved = value ?? false);
                    },
                    activeColor: const Color(0xFF26A69A),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (formKey.currentState!.validate()) {
                      final incident = SafetyIncident(
                        id: existingIncident?.id ?? const Uuid().v4(),
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        severity: selectedSeverity,
                        time: incidentTime,
                        involvedPersonnel: personnelController.text.trim(),
                        actionTaken: actionController.text.trim(),
                        resolved: isResolved,
                      );

                      setState(() {
                        if (existingIncident != null && incidentIndex != null) {
                          safetyIncidents[incidentIndex] = incident;
                        } else {
                          safetyIncidents.add(incident);
                        }
                      });

                      Navigator.pop(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      existingIncident != null ? 'Güncelle' : 'Ekle',
                      style: const TextStyle(
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

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF26A69A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF26A69A), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // Yardımcı metodlar
  String _getTaskStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return 'Başlanmadı';
      case TaskStatus.inProgress:
        return 'Devam Ediyor';
      case TaskStatus.completed:
        return 'Tamamlandı';
      case TaskStatus.delayed:
        return 'Gecikti';
      case TaskStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  String _getSeverityText(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.low:
        return 'Düşük Risk';
      case SafetyLevel.medium:
        return 'Orta Risk';
      case SafetyLevel.high:
        return 'Yüksek Risk';
      case SafetyLevel.critical:
        return 'Kritik Risk';
    }
  }

  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = context.read<AuthController>();
    final currentUser = authController.currentUser!;

    final weatherInfo = WeatherInfo(
      condition: selectedWeather,
      temperature: temperature,
      description: weatherDescription,
      affectedWork: weatherAffectedWork,
      workImpact: workImpact,
    );

    final controller = context.read<DailyReportController>();

    final success = await controller.saveDailyReport(
      date: selectedDate,
      projectName: _projectNameController.text.trim(),
      reportedBy: currentUser.fullName,
      reportedById: currentUser.id,
      todayTasks: todayTasks,
      tomorrowPlans: tomorrowPlans,
      materialsUsed: materialsUsed,
      weatherInfo: weatherInfo,
      safetyIncidents: safetyIncidents,
      photoUrls: photoUrls,
      generalNotes: _generalNotesController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Günlük rapor başarıyla kaydedildi'),
            ],
          ),
          backgroundColor: const Color(0xFF26A69A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Kayıt başarısız'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

// Pattern Painter
class AddReportPatternPainter extends CustomPainter {
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

    // Form patterns
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 8; j++) {
        final x = (size.width / 6) * i + (size.width / 12);
        final y = (size.height / 8) * j + (size.height / 16);

        // Form field rectangles
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 25, height: 10),
            const Radius.circular(2),
          ),
          (i + j) % 2 == 0 ? paint : accentPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
