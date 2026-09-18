import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/financial_provider.dart';
import '../theme/app_theme.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final provider = Provider.of<FinancialProvider>(context);
    final activeIncomes = provider.incomes.where((i) => i.status.name == 'active').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Catatan Pendapatan"),
      ),
      body: activeIncomes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.secondary),
                  const SizedBox(height: 12),
                  const Text(
                    "Belum ada pendapatan dicatat",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddIncomeSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text("+ Catat Pendapatan Pagi/Sore"),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeIncomes.length,
              itemBuilder: (context, index) {
                final income = activeIncomes[index];
                final dateStr = DateFormat('dd MMM yyyy • HH:mm').format(income.transactionDate);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward, color: AppColors.primary, size: 20),
                    ),
                    title: Text(
                      income.category,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    subtitle: Text(
                      dateStr + (income.note != null ? " • ${income.note}" : ""),
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "+${currencyFormat.format(income.amount)}",
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.primary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                          onPressed: () => provider.deleteIncome(income.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddIncomeSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("+ Pendapatan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddIncomeSheet(BuildContext context) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = 'Gojek';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Catat Pendapatan Narik", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: "Aplikasi / Sumber"),
                    items: ['Gojek', 'Grab', 'Maxim', 'ShopeeFood', 'Tips', 'Lainnya']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedCategory = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Nominal (Rp)",
                      prefixText: "Rp ",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: "Catatan (opsional)"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final amount = int.tryParse(amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                      if (amount > 0) {
                        Provider.of<FinancialProvider>(context, listen: false).addIncome(
                          amount: amount,
                          category: selectedCategory,
                          note: noteController.text.isNotEmpty ? noteController.text : null,
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text("Simpan Pendapatan"),
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
