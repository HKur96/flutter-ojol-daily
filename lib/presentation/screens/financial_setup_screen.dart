import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widgets/custom_text_form_field.dart';
import '../providers/financial_provider.dart';
import '../theme/app_theme.dart';
import '../../main.dart';

class FinancialSetupScreen extends StatefulWidget {
  const FinancialSetupScreen({super.key});

  @override
  State<FinancialSetupScreen> createState() => _FinancialSetupScreenState();
}

class _ObligationEntry {
  final TextEditingController nameController;
  final TextEditingController amountController;
  final IconData icon;
  final Color color;

  _ObligationEntry({
    String name = '',
    String amount = '',
    this.icon = Icons.payments,
    this.color = const Color(0xFF006B2C),
  }) : nameController = TextEditingController(text: name),
       amountController = TextEditingController(text: amount);

  void dispose() {
    nameController.dispose();
    amountController.dispose();
  }
}

class _FinancialSetupScreenState extends State<FinancialSetupScreen> {
  final _targetController = TextEditingController();
  final _workingDaysController = TextEditingController(text: '26');
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final List<_ObligationEntry> _obligations = [
    _ObligationEntry(
      name: 'Cicilan Motor',
      amount: '',
      icon: Icons.two_wheeler,
      color: const Color(0xFF8D4B00),
    ),
    _ObligationEntry(
      name: 'Bensin & Operasional',
      amount: '',
      icon: Icons.local_gas_station,
      color: const Color(0xFF006B2C),
    ),
    _ObligationEntry(
      name: 'Kebutuhan Keluarga',
      amount: '',
      icon: Icons.home,
      color: const Color(0xFF565E74),
    ),
  ];

  @override
  void dispose() {
    _targetController.dispose();
    _workingDaysController.dispose();
    for (final ob in _obligations) {
      ob.dispose();
    }
    super.dispose();
  }

  void _addObligation() {
    setState(() {
      _obligations.add(_ObligationEntry());
    });
  }

  void _removeObligation(int index) {
    setState(() {
      _obligations[index].dispose();
      _obligations.removeAt(index);
    });
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<FinancialProvider>();

      // Save monthly target
      final targetAmount =
          int.tryParse(
            _targetController.text.replaceAll('.', '').replaceAll(',', ''),
          ) ??
          0;
      final workingDays = int.tryParse(_workingDaysController.text) ?? 26;

      if (targetAmount > 0) {
        await provider.saveMonthlyTarget(
          monthlyTargetAmount: targetAmount,
          totalWorkingDays: workingDays,
        );
      }

      // Save obligations
      for (final ob in _obligations) {
        final name = ob.nameController.text.trim();
        final amount =
            int.tryParse(
              ob.amountController.text.replaceAll('.', '').replaceAll(',', ''),
            ) ??
            0;
        if (name.isNotEmpty && amount > 0) {
          await provider.addObligation(
            name: name,
            targetAmount: amount,
            dueDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 1),
            category: 'setup',
          );
        }
      }

      // Mark onboarding and financial setup as completed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      await prefs.setBool('financial_setup_completed', true);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.two_wheeler,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Setup Keuangan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        'Atur target & kewajiban awal',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scroll content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Berapa target narikmu?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Isi sesuai kebutuhanmu, bisa diubah kapan saja.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Section 1: Target ──────────
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSectionHeader('Target Pendapatan Bulanan'),
                            const SizedBox(height: 10),
                            CustomTextFormField.currency(
                              controller: _targetController,
                              labelText: 'Target per bulan',
                              hintText: 'Contoh: 5.000.000',
                              
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Masukkan target pendapatan';
                                }
                                final amount =
                                    int.tryParse(
                                      v.replaceAll('.', '').replaceAll(',', ''),
                                    ) ??
                                    0;
                                if (amount < 100000) {
                                  return 'Minimal Rp 100.000';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            CustomTextFormField(
                              controller: _workingDaysController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              labelText: 'Hari kerja per bulan',
                              hintText: '26',
                              suffix: const Text(
                                'hari',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Masukkan hari kerja';
                                }
                                final days = int.tryParse(v) ?? 0;
                                if (days < 1 || days > 31) {
                                  return 'Antara 1-31 hari';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Section 2: Kewajiban ───────
                      _buildSectionHeader('Kewajiban / Alokasi Rutin'),
                      const SizedBox(height: 4),
                      Text(
                        'Pos pengeluaran wajib yang disisihkan setiap hari.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...List.generate(_obligations.length, (index) {
                        final ob = _obligations[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon
                              Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: ob.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(ob.icon, size: 18, color: ob.color),
                              ),
                              const SizedBox(width: 12),
                              // Fields
                              Expanded(
                                child: Column(
                                  children: [
                                    CustomTextFormField(
                                      controller: ob.nameController,
                                      labelText: 'Nama kewajiban',
                                      hintText: 'Contoh: Cicilan Motor',
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    CustomTextFormField.currency(
                                      controller: ob.amountController,
                                      labelText: 'Nominal per bulan',
                                      hintText: '0',
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Remove button
                              if (_obligations.length > 1)
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  onPressed: () => _removeObligation(index),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),

                      // Add obligation button
                      Center(
                        child: TextButton.icon(
                          onPressed: _addObligation,
                          icon: Icon(
                            Icons.add_circle_outline,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            'Tambah Kewajiban',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Info card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Semua data bisa diubah kapan saja di menu Pengaturan. Kewajiban yang kosong nominalnya akan dilewati.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _completeSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Mulai Pakai Ojol Daily',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
