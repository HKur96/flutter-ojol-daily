import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ojol_daily/core/widgets/custom_text_form_field.dart';
import 'package:ojol_daily/presentation/providers/financial_provider.dart';
import 'package:ojol_daily/presentation/theme/app_theme.dart';
import 'package:provider/provider.dart';

class WalletTransferSheet extends StatefulWidget {
  const WalletTransferSheet({super.key});

  @override
  State<WalletTransferSheet> createState() => _WalletTransferSheetState();
}

class _WalletTransferSheetState extends State<WalletTransferSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _fromWalletId;
  String? _toWalletId;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int _parsedAmount() {
    return int.tryParse(
          _amountController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;
  }

  Future<void> _submitTransfer() async {
    final amount = _parsedAmount();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nominal transfer harus lebih dari Rp0")),
      );
      return;
    }

    if (_fromWalletId == null || _toWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih dompet asal dan dompet tujuan")),
      );
      return;
    }

    if (_fromWalletId == _toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Dompet asal dan dompet tujuan tidak boleh sama"),
        ),
      );
      return;
    }

    final provider = Provider.of<FinancialProvider>(context, listen: false);
    await provider.transferBetweenWallets(
      fromWalletId: _fromWalletId!,
      toWalletId: _toWalletId!,
      amount: amount,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Berhasil transfer ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(amount)}!",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinancialProvider>(context);
    final wallets = provider.wallets;
    final walletBalances = provider.state.walletBalances;

    if (wallets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("Belum ada dompet tersedia."),
      );
    }

    _fromWalletId ??= wallets.first.id;
    _toWalletId ??= wallets.length > 1 ? wallets[1].id : wallets.first.id;

    return Container(
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 6,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Transfer Antar Dompet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),

            // From Wallet
            DropdownButtonFormField<String>(
              value: _fromWalletId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Dari Dompet (Asal)",
              ),
              items: wallets.map((w) {
                final bal = walletBalances[w.id] ?? 0;
                return DropdownMenuItem<String>(
                  value: w.id,
                  child: Text(
                    "${w.name} (Saldo: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(bal)})",
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _fromWalletId = val),
            ),
            const SizedBox(height: 12),

            // To Wallet
            DropdownButtonFormField<String>(
              value: _toWalletId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Ke Dompet (Tujuan)",
              ),
              items: wallets.map((w) {
                final bal = walletBalances[w.id] ?? 0;
                return DropdownMenuItem<String>(
                  value: w.id,
                  child: Text(
                    "${w.name} (Saldo: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(bal)})",
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _toWalletId = val),
            ),
            const SizedBox(height: 12),

            CustomTextFormField.currency(
              controller: _amountController,
              labelText: "Nominal Transfer (Rp)",
            ),
            const SizedBox(height: 12),

            CustomTextFormField(
              controller: _noteController,
              labelText: "Catatan (opsional)",
              hintText: "Contoh: Topup GoPay dari Tunai",
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitTransfer,
                child: const Text(
                  "Konfirmasi Transfer",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
