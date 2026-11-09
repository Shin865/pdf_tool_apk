import 'package:document_reviewer/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Screen displaying application version, privacy pledge, and third-party licenses.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versi ${AppConstants.appVersion}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.wifi_off, size: 16),
                  label: const Text('100% Offline-First'),
                  backgroundColor:
                      theme.colorScheme.primaryContainer.withOpacity(0.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),

          // Privacy Policy Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kebijakan Privasi',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Tanpa Akses Jaringan: Aplikasi ini tidak memiliki izin koneksi internet (android.permission.INTERNET sengaja ditiadakan). Dokumen Anda tidak pernah meninggalkan perangkat.\n\n'
                    '2. Tanpa Iklan & Pelacak: Tidak ada SDK analitik, pelacak perilaku, maupun jaringan iklan pihak ketiga yang disematkan.\n\n'
                    '3. Akses Berkas Berizin Minimal: Menggunakan Storage Access Framework (SAF) resmi dari Android. Hanya berkas yang dipilih pengguna yang dapat diakses.\n\n'
                    '4. Biometrik Lokal: Verifikasi PIN dan sidik jari diproses sepenuhnya oleh sistem operasi perangkat Anda.',
                    style: TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Third Party Licenses Tile
          Card(
            child: ListTile(
              leading: const Icon(Icons.source_outlined),
              title: const Text('Lisensi Perangkat Lunak Pihak Ketiga'),
              subtitle:
                  const Text('Open-source licenses (MIT, Apache 2.0, BSD)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: AppConstants.appName,
                  applicationVersion: AppConstants.appVersion,
                  applicationLegalese: 'Copyright © 2026. All rights reserved.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
