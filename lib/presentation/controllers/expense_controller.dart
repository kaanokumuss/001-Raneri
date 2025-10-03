import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/expense_model.dart';
import '../../services/firebase_service.dart';

class ExpenseController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ExpenseModel> get expenses => _expenses;
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

  Future<void> loadExpenses() async {
    _setLoading(true);
    _setError(null);

    try {
      _expenses = await _firebaseService.getExpenses();
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<bool> addExpense({
    required String description,
    required double amount,
    required DateTime date,
    required String category,
    String? notes,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final expense = ExpenseModel(
        id: _uuid.v4(),
        description: description,
        amount: amount,
        date: date,
        category: category,
        notes: notes,
      );

      await _firebaseService.addExpense(expense);
      _expenses.insert(0, expense);
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firebaseService.deleteExpense(expenseId);
      _expenses.removeWhere((e) => e.id == expenseId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  List<ExpenseModel> getExpensesByMonth(int year, int month) {
    return _expenses.where((expense) {
      return expense.date.year == year && expense.date.month == month;
    }).toList();
  }

  double getTotalAmount() {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  double getMonthlyTotal(int year, int month) {
    return getExpensesByMonth(
      year,
      month,
    ).fold(0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> getCategoryTotals() {
    Map<String, double> categoryTotals = {};
    for (var expense in _expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }
}
