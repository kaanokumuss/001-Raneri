import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/daily_report_model.dart';
import '../../data/models/attendance_model.dart';
import '../../services/firebase_service.dart';
import '../../services/daily_report_pdf_service.dart';
import '../../data/models/daily_report_model.dart'; // YENİ EKLEME
import '../../services/daily_report_service.dart'; // YENİ EKLEME

class DailyReportController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final DailyReportService _dailyReportService = DailyReportService();
  final Uuid _uuid = const Uuid();

  List<DailyReportModel> _dailyReports = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DailyReportModel> get dailyReports => _dailyReports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> loadDailyReports() async {
    _setLoading(true);
    _setError(null);

    try {
      _dailyReports = await _dailyReportService.getDailyReports();
      _dailyReports.sort((a, b) => b.date.compareTo(a.date));
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> saveDailyReport({
    required DateTime date,
    required String projectName,
    required String reportedBy,
    required String reportedById,
    required List<TaskModel> todayTasks,
    required List<TaskModel> tomorrowPlans,
    required List<MaterialUsage> materialsUsed,
    required WeatherInfo weatherInfo,
    required List<SafetyIncident> safetyIncidents,
    required List<String> photoUrls,
    required String generalNotes,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Attendance verilerini al
      final attendanceSummary = await _getAttendanceSummary(date);

      final report = DailyReportModel(
        id: _uuid.v4(),
        date: date,
        projectName: projectName,
        reportedBy: reportedBy,
        reportedById: reportedById,
        todayTasks: todayTasks,
        tomorrowPlans: tomorrowPlans,
        attendanceSummary: attendanceSummary,
        materialsUsed: materialsUsed,
        weatherInfo: weatherInfo,
        safetyIncidents: safetyIncidents,
        photoUrls: photoUrls,
        generalNotes: generalNotes,
        createdAt: DateTime.now(),
      );

      await _dailyReportService.saveDailyReport(report);
      _dailyReports.insert(0, report);
      _dailyReports.sort((a, b) => b.date.compareTo(a.date));

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateDailyReport(DailyReportModel report) async {
    _setLoading(true);
    _setError(null);

    try {
      final updatedReport = DailyReportModel(
        id: report.id,
        date: report.date,
        projectName: report.projectName,
        reportedBy: report.reportedBy,
        reportedById: report.reportedById,
        todayTasks: report.todayTasks,
        tomorrowPlans: report.tomorrowPlans,
        attendanceSummary: report.attendanceSummary,
        materialsUsed: report.materialsUsed,
        weatherInfo: report.weatherInfo,
        safetyIncidents: report.safetyIncidents,
        photoUrls: report.photoUrls,
        generalNotes: report.generalNotes,
        createdAt: report.createdAt,
        updatedAt: DateTime.now(),
      );

      await _dailyReportService.updateDailyReport(updatedReport);

      final index = _dailyReports.indexWhere((r) => r.id == report.id);
      if (index != -1) {
        _dailyReports[index] = updatedReport;
        notifyListeners();
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteDailyReport(String reportId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _dailyReportService.deleteDailyReport(reportId);
      _dailyReports.removeWhere((report) => report.id == reportId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<AttendanceSummary> _getAttendanceSummary(DateTime date) async {
    try {
      final attendances = await _firebaseService.getAttendances();
      final dayAttendances = attendances.where((attendance) {
        return attendance.date.year == date.year &&
            attendance.date.month == date.month &&
            attendance.date.day == date.day;
      }).toList();

      final presentWorkers = dayAttendances.where((a) => a.isPresent).toList();
      final absentWorkers = dayAttendances.where((a) => !a.isPresent).toList();

      return AttendanceSummary(
        totalWorkers: dayAttendances.length,
        presentWorkers: presentWorkers.length,
        absentWorkers: absentWorkers.length,
        attendancePercentage: dayAttendances.isNotEmpty
            ? (presentWorkers.length / dayAttendances.length) * 100
            : 0.0,
        presentWorkerNames: presentWorkers.map((a) => a.personnelName).toList(),
        absentWorkerNames: absentWorkers.map((a) => a.personnelName).toList(),
      );
    } catch (e) {
      // Hata durumunda boş özet döndür
      return AttendanceSummary(
        totalWorkers: 0,
        presentWorkers: 0,
        absentWorkers: 0,
        attendancePercentage: 0.0,
        presentWorkerNames: [],
        absentWorkerNames: [],
      );
    }
  }

  List<DailyReportModel> getReportsByDateRange(DateTime start, DateTime end) {
    return _dailyReports.where((report) {
      return report.date.isAfter(start.subtract(const Duration(days: 1))) &&
          report.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  DailyReportModel? getReportByDate(DateTime date) {
    try {
      return _dailyReports.firstWhere((report) {
        return report.date.year == date.year &&
            report.date.month == date.month &&
            report.date.day == date.day;
      });
    } catch (e) {
      return null;
    }
  }

  List<TaskModel> getPendingTasks() {
    List<TaskModel> pendingTasks = [];
    for (var report in _dailyReports) {
      pendingTasks.addAll(report.todayTasks.where((task) =>
          task.status != TaskStatus.completed &&
          task.status != TaskStatus.cancelled));
    }
    return pendingTasks;
  }

  double getAverageProductivity(int days) {
    if (_dailyReports.isEmpty || days <= 0) return 0.0;

    final recentReports = _dailyReports.take(days).toList();
    if (recentReports.isEmpty) return 0.0;

    final totalProgress =
        recentReports.fold(0.0, (sum, report) => sum + report.overallProgress);
    return totalProgress / recentReports.length;
  }
}
