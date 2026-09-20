import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ojol_daily/core/config/enum.dart';
import 'package:ojol_daily/core/config/extension.dart';
import 'package:ojol_daily/core/utils/currency_formatter.dart';
import 'package:ojol_daily/core/utils/currency_input_formatter.dart';
import 'package:ojol_daily/core/widgets/custom_text_form_field.dart';
import 'package:ojol_daily/core/widgets/empty_state_widget.dart';
import 'package:ojol_daily/domain/enums.dart';
import 'package:ojol_daily/domain/financial_state.dart';
import 'package:ojol_daily/domain/models.dart';
import 'package:provider/provider.dart';
import '../providers/financial_provider.dart';
import '../theme/app_theme.dart';

class AllocationScreen extends StatelessWidget {
  const AllocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancialProvider>(
      builder: (context, provider, child) {
        final state = provider.state;
        return Scaffold(
          appBar: AppBar(
            title: const Text("Alokasi Uang \n& Pos Tabungan"),
            actions: [
              GestureDetector(
                onTap: () => _showAddEditObligationDialog(context, provider),
                child: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      'Tambah Kewajiban',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Uang Bebas Header
                Card(
                  color: AppColors.primary.withValues(alpha: 0.1),
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
                              CurrencyFormatter.format(state.freeCash),
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
                            foregroundColor: Colors.white,
                            backgroundColor: AppColors.primary,
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

                state.obligationSummaries.isEmpty
                    ? EmptyStateWidget(
                        imagePath: 'empty_allocation'.image,
                        title: 'Belum Ada Kewajiban Dibuat',
                        subtitle: 'Yuk, buat kewajibanmu sekarang!',
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ob.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Jatuh tempo: "
                                              "${DateFormat('dd MMM yyyy').format(ob.dueDate)}",
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Transform.translate(
                                        offset: const Offset(17, -12),
                                        child: Row(
                                          children: [
                                            _getStatusBadge(ob.status),
                                            PopupMenuButton<String>(
                                              icon: const Icon(
                                                Icons.more_vert,
                                                size: 20,
                                                color:
                                                    AppColors.onSurfaceVariant,
                                              ),
                                              onSelected: (value) {
                                                switch (value) {
                                                  case 'edit':
                                                    _showAddEditObligationDialog(
                                                      context,
                                                      provider,
                                                      ob,
                                                    );
                                                    break;
                                                  case 'pay':
                                                    // TODO: INTEGRATE WITH PAY OBLIGATION
                                                    _showPayObligationDialog(
                                                      context,
                                                      provider,
                                                      ob,
                                                    );
                                                    break;
                                                  default:
                                                    _showDeleteObligationConfirm(
                                                      context,
                                                      provider,
                                                      ob,
                                                    );
                                                    break;
                                                }
                                              },
                                              itemBuilder: (ctx) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.edit_outlined,
                                                        size: 20,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text('Edit Kewajiban'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.red,
                                                        size: 20,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Hapus',
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (ob.allocationProgressPercent ==
                                                    100)
                                                  const PopupMenuItem(
                                                    value: 'pay',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.payment,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'Bayar',
                                                          style: TextStyle(
                                                            color: AppColors
                                                                .primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
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
                                        "Target: ${CurrencyFormatter.format(ob.targetAmount)}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
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
                                    backgroundColor:
                                        AppColors.surfaceContainerHigh,
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
      },
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

  void _showAddEditObligationDialog(
    BuildContext context,
    FinancialProvider provider, [
    dynamic obSummary,
  ]) {
    final isEditing = obSummary != null;

    ObligationDefinition? existingOb;
    if (isEditing) {
      existingOb = provider.obligations.firstWhere(
        (o) => o.id == obSummary.id,
        orElse: () => ObligationDefinition(
          id: obSummary.id,
          name: obSummary.name,
          targetAmount: obSummary.targetAmount,
          dueDate: obSummary.dueDate,
          category: 'Umum',
          type: ObligationDefinitionType.bulanan,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    final nameController = TextEditingController(
      text: isEditing ? existingOb!.name : '',
    );
    final amountController = TextEditingController(
      text: isEditing ? existingOb!.targetAmount.toString() : '',
    );
    DateTime dueDate = isEditing
        ? existingOb!.dueDate
        : DateTime.now().add(const Duration(days: 15));
    ObligationDefinitionType selectedType = isEditing
        ? existingOb!.type
        : ObligationDefinitionType.bulanan;
    String category = isEditing ? existingOb!.category : 'Umum';

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
                top: 10,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
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
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing
                              ? "Edit Kewajiban"
                              : "Tambah Kewajiban Baru",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                    const Text(
                      'Jenis Kewajiban',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<ObligationDefinitionType>(
                      value: selectedType,
                      isExpanded: true,
                      items: ObligationDefinitionType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t.displayObligation,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Jatuh tempo: ${DateFormat('dd MMM yyyy').format(dueDate)}",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dueDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 5),
                              ),
                            );
                            if (picked != null) {
                              setState(() => dueDate = picked);
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text("Pilih Tanggal"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final amount =
                            int.tryParse(
                              amountController.text
                                  .replaceAll('.', '')
                                  .replaceAll(',', ''),
                            ) ??
                            0;
                        if (nameController.text.isNotEmpty && amount > 0) {
                          if (isEditing) {
                            await provider.updateObligation(
                              id: existingOb!.id,
                              name: nameController.text.trim(),
                              targetAmount: amount,
                              dueDate: dueDate,
                              category: category,
                              type: selectedType,
                            );
                          } else {
                            await provider.addObligation(
                              name: nameController.text.trim(),
                              targetAmount: amount,
                              dueDate: dueDate,
                              category: category,
                              type: selectedType,
                            );
                          }
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? "Kewajiban berhasil diperbarui"
                                      : "Kewajiban berhasil ditambahkan",
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        isEditing ? "Simpan Perubahan" : "Simpan Kewajiban",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPayObligationDialog(
    BuildContext context,
    FinancialProvider provider,
    ObligationSummary ob,
  ) {
    final remaining = ob.remainingAmount;

    if (remaining == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kewajiban ini sudah lunas!"),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Bayar Kewajiban: ${ob.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sisa yang harus dibayar: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(remaining)}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              CustomTextFormField(
                controller: amountController,
                labelText: "Jumlah Pembayaran",
                hintText: "Masukkan jumlah pembayaran",
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final amount = int.tryParse(
                  amountController.text.replaceAll('.', '').replaceAll(',', ''),
                );
                if (amount != null && amount > 0 && amount <= remaining) {
                  await provider.payObligation(
                    obligationId: ob.id,
                    amount: amount,
                    note: "Pembayaran cicilan",
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Pembayaran sebesar ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(amount)} berhasil ditambahkan",
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                "Bayar",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteObligationConfirm(
    BuildContext context,
    FinancialProvider provider,
    dynamic obSummary,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Hapus Kewajiban"),
          content: Text(
            "Apakah Anda yakin ingin menghapus kewajiban \"${obSummary.name}\"?\n\nTindakan ini tidak dapat dibatalkan.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await provider.deleteObligation(obSummary.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Kewajiban \"${obSummary.name}\" berhasil dihapus",
                      ),
                    ),
                  );
                }
              },
              child: const Text("Hapus"),
            ),
          ],
        );
      },
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
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Sisihkan Uang ke Pos Alokasi",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Pilih Tujuan Kewajiban",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedObligationId,
                    isExpanded: true,
                    items: provider.state.obligationSummaries
                        .map(
                          (o) => DropdownMenuItem(
                            value: o.id,
                            child: Text(
                              "${o.name} (Sisa target: ${CurrencyFormatter.format(o.remainingAmount)})",
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedObligationId = val!),
                  ),
                  const SizedBox(height: 12),
                  CustomTextFormField.currency(
                    controller: amountController,
                    labelText:
                        "Nominal Alokasi (Maks Rp ${provider.state.freeCash})",
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
