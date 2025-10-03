import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/personnel_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../../data/models/user_model.dart';
import 'personnel_detail_page.dart'; // Eğer aynı klasördeyse

class PersonnelPage extends StatefulWidget {
  const PersonnelPage({super.key});

  @override
  State<PersonnelPage> createState() => _PersonnelPageState();
}

class _PersonnelPageState extends State<PersonnelPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonnelController>().loadPersonnel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel Listesi'),
        actions: [
          IconButton(
            onPressed: () => _showAddPersonnelDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer<PersonnelController>(
        builder: (context, controller, child) {
          if (controller.isLoading && controller.personnel.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hata: ${controller.errorMessage}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.loadPersonnel(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (controller.personnel.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz personel eklenmemiş'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadPersonnel(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.personnel.length,
              itemBuilder: (context, index) {
                final person = controller.personnel[index];
                return PersonnelCard(
                  personnel: person,
                  onTap: () => _showPersonnelDetails(context, person),
                  onDelete: () => _deletePersonnel(context, person),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddPersonnelDialog(BuildContext context) {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Personel Ekle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: firstNameController,
                label: 'İsim',
                validator: (value) =>
                    value?.isEmpty == true ? 'İsim gerekli' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: lastNameController,
                label: 'Soyisim',
                validator: (value) =>
                    value?.isEmpty == true ? 'Soyisim gerekli' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: titleController,
                label: 'Ünvan',
                validator: (value) =>
                    value?.isEmpty == true ? 'Ünvan gerekli' : null,
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
                        if (formKey.currentState!.validate()) {
                          final success = await controller.addPersonnel(
                            firstName: firstNameController.text.trim(),
                            lastName: lastNameController.text.trim(),
                            title: titleController.text.trim(),
                          );

                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Personel başarıyla eklendi'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
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
    );
  }

  void _showPersonnelDetails(BuildContext context, PersonnelModel personnel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonnelDetailPage(personnel: personnel),
      ),
    );
  }

  void _deletePersonnel(BuildContext context, PersonnelModel personnel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Personeli Sil'),
        content: Text(
          '${personnel.fullName} adlı personeli silmek istediğinizden emin misiniz?',
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
                        final success = await controller.deletePersonnel(
                          personnel.id,
                        );
                        if (success && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Personel başarıyla silindi'),
                              backgroundColor: Colors.red,
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
                    : const Text('Sil', style: TextStyle(color: Colors.red)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PersonnelCard extends StatelessWidget {
  final PersonnelModel personnel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PersonnelCard({
    super.key,
    required this.personnel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            personnel.firstName.isNotEmpty
                ? personnel.firstName[0].toUpperCase()
                : 'P',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          personnel.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(personnel.title),
            const SizedBox(height: 4),
            Text(
              'Kayıt: ${DateFormat('dd/MM/yyyy').format(personnel.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (personnel.documents.isNotEmpty)
              Text(
                '${personnel.documents.length} belge',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('Detaylar'),
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
            if (value == 'details') {
              onTap();
            } else if (value == 'delete') {
              onDelete();
            }
          },
        ),
        onTap: onTap,
      ),
    );
  }
}
