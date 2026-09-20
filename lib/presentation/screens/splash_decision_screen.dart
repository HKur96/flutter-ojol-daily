import 'package:flutter/material.dart';
import 'package:ojol_daily/core/config/extension.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../theme/app_theme.dart';
import 'financial_setup_screen.dart';
import 'onboarding_screen.dart';

class SplashDecisionScreen extends StatefulWidget {
  const SplashDecisionScreen({super.key});

  @override
  State<SplashDecisionScreen> createState() => _SplashDecisionScreenState();
}

class _SplashDecisionScreenState extends State<SplashDecisionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _checkInitialRoute();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkInitialRoute() async {
    // Add brief splash delay for smooth transition
    await Future.delayed(const Duration(milliseconds: 2500));

    bool onboardingCompleted = false;
    bool financialSetupCompleted = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      financialSetupCompleted =
          prefs.getBool('financial_setup_completed') ?? false;
    } catch (e) {
      debugPrint('Error accessing SharedPreferences: $e');
    }

    if (!mounted) return;

    Widget targetScreen;
    if (!onboardingCompleted) {
      targetScreen = const OnboardingScreen();
    } else if (!financialSetupCompleted) {
      targetScreen = const FinancialSetupScreen();
    } else {
      targetScreen = const MainNavigationScreen();
    }

    debugPrint('Target screen: $targetScreen');
    debugPrint('onboardingCompleted: $onboardingCompleted');
    debugPrint('financialSetupCompleted: $financialSetupCompleted');

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => targetScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('app_logo'.icon, width: 80, height: 80),
                const SizedBox(height: 20),
                Text(
                  'Ojol Daily',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kelola Uang Narik Setiap Hari',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
