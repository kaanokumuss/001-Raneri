import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/user_model.dart';
import '../data/models/expense_model.dart';
import '../data/models/attendance_model.dart';
import '../data/models/daily_report_model.dart';

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
          trackAttendance: user.trackAttendance, // Yeni field
        );

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(userWithId.toMap());

        // YENİ: Eğer puantaj takibi aktifse otomatik personel olarak ekle
        if (user.trackAttendance) {
          await _addUserAsPersonnel(userWithId);
        }

        // Email verification gönder
        await result.user!.sendEmailVerification();

        return userWithId;
      }
      return null;
    } catch (e) {
      throw Exception('Kayıt hatası: ${e.toString()}');
    }
  }

  // YENİ: Kullanıcıyı otomatik personel olarak ekleme metodu
  Future<void> _addUserAsPersonnel(UserModel user) async {
    try {
      final personnel = PersonnelModel(
        id: user.id, // Aynı ID kullan
        firstName: user.firstName,
        lastName: user.lastName,
        title: user.title,
        createdAt: user.createdAt,
        documents: [], // Boş liste
      );

      await _firestore
          .collection('personnel')
          .doc(personnel.id)
          .set(personnel.toMap());
    } catch (e) {
      throw Exception('Personel ekleme hatası: ${e.toString()}');
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

  // YENİ: Sadece puantaj takibi aktif olan personeli getir
  Future<List<PersonnelModel>> getTrackedPersonnel() async {
    try {
      // Önce users koleksiyonundan trackAttendance=true olanları al
      final usersSnapshot = await _firestore
          .collection('users')
          .where('trackAttendance', isEqualTo: true)
          .get();

      List<PersonnelModel> trackedPersonnel = [];

      for (var userDoc in usersSnapshot.docs) {
        // Her user için personnel koleksiyonundan bilgileri al
        final personnelDoc =
            await _firestore.collection('personnel').doc(userDoc.id).get();

        if (personnelDoc.exists) {
          trackedPersonnel.add(PersonnelModel.fromMap(personnelDoc.data()!));
        }
      }

      trackedPersonnel.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return trackedPersonnel;
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
  // Mevcut FirebaseService sınıfına ekleyin:

// Daily Report Methods (sınıfın sonuna ekleyin)
  Future<List<DailyReportModel>> getDailyReports() async {
    try {
      final querySnapshot = await _firestore
          .collection('daily_reports')
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DailyReportModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Günlük raporlar alınamadı: ${e.toString()}');
    }
  }

  Future<List<DailyReportModel>> getDailyReportsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('daily_reports')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DailyReportModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Tarih aralığındaki raporlar alınamadı: ${e.toString()}');
    }
  }

  Future<DailyReportModel?> getDailyReportByDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('daily_reports')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return DailyReportModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('Günlük rapor alınamadı: ${e.toString()}');
    }
  }

  Future<void> addDailyReport(DailyReportModel report) async {
    try {
      await _firestore
          .collection('daily_reports')
          .doc(report.id)
          .set(report.toMap());
    } catch (e) {
      throw Exception('Günlük rapor eklenemedi: ${e.toString()}');
    }
  }

  Future<void> updateDailyReport(DailyReportModel report) async {
    try {
      await _firestore
          .collection('daily_reports')
          .doc(report.id)
          .update(report.toMap());
    } catch (e) {
      throw Exception('Günlük rapor güncellenemedi: ${e.toString()}');
    }
  }

  Future<void> deleteDailyReport(String reportId) async {
    try {
      await _firestore.collection('daily_reports').doc(reportId).delete();
    } catch (e) {
      throw Exception('Günlük rapor silinemedi: ${e.toString()}');
    }
  }

// Daily Report Statistics
  Future<Map<String, dynamic>> getDailyReportStatistics(int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final reports = await getDailyReportsByDateRange(startDate, endDate);

      if (reports.isEmpty) {
        return {
          'totalReports': 0,
          'averageProgress': 0.0,
          'totalTasks': 0,
          'completedTasks': 0,
          'averageAttendance': 0.0,
          'totalMaterialCost': 0.0,
          'safetyIncidents': 0,
        };
      }

      final totalTasks =
          reports.fold(0, (sum, report) => sum + report.todayTasks.length);
      final completedTasks = reports.fold(
          0,
          (sum, report) =>
              sum +
              report.todayTasks
                  .where((task) => task.status == TaskStatus.completed)
                  .length);

      final averageProgress =
          reports.fold(0.0, (sum, report) => sum + report.overallProgress) /
              reports.length;

      final averageAttendance = reports.fold(
              0.0,
              (sum, report) =>
                  sum + report.attendanceSummary.attendancePercentage) /
          reports.length;

      final totalMaterialCost = reports.fold(
          0.0,
          (sum, report) =>
              sum +
              report.materialsUsed.fold(0.0,
                  (materialSum, material) => materialSum + material.totalCost));

      final safetyIncidents =
          reports.fold(0, (sum, report) => sum + report.safetyIncidents.length);

      return {
        'totalReports': reports.length,
        'averageProgress': averageProgress,
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'averageAttendance': averageAttendance,
        'totalMaterialCost': totalMaterialCost,
        'safetyIncidents': safetyIncidents,
      };
    } catch (e) {
      throw Exception('İstatistikler alınamadı: ${e.toString()}');
    }
  }
}
