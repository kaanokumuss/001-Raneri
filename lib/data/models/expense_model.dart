import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final String? notes;

  ExpenseModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date), // Firestore uyumlu
      'category': category,
      'notes': notes,
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    DateTime date;

    final timestamp = map['date'];
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      date = DateTime.now(); // fallback
    }

    return ExpenseModel(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: date,
      category: map['category'] ?? '',
      notes: map['notes'],
    );
  }
}
