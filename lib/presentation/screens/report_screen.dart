import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ojol_daily/core/config/enum.dart';
import 'package:ojol_daily/core/utils/currency_formatter.dart';
import 'package:ojol_daily/core/utils/date_formatter.dart';
import 'package:ojol_daily/domain/enums.dart';
import 'package:ojol_daily/domain/models.dart';
import 'package:provider/provider.dart';
import '../providers/financial_provider.dart';
import '../theme/app_theme.dart';

enum ActivityType { income, expense, obligationPayment }

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
  final DateTime date;
  final ActivityType type;
  final String? note;

  const ActivityLogItem({
    required this.id,
    required this.title,
    required this.categoryOrSubtitle,
    required this.amount,
    required this.date,
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
  ActivityPeriodFilter _selectedFilter = ActivityPeriodFilter.month;
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Laporan Keuangan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Consumer<FinancialProvider>(
          builder: (context, provider, _) {
            final state = provider.state;
            final allActivities = _buildActivityList(provider);
            final filteredActivities = _getFilteredActivities(allActivities);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cash Position Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Posisi Keuangan Saat Ini",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildReportRow(
                          "Total Pendapatan",
                          CurrencyFormatter.currencyFormat.format(
                            state.totalIncome,
                          ),
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
                          CurrencyFormatter.currencyFormat.format(
                            state.cashAvailable,
                          ),
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
                          CurrencyFormatter.currencyFormat.format(
                            state.freeCash,
                          ),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Rasio Operasional",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
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

                // Activity Log Header & Filters
                _buildActivityLogSection(filteredActivities),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActivityLogSection(List<ActivityLogItem> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Riwayat & Log Aktivitas",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "${activities.length} Transaksi",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Period Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ActivityPeriodFilter.values.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter.label),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSelected ? AppColors.primary : AppColors.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Month Picker Widget when 'Bulan Ini' filter is active
        if (_selectedFilter == ActivityPeriodFilter.month) ...[
          const SizedBox(height: 8),
          Center(child: _buildMonthSelector()),
        ],

        const SizedBox(height: 12),

        // Activities List or Empty State
        if (activities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  "Belum Ada Aktivitas",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Belum ada catatan transaksi pada periode yang dipilih.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              return _buildActivityTile(activities[index]);
            },
          ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          InkWell(
            onTap: _pickMonth,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    monthName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final months = List.generate(12, (index) {
      return DateTime(now.year, now.month - index, 1);
    });

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Pilih Bulan'),
          children: months.map((m) {
            final label = DateFormat('MMMM yyyy', 'id_ID').format(m);
            final isCurrent =
                m.year == _selectedMonth.year && m.month == _selectedMonth.month;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, m),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color:
                            isCurrent ? AppColors.primary : AppColors.onSurface,
                      ),
                    ),
                    if (isCurrent)
                      const Icon(Icons.check, size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
    }
  }

  Widget _buildActivityTile(ActivityLogItem item) {
    IconData iconData;
    Color iconBgColor;
    Color iconColor;
    String sign;
    Color amountColor;

    switch (item.type) {
      case ActivityType.income:
        iconData = Icons.add_circle_outline;
        iconBgColor = Colors.green.shade50;
        iconColor = Colors.green.shade700;
        sign = '+';
        amountColor = Colors.green.shade700;
        break;
      case ActivityType.expense:
        iconData = Icons.remove_circle_outline;
        iconBgColor = Colors.red.shade50;
        iconColor = Colors.red.shade700;
        sign = '-';
        amountColor = Colors.red.shade700;
        break;
      case ActivityType.obligationPayment:
        iconData = Icons.account_balance_wallet_outlined;
        iconBgColor = AppColors.primary.withValues(alpha: 0.1);
        iconColor = AppColors.primary;
        sign = '-';
        amountColor = AppColors.primary;
        break;
    }

    final formattedAmount =
        '$sign${CurrencyFormatter.currencyFormat.format(item.amount)}';
    final formattedTime = DateFormatter.dayHours(item.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.categoryOrSubtitle +
                      (item.note != null && item.note!.isNotEmpty
                          ? ' • ${item.note}'
                          : ''),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formattedAmount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  List<ActivityLogItem> _buildActivityList(FinancialProvider provider) {
    final List<ActivityLogItem> items = [];

    // 1. Incomes
    for (final inc in provider.incomes) {
      if (inc.status == TransactionStatus.deleted) continue;
      items.add(
        ActivityLogItem(
          id: inc.id,
          title: inc.category,
          categoryOrSubtitle: 'Pendapatan',
          amount: inc.amount,
          date: inc.transactionDate,
          type: ActivityType.income,
          note: inc.note,
        ),
      );
    }

    // 2. Expenses
    for (final exp in provider.expenses) {
      if (exp.status == TransactionStatus.deleted) continue;
      final sourceLabel = exp.source == ExpenseSource.allocated
          ? 'Pengeluaran (Dialokasikan)'
          : exp.source == ExpenseSource.mixed
              ? 'Pengeluaran (Campuran)'
              : 'Pengeluaran (Uang Bebas)';
      items.add(
        ActivityLogItem(
          id: exp.id,
          title: exp.category,
          categoryOrSubtitle: sourceLabel,
          amount: exp.amount,
          date: exp.transactionDate,
          type: ActivityType.expense,
          note: exp.note,
        ),
      );
    }

    // 3. Obligation Payments
    for (final pay in provider.payments) {
      if (pay.status == TransactionStatus.deleted) continue;
      final obName = provider.obligations
          .firstWhere(
            (o) => o.id == pay.obligationId,
            orElse: () => ObligationDefinition(
              id: '',
              name: 'Kewajiban',
              targetAmount: 0,
              dueDate: DateTime.now(),
              category: '',
              type: ObligationDefinitionType.bulanan,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
          .name;
      items.add(
        ActivityLogItem(
          id: pay.id,
          title: 'Bayar $obName',
          categoryOrSubtitle: 'Pembayaran Kewajiban',
          amount: pay.amount,
          date: pay.paymentDate,
          type: ActivityType.obligationPayment,
          note: pay.note,
        ),
      );
    }

    // Sort descending by date
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  List<ActivityLogItem> _getFilteredActivities(
    List<ActivityLogItem> allItems,
  ) {
    final now = DateTime.now();

    return allItems.where((item) {
      switch (_selectedFilter) {
        case ActivityPeriodFilter.today:
          return item.date.year == now.year &&
              item.date.month == now.month &&
              item.date.day == now.day;
        case ActivityPeriodFilter.week:
          final difference = now.difference(item.date).inDays;
          return difference >= 0 && difference < 7;
        case ActivityPeriodFilter.month:
          return item.date.year == _selectedMonth.year &&
              item.date.month == _selectedMonth.month;
        case ActivityPeriodFilter.all:
          return true;
      }
    }).toList();
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
