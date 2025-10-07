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
import '../reports/daily_report_page.dart'; // YENİ EKLEME

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final user = authController.currentUser;
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1DE9B6),
              ),
            ),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(context, user),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1DE9B6), // Raneri yeşili
                  Color(0xFF26A69A), // Orta teal
                  Color(0xFF00ACC1), // Cyan-mavi
                  Color(0xFF455A64), // Koyu gri-mavi
                  Color(0xFF37474F), // Çok koyu gri
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Arka plan pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: HomePatternPainter(),
                  ),
                ),

                // Ana içerik
                SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Hoşgeldin başlığı
                        _buildWelcomeHeader(user),

                        const SizedBox(height: 32),

                        // Dashboard grid
                        Expanded(
                          child: _buildDashboardGrid(context, user.role, size),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, UserModel user) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: ClipRRect(
          child: Container(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Raneri Energy',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[700]),
                    const SizedBox(width: 12),
                    const Text('Profil'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red[600]),
                    const SizedBox(width: 12),
                    Text('Çıkış Yap', style: TextStyle(color: Colors.red[600])),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'profile') {
                _showProfile(context, user);
              } else if (value == 'logout') {
                _logout(context);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeHeader(UserModel user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1DE9B6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş Geldiniz',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DE9B6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.role == UserRole.admin ? 'Yönetici' : 'Çalışan',
                    style: TextStyle(
                      color: const Color(0xFF1DE9B6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid(BuildContext context, UserRole role, Size size) {
    final cards = _buildCategoryCards(context, role);
    final crossAxisCount = size.width > 600 ? 3 : 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: cards,
      ),
    );
  }

  // _buildCategoryCards metodunu güncelleyin:

  List<Widget> _buildCategoryCards(BuildContext context, UserRole role) {
    if (role == UserRole.admin) {
      return [
        _CategoryCard(
          title: 'Personel\nListesi',
          icon: Icons.people,
          gradient: const LinearGradient(
            colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PersonnelPage()),
          ),
        ),
        _CategoryCard(
          title: 'Harcama\nYönetimi',
          icon: Icons.receipt_long,
          gradient: const LinearGradient(
            colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExpensesPage()),
          ),
        ),
        _CategoryCard(
          title: 'Puantaj\nSistemi',
          icon: Icons.access_time,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AttendancePage()),
          ),
        ),
        _CategoryCard(
          title: 'Puantaj\nListele',
          icon: Icons.list_alt,
          gradient: const LinearGradient(
            colors: [Color(0xFFAB47BC), Color(0xFF9C27B0)],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AttendanceListPage()),
          ),
        ),
        // YENİ EKLENEN GÜNLÜK RAPOR KARTI
        _CategoryCard(
          title: 'Günlük\nRapor',
          icon: Icons.analytics,
          gradient: const LinearGradient(
            colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyReportPage()),
          ),
        ),
        _CategoryCard(
          title: 'Bildirim\nMerkezi',
          icon: Icons.notifications,
          gradient: const LinearGradient(
            colors: [Color(0xFFEF5350), Color(0xFFE53935)],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsPage()),
          ),
        ),
      ];
    } else {
      return [
        _CategoryCard(
          title: 'Puantaj\nListem',
          icon: Icons.list_alt,
          gradient: const LinearGradient(
            colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AttendanceListPage()),
          ),
        ),
        // ÇALIŞANLAR İÇİN GÜNLÜK RAPOR GÖRÜNTÜLEME
        _CategoryCard(
          title: 'Günlük\nRaporlar',
          icon: Icons.assignment,
          gradient: const LinearGradient(
            colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyReportPage()),
          ),
        ),
      ];
    }
  }

  void _showProfile(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Profil Bilgileri',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProfileRow(label: 'Ad Soyad', value: user.fullName),
            _ProfileRow(label: 'Ünvan', value: user.title),
            _ProfileRow(label: 'E-posta', value: user.email),
            _ProfileRow(
              label: 'Rol',
              value: user.role == UserRole.admin ? 'Yönetici' : 'Çalışan',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Kapat',
              style: TextStyle(color: Color(0xFF26A69A)),
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Çıkış Yap',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthController>().logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _controller.forward().then((_) {
                _controller.reverse();
                widget.onTap();
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient.colors[0].withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Home sayfası için pattern painter
class HomePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final accentPaint = Paint()
      ..color = const Color(0xFF1DE9B6).withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Grid pattern
    final gridSpacing = size.width / 8;
    for (int i = 1; i < 8; i++) {
      final x = gridSpacing * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    final verticalSpacing = size.height / 10;
    for (int i = 1; i < 10; i++) {
      final y = verticalSpacing * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Dashboard icons pattern
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 3; j++) {
        final x = (size.width / 4) * i + (size.width / 8);
        final y = (size.height / 3) * j + (size.height / 6);

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 20, height: 20),
            const Radius.circular(4),
          ),
          (i + j) % 2 == 0 ? paint : accentPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
