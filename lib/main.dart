import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/financial_provider.dart';
import 'presentation/screens/allocation_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/expense_screen.dart';
import 'presentation/screens/income_screen.dart';
import 'presentation/screens/obligation_screen.dart';
import 'presentation/screens/report_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/splash_decision_screen.dart';
import 'presentation/screens/target_screen.dart';
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

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onNavigate: _navigateTo),
      const IncomeScreen(),
      const ExpenseScreen(),
      const AllocationScreen(),
      const ObligationScreen(),
      const TargetScreen(),
      const ReportScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex > 4 ? 0 : _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.two_wheeler_outlined),
            selectedIcon: Icon(Icons.two_wheeler, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.arrow_downward_outlined),
            selectedIcon: Icon(Icons.arrow_downward, color: AppColors.primary),
            label: 'Pendapatan',
          ),
          NavigationDestination(
            icon: Icon(Icons.arrow_upward_outlined),
            selectedIcon: Icon(Icons.arrow_upward, color: AppColors.error),
            label: 'Pengeluaran',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart, color: AppColors.primary),
            label: 'Alokasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
            label: 'Kewajiban',
          ),
        ],
      ),
    );
  }
}
