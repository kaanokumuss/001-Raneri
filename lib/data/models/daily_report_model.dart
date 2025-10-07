import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { notStarted, inProgress, completed, delayed, cancelled }

enum WeatherCondition { sunny, rainy, cloudy, stormy, snowy }

enum SafetyLevel { low, medium, high, critical }

class DailyReportModel {
  final String id;
  final DateTime date;
  final String projectName;
  final String reportedBy;
  final String reportedById;
  final List<TaskModel> todayTasks;
  final List<TaskModel> tomorrowPlans;
  final AttendanceSummary attendanceSummary;
  final List<MaterialUsage> materialsUsed;
  final WeatherInfo weatherInfo;
  final List<SafetyIncident> safetyIncidents;
  final List<String> photoUrls;
  final String generalNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DailyReportModel({
    required this.id,
    required this.date,
    required this.projectName,
    required this.reportedBy,
    required this.reportedById,
    required this.todayTasks,
    required this.tomorrowPlans,
    required this.attendanceSummary,
    required this.materialsUsed,
    required this.weatherInfo,
    required this.safetyIncidents,
    required this.photoUrls,
    required this.generalNotes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': Timestamp.fromDate(date),
      'projectName': projectName,
      'reportedBy': reportedBy,
      'reportedById': reportedById,
      'todayTasks': todayTasks.map((task) => task.toMap()).toList(),
      'tomorrowPlans': tomorrowPlans.map((task) => task.toMap()).toList(),
      'attendanceSummary': attendanceSummary.toMap(),
      'materialsUsed':
          materialsUsed.map((material) => material.toMap()).toList(),
      'weatherInfo': weatherInfo.toMap(),
      'safetyIncidents':
          safetyIncidents.map((incident) => incident.toMap()).toList(),
      'photoUrls': photoUrls,
      'generalNotes': generalNotes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory DailyReportModel.fromMap(Map<String, dynamic> map) {
    return DailyReportModel(
      id: map['id'] ?? '',
      date: _parseDate(map['date']),
      projectName: map['projectName'] ?? '',
      reportedBy: map['reportedBy'] ?? '',
      reportedById: map['reportedById'] ?? '',
      todayTasks: (map['todayTasks'] as List<dynamic>?)
              ?.map((task) => TaskModel.fromMap(task))
              .toList() ??
          [],
      tomorrowPlans: (map['tomorrowPlans'] as List<dynamic>?)
              ?.map((task) => TaskModel.fromMap(task))
              .toList() ??
          [],
      attendanceSummary:
          AttendanceSummary.fromMap(map['attendanceSummary'] ?? {}),
      materialsUsed: (map['materialsUsed'] as List<dynamic>?)
              ?.map((material) => MaterialUsage.fromMap(material))
              .toList() ??
          [],
      weatherInfo: WeatherInfo.fromMap(map['weatherInfo'] ?? {}),
      safetyIncidents: (map['safetyIncidents'] as List<dynamic>?)
              ?.map((incident) => SafetyIncident.fromMap(incident))
              .toList() ??
          [],
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      generalNotes: map['generalNotes'] ?? '',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? _parseDate(map['updatedAt']) : null,
    );
  }

  static DateTime _parseDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return DateTime.now();
    }
  }

  double get overallProgress {
    if (todayTasks.isEmpty) return 0.0;
    final totalProgress =
        todayTasks.fold(0.0, (sum, task) => sum + task.completionPercentage);
    return totalProgress / todayTasks.length;
  }
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final double completionPercentage;
  final int assignedWorkers;
  final String priority; // high, medium, low
  final DateTime? startTime;
  final DateTime? endTime;
  final String? notes;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.completionPercentage,
    required this.assignedWorkers,
    required this.priority,
    this.startTime,
    this.endTime,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'completionPercentage': completionPercentage,
      'assignedWorkers': assignedWorkers,
      'priority': priority,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'notes': notes,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TaskStatus.notStarted,
      ),
      completionPercentage: (map['completionPercentage'] ?? 0.0).toDouble(),
      assignedWorkers: map['assignedWorkers'] ?? 0,
      priority: map['priority'] ?? 'medium',
      startTime: map['startTime'] != null
          ? DailyReportModel._parseDate(map['startTime'])
          : null,
      endTime: map['endTime'] != null
          ? DailyReportModel._parseDate(map['endTime'])
          : null,
      notes: map['notes'],
    );
  }
}

