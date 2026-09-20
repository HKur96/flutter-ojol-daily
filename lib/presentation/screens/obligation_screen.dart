import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ojol_daily/core/config/enum.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/custom_text_form_field.dart';
import '../../domain/enums.dart';
import '../providers/financial_provider.dart';
import '../theme/app_theme.dart';

class ObligationScreen extends StatelessWidget {
  const ObligationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final provider = Provider.of<FinancialProvider>(context);
    final summaries = provider.state.obligationSummaries;

    return Scaffold(
      appBar: AppBar(title: const Text("Kewajiban & Tagihan")),
      body: summaries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Belum ada kewajiban terdaftar",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddObligationSheet(context, provider),
                    icon: const Icon(Icons.add),
                    label: const Text("+ Tambah Kewajiban Baru"),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                final ob = summaries[index];
                final dueDateStr = DateFormat('dd MMM yyyy').format(ob.dueDate);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ob.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            _getStatusBadge(ob.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Jatuh tempo: $dueDateStr",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Target: ${currencyFormat.format(ob.targetAmount)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "Dibayar: ${currencyFormat.format(ob.paidAmount)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: ob.paymentProgressPercent / 100.0,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          color: AppColors.primary,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 12),
                        if (ob.status != ObligationStatus.paid)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => _showPayObligationSheet(
                                  context,
                                  provider,
                                  ob,
                                ),
                                child: const Text("Bayar Tagihan"),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'obligation_fab',
        onPressed: () => _showAddObligationSheet(context, provider),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Kewajiban",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _getStatusBadge(ObligationStatus status) {
    String label;
    Color color;
    switch (status) {
      case ObligationStatus.paid:
        label = "LUNAS";
        color = AppColors.primary;
        break;
      case ObligationStatus.ready:
        label = "SIAP DIBAYAR";
        color = AppColors.primary;
        break;
      case ObligationStatus.overdue:
        label = "JATUH TEMPO";
        color = AppColors.error;
        break;
      case ObligationStatus.partiallyPaid:
        label = "SEBAGIAN";
        color = AppColors.warning;
        break;
      default:
        label = "PROSES";
        color = AppColors.secondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  void _showAddObligationSheet(
    BuildContext context,
    FinancialProvider provider,
  ) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 15));

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
                    "Tambah Kewajiban Baru",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: nameController,
                    labelText: "Nama Kewajiban",
                    hintText: "misal: Cicilan Motor, Listrik",
                  ),
                  const SizedBox(height: 12),
                  CustomTextFormField.currency(
                    controller: amountController,
                    labelText: "Target Nominal (Rp)",
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Jatuh tempo: ${DateFormat('dd MMM yyyy').format(dueDate)}",
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) setState(() => dueDate = picked);
                        },
                        child: const Text("Pilih Tanggal"),
                      ),
                    ],
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
                      if (nameController.text.isNotEmpty && amount > 0) {
                        provider.addObligation(
                          name: nameController.text,
                          targetAmount: amount,
                          dueDate: dueDate,
                          category: 'Umum',
                          type: ObligationDefinitionType.bulanan,
                        );
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text("Simpan Kewajiban"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPayObligationSheet(
    BuildContext context,
    FinancialProvider provider,
    dynamic obSummary,
  ) {
    final amountController = TextEditingController(
      text: obSummary.remainingAmount.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
              Text(
                "Bayar Kewajiban: ${obSummary.name}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Sisa tagihan: Rp ${obSummary.remainingAmount}",
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              CustomTextFormField.currency(
                controller: amountController,
                labelText: "Nominal Pembayaran (Rp)",
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final amount =
                      int.tryParse(
                        amountController.text
                            .replaceAll('.', '')
                            .replaceAll(',', ''),
                      ) ??
                      0;
                  if (amount > 0) {
                    final success = await provider.payObligation(
                      obligationId: obSummary.id,
                      amount: amount,
                    );
                    if (!success && ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Pembayaran melebihi sisa target kewajiban (Aturan FI-004)",
                          ),
                        ),
                      );
                    } else if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  }
                },
                child: const Text("Konfirmasi Pembayaran"),
              ),
            ],
          ),
        );
      },
    );
  }
}
