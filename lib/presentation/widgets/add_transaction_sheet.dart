import 'package:flutter/material.dart';
import 'package:ojol_daily/core/config/enum.dart';
import 'package:ojol_daily/core/widgets/animated_option_slider.dart';
import 'package:ojol_daily/core/widgets/custom_text_form_field.dart';
import 'package:ojol_daily/domain/enums.dart';
import 'package:ojol_daily/presentation/providers/financial_provider.dart';
import 'package:ojol_daily/presentation/theme/app_theme.dart';
import 'package:provider/provider.dart';

/// A self-contained StatefulWidget for the add-transaction bottom sheet.
///
/// All form state (TextEditingControllers, selected enums) lives inside this
/// widget's State, so it is never reset by parent rebuilds.
class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  // ── shared state ──────────────────────────────────────────────────────
  DailyType _dailyType = DailyType.income;
  final _incomeAmountController = TextEditingController();
  final _expenseAmountController = TextEditingController();
  final _incomeNoteController = TextEditingController();
  final _expenseNoteController = TextEditingController();
  String? _selectedIncomeWalletId;
  String? _selectedExpenseWalletId;

  // ── income-specific state ─────────────────────────────────────────────
  IncomeSource? _selectedIncomeSource;

  // ── expense-specific state ────────────────────────────────────────────
  String _selectedCategory = 'Bensin';
  ExpenseSource _selectedExpenseSource = ExpenseSource.free;

  @override
  void dispose() {
    _incomeAmountController.dispose();
    _expenseAmountController.dispose();
    _incomeNoteController.dispose();
    _expenseNoteController.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────

  int _parsedIncomeAmount() {
    return int.tryParse(
          _incomeAmountController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;
  }

  int _parsedExpenseAmount() {
    return int.tryParse(
          _expenseAmountController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;
  }

  void _saveIncome(String defaultWalletId) {
    final amount = _parsedIncomeAmount();
    if (amount > 0 && _selectedIncomeSource != null) {
      Provider.of<FinancialProvider>(context, listen: false).addIncome(
        amount: amount,
        category: _selectedIncomeSource!.displayIncomeSource,
        walletId: _selectedIncomeWalletId ?? defaultWalletId,
        note: _incomeNoteController.text.isNotEmpty
            ? _incomeNoteController.text
            : null,
      );
      Navigator.pop(context);
    }
  }

  void _saveExpense(String defaultWalletId) {
    final amount = _parsedExpenseAmount();
    if (amount > 0) {
      Provider.of<FinancialProvider>(context, listen: false).addExpense(
        amount: amount,
        category: _selectedCategory,
        walletId: _selectedExpenseWalletId ?? defaultWalletId,
        source: _selectedExpenseSource,
        freeAmountUsed: _selectedExpenseSource == ExpenseSource.free
            ? amount
            : 0,
        allocatedAmountUsed: _selectedExpenseSource == ExpenseSource.allocated
            ? amount
            : 0,
        note: _expenseNoteController.text.isNotEmpty
            ? _expenseNoteController.text
            : null,
      );
      Navigator.pop(context);
    }
  }

  // ── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinancialProvider>(context);
    final wallets = provider.wallets;
    final defaultWalletId = wallets.isNotEmpty
        ? (wallets.any((w) => w.isDefault)
              ? wallets.firstWhere((w) => w.isDefault).id
              : wallets.first.id)
        : 'w_cash';

    return Padding(
      padding: EdgeInsets.only(
        top: 10,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 6,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // income / expense toggle
          AnimatedOptionSlider(
            onSelectionChanged: (value) {
              setState(() => _dailyType = value);
            },
          ),
          const SizedBox(height: 20),

          // form body
          if (_dailyType == DailyType.income)
            _buildIncomeForm(wallets, defaultWalletId)
          else
            _buildExpenseForm(wallets, defaultWalletId),
        ],
      ),
    );
  }

  // ── income form ───────────────────────────────────────────────────────

  Widget _buildIncomeForm(List<dynamic> wallets, String defaultWalletId) {
    final selectedWallet = _selectedIncomeWalletId ?? defaultWalletId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Catat Pendapatan Narik",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<IncomeSource>(
          value: _selectedIncomeSource,
          isExpanded: true,
          decoration: const InputDecoration(labelText: "Aplikasi / Sumber"),
          items: IncomeSource.values
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c.displayIncomeSource,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            setState(() => _selectedIncomeSource = val);
          },
        ),
        const SizedBox(height: 12),
        if (wallets.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            value: wallets.any((w) => w.id == selectedWallet)
                ? selectedWallet
                : defaultWalletId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: "Dompet Tujuan"),
            items: wallets
                .map(
                  (w) => DropdownMenuItem<String>(
                    value: w.id as String,
                    child: Text("${w.name} (Saldo IDR ${w.id})"),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedIncomeWalletId = val),
          ),
          const SizedBox(height: 12),
        ],
        CustomTextFormField.currency(
          controller: _incomeAmountController,
          labelText: "Nominal (Rp)",
        ),
        const SizedBox(height: 12),
        CustomTextFormField(
          controller: _incomeNoteController,
          labelText: "Catatan (opsional)",
          hintText: "Catatan (opsional)",
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => _saveIncome(defaultWalletId),
          child: const Text("Simpan Pendapatan"),
        ),
      ],
    );
  }

  // ── expense form ──────────────────────────────────────────────────────

  Widget _buildExpenseForm(List<dynamic> wallets, String defaultWalletId) {
    final selectedWallet = _selectedExpenseWalletId ?? defaultWalletId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Catat Pengeluaran",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          isExpanded: true,
          decoration: const InputDecoration(labelText: "Kategori Pengeluaran"),
          items:
              [
                    'Bensin',
                    'Makan',
                    'Servis Motor',
                    'Oli',
                    'Tambal Ban',
                    'Keluarga',
                    'Mendadak',
                    'Lainnya',
                  ]
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
          onChanged: (val) => setState(() => _selectedCategory = val!),
        ),
        const SizedBox(height: 12),
        if (wallets.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            value: wallets.any((w) => w.id == selectedWallet)
                ? selectedWallet
                : defaultWalletId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: "Dompet Asal"),
            items: wallets
                .map(
                  (w) => DropdownMenuItem<String>(
                    value: w.id as String,
                    child: Text("${w.name}"),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedExpenseWalletId = val),
          ),
          const SizedBox(height: 12),
        ],
        CustomTextFormField.currency(
          controller: _expenseAmountController,
          labelText: "Nominal (Rp)",
        ),
        const SizedBox(height: 12),
        const Text(
          "Sumber Dana Pengeluaran:",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        SegmentedButton<ExpenseSource>(
          segments: const [
            ButtonSegment(value: ExpenseSource.free, label: Text("Uang Bebas")),
            ButtonSegment(
              value: ExpenseSource.allocated,
              label: Text("Uang Alokasi"),
            ),
          ],
          selected: {_selectedExpenseSource},
          onSelectionChanged: (set) =>
              setState(() => _selectedExpenseSource = set.first),
        ),
        const SizedBox(height: 12),
        CustomTextFormField(
          controller: _expenseNoteController,
          labelText: "Catatan (opsional)",
          hintText: "Catatan (opsional)",
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => _saveExpense(defaultWalletId),
          child: const Text("Simpan Pengeluaran"),
        ),
      ],
    );
  }
}
