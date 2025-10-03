import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';
import '../data/models/expense_model.dart';
import '../data/models/attendance_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication Methods
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final userDoc =
            await _firestore.collection('users').doc(result.user!.uid).get();

        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data()!);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Giriş hatası: ${e.toString()}');
    }
  }

  Future<UserModel?> signUp(UserModel user, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      if (result.user != null) {
        final userWithId = UserModel(
          id: result.user!.uid,
          firstName: user.firstName,
          lastName: user.lastName,
          title: user.title,
          email: user.email,
          username: user.username,
          role: user.role,
          createdAt: user.createdAt,
        );

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(userWithId.toMap());

        // Email verification gönder
        await result.user!.sendEmailVerification();

        return userWithId;
      }
      return null;
    } catch (e) {
      throw Exception('Kayıt hatası: ${e.toString()}');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Şifre sıfırlama hatası: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data()!);
      }
    }
    return null;
  }

  // Personnel Methods
  Future<List<PersonnelModel>> getPersonnel() async {
    try {
      final querySnapshot = await _firestore
          .collection('personnel')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PersonnelModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Personel listesi alınamadı: ${e.toString()}');
    }
  }

  Future<void> addPersonnel(PersonnelModel personnel) async {
    try {
      await _firestore
          .collection('personnel')
          .doc(personnel.id)
          .set(personnel.toMap());
    } catch (e) {
      throw Exception('Personel eklenemedi: ${e.toString()}');
    }
  }

  Future<void> deletePersonnel(String personnelId) async {
    try {
      await _firestore.collection('personnel').doc(personnelId).delete();
    } catch (e) {
      throw Exception('Personel silinemedi: ${e.toString()}');
    }
  }

  Future<void> addDocumentToPersonnel(
    String personnelId,
    DocumentModel document,
  ) async {
    try {
      await _firestore.collection('personnel').doc(personnelId).update({
        'documents': FieldValue.arrayUnion([document.toMap()]),
      });
    } catch (e) {
      throw Exception('Belge eklenemedi: ${e.toString()}');
    }
  }

  Future<void> updateDocumentInPersonnel(
    String personnelId,
    DocumentModel oldDocument,
    DocumentModel newDocument,
  ) async {
    try {
      // Önce eski belgeyi array'den çıkar
      await _firestore.collection('personnel').doc(personnelId).update({
        'documents': FieldValue.arrayRemove([oldDocument.toMap()]),
      });

      // Sonra yeni belgeyi array'e ekle
      await _firestore.collection('personnel').doc(personnelId).update({
        'documents': FieldValue.arrayUnion([newDocument.toMap()]),
      });
    } catch (e) {
      throw Exception('Belge güncellenemedi: ${e.toString()}');
    }
  }

  Future<void> deleteDocumentFromPersonnel(
    String personnelId,
    DocumentModel document,
  ) async {
    try {
      await _firestore.collection('personnel').doc(personnelId).update({
        'documents': FieldValue.arrayRemove([document.toMap()]),
      });
    } catch (e) {
      throw Exception('Belge silinemedi: ${e.toString()}');
    }
  }

  // Expense Methods
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final querySnapshot = await _firestore
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Harcamalar alınamadı: ${e.toString()}');
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _firestore
          .collection('expenses')
          .doc(expense.id)
          .set(expense.toMap());
    } catch (e) {
      throw Exception('Harcama eklenemedi: ${e.toString()}');
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestore.collection('expenses').doc(expenseId).delete();
    } catch (e) {
      throw Exception('Harcama silinemedi: ${e.toString()}');
    }
  }

  // Attendance Methods
  Future<List<AttendanceModel>> getAttendances() async {
    try {
      final querySnapshot = await _firestore
          .collection('attendances')
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AttendanceModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Puantaj kayıtları alınamadı: ${e.toString()}');
    }
  }

  Future<void> addAttendance(AttendanceModel attendance) async {
    try {
      await _firestore
          .collection('attendances')
          .doc(attendance.id)
          .set(attendance.toMap());
    } catch (e) {
      throw Exception('Puantaj eklenemedi: ${e.toString()}');
    }
  }

  Future<void> deleteAttendancesByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('attendances')
          .where(
            'date',
            isGreaterThanOrEqualTo: startOfDay.millisecondsSinceEpoch,
          )
          .where('date', isLessThanOrEqualTo: endOfDay.millisecondsSinceEpoch)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Puantaj kayıtları silinemedi: ${e.toString()}');
    }
  }
}
