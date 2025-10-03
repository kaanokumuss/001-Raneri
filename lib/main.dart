import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/personnel_controller.dart';
import 'presentation/controllers/expense_controller.dart';
import 'presentation/controllers/attendance_controller.dart';
import 'presentation/pages/auth/splash_page.dart';
import 'presentation/themes/app_theme.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locale verilerini başlat - hem tr_TR hem de en_US için
  await initializeDateFormatting('tr_TR', null);
  await initializeDateFormatting('en_US', null);

  await Firebase.initializeApp();
  await NotificationService.initialize();

  runApp(const PersonnelTrackerApp());
}

class PersonnelTrackerApp extends StatelessWidget {
  const PersonnelTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => PersonnelController()),
        ChangeNotifierProvider(create: (_) => ExpenseController()),
        ChangeNotifierProvider(create: (_) => AttendanceController()),
      ],
      child: MaterialApp(
        title: 'Personel Takip',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashPage(),
        locale: const Locale('tr', 'TR'), // Türkçe locale
        supportedLocales: const [
          Locale('tr', 'TR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
