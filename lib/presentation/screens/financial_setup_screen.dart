import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ojol_daily/core/config/enum.dart';
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
  final ObligationDefinitionType type;

  _ObligationEntry({
    String name = '',
    String amount = '',
    this.type = ObligationDefinitionType.bulanan,
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
  final ValueNotifier<bool> _isSubmitting = ValueNotifier<bool>(false);

  final ValueNotifier<List<_ObligationEntry>> _obligations = ValueNotifier([
    _ObligationEntry(
      name: 'Cicilan Motor',
      amount: '',
      type: ObligationDefinitionType.bulanan,
    ),
    _ObligationEntry(
      name: 'Bensin & Operasional',
      amount: '',
      type: ObligationDefinitionType.bulanan,
    ),
    _ObligationEntry(
      name: 'Kebutuhan Keluarga',
      amount: '',
      type: ObligationDefinitionType.bulanan,
    ),
  ]);

  @override
  void dispose() {
    _targetController.dispose();
    _workingDaysController.dispose();
    for (final ob in _obligations.value) {
      ob.dispose();
    }
    _obligations.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  void _addObligation() {
    final currentObligations = _obligations.value;
    _obligations.value = [...currentObligations, _ObligationEntry()];
  }

  void _removeObligation(int index) {
    final currentObligations = _obligations.value;
    _obligations.value =
        currentObligations.take(index).toList() +
        currentObligations.skip(index + 1).toList();
  }

  void _updateObligationType(int index, ObligationDefinitionType type) {
    final currentObligations = _obligations.value;
    final obligation = currentObligations[index];
    _obligations.value = [
      ...currentObligations.take(index),
      _ObligationEntry(
        name: obligation.nameController.text,
        amount: obligation.amountController.text,
        type: type,
      ),
      ...currentObligations.skip(index + 1),
    ];
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    _isSubmitting.value = true;

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
      for (final ob in _obligations.value) {
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
            type: ob.type,
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
      _isSubmitting.value = false;
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
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Section 1: Target ──────────
                      _buildFinancialGoalSetup(),

                      // ── Section 2: Kewajiban ───────
                      _buildObligationDefinition(),

                      // Info card
                      _buildInfoCard(),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom CTA
            ValueListenableBuilder<bool>(
              valueListenable: _isSubmitting,
              builder: (context, isSubmitting, child) {
                return Container(
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
                      onPressed: isSubmitting ? null : _completeSetup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSubmitting
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildObligationDefinition() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Kewajiban / Alokasi Rutin',
          'Pos pengeluaran wajib yang disisihkan setiap hari.',
        ),

        ValueListenableBuilder(
          valueListenable: _obligations,
          builder: (_, obligations, _) => Container(
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
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: obligations.length,
              separatorBuilder: (_, _) => Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 5),
                child: Divider(color: Colors.grey.shade400),
              ),
              itemBuilder: (_, index) =>
                  _buildItemObligation(obligations, index),
            ),
          ),
        ),

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
      ],
    );
  }

  Widget _buildInfoCard() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Semua data bisa diubah kapan saja di menu '
                'Pengaturan. Kewajiban yang kosong nominalnya '
                'akan dilewati.',
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
  );

  Widget _buildFinancialGoalSetup() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader(
        'Target Pendapatan Bulanan',
        'Target pendapatan yang ingin kamu capai setiap bulannya.',
      ),
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
            CustomTextFormField.currency(
              controller: _targetController,
              labelText: 'Target per bulan',
              hintText: 'Contoh: 5.000.000',

              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Masukkan target pendapatan';
                }
                final amount =
                    int.tryParse(v.replaceAll('.', '').replaceAll(',', '')) ??
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              labelText: 'Hari kerja per bulan',
              hintText: '26',
              suffix: const Text(
                'hari',
                style: TextStyle(color: AppColors.secondary),
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
    ],
  );

  Widget _buildItemObligation(List<_ObligationEntry> obligations, int index) {
    final ob = obligations[index];
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CustomTextFormField(
                controller: ob.nameController,
                labelText: 'Nama kewajiban',
                hintText: 'Contoh: Cicilan Motor',
                textCapitalization: TextCapitalization.words,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Masukkan nama kewajiban';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
            ),
            // Remove button
            if (obligations.length > 1)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.error,
                ),
                onPressed: () => _removeObligation(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 10,
          children: [
            // Fields
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  CustomTextFormField.currency(
                    controller: ob.amountController,
                    labelText: 'Nominal per bulan',
                    hintText: '0',
                    textInputAction: TextInputAction.done,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jenis Kewajiban',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ObligationDefinitionType>(
                        value: ob.type,
                        items: ObligationDefinitionType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayObligation),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          _updateObligationType(index, value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
