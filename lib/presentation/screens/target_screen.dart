import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/custom_text_form_field.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../providers/financial_provider.dart';
import '../theme/app_theme.dart';

class TargetScreen extends StatelessWidget {
  const TargetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final provider = Provider.of<FinancialProvider>(context);
    final target = provider.state.targetSummary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Target Pendapatan Narik"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Hero Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Target Bulan Ini", style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(minimumSize: const Size(100, 36)),
                          onPressed: () => _showSetupTargetDialog(context, provider),
                          child: const Text("Ubah Target"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currencyFormat.format(target?.monthlyTargetAmount ?? 0),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Capaian: ${currencyFormat.format(target?.totalIncome ?? 0)}", style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                        Text("${target?.progressPercent.toStringAsFixed(0)}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (target?.progressPercent ?? 0) / 100.0,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      color: AppColors.primary,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Dynamic Daily Income Target Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.track_changes, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text("Target Harian Dinamis", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${currencyFormat.format(target?.requiredDailyIncome ?? 0)} / hari narik",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Dihitung berdasarkan sisa target ${currencyFormat.format(target?.remainingTargetAmount ?? 0)} dibagi ${target?.remainingWorkingDays ?? 0} hari narik tersisa.",
                      style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Day Status Toggle Section (OFF / WORKING) (PRD Section 1.1)
            const Text("Atur Hari Libur Narik (OFF)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              "Menandai hari libur (OFF) tidak mengurangi saldo dan tidak menganggap kamu gagal target.",
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (idx) {
                final dayDate = DateTime.now().add(Duration(days: idx - 3));
                final dateStr = DateFormat('yyyy-MM-dd').format(dayDate);
                final dayName = DateFormat('EEE, dd MMM').format(dayDate);

                final activity = provider.dayActivities.firstWhere(
                  (a) => a.dateString == dateStr,
                  orElse: () => DayActivity(dateString: dateStr, status: DayStatus.working),
                );

                final isOff = activity.status == DayStatus.off;

                return FilterChip(
                  label: Text("$dayName ${isOff ? '(OFF)' : ''}"),
                  selected: isOff,
                  selectedColor: AppColors.warningContainer,
                  onSelected: (selected) {
                    provider.setDayStatus(
                      dateStr,
                      selected ? DayStatus.off : DayStatus.working,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetupTargetDialog(BuildContext context, FinancialProvider provider) {
    final targetController = TextEditingController(text: provider.currentTarget?.monthlyTargetAmount.toString() ?? "4000000");
    final daysController = TextEditingController(text: provider.currentTarget?.totalWorkingDays.toString() ?? "26");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
              const Text("Setup Target Pendapatan Bulanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              CustomTextFormField.currency(
                controller: targetController,
                labelText: "Target Pendapatan Bulan Ini (Rp)",
              ),
              const SizedBox(height: 12),
              CustomTextFormField(
                controller: daysController,
                keyboardType: TextInputType.number,
                labelText: "Rencana Jumlah Hari Narik",
                hintText: "26",
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final target = int.tryParse(targetController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                  final days = int.tryParse(daysController.text) ?? 26;

                  if (target > 0 && days > 0) {
                    provider.saveMonthlyTarget(
                      monthlyTargetAmount: target,
                      totalWorkingDays: days,
                    );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Simpan Konfigurasi Target"),
              ),
            ],
          ),
        );
      },
    );
  }
}
