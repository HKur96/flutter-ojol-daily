import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/financial_provider.dart';
import 'presentation/screens/allocation_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/report_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/splash_decision_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/widgets/add_transaction_sheet.dart';

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
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
        locale: const Locale('id', 'ID'),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onOpen: _onAddPressed),
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
}
