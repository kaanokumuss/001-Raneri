import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../personnel/personnel_page.dart';
import '../expenses/expenses_page.dart';
import '../attendance/attendance_page.dart';
import '../attendance/attendance_list_page.dart';
import '../notification/notifications_page.dart';
import '../reports/daily_report_page.dart';
import '../../../data/models/user_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final user = authController.currentUser;
        if (user == null) return const CircularProgressIndicator();

        return Scaffold(
          appBar: AppBar(
            title: Text('Hoş Geldiniz, ${user.firstName}'),
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('Profil'),
                      ],
                    ),
                    onTap: () => _showProfile(context, user),
                  ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Çıkış Yap'),
                      ],
                    ),
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: _buildCategoryCards(context, user.role),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCategoryCards(BuildContext context, UserRole role) {
    if (role == UserRole.admin) {
      return [
        _CategoryCard(
          title: 'Personel Listesi',
          icon: Icons.people,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PersonnelPage()),
          ),
        ),
        _CategoryCard(
          title: 'Harcamalar',
          icon: Icons.receipt_long,
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExpensesPage()),
          ),
        ),
        _CategoryCard(
          title: 'Puantaj',
          icon: Icons.access_time,
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AttendancePage()),
          ),
        ),
        _CategoryCard(
          title: 'Puantaj Listele',
          icon: Icons.list_alt,
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AttendanceListPage()),
          ),
        ),
        _CategoryCard(
          title: 'Bildirimler',
          icon: Icons.notifications,
          color: Colors.red,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
        ),
        _CategoryCard(
          title: 'Günlük Rapor',
          icon: Icons.analytics,
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyReportPage()),
          ),
        ),
      ];
    } else {
      // Çalışan sadece puantaj listeleme görebilir
      return [
        _CategoryCard(
          title: 'Puantaj Listem',
          icon: Icons.list_alt,
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AttendanceListPage()),
          ),
        ),
      ];
    }
  }

  void _showProfile(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Bilgileri'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // ✅ doğru olan
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ad Soyad: ${user.fullName}'),
            const SizedBox(height: 8),
            Text('Ünvan: ${user.title}'),
            const SizedBox(height: 8),
            Text('E-posta: ${user.email}'),
            const SizedBox(height: 8),
            Text(
              'Rol: ${user.role == UserRole.admin ? 'Yönetici' : 'Çalışan'}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthController>().logout();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
