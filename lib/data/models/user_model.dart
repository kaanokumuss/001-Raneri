import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, employee }

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String title;
  final String email;
  final String username;
  UserRole role;
  final DateTime createdAt;
  final bool trackAttendance; // Yeni field

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.title,
    required this.email,
    required this.username,
    required this.role,
    required this.createdAt,
    this.trackAttendance = false, // Default false
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'title': title,
      'email': email,
      'username': username,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'trackAttendance': trackAttendance, // Yeni field
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime createdAt;
    final timestamp = map['createdAt'];
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    } else if (timestamp is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      createdAt = DateTime.now();
    }

    return UserModel(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      title: map['title'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      role: UserRole.values.byName(map['role'] ?? 'employee'),
      createdAt: createdAt,
      trackAttendance: map['trackAttendance'] ?? false, // Yeni field
    );
  }
}

class PersonnelModel {
  final String id;
  final String firstName;
  final String lastName;
  final String title;
  final DateTime createdAt;
  final List<DocumentModel> documents;

  PersonnelModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.title,
    required this.createdAt,
    this.documents = const [],
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'documents': documents.map((doc) => doc.toMap()).toList(),
    };
  }

  factory PersonnelModel.fromMap(Map<String, dynamic> map) {
    DateTime createdAt;
    final timestamp = map['createdAt'];
    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    } else if (timestamp is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      createdAt = DateTime.now();
    }

    return PersonnelModel(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      title: map['title'] ?? '',
      createdAt: createdAt,
      documents: (map['documents'] as List<dynamic>?)
              ?.map((doc) => DocumentModel.fromMap(doc))
              .toList() ??
          [],
    );
  }
}

class DocumentModel {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  DocumentModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    DateTime startDate;
    final startTimestamp = map['startDate'];
    if (startTimestamp is Timestamp) {
      startDate = startTimestamp.toDate();
    } else if (startTimestamp is int) {
      startDate = DateTime.fromMillisecondsSinceEpoch(startTimestamp);
    } else {
      startDate = DateTime.now();
    }

    DateTime endDate;
    final endTimestamp = map['endDate'];
    if (endTimestamp is Timestamp) {
      endDate = endTimestamp.toDate();
    } else if (endTimestamp is int) {
      endDate = DateTime.fromMillisecondsSinceEpoch(endTimestamp);
    } else {
      endDate = DateTime.now();
    }

    return DocumentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      startDate: startDate,
      endDate: endDate,
    );
  }
}
