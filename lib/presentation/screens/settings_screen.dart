import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ojol_daily/core/widgets/custom_text_form_field.dart';
import 'package:ojol_daily/presentation/screens/financial_setup_screen.dart';
import 'package:ojol_daily/presentation/screens/wallet_management_screen.dart';
import 'package:provider/provider.dart';
import '../providers/financial_provider.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _startBalance = TextEditingController();
  bool _startBalanceInitialized = false;

  static final _numberFormat = NumberFormat('#,###', 'id_ID');

  @override
  void dispose() {
    _startBalance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan & Backup")),
      body: Consumer<FinancialProvider>(
        builder: (context, provider, _) {
          // Initialize controller once with current value from provider
          if (!_startBalanceInitialized && !provider.isLoading) {
            final currentBalance = provider.currentTarget?.startBalance ?? 0;
            if (currentBalance > 0) {
              _startBalance.text = _numberFormat.format(currentBalance);
            }
            _startBalanceInitialized = true;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Saldo Awal Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Saldo Awal",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Saldo awal yang kamu miliki di awal bulan ini.",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomTextFormField.currency(
                        controller: _startBalance,
                        labelText: 'Saldo awal',
                        hintText: 'Contoh: 10.000.000',
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final amount =
                                int.tryParse(
                                  _startBalance.text
                                      .replaceAll('.', '')
                                      .replaceAll(',', ''),
                                ) ??
                                0;
                            provider.updateStartBalance(amount);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saldo awal berhasil diperbarui'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Simpan Saldo Awal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                              value: provider
                                  .reminderSettings
                                  .secondReminderEnabled,
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

                        if (provider
                            .reminderSettings
                            .secondReminderEnabled) ...[
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

              // Manajemen Dompet Card
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    "Manajemen Dompet (Multi-Dompet)",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    "Kelola dompet Tunai, GoPay, BCA & Transfer",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WalletManagementScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Akun Google Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_circle, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            "Akun Google",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (provider.googleUser != null) ...[
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryContainer,
                              radius: 20,
                              backgroundImage:
                                  (provider.googleUser?.photoUrl != null)
                                  ? NetworkImage(provider.googleUser!.photoUrl!)
                                  : null,
                              child: (provider.googleUser?.photoUrl == null)
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.googleUser!.displayName!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    provider.googleUser!.email,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Terhubung",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: provider.isGoogleDriveLoading
                              ? null
                              : () async {
                                  await provider.signOutGoogle();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Telah keluar dari akun Google.",
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text("Keluar Akun Google"),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(40),
                            foregroundColor: AppColors.error,
                          ),
                        ),
                      ] else ...[
                        const Text(
                          "Hubungkan akun Google untuk menyinkronkan & menyimpan cadangan data secara otomatis ke Google Drive.",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: provider.isGoogleDriveLoading
                              ? null
                              : () async {
                                  await provider.signInGoogle();
                                  if (!context.mounted) return;
                                  if (provider.googleUser != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Berhasil terhubung dengan Akun Google!",
                                        ),
                                        backgroundColor: AppColors.primary,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          icon: provider.isGoogleDriveLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.g_mobiledata, size: 24),
                          label: Text(
                            provider.isGoogleDriveLoading
                                ? "Menghubungkan..."
                                : "Hubungkan Akun Google",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Backup & Restore Google Drive Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_to_drive,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Backup & Restore Google Drive",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (provider.isGoogleDriveLoading) ...[
                              const Spacer(),
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload,
                            color: AppColors.primary,
                          ),
                        ),
                        title: const Text(
                          "Cadangkan ke Google Drive",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          provider.lastGoogleBackupTime != null
                              ? "Terakhir dicadangkan: ${DateFormat('dd MMM yyyy, HH:mm').format(provider.lastGoogleBackupTime!)}"
                              : "Belum pernah dicadangkan ke Google Drive",
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: provider.isGoogleDriveLoading
                            ? null
                            : () async {
                                final success = await provider
                                    .backupToGoogleDrive();
                                if (!context.mounted) return;
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Data berhasil dicadangkan ke Google Drive!",
                                      ),
                                      backgroundColor: AppColors.primary,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Gagal mencadangkan data ke Google Drive.",
                                      ),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_download,
                            color: AppColors.warning,
                          ),
                        ),
                        title: const Text(
                          "Pulihkan dari Google Drive",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          "Unduh dan pulihkan data transaksi dari Google Drive",
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: provider.isGoogleDriveLoading
                            ? null
                            : () async {
                                final jsonStr = await provider
                                    .downloadBackupFromGoogleDrive();
                                if (!context.mounted) return;
                                if (jsonStr == null || jsonStr.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Tidak ditemukan data cadangan di Google Drive.",
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  _processAndConfirmRestore(
                                    context,
                                    provider,
                                    jsonStr,
                                  );
                                }
                              },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ExpansionTile(
                        leading: const Icon(
                          Icons.folder_zip_outlined,
                          color: AppColors.secondary,
                        ),
                        title: const Text(
                          "Opsi Cadangan Lokal (File / Clipboard)",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          "Ekspor/impor manual menggunakan file .json lokal",
                          style: TextStyle(fontSize: 11),
                        ),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.share_outlined, size: 20),
                            title: const Text("Ekspor ke File / Share"),
                            onTap: () => _showBackupSheet(context, provider),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.file_open_outlined,
                              size: 20,
                            ),
                            title: const Text("Impor dari File / Paste JSON"),
                            onTap: () => _showRestoreSheet(context, provider),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: AppColors.error,
                  ),
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
                      if (!context.mounted) return;
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
          );
        },
      ),
    );
  }

  Widget _buildWorkDaysSelector(FinancialProvider provider) {
    const dayNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final workDays = provider.reminderSettings.workDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Hari Kerja (Pengingat Aktif):",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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

  void _showBackupSheet(BuildContext context, FinancialProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cadangkan Data (Backup)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Ekspor seluruh data transaksi & pengaturan ke JSON",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.share_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text("Bagikan / Simpan File Backup"),
                  subtitle: const Text(
                    "Kirim file .json ke Google Drive, WA, atau simpan di HP",
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await provider.shareBackupFile();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Gagal membagikan backup: $e"),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.copy_outlined,
                    color: AppColors.secondary,
                  ),
                  title: const Text("Salin Kode Backup (Clipboard)"),
                  subtitle: const Text(
                    "Salin data teks JSON langsung ke clipboard",
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final jsonStr = await provider.exportBackupJson();
                      await Clipboard.setData(ClipboardData(text: jsonStr));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Kode backup JSON berhasil disalin ke clipboard!",
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Gagal menyalin backup: $e"),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.code, color: AppColors.tertiary),
                  title: const Text("Pratinjau Teks JSON"),
                  subtitle: const Text("Lihat format teks data cadangan"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final jsonStr = await provider.exportBackupJson();
                    if (!context.mounted) return;
                    _showJsonPreviewDialog(context, jsonStr);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRestoreSheet(BuildContext context, FinancialProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_download_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pulihkan Data (Restore)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Impor data dari file backup JSON sebelumnya",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.file_open_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text("Pilih File Backup (.json)"),
                  subtitle: const Text(
                    "Buka file backup yang tersimpan di perangkat",
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final jsonStr = await provider.pickBackupFile();
                      if (jsonStr == null) return;
                      if (!context.mounted) return;
                      _processAndConfirmRestore(context, provider, jsonStr);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Gagal membaca file: $e"),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.paste_outlined,
                    color: AppColors.secondary,
                  ),
                  title: const Text("Tempel Kode JSON (Paste)"),
                  subtitle: const Text("Tempel teks JSON backup secara manual"),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPasteJsonDialog(context, provider);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPasteJsonDialog(BuildContext context, FinancialProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tempel Kode Backup JSON"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tempelkan isi teks backup JSON yang telah disalin sebelumnya:",
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: '{"appName": "ojol_daily", "tables": ...}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              final jsonText = controller.text.trim();
              Navigator.pop(ctx);
              if (jsonText.isNotEmpty) {
                _processAndConfirmRestore(context, provider, jsonText);
              }
            },
            child: const Text("Proses Restore"),
          ),
        ],
      ),
    );
  }

  void _processAndConfirmRestore(
    BuildContext context,
    FinancialProvider provider,
    String jsonStr,
  ) {
    try {
      final summary = provider.parseAndValidateBackup(jsonStr);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text("Konfirmasi Restore"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Data backup valid ditemukan. Detail data cadangan:",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tanggal Ekspor: ${summary['exportedAt']}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "• Pemasukan: ${summary['totalIncome']} transaksi",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      "• Pengeluaran: ${summary['totalExpense']} transaksi",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      "• Kewajiban: ${summary['totalObligations']} item",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      "• Dompet: ${summary['totalWallets']} dompet",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "PERINGATAN: Memulihkan data akan MENGGANTIKAN seluruh transaksi & dompet saat ini secara permanen.",
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await provider.restoreBackupJson(jsonStr);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Data berhasil dipulihkan dari backup!"),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Gagal memulihkan data: $e"),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text("Pulihkan Data Sekarang"),
            ),
          ],
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Format Backup Tidak Valid"),
          content: Text(e.toString().replaceAll('FormatException: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Tutup"),
            ),
          ],
        ),
      );
    }
  }

  void _showJsonPreviewDialog(BuildContext context, String jsonStr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kode Backup JSON"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonStr,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text("Salin Kode"),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Kode backup berhasil disalin!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }
}
