import 'package:flutter/material.dart';
import 'package:ojol_daily/presentation/screens/financial_setup_screen.dart';
import 'package:provider/provider.dart';
import '../providers/financial_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinancialProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan & Backup")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage, color: AppColors.primary),
              title: const Text(
                "Storage Local Database",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                "Tersimpan offline dengan SQLite (`sqflite`)",
              ),
              trailing: const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pengingat Input Harian Card (PRD Section 48.9)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Pengingat Input Harian",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: provider.reminderSettings.enabled,
                        activeColor: AppColors.primary,
                        onChanged: (enabled) {
                          provider.saveReminderSettings(
                            provider.reminderSettings.copyWith(
                              enabled: enabled,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Text(
                    "Ingatkan saya untuk mencatat pendapatan setelah selesai narik (PRD Section 48).",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (provider.reminderSettings.enabled) ...[
                    const Divider(height: 24),

                    _buildWorkDaysSelector(provider),

                    const SizedBox(height: 12),

                    // First Reminder
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Waktu Pengingat Pertama:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.access_time, size: 16),
                          label: Text(
                            provider.reminderSettings.firstReminderTime,
                          ),
                          onPressed: () async {
                            final parts = provider
                                .reminderSettings
                                .firstReminderTime
                                .split(':');
                            final initialTime = TimeOfDay(
                              hour: int.parse(parts[0]),
                              minute: int.parse(parts[1]),
                            );
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: initialTime,
                            );
                            if (picked != null) {
                              final timeStr =
                                  "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                              provider.saveReminderSettings(
                                provider.reminderSettings.copyWith(
                                  firstReminderTime: timeStr,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Second Reminder Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Pengingat Kedua (Jika Belum Input):",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value:
                              provider.reminderSettings.secondReminderEnabled,
                          activeColor: AppColors.primary,
                          onChanged: (enabled) {
                            provider.saveReminderSettings(
                              provider.reminderSettings.copyWith(
                                secondReminderEnabled: enabled,
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    if (provider.reminderSettings.secondReminderEnabled) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Waktu Pengingat Kedua:",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.access_time, size: 16),
                            label: Text(
                              provider.reminderSettings.secondReminderTime,
                            ),
                            onPressed: () async {
                              final parts = provider
                                  .reminderSettings
                                  .secondReminderTime
                                  .split(':');
                              final initialTime = TimeOfDay(
                                hour: int.parse(parts[0]),
                                minute: int.parse(parts[1]),
                              );
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: initialTime,
                              );
                              if (picked != null) {
                                final timeStr =
                                    "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                                provider.saveReminderSettings(
                                  provider.reminderSettings.copyWith(
                                    secondReminderTime: timeStr,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.backup_outlined,
                color: AppColors.secondary,
              ),
              title: const Text("Backup & Restore Data"),
              subtitle: const Text("Simpan cadangan data ke memori perangkat"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Data telah tersimpan di SQLite lokal. Backup otomatis aktif.",
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.error),
              title: const Text(
                "Bersihkan / Reset Data",
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: const Text("Hapus seluruh data simulasi transaksi"),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Reset Data Transaksi?"),
                    content: const Text(
                      "Seluruh catatan pendapatan, pengeluaran, dan alokasi akan dihapus.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          "Reset Data",
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await provider.clearAllData();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const FinancialSetupScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDaysSelector(FinancialProvider provider) {
    const dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final workDays = provider.reminderSettings.workDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Hari Kerja (Pengingat Aktif):",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: List.generate(7, (index) {
            final dayIso = index + 1;
            final isSelected = workDays.contains(dayIso);
            return FilterChip(
              label: Text(dayNames[index]),
              selected: isSelected,
              selectedColor: AppColors.primary.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primary : AppColors.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                final updatedDays = List<int>.from(workDays);
                if (selected) {
                  if (!updatedDays.contains(dayIso)) updatedDays.add(dayIso);
                } else {
                  updatedDays.remove(dayIso);
                }
                updatedDays.sort();
                provider.saveReminderSettings(
                  provider.reminderSettings.copyWith(
                    workDays: updatedDays,
                    enabled: updatedDays.isNotEmpty,
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
