import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/enums.dart';
import '../../domain/financial_state.dart';
import '../../services/notification_service.dart';
import '../providers/financial_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/quick_input_modal.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int navIndex) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    final service = NotificationService();
    await service.initialize();
    await service.requestPermissions();
  }

  void _showQuickInput(BuildContext context) {
    QuickInputModal.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final provider = Provider.of<FinancialProvider>(context);
    final state = provider.state;
    final target = state.targetSummary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.two_wheeler, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              "Ojol Daily",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Offline",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offline Reassurance Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              "Mode Offline • Tersimpan di HP",
                              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.cloud_done_outlined, size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              "Aman",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Greeting
                  const Text(
                    "Selamat narik 👋",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.onSurface),
                  ),
                  const Text(
                    "Bagaimana kondisi uangmu hari ini?",
                    style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                  ),

                  const SizedBox(height: 16),

                  // Dashboard Reminder Banner (PRD Section 48.8)
                  if (provider.incomeTodayAmount == 0 && provider.todayDayStatus != DayStatus.off)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                            child: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Belum ada pendapatan hari ini",
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                                ),
                                const Text(
                                  "Setelah selesai narik, jangan lupa catat ya.",
                                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(90, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: () => _showQuickInput(context),
                            child: const Text("Catat", style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),

                  // Allocation Shortfall Warning Banner (PRD Section 30 & 44)
                  if (state.hasShortfall)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warningContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.warning, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Peringatan Alokasi (Shortfall)",
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.warning),
                                ),
                                Text(
                                  "Alokasi kurang ${currencyFormat.format(state.allocationShortfall)} karena pengeluaran mendadak memakan dana alokasi.",
                                  style: const TextStyle(fontSize: 12, color: AppColors.onSurface),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 1. Primary Financial Clarity Hero: Uang Bebas
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.verified_user_outlined, size: 18, color: AppColors.primary),
                                      SizedBox(width: 6),
                                      Text(
                                        "UANG BEBAS",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "Yang belum punya tujuan",
                                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.lock_open, size: 14, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      "Aman Dipakai",
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            currencyFormat.format(state.freeCash),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Uang tersedia (fisik):", style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                                    Text(currencyFormat.format(state.cashAvailable), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Sudah dialokasikan:", style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                                    Text("- ${currencyFormat.format(state.totalActiveAllocation)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.tertiary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Dynamic Target Performance Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Pendapatan Hari Ini",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              if (target != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${target.progressPercent.toStringAsFixed(0)}% target bulan",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                currencyFormat.format(state.totalIncome),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 8),
                              if (target != null)
                                Expanded(
                                  child: Text(
                                    "Target: ${currencyFormat.format(target.requiredDailyIncome)}/hari narik",
                                    style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: (target?.progressPercent ?? 0.0) / 100.0,
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

                  // 3. Quick Actions
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.add_circle_outline,
                          label: "+ Pendapatan",
                          color: AppColors.primary,
                          bgColor: AppColors.primaryContainer.withValues(alpha: 0.12),
                          onTap: () => widget.onNavigate(1), // Income tab
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.remove_circle_outline,
                          label: "- Pengeluaran",
                          color: AppColors.error,
                          bgColor: AppColors.errorContainer.withValues(alpha: 0.4),
                          onTap: () => widget.onNavigate(2), // Expense tab
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.pie_chart_outline,
                          label: "Alokasikan",
                          color: AppColors.secondary,
                          bgColor: AppColors.secondaryContainer,
                          onTap: () => widget.onNavigate(3), // Allocation tab
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _QuickActionButton(
                          icon: Icons.payments_outlined,
                          label: "Bayar",
                          color: AppColors.tertiary,
                          bgColor: AppColors.tertiaryContainer.withValues(alpha: 0.2),
                          onTap: () => widget.onNavigate(4), // Obligation tab
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4. Nearest Obligation Card
                  if (state.obligationSummaries.isNotEmpty) ...[
                    const Text(
                      "Kewajiban Terdekat",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    _NearestObligationCard(summary: state.obligationSummaries.first, onNavigate: () => widget.onNavigate(4)),
                  ],

                  const SizedBox(height: 16),

                  // Motivational Quote Strip
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.favorite, color: AppColors.primary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Utamakan keselamatan di jalan. Istirahat sejenak jika mulai lelah narik!",
                            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceContainerHigh),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NearestObligationCard extends StatelessWidget {
  final ObligationSummary summary;
  final VoidCallback onNavigate;

  const _NearestObligationCard({required this.summary, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  summary.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  currencyFormat.format(summary.targetAmount),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Sudah disiapkan: ${currencyFormat.format(summary.allocatedAmount)}",
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                Text(
                  "${summary.allocationProgressPercent.toStringAsFixed(0)}% siap",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: summary.allocationProgressPercent / 100.0,
              backgroundColor: AppColors.surfaceContainerHigh,
              color: AppColors.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }
}
