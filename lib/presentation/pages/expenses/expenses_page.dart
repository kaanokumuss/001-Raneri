import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/expense_controller.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../../data/models/expense_model.dart';
import '../../../services/pdf_service.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseController>().loadExpenses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcamalar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tüm Harcamalar', icon: Icon(Icons.list)),
            Tab(text: 'Aylık Görünüm', icon: Icon(Icons.calendar_month)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddExpenseDialog(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAllExpensesTab(), _buildMonthlyViewTab()],
      ),
    );
  }

  Widget _buildAllExpensesTab() {
    return Consumer<ExpenseController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.expenses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Hata: ${controller.errorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.loadExpenses(),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        if (controller.expenses.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Henüz harcama eklenmemiş'),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Özet kartı
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${controller.expenses.length}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const Text('Toplam Harcama'),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '₺${NumberFormat('#,##0.00', 'tr').format(controller.getTotalAmount())}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                        ),
                        const Text('Toplam Tutar'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.loadExpenses(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = controller.expenses[index];
                    return ExpenseCard(
                      expense: expense,
                      onDelete: () => _deleteExpense(context, expense),
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

  Widget _buildMonthlyViewTab() {
    return Consumer<ExpenseController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // Tarih seçici
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy', 'tr').format(selectedDate),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedDate = DateTime(
                                selectedDate.year,
                                selectedDate.month - 1,
                              );
                            });
                          },
                          icon: const Icon(Icons.arrow_back_ios),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              selectedDate = DateTime(
                                selectedDate.year,
                                selectedDate.month + 1,
                              );
                            });
                          },
                          icon: const Icon(Icons.arrow_forward_ios),
                        ),
                        IconButton(
                          onPressed: () =>
                              _exportMonthlyPDF(context, controller),
                          icon: const Icon(Icons.picture_as_pdf),
                          tooltip: 'PDF\'e Aktar',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Aylık özet
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '₺${NumberFormat('#,##0.00', 'tr').format(controller.getMonthlyTotal(selectedDate.year, selectedDate.month))}',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                    ),
                    Text(
                      '${DateFormat('MMMM yyyy', 'tr').format(selectedDate)} Toplam Harcama',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Aylık harcamalar listesi
            Expanded(
              child: Builder(
                builder: (context) {
                  final monthlyExpenses = controller.getExpensesByMonth(
                    selectedDate.year,
                    selectedDate.month,
                  );

                  if (monthlyExpenses.isEmpty) {
                    return const Center(
                      child: Text('Bu ay için harcama bulunamadı'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: monthlyExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = monthlyExpenses[index];
                      return ExpenseCard(
                        expense: expense,
                        onDelete: () => _deleteExpense(context, expense),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    DateTime selectedDate = DateTime.now();
    String selectedCategory = 'Diğer';

    final categories = [
      'Yemek',
      'Ulaşım',
      'Ofis Malzemeleri',
      'Teknoloji',
      'Temizlik',
      'Bakım-Onarım',
      'Diğer',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Harcama Ekle'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: descriptionController,
                    label: 'Harcama Açıklaması',
                    validator: (value) =>
                        value?.isEmpty == true ? 'Açıklama gerekli' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: amountController,
                    label: 'Tutar (₺)',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Tutar gerekli';
                      if (double.tryParse(value!) == null)
                        return 'Geçerli bir tutar girin';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedCategory = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: notesController,
                    label: 'Not (Opsiyonel)',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            Consumer<ExpenseController>(
              builder: (context, controller, child) {
                return TextButton(
                  onPressed: controller.isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            final success = await controller.addExpense(
                              description: descriptionController.text.trim(),
                              amount: double.parse(
                                amountController.text.trim(),
                              ),
                              date: selectedDate,
                              category: selectedCategory,
                              notes: notesController.text.trim().isEmpty
                                  ? null
                                  : notesController.text.trim(),
                            );

                            if (success && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Harcama başarıyla eklendi'),
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
      ),
    );
  }

  void _deleteExpense(BuildContext context, ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Harcamayı Sil'),
        content: Text(
          '${expense.description} harcamasını silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          Consumer<ExpenseController>(
            builder: (context, controller, child) {
              return TextButton(
                onPressed: controller.isLoading
                    ? null
                    : () async {
                        final success = await controller.deleteExpense(
                          expense.id,
                        );
                        if (success && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Harcama başarıyla silindi'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportMonthlyPDF(
    BuildContext context,
    ExpenseController controller,
  ) async {
    final expenses = controller.getExpensesByMonth(
      selectedDate.year,
      selectedDate.month,
    );

    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ay için harcama bulunamadı')),
      );
      return;
    }

    try {
      await PDFService.generateMonthlyExpenseReport(
        expenses,
        selectedDate.year,
        selectedDate.month,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF başarıyla oluşturuldu ve kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF oluşturulamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onDelete;

  const ExpenseCard({super.key, required this.expense, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(expense.category).withOpacity(0.1),
          child: Icon(
            _getCategoryIcon(expense.category),
            color: _getCategoryColor(expense.category),
          ),
        ),
        title: Text(
          expense.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(expense.category),
            Text(DateFormat('dd/MM/yyyy').format(expense.date)),
            if (expense.notes != null)
              Text(
                expense.notes!,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₺${NumberFormat('#,##0.00', 'tr').format(expense.amount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              iconSize: 20,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Yemek':
        return Icons.restaurant;
      case 'Ulaşım':
        return Icons.directions_car;
      case 'Ofis Malzemeleri':
        return Icons.business_center;
      case 'Teknoloji':
        return Icons.computer;
      case 'Temizlik':
        return Icons.cleaning_services;
      case 'Bakım-Onarım':
        return Icons.build;
      default:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Yemek':
        return Colors.orange;
      case 'Ulaşım':
        return Colors.blue;
      case 'Ofis Malzemeleri':
        return Colors.purple;
      case 'Teknoloji':
        return Colors.green;
      case 'Temizlik':
        return Colors.teal;
      case 'Bakım-Onarım':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
