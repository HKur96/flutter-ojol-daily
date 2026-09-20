import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/custom_text_form_field.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../providers/financial_provider.dart';
import '../theme/app_theme.dart';

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final provider = Provider.of<FinancialProvider>(context);
    final activeExpenses = provider.expenses.where((e) => e.status == TransactionStatus.active).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengeluaran Operasional"),
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceContainerHigh),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Pengeluaran", style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(provider.state.totalExpense),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.error),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_upward, color: AppColors.error),
                ),
              ],
            ),
          ),

          Expanded(
            child: activeExpenses.isEmpty
                ? const Center(
                    child: Text("Belum ada pengeluaran dicatat", style: TextStyle(color: AppColors.onSurfaceVariant)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: activeExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = activeExpenses[index];
                      final dateStr = DateFormat('dd MMM yyyy • HH:mm').format(expense.transactionDate);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(expense.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  Text(
                                    "-${currencyFormat.format(expense.amount)}",
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.error),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(dateStr + (expense.note != null ? " • ${expense.note}" : ""), style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 8),

                              // Source badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _getSourceBgColor(expense.source),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _getSourceLabel(expense.source, expense),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _getSourceTextColor(expense.source)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expense_fab',
        onPressed: () => _showAddExpenseSheet(context),
        backgroundColor: AppColors.error,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Catat Pengeluaran", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Color _getSourceBgColor(ExpenseSource source) {
    switch (source) {
      case ExpenseSource.free:
        return AppColors.primaryContainer.withValues(alpha: 0.12);
      case ExpenseSource.allocated:
        return AppColors.tertiaryContainer.withValues(alpha: 0.2);
      case ExpenseSource.mixed:
        return AppColors.secondaryContainer;
    }
  }

  Color _getSourceTextColor(ExpenseSource source) {
    switch (source) {
      case ExpenseSource.free:
        return AppColors.primary;
      case ExpenseSource.allocated:
        return AppColors.tertiary;
      case ExpenseSource.mixed:
        return AppColors.secondary;
    }
  }

  String _getSourceLabel(ExpenseSource source, ExpenseTransaction e) {
    switch (source) {
      case ExpenseSource.free:
        return "Uang Bebas";
      case ExpenseSource.allocated:
        return "Uang Alokasi";
      case ExpenseSource.mixed:
        return "Campuran (${e.freeAmountUsed} Bebas + ${e.allocatedAmountUsed} Alokasi)";
    }
  }

  void _showAddExpenseSheet(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = 'Bensin';
    ExpenseSource selectedSource = ExpenseSource.free;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 10,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 6,
                        width: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.grey.shade400
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Catat Pengeluaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: "Kategori Pengeluaran"),
                    items: ['Bensin', 'Makan', 'Servis Motor', 'Oli', 'Tambal Ban', 'Keluarga', 'Mendadak', 'Lainnya']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedCategory = val!),
                  ),
                  const SizedBox(height: 12),
                  CustomTextFormField.currency(
                    controller: amountController,
                    labelText: "Nominal (Rp)",
                  ),
                  const SizedBox(height: 12),
                  const Text("Sumber Dana Pengeluaran:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  SegmentedButton<ExpenseSource>(
                    segments: const [
                      ButtonSegment(value: ExpenseSource.free, label: Text("Uang Bebas")),
                      ButtonSegment(value: ExpenseSource.allocated, label: Text("Uang Alokasi")),
                    ],
                    selected: {selectedSource},
                    onSelectionChanged: (set) => setState(() => selectedSource = set.first),
                  ),
                  const SizedBox(height: 12),
                  CustomTextFormField(
                    controller: noteController,
                    labelText: "Catatan (opsional)",
                    hintText: "Catatan (opsional)",
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: () {
                      final amount = int.tryParse(amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                      if (amount > 0) {
                        Provider.of<FinancialProvider>(context, listen: false).addExpense(
                          amount: amount,
                          category: selectedCategory,
                          source: selectedSource,
                          freeAmountUsed: selectedSource == ExpenseSource.free ? amount : 0,
                          allocatedAmountUsed: selectedSource == ExpenseSource.allocated ? amount : 0,
                          note: noteController.text.isNotEmpty ? noteController.text : null,
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text("Simpan Pengeluaran"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
