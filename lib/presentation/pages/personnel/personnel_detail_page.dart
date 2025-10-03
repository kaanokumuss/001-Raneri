import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/personnel_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../../data/models/user_model.dart';

class PersonnelDetailPage extends StatefulWidget {
  final PersonnelModel personnel;

  const PersonnelDetailPage({super.key, required this.personnel});

  @override
  State<PersonnelDetailPage> createState() => _PersonnelDetailPageState();
}

class _PersonnelDetailPageState extends State<PersonnelDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.personnel.fullName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personel Bilgileri Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          child: Text(
                            widget.personnel.firstName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.personnel.fullName,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              Text(
                                widget.personnel.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                              Text(
                                'Kayıt: ${DateFormat('dd MMMM yyyy', 'tr').format(widget.personnel.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Belgeler Bölümü
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Belgeler', style: Theme.of(context).textTheme.titleLarge),
                ElevatedButton.icon(
                  onPressed: () => _showAddDocumentDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Belge Ekle'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (widget.personnel.documents.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz belge eklenmemiş',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.personnel.documents.length,
                itemBuilder: (context, index) {
                  final document = widget.personnel.documents[index];
                  return DocumentCard(
                    document: document,
                    personnel: widget.personnel,
                    onEdit: () => _showEditDocumentDialog(context, document),
                    onDelete: () => _deleteDocument(context, document),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddDocumentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Belge Ekle'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Belge Adı',
                  validator: (value) =>
                      value?.isEmpty == true ? 'Belge adı gerekli' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() => startDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          startDate != null
                              ? DateFormat('dd/MM/yyyy').format(startDate!)
                              : 'Başlangıç Tarihi',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: startDate ?? DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() => endDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          endDate != null
                              ? DateFormat('dd/MM/yyyy').format(endDate!)
                              : 'Bitiş Tarihi',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            Consumer<PersonnelController>(
              builder: (context, controller, child) {
                return TextButton(
                  onPressed: controller.isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate() &&
                              startDate != null &&
                              endDate != null) {
                            final success = await controller.addDocument(
                              personnelId: widget.personnel.id,
                              documentName: nameController.text.trim(),
                              startDate: startDate!,
                              endDate: endDate!,
                            );

                            if (success && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Belge başarıyla eklendi'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Sayfayı yenile
                              setState(() {});
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lütfen tüm alanları doldurun'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                  child: controller.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ekle'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDocumentDialog(BuildContext context, DocumentModel document) {
    final nameController = TextEditingController(text: document.name);
    final formKey = GlobalKey<FormState>();
    DateTime? startDate = document.startDate;
    DateTime? endDate = document.endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Belgeyi Düzenle'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Belge Adı',
                  validator: (value) =>
                      value?.isEmpty == true ? 'Belge adı gerekli' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() => startDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          startDate != null
                              ? DateFormat('dd/MM/yyyy').format(startDate!)
                              : 'Başlangıç Tarihi',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? startDate ?? DateTime.now(),
                            firstDate: startDate ?? DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() => endDate = date);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          endDate != null
                              ? DateFormat('dd/MM/yyyy').format(endDate!)
                              : 'Bitiş Tarihi',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            Consumer<PersonnelController>(
              builder: (context, controller, child) {
                return TextButton(
                  onPressed: controller.isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate() &&
                              startDate != null &&
                              endDate != null) {
                            final success = await controller.updateDocument(
                              personnelId: widget.personnel.id,
                              oldDocument: document,
                              documentName: nameController.text.trim(),
                              startDate: startDate!,
                              endDate: endDate!,
                            );

                            if (success && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Belge başarıyla güncellendi'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Sayfayı yenile
                              setState(() {});
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lütfen tüm alanları doldurun'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                  child: controller.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Güncelle'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _deleteDocument(BuildContext context, DocumentModel document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Belgeyi Sil'),
        content: Text(
          '${document.name} belgesini silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          Consumer<PersonnelController>(
            builder: (context, controller, child) {
              return TextButton(
                onPressed: controller.isLoading
                    ? null
                    : () async {
                        final success = await controller.deleteDocument(
                          personnelId: widget.personnel.id,
                          document: document,
                        );
                        if (success && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Belge başarıyla silindi'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          // Sayfayı yenile
                          setState(() {});
                        }
                      },
                child: controller.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sil', style: TextStyle(color: Colors.red)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DocumentCard extends StatelessWidget {
  final DocumentModel document;
  final PersonnelModel personnel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    required this.personnel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysUntilExpiry = document.endDate.difference(now).inDays;
    final isExpiring = daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
    final isExpired = daysUntilExpiry < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isExpired
          ? Colors.red.shade50
          : isExpiring
              ? Colors.orange.shade50
              : null,
      child: ListTile(
        leading: Icon(
          Icons.description,
          color: isExpired
              ? Colors.red
              : isExpiring
                  ? Colors.orange
                  : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          document.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Başlangıç: ${DateFormat('dd/MM/yyyy').format(document.startDate)}',
            ),
            Text('Bitiş: ${DateFormat('dd/MM/yyyy').format(document.endDate)}'),
            if (isExpired)
              Text(
                '${(-daysUntilExpiry)} gün önce süresi doldu',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (isExpiring)
              Text(
                '$daysUntilExpiry gün kaldı',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit), // edit_outline yerine edit kullandım
                  SizedBox(width: 8),
                  Text('Düzenle'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sil', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
        ),
      ),
    );
  }
}
