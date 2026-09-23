import 'package:flutter/material.dart';
import 'package:ojol_daily/core/theme/app_theme.dart';
import 'package:ojol_daily/presentation/widgets/finance_history_widget.dart';
import 'package:ojol_daily/presentation/widgets/finance_recap_widget.dart';

enum ActivityType { income, expense, obligationPayment, allocation }

enum ActivityPeriodFilter {
  today('Hari Ini'),
  week('Minggu Ini'),
  month('Bulan Ini'),
  all('Semua');

  final String label;
  const ActivityPeriodFilter(this.label);
}

class ActivityLogItem {
  final String id;
  final String title;
  final String categoryOrSubtitle;
  final int amount;
  final DateTime transactionDate;
  final ActivityType type;
  final String? note;

  const ActivityLogItem({
    required this.id,
    required this.title,
    required this.categoryOrSubtitle,
    required this.amount,
    required this.transactionDate,
    required this.type,
    this.note,
  });
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Keuangan'),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[700],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Riwayat'),
                  Tab(text: 'Rekap'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            // Konten untuk Tab 1: Riwayat
            FinanceHistoryWidget(),

            // Konten untuk Tab 2: Rekap
            FinanceRecapWidget(),
          ],
        ),
      ),
    );
  }
}
