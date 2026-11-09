import 'dart:io';

import 'package:document_reviewer/app/providers.dart';
import 'package:document_reviewer/features/backup_restore/models/backup_models.dart';
import 'package:document_reviewer/features/backup_restore/services/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for backup service.
final backupServiceProvider = Provider<BackupService>((ref) {
  return const BackupService();
});

/// Screen for exporting and restoring application backups.
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _includeDocuments = false;
  bool _encryptBackup = false;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isProcessing = false;
  BackupPreview? _loadedPreview;
  String? _selectedBackupPath;
  bool _overwriteExisting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleExportBackup() async {
    if (_encryptBackup) {
      if (_passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kata sandi tidak boleh kosong')),
        );
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konfirmasi kata sandi tidak cocok')),
        );
        return;
      }
    }

    setState(() => _isProcessing = true);
    try {
      final db = ref.read(databaseProvider);
      final backupService = ref.read(backupServiceProvider);
      final saf = ref.read(safServiceProvider);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath =
          '${Directory.systemTemp.path}/DocumentReviewer_Backup_$timestamp.drbackup';

      await backupService.createBackup(
        database: db,
        outputPath: outPath,
        includeDocuments: _includeDocuments,
        password: _encryptBackup ? _passwordController.text : null,
      );

      // Offer to share via SAF/Intent
      await saf.shareFile(
        uri: outPath,
        mimeType: 'application/octet-stream',
        displayName: 'DocumentReviewer_Backup_$timestamp.drbackup',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cadangan berhasil dibuat: $outPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat cadangan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handlePickBackupFile() async {
    final saf = ref.read(safServiceProvider);
    final pick = await saf.pickFile(mimeTypes: ['*/*']);
    if (pick != null && mounted) {
      final tempPath =
          '${Directory.systemTemp.path}/import_${DateTime.now().millisecondsSinceEpoch}_${pick.displayName}';
      final ok =
          await saf.copyToLocal(uri: pick.uri, destinationPath: tempPath);
      if (ok && mounted) {
        await _inspectBackupFile(tempPath);
      }
    }
  }

  Future<void> _inspectBackupFile(String path, {String? password}) async {
    setState(() => _isProcessing = true);
    final backupService = ref.read(backupServiceProvider);

    try {
      final preview = await backupService.inspectBackup(
        backupPath: path,
        password: password,
      );

      setState(() {
        _loadedPreview = preview;
        _selectedBackupPath = path;
      });
    } on UnsupportedBackupVersionException catch (e) {
      if (mounted) {
        _showErrorDialog('Versi Tidak Didukung', e.toString());
      }
    } on InvalidBackupPasswordException {
      if (mounted) {
        _promptPasswordDialog(path);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Gagal Membaca Berkas', e.toString());
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _promptPasswordDialog(String path) {
    final pwdController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cadangan Terenkripsi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Masukkan kata sandi untuk mendekripsi berkas cadangan.'),
            const SizedBox(height: 12),
            TextField(
              controller: pwdController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Kata Sandi',
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
              Navigator.of(ctx).pop();
              _inspectBackupFile(path, password: pwdController.text);
            },
            child: const Text('Buka'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRestore() async {
    if (_selectedBackupPath == null || _loadedPreview == null) return;

    setState(() => _isProcessing = true);
    try {
      final db = ref.read(databaseProvider);
      final backupService = ref.read(backupServiceProvider);

      final res = await backupService.restoreBackup(
        database: db,
        backupPath: _selectedBackupPath!,
        password: _loadedPreview!.isEncrypted ? _passwordController.text : null,
        overwriteExisting: _overwriteExisting,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message ?? 'Pemulihan selesai!')),
        );
        setState(() {
          _loadedPreview = null;
          _selectedBackupPath = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Gagal Memulihkan', e.toString());
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadangan & Pemulihan'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Export Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.backup_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Buat Cadangan (Export)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Simpan daftar riwayat dokumen, favorit, dan pengaturan ke satu berkas aman.',
                      ),
                      const Divider(height: 24),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sertakan salinan berkas dokumen'),
                        subtitle: const Text(
                            'Ukuran berkas cadangan akan lebih besar'),
                        value: _includeDocuments,
                        onChanged: (v) =>
                            setState(() => _includeDocuments = v ?? false),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enkripsi dengan kata sandi'),
                        subtitle:
                            const Text('Menggunakan kunci AES-256 PBKDF2'),
                        value: _encryptBackup,
                        onChanged: (v) =>
                            setState(() => _encryptBackup = v ?? false),
                      ),
                      if (_encryptBackup) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Kata Sandi Cadangan',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Ulangi Kata Sandi',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Ekspor Berkas Cadangan'),
                        onPressed: _isProcessing ? null : _handleExportBackup,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Restore Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.restore,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pulihkan Cadangan (Restore)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pilih berkas cadangan (.drbackup) untuk memulihkan metadata dokumen Anda.',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_open),
                        label: const Text('Pilih Berkas Cadangan'),
                        onPressed: _isProcessing ? null : _handlePickBackupFile,
                      ),
                      if (_loadedPreview != null) ...[
                        const Divider(height: 24),
                        Text(
                          'Pratinjau Cadangan:',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Jumlah Dokumen: ${_loadedPreview!.documentCount}'),
                        Text(
                          'Tanggal Dibuat: ${_loadedPreview!.manifest.createdAt.toLocal().toString().split(".")[0]}',
                        ),
                        Text(
                          'Terenkripsi: ${_loadedPreview!.isEncrypted ? "Ya" : "Tidak"}',
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Ganti dokumen yang sudah ada'),
                          value: _overwriteExisting,
                          onChanged: (v) =>
                              setState(() => _overwriteExisting = v ?? false),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Konfirmasi & Pulihkan Sekarang'),
                          onPressed: _isProcessing ? null : _handleRestore,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isProcessing)
            const ColoredBox(
              color: Colors.black45,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
