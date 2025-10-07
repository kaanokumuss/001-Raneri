import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/user_model.dart';
import '../../services/firebase_service.dart';

class AttendanceController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  List<AttendanceModel> _attendances = [];
  List<PersonnelModel> _personnel = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AttendanceModel> get attendances => _attendances;
  List<PersonnelModel> get personnel => _personnel;
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

  // DEĞİŞTİRİLDİ: Sadece puantaj takibi aktif olan personeli getir
  Future<void> loadPersonnel() async {
    _setLoading(true);
    _setError(null);

    try {
      _personnel = await _firebaseService.getTrackedPersonnel(); // Değişti
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> loadAttendances() async {
    _setLoading(true);
    _setError(null);

    try {
      _attendances = await _firebaseService.getAttendances();
      _attendances.sort((a, b) => b.date.compareTo(a.date));
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> saveAttendances(
    DateTime date,
    Map<String, Map<String, dynamic>> attendanceData,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      // Aynı tarih için mevcut kayıtları sil
      await _firebaseService.deleteAttendancesByDate(date);

      // Yeni kayıtları ekle
      for (var entry in attendanceData.entries) {
        final personnelId = entry.key;
        final data = entry.value;
        final personnel = _personnel.firstWhere((p) => p.id == personnelId);

        final attendance = AttendanceModel(
          id: _uuid.v4(),
          personnelId: personnelId,
          personnelName: personnel.fullName,
          date: date,
          isPresent: data['isPresent'] as bool,
          workHours: (data['workHours'] as double?) ?? 0.0,
          notes: data['notes'] as String?,
        );

        await _firebaseService.addAttendance(attendance);
      }

      await loadAttendances();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  List<AttendanceModel> getAttendancesByDate(DateTime date) {
    return _attendances.where((attendance) {
      return attendance.date.year == date.year &&
          attendance.date.month == date.month &&
          attendance.date.day == date.day;
    }).toList();
  }

  List<AttendanceModel> getAttendancesByPersonnel(String personnelId) {
    return _attendances.where((attendance) {
      return attendance.personnelId == personnelId;
    }).toList();
  }

  // YENİ: Sadece belirli personelin puantajlarını getir (erişim kontrolü için)
  List<AttendanceModel> getAttendancesByPersonnelFiltered(
    String personnelId,
    UserModel? currentUser,
  ) {
    // Eğer admin değilse sadece kendi puantajını görebilir
    if (currentUser?.role != UserRole.admin && currentUser?.id != personnelId) {
      return [];
    }

    return _attendances.where((attendance) {
      return attendance.personnelId == personnelId;
    }).toList();
  }

  // YENİ: Erişim kontrollü personel listesi
  List<PersonnelModel> getFilteredPersonnel(UserModel? currentUser) {
    if (currentUser?.role == UserRole.admin) {
      // Admin tüm personeli görebilir
      return _personnel;
    } else {
      // Çalışan sadece kendisini görebilir
      if (currentUser != null) {
        return _personnel.where((p) => p.id == currentUser.id).toList();
      }
      return [];
    }
  }

  MonthlyAttendanceSummary getMonthlyAttendanceSummary(
    String personnelId,
    int year,
    int month,
  ) {
    final monthlyAttendances = _attendances.where((attendance) {
      return attendance.personnelId == personnelId &&
          attendance.date.year == year &&
          attendance.date.month == month;
    }).toList();

    final personnel = _personnel.firstWhere(
      (p) => p.id == personnelId,
      orElse: () => PersonnelModel(
        id: personnelId,
        firstName: 'Bilinmeyen',
        lastName: 'Personel',
        title: '',
        createdAt: DateTime.now(),
      ),
    );

    final presentDays = monthlyAttendances.where((a) => a.isPresent).length;
    final totalWorkHours = monthlyAttendances
        .where((a) => a.isPresent)
        .fold(0.0, (sum, a) => sum + a.workHours);

    return MonthlyAttendanceSummary(
      personnelId: personnelId,
      personnelName: personnel.fullName,
      year: year,
      month: month,
      totalWorkDays: monthlyAttendances.length,
      presentDays: presentDays,
      totalWorkHours: totalWorkHours,
      attendances: monthlyAttendances,
    );
  }

  // YENİ: Erişim kontrollü aylık özet
  MonthlyAttendanceSummary? getMonthlyAttendanceSummaryFiltered(
    String personnelId,
    int year,
    int month,
    UserModel? currentUser,
  ) {
    // Eğer admin değilse ve kendi ID'si değilse null döndür
    if (currentUser?.role != UserRole.admin && currentUser?.id != personnelId) {
      return null;
    }

    return getMonthlyAttendanceSummary(personnelId, year, month);
  }

  Map<String, List<AttendanceModel>> getAttendancesByPersonnelGrouped() {
    Map<String, List<AttendanceModel>> grouped = {};
    for (var attendance in _attendances) {
      if (!grouped.containsKey(attendance.personnelId)) {
        grouped[attendance.personnelId] = [];
      }
      grouped[attendance.personnelId]!.add(attendance);
    }
    return grouped;
  }
}
