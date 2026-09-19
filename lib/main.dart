import 'package:flutter/material.dart';
import 'package:ojol_daily/core/config/enum.dart';
import 'package:ojol_daily/core/widgets/animated_option_slider.dart';
import 'package:ojol_daily/domain/enums.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/financial_provider.dart';
import 'presentation/screens/allocation_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/report_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/splash_decision_screen.dart';
import 'presentation/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OjolDailyApp());
}

class OjolDailyApp extends StatelessWidget {
  const OjolDailyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinancialProvider.create()..loadData(),
      child: MaterialApp(
        title: 'Ojol Daily',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashDecisionScreen(),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onAddPressed() {
    DailyType dailyType = DailyType.income;

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
                  AnimatedOptionSlider(
                    onSelectionChanged: (value) {
                      setState(() {
                        dailyType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (dailyType == DailyType.income)
                    _buildIncomeForm(ctx, setState)
                  else
                    _buildExpenseForm(ctx, setState),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(),
      const AllocationScreen(),
      const ReportScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPressed,
        backgroundColor: AppTheme.primary,
        elevation: 2.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: AppColors.surfaceContainer,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 'Beranda', 0),
              _buildNavItem(
                Icons.pie_chart_outline,
                Icons.pie_chart,
                'Alokasi',
                1,
              ),

              const SizedBox(width: 40),

              _buildNavItem(
                Icons.note_alt_outlined,
                Icons.note_alt,
                'Laporan',
                2,
              ),
              _buildNavItem(
                Icons.settings_outlined,
                Icons.settings,
                'Settings',
                3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData iconOutlined,
    IconData iconFilled,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : Colors.black;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? iconFilled : iconOutlined,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeForm(BuildContext ctx, StateSetter setState) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    IncomeSource? selectedSource;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Catat Pendapatan Narik",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<IncomeSource>(
          value: selectedSource,
          decoration: const InputDecoration(labelText: "Aplikasi / Sumber"),
          items: IncomeSource.values
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.displayIncomeSource),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => selectedSource = val!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Nominal (Rp)",
            prefixText: "Rp ",
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: "Catatan (opsional)"),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            final amount =
                int.tryParse(
                  amountController.text.replaceAll('.', '').replaceAll(',', ''),
                ) ??
                0;
            if (amount > 0 && selectedSource != null) {
              Provider.of<FinancialProvider>(context, listen: false).addIncome(
                amount: amount,
                category: selectedSource!.displayIncomeSource,
                note: noteController.text.isNotEmpty
                    ? noteController.text
                    : null,
              );
              Navigator.pop(ctx);
            }
          },
          child: const Text("Simpan Pendapatan"),
        ),
      ],
    );
  }

  Widget _buildExpenseForm(BuildContext ctx, StateSetter setState) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = 'Bensin';
    ExpenseSource selectedSource = ExpenseSource.free;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Catat Pengeluaran",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: selectedCategory,
          decoration: const InputDecoration(labelText: "Kategori Pengeluaran"),
          items: [
            'Bensin',
            'Makan',
            'Servis Motor',
            'Oli',
            'Tambal Ban',
            'Keluarga',
            'Mendadak',
            'Lainnya',
          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) => setState(() => selectedCategory = val!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Nominal (Rp)",
            prefixText: "Rp ",
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Sumber Dana Pengeluaran:",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        SegmentedButton<ExpenseSource>(
          segments: const [
            ButtonSegment(value: ExpenseSource.free, label: Text("Uang Bebas")),
            ButtonSegment(
              value: ExpenseSource.allocated,
              label: Text("Uang Alokasi"),
            ),
          ],
          selected: {selectedSource},
          onSelectionChanged: (set) =>
              setState(() => selectedSource = set.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: "Catatan (opsional)"),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () {
            final amount =
                int.tryParse(
                  amountController.text.replaceAll('.', '').replaceAll(',', ''),
                ) ??
                0;
            if (amount > 0) {
              Provider.of<FinancialProvider>(context, listen: false).addExpense(
                amount: amount,
                category: selectedCategory,
                source: selectedSource,
                freeAmountUsed: selectedSource == ExpenseSource.free
                    ? amount
                    : 0,
                allocatedAmountUsed: selectedSource == ExpenseSource.allocated
                    ? amount
                    : 0,
                note: noteController.text.isNotEmpty
                    ? noteController.text
                    : null,
              );
              Navigator.pop(ctx);
            }
          },
          child: const Text("Simpan Pengeluaran"),
        ),
      ],
    );
  }
}
