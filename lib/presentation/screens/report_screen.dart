import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/financial_provider.dart';
import '../theme/app_theme.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final provider = Provider.of<FinancialProvider>(context);
    final state = provider.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Laporan Keuangan"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cash Position Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Posisi Keuangan Saat Ini", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _buildReportRow("Total Pendapatan", currencyFormat.format(state.totalIncome), AppColors.primary),
                    const Divider(height: 20),
                    _buildReportRow("Total Pengeluaran", "-${currencyFormat.format(state.totalExpense)}", AppColors.error),
                    const Divider(height: 20),
                    _buildReportRow("Cash Available (Uang Fisik)", currencyFormat.format(state.cashAvailable), AppColors.onSurface),
                    const Divider(height: 20),
                    _buildReportRow("Sudah Dialokasikan", "-${currencyFormat.format(state.totalActiveAllocation)}", AppColors.tertiary),
                    const Divider(height: 20),
                    _buildReportRow("UANG BEBAS", currencyFormat.format(state.freeCash), AppColors.primary, isBold: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ratios Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Rasio Operasional", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Rasio Pengeluaran vs Pendapatan:", style: TextStyle(fontSize: 13)),
                        Text("${state.expenseToIncomeRatio.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Rasio Bensin vs Pendapatan:", style: TextStyle(fontSize: 13)),
                        Text("${state.fuelToIncomeRatio.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w800 : FontWeight.w500)),
        Text(
          value,
          style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.w800 : FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
