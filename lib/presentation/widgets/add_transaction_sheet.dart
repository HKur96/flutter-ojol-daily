import 'package:flutter/material.dart';
import 'package:ojol_daily/core/config/enum.dart';
import 'package:ojol_daily/core/utils/currency_formatter.dart';
import 'package:ojol_daily/core/utils/date_formatter.dart';
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
  late final provider = Provider.of<FinancialProvider>(context);
  // ── shared state ──────────────────────────────────────────────────────
  DailyType _dailyType = DailyType.income;
  final _incomeAmountController = TextEditingController();
  final _incomeNoteController = TextEditingController();
  final _incomeDateController = TextEditingController();

  final _expenseAmountController = TextEditingController();
  final _expenseNoteController = TextEditingController();
  final _expenseDateController = TextEditingController();

  String? _selectedIncomeWalletId;
  String? _selectedExpenseWalletId;

  // ── income-specific state ─────────────────────────────────────────────
  IncomeSource? _selectedIncomeSource;

  // ── expense-specific state ────────────────────────────────────────────
  String _selectedCategory = 'Bensin';
  ExpenseSource _selectedExpenseSource = ExpenseSource.free;

  DateTime? _selectedIncomeDate;
  DateTime? _selectedExpenseDate;

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _incomeAmountController.dispose();
    _incomeNoteController.dispose();
    _incomeDateController.dispose();
    _expenseAmountController.dispose();
    _expenseNoteController.dispose();
    _expenseDateController.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    final amount = _parsedIncomeAmount();
    if (amount > 0 && _selectedIncomeSource != null) {
      Provider.of<FinancialProvider>(context, listen: false).addIncome(
        amount: amount,
        category: _selectedIncomeSource!.displayIncomeSource,
        walletId: _selectedIncomeWalletId ?? defaultWalletId,
        note: _incomeNoteController.text.isNotEmpty
            ? _incomeNoteController.text
            : null,
        transactionDate: _selectedIncomeDate ?? DateTime.now(),
      );
      Navigator.pop(context);
    }
  }

  void _saveExpense(String defaultWalletId) {
    if (!_formKey.currentState!.validate()) return;

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
        transactionDate: _selectedExpenseDate ?? DateTime.now(),
      );
      Navigator.pop(context);
    }
  }

  // ── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final wallets = provider.wallets;
    final defaultWalletId = wallets.isNotEmpty
        ? (wallets.any((w) => w.isDefault)
              ? wallets.firstWhere((w) => w.isDefault).id
              : wallets.first.id)
        : 'w_cash';

    return Form(
      key: _formKey,
      child: Container(
        padding: EdgeInsets.only(
          top: 10,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
        ),
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
        _buildLabelText("Aplikasi / Sumber"),
        const SizedBox(height: 6),
        DropdownButtonFormField<IncomeSource>(
          value: _selectedIncomeSource,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: "Pilih Sumber Pendapatan",
            hintStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
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
          _buildLabelText("Dompet Tujuan"),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: wallets.any((w) => w.id == selectedWallet)
                ? selectedWallet
                : defaultWalletId,
            isExpanded: true,
            items: wallets
                .map(
                  (w) => DropdownMenuItem<String>(
                    value: w.id as String,
                    child: Text(w.name),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedIncomeWalletId = val),
          ),
          const SizedBox(height: 12),
        ],
        CustomTextFormField(
          controller: _incomeDateController,
          labelText: "Tanggal",
          hintText: "Tanggal",
          readOnly: true,
          prefixIcon: const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
          textCapitalization: TextCapitalization.words,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Masukkan tanggal';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
          onTap: () async {
            final pickedDate = await _selectDate(_incomeDateController);

            if (pickedDate == null) return;

            setState(() => _selectedIncomeDate = pickedDate);
          },
        ),
        const SizedBox(height: 12),
        CustomTextFormField.currency(
          controller: _incomeAmountController,
          labelText: "Nominal (Rp)",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Masukkan nominal";
            }
            final amount = CurrencyFormatter.parse(value);
            if (amount <= 0) {
              return "Nominal harus lebih besar dari 0";
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        CustomTextFormField(
          controller: _incomeNoteController,
          labelText: "Catatan (opsional)",
          hintText: "Catatan (opsional)",
          maxLines: 2,
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
        _buildLabelText("Kategori Pengeluaran"),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          isExpanded: true,
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
          _buildLabelText("Dompet Asal"),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: wallets.any((w) => w.id == selectedWallet)
                ? selectedWallet
                : defaultWalletId,
            isExpanded: true,
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
        CustomTextFormField(
          controller: _expenseDateController,
          labelText: "Tanggal",
          hintText: "Tanggal",
          readOnly: true,
          prefixIcon: const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
          textCapitalization: TextCapitalization.words,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Masukkan tanggal';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
          onTap: () async {
            final pickedDate = await _selectDate(_expenseDateController);

            if (pickedDate == null) return;

            setState(() => _selectedExpenseDate = pickedDate);
          },
        ),
        const SizedBox(height: 12),
        CustomTextFormField.currency(
          controller: _expenseAmountController,
          labelText: "Nominal (Rp)",
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Masukkan nominal";
            }
            final amount = CurrencyFormatter.parse(value);
            if (amount <= 0) {
              return "Nominal harus lebih besar dari 0";
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        _buildLabelText("Sumber Dana Pengeluaran:"),
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
          maxLines: 2,
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

  Future<DateTime?> _selectDate(TextEditingController controller) async {
    final now = DateTime.now();
    final DateTime initialDate = now;
    final DateTime firstDate = DateTime(2010);
    final DateTime lastDate = now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      controller.text = DateFormatter.fullDate(pickedDate);
    }

    return pickedDate;
  }

  Widget _buildLabelText(String val) {
    return Text(
      val,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    );
  }
}
