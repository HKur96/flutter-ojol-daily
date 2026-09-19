import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/financial_provider.dart';
import '../theme/app_theme.dart';

class AllocationScreen extends StatelessWidget {
  const AllocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final provider = Provider.of<FinancialProvider>(context);
    final state = provider.state;

    return Scaffold(
      appBar: AppBar(title: const Text("Alokasi Uang & Pos Tabungan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uang Bebas Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Sisa Uang Bebas Saat Ini",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(state.freeCash),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 42),
                      ),
                      onPressed: state.freeCash <= 0
                          ? null
                          : () => _showAllocateDialog(context, provider),
                      child: const Text("+ Sisihkan"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              "Daftar Pos Alokasi Kewajiban",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            state.obligationSummaries.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        "Belum ada kewajiban dibuat. Tambahkan kewajiban di menu Kewajiban.",
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.obligationSummaries.length,
                    itemBuilder: (context, index) {
                      final ob = state.obligationSummaries[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    ob.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    currencyFormat.format(ob.targetAmount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Dialokasikan: ${currencyFormat.format(ob.allocatedAmount)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    "${ob.allocationProgressPercent.toStringAsFixed(0)}% terkumpul",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: ob.allocationProgressPercent / 100.0,
                                backgroundColor: AppColors.surfaceContainerHigh,
                                color: AppColors.primary,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _showAllocateDialog(BuildContext context, FinancialProvider provider) {
    if (provider.state.obligationSummaries.isEmpty) return;

    String selectedObligationId = provider.state.obligationSummaries.first.id;
    final amountController = TextEditingController();

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
                  const Text(
                    "Sisihkan Uang ke Pos Alokasi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedObligationId,
                    decoration: const InputDecoration(
                      labelText: "Pilih Tujuan Kewajiban",
                    ),
                    items: provider.state.obligationSummaries
                        .map(
                          (o) => DropdownMenuItem(
                            value: o.id,
                            child: Text(
                              "${o.name} (Sisa target: ${o.remainingAmount})",
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedObligationId = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                          "Nominal Alokasi (Maks Rp ${provider.state.freeCash})",
                      prefixText: "Rp ",
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final amount =
                          int.tryParse(
                            amountController.text
                                .replaceAll('.', '')
                                .replaceAll(',', ''),
                          ) ??
                          0;
                      if (amount > 0 && amount <= provider.state.freeCash) {
                        provider.addAllocation(
                          obligationId: selectedObligationId,
                          amount: amount,
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text("Simpan Alokasi"),
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
