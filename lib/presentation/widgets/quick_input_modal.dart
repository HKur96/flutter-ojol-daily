import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financial_provider.dart';
import '../theme/app_theme.dart';

class QuickInputModal extends StatefulWidget {
  const QuickInputModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const QuickInputModal(),
    );
  }

  @override
  State<QuickInputModal> createState() => _QuickInputModalState();
}

class _QuickInputModalState extends State<QuickInputModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'Gojek';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.flash_on, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "Catat Pendapatan Hari Ini",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Cukup masukkan total pendapatan narik hari ini.",
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: "Aplikasi / Sumber"),
            items: ['Gojek', 'Grab', 'Maxim', 'ShopeeFood', 'Tips', 'Lainnya']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
            decoration: const InputDecoration(
              labelText: "Total Pendapatan (Rp)",
              prefixText: "Rp ",
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: "Catatan (opsional)"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(_amountController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
              if (amount > 0) {
                final provider = Provider.of<FinancialProvider>(context, listen: false);
                await provider.addIncome(
                  amount: amount,
                  category: _selectedCategory,
                  note: _noteController.text.isNotEmpty ? _noteController.text : "Quick Input Pendapatan",
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Pendapatan berhasil dicatat. Dashboard & target telah diperbarui!")),
                  );
                }
              }
            },
            child: const Text("Simpan Pendapatan"),
          ),
        ],
      ),
    );
  }
}
