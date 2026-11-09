import 'package:document_reviewer/app/providers.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:document_reviewer/features/backup_restore/ui/backup_restore_screen.dart';
import 'package:document_reviewer/features/onboarding/onboarding_screen.dart';
import 'package:document_reviewer/features/settings/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-featured Settings screen covering Themes, App Lock Security,
/// Backup & Restore, Secure Data Wipe, and About info.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final loc = AppLocalizations.of(context);
    final lockService = ref.watch(appLockServiceProvider);
    final lockState = lockService.state;

    return Scaffold(
      appBar: AppBar(title: Text(loc.settings)),
      body: ListView(
        children: [
          // 1. Theme Section
          _SectionTitle(title: loc.theme),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(loc.theme),
            subtitle: Text(
              switch (themeMode) {
                ThemeModePreference.light => loc.themeLight,
                ThemeModePreference.dark => loc.themeDark,
                ThemeModePreference.system => loc.themeSystem,
              },
            ),
            onTap: () => _showThemeDialog(context, ref, themeMode, loc),
          ),

          const Divider(),

          // 2. Security Section (App Lock & FLAG_SECURE)
          const _SectionTitle(title: 'Keamanan & Kunci Aplikasi'),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('Kunci PIN & Biometrik'),
            subtitle: Text(
              lockState.isLockEnabled
                  ? 'PIN aktif (Biometrik ${lockState.useBiometrics ? "aktif" : "nonaktif"})'
                  : 'Nonaktif',
            ),
            value: lockState.isLockEnabled,
            onChanged: (enabled) {
              if (enabled) {
                _showSetPinDialog(context);
              } else {
                _showDisableLockDialog(context);
              }
            },
          ),
          if (lockState.isLockEnabled) ...[
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Gunakan Biometrik (Sidik Jari / Wajah)'),
              subtitle:
                  const Text('Buka kunci lebih cepat dengan sensor perangkat'),
              value: lockState.useBiometrics,
              onChanged: (val) {
                setState(() {
                  lockService.setUseBiometrics(enabled: val);
                });
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.timer_outlined),
              title: const Text('Kunci Otomatis di Latar Belakang'),
              subtitle: const Text('Kunci kembali saat aplikasi ditinggalkan'),
              value: lockState.autoLockOnBackground,
              onChanged: (val) {
                setState(() {
                  lockService.setAutoLockOnBackground(enabled: val);
                });
              },
            ),
          ],
          SwitchListTile(
            secondary: const Icon(Icons.security),
            title: const Text('Blokir Tangkapan Layar (FLAG_SECURE)'),
            subtitle: const Text('Cegah screenshot & pratinjau di recent apps'),
            value: lockState.blockScreenshots,
            onChanged: (val) async {
              await lockService.setBlockScreenshots(block: val);
              setState(() {});
            },
          ),

          const Divider(),

          // 3. Backup & Restore Section
          const _SectionTitle(title: 'Cadangan & Pemulihan Data'),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Cadangan & Pemulihan (Backup & Restore)'),
            subtitle: const Text(
                'Ekspor metadata, pengaturan, atau pulihkan dari berkas'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const BackupRestoreScreen(),
                ),
              );
            },
          ),

          const Divider(),

          // 4. Secure Wipe Section
          const _SectionTitle(title: 'Pembersihan & Hapus Aman'),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Bersihkan Berkas Sementara & Cache'),
            subtitle: const Text('Hapus cache pindaian OCR dan file pratinjau'),
            onTap: () => _handleCleanCache(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Hapus Semua Data Aplikasi',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text(
                'Reset database dan pengaturan (berkas asli tetap aman)'),
            onTap: () => _showWipeAllDataDialog(context),
          ),

          const Divider(),

          // 5. About & Help Section
          const _SectionTitle(title: 'Tentang & Bantuan'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Panduan Pengenalan Aplikasi'),
            subtitle: const Text('Buka kembali tur walkthrough fitur utama'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => OnboardingScreen(
                    onFinished: () => Navigator.of(context).pop(),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang Aplikasi'),
            subtitle: const Text(
                'Versi, kebijakan privasi, dan lisensi pihak ketiga'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeModePreference current,
    AppLocalizations loc,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(loc.theme),
        children: ThemeModePreference.values.map((mode) {
          return RadioListTile<ThemeModePreference>(
            title: Text(
              switch (mode) {
                ThemeModePreference.light => loc.themeLight,
                ThemeModePreference.dark => loc.themeDark,
                ThemeModePreference.system => loc.themeSystem,
              },
            ),
            value: mode,
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeModeProvider.notifier).state = value;
              }
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
    );
  }

  void _showSetPinDialog(BuildContext context) {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atur PIN Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan 4 - 6 digit PIN untuk mengamankan aplikasi.'),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN Baru',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (pinCtrl.text.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN minimal 4 digit')),
                );
                return;
              }
              if (pinCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Konfirmasi PIN tidak cocok')),
                );
                return;
              }

              ref.read(appLockServiceProvider).setPin(pinCtrl.text);
              Navigator.of(ctx).pop();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kunci PIN berhasil diaktifkan')),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDisableLockDialog(BuildContext context) {
    final pinCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nonaktifkan Kunci'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan PIN Anda saat ini untuk menonaktifkan kunci.'),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN Saat Ini',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final ok =
                  ref.read(appLockServiceProvider).verifyPin(pinCtrl.text);
              if (ok) {
                ref.read(appLockServiceProvider).disableLock();
                Navigator.of(ctx).pop();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kunci aplikasi dinonaktifkan')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN salah')),
                );
              }
            },
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCleanCache(BuildContext context) async {
    final wipeService = ref.read(secureWipeServiceProvider);
    final res = await wipeService.cleanTemporaryCaches();

    if (context.mounted) {
      final kb = (res.freedBytes / 1024).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pembersihan selesai: ${res.deletedFilesCount} berkas sementara dihapus ($kb KB dibebaskan).',
          ),
        ),
      );
    }
  }

  void _showWipeAllDataDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Semua Data?'),
          ],
        ),
        content: const Text(
          'Tindakan ini akan menghapus seluruh metadata riwayat dokumen, favorit, berkas sementara, dan pengaturan keamanan aplikasi secara permanen.\n\n'
          'Berkas dokumen asli pada penyimpanan Anda TIDAK akan terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok =
                  await ref.read(secureWipeServiceProvider).wipeAllAppData();
              if (context.mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Seluruh data aplikasi berhasil dibersihkan.'
                          : 'Gagal membersihkan sebagian data.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Ya, Hapus Semua Data'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