class AttendanceSummary {
  final int totalWorkers;
  final int presentWorkers;
  final int absentWorkers;
  final double attendancePercentage;
  final List<String> presentWorkerNames;
  final List<String> absentWorkerNames;

  AttendanceSummary({
    required this.totalWorkers,
    required this.presentWorkers,
    required this.absentWorkers,
    required this.attendancePercentage,
    required this.presentWorkerNames,
    required this.absentWorkerNames,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalWorkers': totalWorkers,
      'presentWorkers': presentWorkers,
      'absentWorkers': absentWorkers,
      'attendancePercentage': attendancePercentage,
      'presentWorkerNames': presentWorkerNames,
      'absentWorkerNames': absentWorkerNames,
    };
  }

  factory AttendanceSummary.fromMap(Map<String, dynamic> map) {
    return AttendanceSummary(
      totalWorkers: map['totalWorkers'] ?? 0,
      presentWorkers: map['presentWorkers'] ?? 0,
      absentWorkers: map['absentWorkers'] ?? 0,
      attendancePercentage: (map['attendancePercentage'] ?? 0.0).toDouble(),
      presentWorkerNames: List<String>.from(map['presentWorkerNames'] ?? []),
      absentWorkerNames: List<String>.from(map['absentWorkerNames'] ?? []),
    );
  }
}

class MaterialUsage {
  final String id;
  final String materialName;
  final String unit; // kg, m3, adet, etc.
  final double quantity;
  final double unitPrice;
  final String supplier;
  final String notes;

  MaterialUsage({
    required this.id,
    required this.materialName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.supplier,
    required this.notes,
  });

  double get totalCost => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materialName': materialName,
      'unit': unit,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'supplier': supplier,
      'notes': notes,
    };
  }

  factory MaterialUsage.fromMap(Map<String, dynamic> map) {
    return MaterialUsage(
      id: map['id'] ?? '',
      materialName: map['materialName'] ?? '',
      unit: map['unit'] ?? '',
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      supplier: map['supplier'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}

class WeatherInfo {
  final WeatherCondition condition;
  final double temperature;
  final String description;
  final bool affectedWork;
  final String? workImpact;

  WeatherInfo({
    required this.condition,
    required this.temperature,
    required this.description,
    required this.affectedWork,
    this.workImpact,
  });

  Map<String, dynamic> toMap() {
    return {
      'condition': condition.name,
      'temperature': temperature,
      'description': description,
      'affectedWork': affectedWork,
      'workImpact': workImpact,
    };
  }

  factory WeatherInfo.fromMap(Map<String, dynamic> map) {
    return WeatherInfo(
      condition: WeatherCondition.values.firstWhere(
        (e) => e.name == map['condition'],
        orElse: () => WeatherCondition.sunny,
      ),
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      affectedWork: map['affectedWork'] ?? false,
      workImpact: map['workImpact'],
    );
  }
}

class SafetyIncident {
  final String id;
  final String title;
  final String description;
  final SafetyLevel severity;
  final DateTime time;
  final String involvedPersonnel;
  final String actionTaken;
  final bool resolved;

  SafetyIncident({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.time,
    required this.involvedPersonnel,
    required this.actionTaken,
    required this.resolved,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.name,
      'time': Timestamp.fromDate(time),
      'involvedPersonnel': involvedPersonnel,
      'actionTaken': actionTaken,
      'resolved': resolved,
    };
  }

  factory SafetyIncident.fromMap(Map<String, dynamic> map) {
    return SafetyIncident(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      severity: SafetyLevel.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => SafetyLevel.low,
      ),
      time: DailyReportModel._parseDate(map['time']),
      involvedPersonnel: map['involvedPersonnel'] ?? '',
      actionTaken: map['actionTaken'] ?? '',
      resolved: map['resolved'] ?? false,
    );
  }
}
