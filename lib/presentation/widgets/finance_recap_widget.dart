import 'package:flutter/material.dart';
import 'package:ojol_daily/core/theme/app_theme.dart';
import 'package:ojol_daily/core/utils/currency_formatter.dart';
import 'package:ojol_daily/presentation/providers/financial_provider.dart';
import 'package:provider/provider.dart';

class FinanceRecapWidget extends StatelessWidget {
  const FinanceRecapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinancialProvider>(
      builder: (context, provider, _) {
        final state = provider.state;
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Posisi Keuangan Saat Ini",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _buildReportRow(
                      "Total Pendapatan",
                      CurrencyFormatter.currencyFormat.format(state.totalIncome),
                      AppColors.primary,
                    ),
                    const Divider(height: 20),
                    _buildReportRow(
                      "Total Pengeluaran",
                      "-${CurrencyFormatter.currencyFormat.format(state.totalExpense)}",
                      AppColors.error,
                    ),
                    const Divider(height: 20),
                    _buildReportRow(
                      "Cash Available (Uang Fisik)",
                      CurrencyFormatter.currencyFormat.format(state.cashAvailable),
                      AppColors.onSurface,
                    ),
                    const Divider(height: 20),
                    _buildReportRow(
                      "Sudah Dialokasikan",
                      "-${CurrencyFormatter.currencyFormat.format(state.totalActiveAllocation)}",
                      AppColors.tertiary,
                    ),
                    const Divider(height: 20),
                    _buildReportRow(
                      "UANG BEBAS",
                      CurrencyFormatter.currencyFormat.format(state.freeCash),
                      AppColors.primary,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
        
            const SizedBox(height: 16),
        
            // Ratios Card
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Rasio Operasional",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Rasio Pengeluaran vs Pendapatan:",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "${state.expenseToIncomeRatio.toStringAsFixed(1)}%",
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Rasio Bensin vs Pendapatan:",
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          "${state.fuelToIncomeRatio.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        
            const SizedBox(height: 24),
          ],
        );
      }
    );
  }

  Widget _buildReportRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
