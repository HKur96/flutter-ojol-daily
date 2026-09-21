import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ojol_daily/core/widgets/custom_text_form_field.dart';
import 'package:ojol_daily/domain/financial_state.dart';
import 'package:ojol_daily/domain/wallet.dart';
import 'package:ojol_daily/presentation/providers/financial_provider.dart';
import 'package:ojol_daily/presentation/theme/app_theme.dart';
import 'package:provider/provider.dart';

class WalletSplitItem {
  String walletId;
  TextEditingController controller;

  WalletSplitItem({required this.walletId, required this.controller});
}

class PayObligationSheet extends StatefulWidget {
  final ObligationSummary obligation;

  const PayObligationSheet({super.key, required this.obligation});

  @override
  State<PayObligationSheet> createState() => _PayObligationSheetState();
}

class _PayObligationSheetState extends State<PayObligationSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final List<WalletSplitItem> _splits = [];
  bool _initializedSplits = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    for (final s in _splits) {
      s.controller.dispose();
    }
    super.dispose();
  }

  void _initDefaultSplit(List<Wallet> wallets) {
    if (_initializedSplits || wallets.isEmpty) return;
    _initializedSplits = true;
    final defaultWallet = wallets.firstWhere(
      (w) => w.isDefault,
      orElse: () => wallets.first,
    );
    _splits.add(
      WalletSplitItem(
        walletId: defaultWallet.id,
        controller: TextEditingController(),
      ),
    );
  }

  int _parseAmount(String text) {
    return int.tryParse(text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  }

  int get _totalSplitAmount {
    int sum = 0;
    for (final s in _splits) {
      sum += _parseAmount(s.controller.text);
    }
    return sum;
  }

  void _addSplitRow(List<Wallet> wallets) {
    if (wallets.isEmpty) return;
    // Find a wallet not yet added, or fallback to first
    final usedWalletIds = _splits.map((s) => s.walletId).toSet();
    final availableWallet = wallets.firstWhere(
      (w) => !usedWalletIds.contains(w.id),
      orElse: () => wallets.first,
    );

    setState(() {
      _splits.add(
        WalletSplitItem(
          walletId: availableWallet.id,
          controller: TextEditingController(),
        ),
      );
    });
  }

  void _removeSplitRow(int index) {
    if (_splits.length <= 1) return;
    setState(() {
      _splits[index].controller.dispose();
      _splits.removeAt(index);
    });
  }

  Future<void> _submitPayment() async {
    final totalPayment = _parseAmount(_amountController.text);
    if (totalPayment <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nominal pembayaran harus lebih dari Rp0"),
        ),
      );
      return;
    }

    if (totalPayment > widget.obligation.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Pembayaran melebihi sisa kewajiban (Maks ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(widget.obligation.remainingAmount)})",
          ),
        ),
      );
      return;
    }

    final splitSum = _totalSplitAmount;
    if (_splits.length > 1 && splitSum != totalPayment) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Total rincian dompet (Rp ${NumberFormat.decimalPattern('id_ID').format(splitSum)}) harus sama dengan Total Pembayaran (Rp ${NumberFormat.decimalPattern('id_ID').format(totalPayment)})",
          ),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final splitsPayload = <ObligationPaymentSplit>[];

    if (_splits.length == 1) {
      splitsPayload.add(
        ObligationPaymentSplit(
          id: 'ps_${now.millisecondsSinceEpoch}_0',
          paymentId: '', // set in repository
          walletId: _splits.first.walletId,
          amount: totalPayment,
        ),
      );
    } else {
      for (int i = 0; i < _splits.length; i++) {
        final amount = _parseAmount(_splits[i].controller.text);
        if (amount > 0) {
          splitsPayload.add(
            ObligationPaymentSplit(
              id: 'ps_${now.millisecondsSinceEpoch}_$i',
              paymentId: '',
              walletId: _splits[i].walletId,
              amount: amount,
            ),
          );
        }
      }
    }

    final provider = Provider.of<FinancialProvider>(context, listen: false);
    final success = await provider.payObligation(
      obligationId: widget.obligation.id,
      amount: totalPayment,
      splits: splitsPayload,
      note: _noteController.text.isNotEmpty
          ? _noteController.text
          : "Pembayaran ${widget.obligation.name}",
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Pembayaran ${widget.obligation.name} sebesar ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(totalPayment)} berhasil!",
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal memproses pembayaran kewajiban."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinancialProvider>(context);
    final wallets = provider.wallets;
    final walletBalances = provider.state.walletBalances;
    _initDefaultSplit(wallets);

    final totalPayment = _parseAmount(_amountController.text);
    final splitSum = _totalSplitAmount;
    final isMultiSplit = _splits.length > 1;
    final isSplitMatched = !isMultiSplit || (splitSum == totalPayment);

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
            // Handle bar
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Bayar: ${widget.obligation.name}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Sisa: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(widget.obligation.remainingAmount)}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total Payment Amount
            CustomTextFormField.currency(
              controller: _amountController,
              labelText: "Total Nominal Pembayaran (Rp)",
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Wallet Selection / Split Builder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Rincian Dompet (Multi-Dompet):",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  onPressed: () => _addSplitRow(wallets),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    "Tambah Dompet",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _splits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _splits[index];

                return Row(
                  children: [
                    // Wallet Dropdown
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: item.walletId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: wallets.map((w) {
                          final bal = walletBalances[w.id] ?? 0;
                          return DropdownMenuItem<String>(
                            value: w.id,
                            child: Text(
                              "${w.name} (Rp ${NumberFormat.compact(locale: 'id_ID').format(bal)})",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => item.walletId = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Amount per Wallet (if multi-split)
                    if (isMultiSplit) ...[
                      Expanded(
                        flex: 2,
                        child: CustomTextFormField.currency(
                          controller: item.controller,
                          labelText: "Nominal",
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeSplitRow(index),
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

            if (isMultiSplit) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSplitMatched
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSplitMatched
                        ? Colors.green.shade300
                        : Colors.red.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSplitMatched ? Icons.check_circle : Icons.warning,
                      color: isSplitMatched ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isSplitMatched
                            ? "Total pecahan dompet cocok dengan total pembayaran."
                            : "Total pecahan (Rp ${NumberFormat.decimalPattern('id_ID').format(splitSum)}) belum cocok dengan Total (Rp ${NumberFormat.decimalPattern('id_ID').format(totalPayment)})",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSplitMatched
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            CustomTextFormField(
              controller: _noteController,
              labelText: "Catatan (opsional)",
              hintText: "Contoh: Pembayaran via GoPay & Tunai",
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
                onPressed: _submitPayment,
                child: const Text(
                  "Konfirmasi Pembayaran",
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
