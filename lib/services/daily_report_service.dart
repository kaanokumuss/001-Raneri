import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/daily_report_model.dart';
import 'firebase_service.dart'; // YENİ EKLEME

class DailyReportService {
  final FirebaseService _firebaseService = FirebaseService(); // YENİ EKLEME

  // Tüm metodları firebase_service'e delege et
  Future<List<DailyReportModel>> getDailyReports() async {
    return await _firebaseService.getDailyReports();
  }

  Future<List<DailyReportModel>> getReportsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _firebaseService.getDailyReportsByDateRange(
        startDate, endDate);
  }

  Future<DailyReportModel?> getReportByDate(DateTime date) async {
    return await _firebaseService.getDailyReportByDate(date);
  }

  Future<void> saveDailyReport(DailyReportModel report) async {
    return await _firebaseService.addDailyReport(report);
  }

  Future<void> updateDailyReport(DailyReportModel report) async {
    return await _firebaseService.updateDailyReport(report);
  }

  Future<void> deleteDailyReport(String reportId) async {
    return await _firebaseService.deleteDailyReport(reportId);
  }

  Future<Map<String, dynamic>> getReportStatistics(int days) async {
    return await _firebaseService.getDailyReportStatistics(days);
  }
}
