import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ojol_daily/core/config/enum.dart';
import 'package:ojol_daily/core/utils/date_formatter.dart';
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
  final TextEditingController dueDateController;

  _ObligationEntry({
    String name = '',
    String amount = '',
    this.type = ObligationDefinitionType.bulanan,
    String dueDate = '',
  }) : nameController = TextEditingController(text: name),
       amountController = TextEditingController(text: amount),
       dueDateController = TextEditingController(text: dueDate);

  void dispose() {
    nameController.dispose();
    amountController.dispose();
    dueDateController.dispose();
  }
}

class _FinancialSetupScreenState extends State<FinancialSetupScreen> {
  final _targetController = TextEditingController();
  final _workingDaysController = TextEditingController(text: '26');
  final _startBalance = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> _isSubmitting = ValueNotifier<bool>(false);

  final ValueNotifier<List<_ObligationEntry>> _obligations = ValueNotifier([
    _ObligationEntry(
      name: 'Cicilan Motor',
      amount: '',
      type: ObligationDefinitionType.bulanan,
      dueDate: '',
    ),
    _ObligationEntry(
      name: 'Kebutuhan Keluarga',
      amount: '',
      type: ObligationDefinitionType.bulanan,
      dueDate: '',
    ),
  ]);

  final ValueNotifier<List<Map<String, bool>>> _weekDays =
      ValueNotifier<List<Map<String, bool>>>([
        {'Senin': false},
        {'Selasa': false},
        {'Rabu': false},
        {'Kamis': false},
        {'Jumat': false},
        {'Sabtu': false},
        {'Minggu': false},
      ]);

  @override
  void dispose() {
    _targetController.dispose();
    _workingDaysController.dispose();
    _startBalance.dispose();
    for (final ob in _obligations.value) {
      ob.dispose();
    }
    _obligations.dispose();
    _isSubmitting.dispose();
    _weekDays.dispose();
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

  void _updateObligationDueDate(int index, TextEditingController controller) {
    final currentObligations = _obligations.value;
    final obligation = currentObligations[index];
    _obligations.value = [
      ...currentObligations.take(index),
      _ObligationEntry(
        name: obligation.nameController.text,
        amount: obligation.amountController.text,
        type: obligation.type,
        dueDate: controller.text,
      ),
      ...currentObligations.skip(index + 1),
    ];
  }

  Future<DateTime?> _selectDate(
    int index,
    TextEditingController controller,
  ) async {
    final now = DateTime.now();
    final DateTime initialDate = now;
    final DateTime firstDate = now;
    final DateTime lastDate = DateTime(2030);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      controller.text = DateFormatter.fullDate(pickedDate);
    }

    return pickedDate;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<FinancialProvider>();
      final workDays = provider.reminderSettings.workDays;
      if (workDays.isNotEmpty) {
        _weekDays.value = [
          {'Senin': workDays.contains(1)},
          {'Selasa': workDays.contains(2)},
          {'Rabu': workDays.contains(3)},
          {'Kamis': workDays.contains(4)},
          {'Jumat': workDays.contains(5)},
          {'Sabtu': workDays.contains(6)},
          {'Minggu': workDays.contains(7)},
        ];
        final activeCount = _weekDays.value
            .where((day) => day.values.first)
            .length;
        if (activeCount > 0) {
          _workingDaysController.text = (activeCount * 4).toString();
        }
      }
    });
  }

  void _updateWorkingDays(int index, bool value) {
    final currentWorkingDays = _weekDays.value;
    final currentWorkingDay = currentWorkingDays[index];
    final updated = [
      ...currentWorkingDays.take(index),
      {currentWorkingDay.keys.first: value},
      ...currentWorkingDays.skip(index + 1),
    ];
    _weekDays.value = updated;
    // final activeCount = updated.where((day) => day.values.first).length;
    // if (activeCount > 0) {
    //   _workingDaysController.text = (activeCount * 4).toString();
    // }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    // validate weekdays should be at least 1
    final isWorkingDaysSelected = _weekDays.value.any(
      (day) => day.values.first,
    );
    if (!isWorkingDaysSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih setidaknya 1 hari kerja')),
      );
      return;
    }

    _isSubmitting.value = true;

    try {
      final provider = context.read<FinancialProvider>();

      // Save working days to ReminderSettings
      final List<int> selectedWorkDays = [];
      for (int i = 0; i < _weekDays.value.length; i++) {
        if (_weekDays.value[i].values.first) {
          selectedWorkDays.add(i + 1); // 1=Senin, ..., 7=Minggu
        }
      }

      final updatedReminderSettings = provider.reminderSettings.copyWith(
        workDays: selectedWorkDays,
        enabled: selectedWorkDays.isNotEmpty,
      );
      await provider.saveReminderSettings(updatedReminderSettings);

      // Save monthly target
      final targetAmount =
          int.tryParse(
            _targetController.text.replaceAll('.', '').replaceAll(',', ''),
          ) ??
          0;
      final workingDays = int.tryParse(_workingDaysController.text) ?? 26;
      final startBalance =
          int.tryParse(
            _startBalance.text.replaceAll('.', '').replaceAll(',', ''),
          ) ??
          0;

      if (targetAmount > 0) {
        await provider.saveMonthlyTarget(
          monthlyTargetAmount: targetAmount,
          totalWorkingDays: workingDays,
          startBalance: startBalance,
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
            dueDate: DateFormatter.fullDateToDateTime(
              ob.dueDateController.text,
            ),
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

                      // ── Section 2: Working Days ──────────
                      _buildWorkingDaysSetup(),

                      // ── Section 3: Kewajiban ───────
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
              textInputAction: TextInputAction.next,
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
              textInputAction: TextInputAction.next,
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
            const SizedBox(height: 12),
            CustomTextFormField.currency(
              controller: _startBalance,
              labelText: 'Saldo awal',
              hintText: 'Contoh: 10.000.000',
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Masukkan saldo awal';
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
        CustomTextFormField(
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
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CustomTextFormField(
                controller: ob.dueDateController,
                labelText: 'Tanggal jatuh tempo',
                hintText: 'Contoh: 1 Agustus 2026',
                readOnly: true,
                prefixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.onSurfaceVariant,
                ),
                textCapitalization: TextCapitalization.words,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Masukkan tanggal jatuh tempo';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onTap: () async {
                  final pickedDate = await _selectDate(
                    index,
                    ob.dueDateController,
                  );

                  if (pickedDate == null) return;

                  _updateObligationDueDate(index, ob.dueDateController);
                },
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
      ],
    );
  }

  Widget _buildWorkingDaysSetup() {
    return ValueListenableBuilder<List<Map<String, bool>>>(
      valueListenable: _weekDays,
      builder: (context, weekDays, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Hari Kerja',
              'Hari kerja yang ingin kamu capai setiap minggu.',
            ),
            Row(
              children: [
                ...List.generate(weekDays.length, (index) {
                  return _buildWorkingDays(index, weekDays[index]);
                }),
              ],
            ),
            const SizedBox(height: 28),
          ],
        );
      },
    );
  }

  Widget _buildWorkingDays(int index, Map<String, bool> weekday) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _updateWorkingDays(index, !weekday.values.first),
        child: Container(
          margin: index == 0 ? EdgeInsets.zero : const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: weekday.values.first
                ? AppColors.primary
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Text(
            weekday.keys.first,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: weekday.values.first
                  ? AppColors.onPrimary
                  : AppColors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
