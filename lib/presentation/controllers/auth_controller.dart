import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../services/firebase_service.dart';

class AuthController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final user = await _firebaseService.signIn(email, password);
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Giriş başarısız: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(
    UserModel user,
    String password,
    String accessCode,
  ) async {
    _setLoading(true);
    _setError(null);

    // Erişim kodu kontrolü
    if (accessCode != '55386153' && accessCode != '123456') {
      _setError('Geçersiz erişim kodu!');
      _setLoading(false);
      return false;
    }

    // Rol belirleme
    user.role = accessCode == '55386153' ? UserRole.admin : UserRole.employee;

    try {
      final registeredUser = await _firebaseService.signUp(user, password);
      if (registeredUser != null) {
        _currentUser = registeredUser;
        _setLoading(false);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Kayıt başarısız: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firebaseService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Şifre sıfırlama başarısız: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> checkAuthState() async {
    final user = await _firebaseService.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }
}
