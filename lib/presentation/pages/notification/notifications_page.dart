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
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Form validation için eklendi
  String _selectedRecipient = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonnelController>().loadPersonnel();
      _checkDocumentExpirations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      appBar: AppBar(
        title: const Text('Bildirimler'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bildirim Gönder', icon: Icon(Icons.send)),
            Tab(text: 'Belge Uyarıları', icon: Icon(Icons.warning)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSendNotificationTab(), _buildDocumentWarningsTab()],
      ),
    );
  }

  Widget _buildSendNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        // Form widget'ı eklendi
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bildirim Gönder',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 8),

            Text(
              'Çalışanlara manuel bildirim gönderebilirsiniz.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),

            const SizedBox(height: 32),

            // Alıcı seçimi
            Text(
              'Alıcı',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            Consumer<PersonnelController>(
              builder: (context, controller, child) {
                return DropdownButtonFormField<String>(
                  value: _selectedRecipient,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.people),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('Tüm Çalışanlar'),
                    ),
                    ...controller.personnel.map((personnel) {
                      return DropdownMenuItem(
                        value: personnel.id,
                        child: Text(personnel.fullName),
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
                );
              },
            ),

            const SizedBox(height: 24),

            // Başlık
            CustomTextField(
              controller: _titleController,
              label: 'Bildirim Başlığı',
              prefixIcon: Icons.title,
              validator: (value) {
                if (value?.isEmpty == true) return 'Başlık gerekli';
                if (value!.length < 3) return 'Başlık en az 3 karakter olmalı';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Mesaj
            CustomTextField(
              controller: _messageController,
              label: 'Mesaj',
              prefixIcon: Icons.message,
              maxLines: 4,
              validator: (value) {
                if (value?.isEmpty == true) return 'Mesaj gerekli';
                if (value!.length < 10) return 'Mesaj en az 10 karakter olmalı';
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Gönder butonu
            CustomButton(
              onPressed: _isLoading ? null : _sendNotification,
              text: 'Bildirim Gönder',
              isLoading: _isLoading,
              icon: Icons.send,
            ),

            const SizedBox(height: 24),

            // Bilgi kartı
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bilgi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bildirimler Firebase Cloud Messaging üzerinden gönderilir. Kullanıcıların bildirim izinlerini açık tutmaları gerekir.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
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

  Widget _buildDocumentWarningsTab() {
    return Consumer<PersonnelController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                    'Süresi dolmak üzere olan belge yok'), // Yazım hatası düzeltildi
                SizedBox(height: 8),
                Text(
                  'Tüm belgeler geçerli durumda',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Özet kartı
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange.shade700,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dikkat!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${expiringDocuments.length} belgenin süresi 30 gün içinde dolacak',
                            style: TextStyle(color: Colors.orange.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Belgeler listesi
            Expanded(
              child: RefreshIndicator(
                // Yenileme özelliği eklendi
                onRefresh: () async {
                  await context.read<PersonnelController>().loadPersonnel();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
      },
    );
  }

  Future<void> _sendNotification() async {
    // Form validation kontrolü eklendi
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Burada gerçek bildirim gönderme işlemi yapılacak
      // Server-side API'sine istek atmanız gerekir
      await Future.delayed(const Duration(seconds: 2)); // Simulated delay

      // Başarı mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedRecipient == 'all'
                  ? 'Bildirim tüm çalışanlara gönderildi'
                  : 'Bildirim seçili personele gönderildi',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Form temizle
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

class DocumentWarningCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isExpired = daysUntilExpiry < 0;
    final isUrgent = daysUntilExpiry <= 7 && daysUntilExpiry >= 0;

    Color getCardColor() {
      if (isExpired) return Colors.red.shade50;
      if (isUrgent) return Colors.orange.shade50;
      return Colors.yellow.shade50;
    }

    Color getIconColor() {
      if (isExpired) return Colors.red;
      if (isUrgent) return Colors.orange;
      return Colors.yellow.shade700;
    }

    IconData getIcon() {
      if (isExpired) return Icons.error;
      if (isUrgent) return Icons.warning;
      return Icons.schedule;
    }

    String getStatusText() {
      if (isExpired) return '${-daysUntilExpiry} gün önce süresi doldu';
      if (daysUntilExpiry == 0) return 'Bugün süresi doluyor';
      return '$daysUntilExpiry gün kaldı';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: getCardColor(),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: getIconColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(getIcon(), color: getIconColor()),
        ),
        title: Text(
          '${personnel.fullName} - ${document.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bitiş: ${DateFormat('dd/MM/yyyy').format(document.endDate)}'),
            const SizedBox(height: 4),
            Text(
              getStatusText(),
              style: TextStyle(
                color: getIconColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () async {
            // async eklendi
            try {
              await NotificationService.scheduleDocumentExpirationNotification(
                personnelName: personnel.fullName,
                documentName: document.name,
                expirationDate: document.endDate,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hatırlatma bildirimi planlandı'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bildirim planlanamadı: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.notifications_active),
          tooltip: 'Bildirim Gönder',
        ),
      ),
    );
  }
}
