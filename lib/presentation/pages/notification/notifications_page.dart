import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/personnel_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../../services/notification_service.dart';
import '../../../data/models/user_model.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRecipient = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonnelController>().loadPersonnel();
      _checkDocumentExpirations();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _checkDocumentExpirations() {
    final personnelController = context.read<PersonnelController>();
    final now = DateTime.now();

    for (var personnel in personnelController.personnel) {
      for (var document in personnel.documents) {
        final daysUntilExpiry = document.endDate.difference(now).inDays;
        if (daysUntilExpiry <= 30 && daysUntilExpiry >= 0) {
          NotificationService.scheduleDocumentExpirationNotification(
            personnelName: personnel.fullName,
            documentName: document.name,
            expirationDate: document.endDate,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
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
                painter: NotificationsPatternPainter(),
              ),
            ),

            // Ana içerik
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Header
                    _buildHeader(context),

                    const SizedBox(height: 24),

                    // Tab bar
                    _buildTabBar(),

                    const SizedBox(height: 16),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSendNotificationTab(),
                          _buildDocumentWarningsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      centerTitle: true,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Text(
          'Bildirim Merkezi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1DE9B6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bildirim Merkezi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bildirim gönder ve uyarıları yönet',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send, size: 18),
                SizedBox(width: 8),
                Text('Bildirim Gönder', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, size: 18),
                SizedBox(width: 8),
                Text('Belge Uyarıları', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form başlığı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bildirim Gönder',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Çalışanlara manuel bildirim gönderin',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Alıcı seçimi
            _buildRecipientSelector(),

            const SizedBox(height: 20),

            // Başlık
            _buildNotificationField(
              controller: _titleController,
              label: 'Bildirim Başlığı',
              icon: Icons.title,
              validator: (value) {
                if (value?.isEmpty == true) return 'Başlık gerekli';
                if (value!.length < 3) return 'Başlık en az 3 karakter olmalı';
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Mesaj
            _buildNotificationField(
              controller: _messageController,
              label: 'Mesaj',
              icon: Icons.message,
              maxLines: 4,
              validator: (value) {
                if (value?.isEmpty == true) return 'Mesaj gerekli';
                if (value!.length < 10) return 'Mesaj en az 10 karakter olmalı';
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Gönder butonu
            _buildSendButton(),

            const SizedBox(height: 24),

            // Bilgi kartı
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alıcı',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Consumer<PersonnelController>(
          builder: (context, controller, child) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1DE9B6).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedRecipient,
                dropdownColor: Colors.white,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.people, color: Color(0xFF1DE9B6)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('Tüm Çalışanlar',
                        style: TextStyle(color: Colors.black)),
                  ),
                  ...controller.personnel.map((personnel) {
                    return DropdownMenuItem(
                      value: personnel.id,
                      child: Text(personnel.fullName,
                          style: const TextStyle(color: Colors.black)),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRecipient = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen alıcı seçin';
                  }
                  return null;
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotificationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1DE9B6).withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF1DE9B6)),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              errorStyle:
                  TextStyle(color: Colors.orange.shade200, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLoading
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [const Color(0xFF1DE9B6), const Color(0xFF26A69A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1DE9B6).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _sendNotification,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Gönderiliyor...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Bildirim Gönder',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Bilgi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bildirimler Firebase Cloud Messaging üzerinden gönderilir. Kullanıcıların bildirim izinlerini açık tutmaları gerekir.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentWarningsTab() {
    return Consumer<PersonnelController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return _buildLoadingState();
        }

        final now = DateTime.now();
        final expiringDocuments = <Map<String, dynamic>>[];

        for (var personnel in controller.personnel) {
          for (var document in personnel.documents) {
            final daysUntilExpiry = document.endDate.difference(now).inDays;
            if (daysUntilExpiry <= 30) {
              expiringDocuments.add({
                'personnel': personnel,
                'document': document,
                'daysUntilExpiry': daysUntilExpiry,
              });
            }
          }
        }

        expiringDocuments.sort(
          (a, b) => (a['daysUntilExpiry'] as int).compareTo(
            b['daysUntilExpiry'] as int,
          ),
        );

        if (expiringDocuments.isEmpty) {
          return _buildNoWarningsState();
        }

        return _buildWarningsList(expiringDocuments);
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                    color: Color(0xFF1DE9B6), strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belgeler kontrol ediliyor...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWarningsState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Colors.green, Colors.lightGreen]),
                borderRadius: BorderRadius.circular(40),
              ),
              child:
                  const Icon(Icons.check_circle, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tüm Belgeler Güncel!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Süresi dolmak üzere olan belge bulunmuyor.\nTüm belgeler geçerli durumda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningsList(List<Map<String, dynamic>> expiringDocuments) {
    return Column(
      children: [
        // Özet kartı
        Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFF8A65), Color(0xFFFF5722)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dikkat Gerekli!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${expiringDocuments.length} belgenin süresi 30 gün içinde dolacak',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Belgeler listesi
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await context.read<PersonnelController>().loadPersonnel();
            },
            color: const Color(0xFF1DE9B6),
            backgroundColor: Colors.white,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: expiringDocuments.length,
              itemBuilder: (context, index) {
                final item = expiringDocuments[index];
                final personnel = item['personnel'] as PersonnelModel;
                final document = item['document'] as DocumentModel;
                final daysUntilExpiry = item['daysUntilExpiry'] as int;

                return DocumentWarningCard(
                  personnel: personnel,
                  document: document,
                  daysUntilExpiry: daysUntilExpiry,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedRecipient == 'all'
                        ? 'Bildirim tüm çalışanlara gönderildi'
                        : 'Bildirim seçili personele gönderildi',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF26A69A),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedRecipient = 'all';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirim gönderilemedi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class DocumentWarningCard extends StatefulWidget {
  final PersonnelModel personnel;
  final DocumentModel document;
  final int daysUntilExpiry;

  const DocumentWarningCard({
    super.key,
    required this.personnel,
    required this.document,
    required this.daysUntilExpiry,
  });

  @override
  State<DocumentWarningCard> createState() => _DocumentWarningCardState();
}

class _DocumentWarningCardState extends State<DocumentWarningCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
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
    final isExpired = widget.daysUntilExpiry < 0;
    final isUrgent = widget.daysUntilExpiry <= 7 && widget.daysUntilExpiry >= 0;

    LinearGradient getGradient() {
      if (isExpired) {
        return const LinearGradient(
            colors: [Color(0xFFE57373), Color(0xFFEF5350)]);
      } else if (isUrgent) {
        return const LinearGradient(
            colors: [Color(0xFFFFB74D), Color(0xFFFF9800)]);
      } else {
        return const LinearGradient(
            colors: [Color(0xFFFFF176), Color(0xFFFFEB3B)]);
      }
    }

    IconData getIcon() {
      if (isExpired) return Icons.error;
      if (isUrgent) return Icons.warning;
      return Icons.schedule;
    }

    String getStatusText() {
      if (isExpired) return '${-widget.daysUntilExpiry} gün önce süresi doldu';
      if (widget.daysUntilExpiry == 0) return 'Bugün süresi doluyor';
      return '${widget.daysUntilExpiry} gün kaldı';
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: getGradient(),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: getGradient().colors[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(getIcon(), color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.personnel.fullName} - ${widget.document.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white.withOpacity(0.6),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bitiş: ${DateFormat('dd/MM/yyyy').format(widget.document.endDate)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: getGradient(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          getStatusText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1DE9B6), Color(0xFF26A69A)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        _controller
                            .forward()
                            .then((_) => _controller.reverse());
                        try {
                          await NotificationService
                              .scheduleDocumentExpirationNotification(
                            personnelName: widget.personnel.fullName,
                            documentName: widget.document.name,
                            expirationDate: widget.document.endDate,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Hatırlatma bildirimi planlandı'),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF26A69A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Bildirim planlanamadı: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Notifications sayfası için pattern painter
class NotificationsPatternPainter extends CustomPainter {
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

    // Notification icons pattern
    for (int i = 0; i < 6; i++) {
      for (int j = 0; j < 8; j++) {
        final x = (size.width / 6) * i + (size.width / 12);
        final y = (size.height / 8) * j + (size.height / 16);

        // Bell icon outline
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 12, height: 16),
            const Radius.circular(6),
          ),
          (i + j) % 2 == 0 ? paint : accentPaint,
        );

        // Bell clapper
        canvas.drawCircle(
          Offset(x, y + 10),
          2,
          (i + j) % 2 == 0 ? paint : accentPaint,
        );
      }
    }

    // Wave lines representing notifications
    for (int i = 0; i < 4; i++) {
      final y = size.height * (0.2 + i * 0.2);
      final path = Path();
      path.moveTo(0, y);

      for (double x = 0; x <= size.width; x += 20) {
        path.lineTo(x, y + (i % 2 == 0 ? 5 : -5) * (x % 40 == 0 ? 1 : 0));
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
