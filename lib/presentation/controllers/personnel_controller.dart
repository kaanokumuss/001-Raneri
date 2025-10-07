import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/user_model.dart';
import '../../services/firebase_service.dart';

class PersonnelController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final Uuid _uuid = const Uuid();

  List<PersonnelModel> _personnel = [];
  bool _isLoading = false;
  String? _errorMessage;

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

  Future<bool> addPersonnel({
    required String firstName,
    required String lastName,
    required String title,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final personnel = PersonnelModel(
        id: _uuid.v4(),
        firstName: firstName,
        lastName: lastName,
        title: title,
        createdAt: DateTime.now(),
      );

      await _firebaseService.addPersonnel(personnel);
      _personnel.insert(0, personnel);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deletePersonnel(String personnelId) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firebaseService.deletePersonnel(personnelId);
      _personnel.removeWhere((p) => p.id == personnelId);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> addDocument({
    required String personnelId,
    required String documentName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final document = DocumentModel(
        id: _uuid.v4(),
        name: documentName,
        startDate: startDate,
        endDate: endDate,
      );

      await _firebaseService.addDocumentToPersonnel(personnelId, document);

      // Local state güncelle
      final index = _personnel.indexWhere((p) => p.id == personnelId);
      if (index != -1) {
        _personnel[index] = PersonnelModel(
          id: _personnel[index].id,
          firstName: _personnel[index].firstName,
          lastName: _personnel[index].lastName,
          title: _personnel[index].title,
          createdAt: _personnel[index].createdAt,
          documents: [..._personnel[index].documents, document],
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateDocument({
    required String personnelId,
    required DocumentModel oldDocument,
    required String documentName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final newDocument = DocumentModel(
        id: oldDocument.id,
        name: documentName,
        startDate: startDate,
        endDate: endDate,
      );

      await _firebaseService.updateDocumentInPersonnel(
        personnelId,
        oldDocument,
        newDocument,
      );

      // Local state güncelle
      final index = _personnel.indexWhere((p) => p.id == personnelId);
      if (index != -1) {
        final updatedDocuments = _personnel[index].documents.map((doc) {
          if (doc.id == oldDocument.id) {
            return newDocument;
          }
          return doc;
        }).toList();

        _personnel[index] = PersonnelModel(
          id: _personnel[index].id,
          firstName: _personnel[index].firstName,
          lastName: _personnel[index].lastName,
          title: _personnel[index].title,
          createdAt: _personnel[index].createdAt,
          documents: updatedDocuments,
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteDocument({
    required String personnelId,
    required DocumentModel document,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      await _firebaseService.deleteDocumentFromPersonnel(personnelId, document);

      // Local state güncelle
      final index = _personnel.indexWhere((p) => p.id == personnelId);
      if (index != -1) {
        final updatedDocuments = _personnel[index]
            .documents
            .where((doc) => doc.id != document.id)
            .toList();

        _personnel[index] = PersonnelModel(
          id: _personnel[index].id,
          firstName: _personnel[index].firstName,
          lastName: _personnel[index].lastName,
          title: _personnel[index].title,
          createdAt: _personnel[index].createdAt,
          documents: updatedDocuments,
        );
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }
}
