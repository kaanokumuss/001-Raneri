import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String personnelId;
  final String personnelName;
  final DateTime date;
  final bool isPresent;
  final double workHours;
  final String? notes;

  AttendanceModel({
    required this.id,
    required this.personnelId,
    required this.personnelName,
    required this.date,
    required this.isPresent,
    required this.workHours,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personnelId': personnelId,
      'personnelName': personnelName,
      'date': Timestamp.fromDate(date),
      'isPresent': isPresent,
      'workHours': workHours,
      'notes': notes,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    final timestamp = map['date'];
    DateTime date;

    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      date = DateTime.now(); // fallback
    }

    return AttendanceModel(
      id: map['id'] ?? '',
      personnelId: map['personnelId'] ?? '',
      personnelName: map['personnelName'] ?? '',
      date: date,
      isPresent: map['isPresent'] ?? false,
      workHours: (map['workHours'] ?? 0.0).toDouble(),
      notes: map['notes'],
    );
  }
}

class MonthlyAttendanceSummary {
  final String personnelId;
  final String personnelName;
  final int year;
  final int month;
  final int totalWorkDays;
  final int presentDays;
  final double totalWorkHours;
  final List<AttendanceModel> attendances;

  MonthlyAttendanceSummary({
    required this.personnelId,
    required this.personnelName,
    required this.year,
    required this.month,
    required this.totalWorkDays,
    required this.presentDays,
    required this.totalWorkHours,
    required this.attendances,
  });

  double get attendanceRate =>
      totalWorkDays > 0 ? (presentDays / totalWorkDays) * 100 : 0;
  double get averageWorkHours =>
      presentDays > 0 ? totalWorkHours / presentDays : 0;
}
