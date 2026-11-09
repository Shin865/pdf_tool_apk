import 'dart:io';

import 'package:document_reviewer/core/engine/pdf_page_engine.dart';
import 'package:document_reviewer/data/saf/saf_file_service.dart';
import 'package:document_reviewer/features/pdf_tools/merge/pdf_merge_dialog.dart';
import 'package:document_reviewer/features/pdf_tools/split/pdf_split_dialog.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Screen for managing PDF pages: reorder, rotate, delete, extract, and export.
class PdfPageManagerScreen extends StatefulWidget {
  const PdfPageManagerScreen({
    required this.filePath,
    required this.initialPageCount,
    required this.pageEngine,
    this.safService,
    super.key,
  });

  final String filePath;
  final int initialPageCount;
  final PdfPageEngine pageEngine;
  final SafFileService? safService;

  @override
  State<PdfPageManagerScreen> createState() => _PdfPageManagerScreenState();
}

class _PdfPageManagerScreenState extends State<PdfPageManagerScreen> {
  late List<int> _pageOrder; // 0-based page indices
  final Map<int, int> _pageRotations = {}; // original page index -> degrees
  final Set<int> _selectedPages = {}; // selected 0-based indices
  bool _isSaving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _pageOrder = List.generate(widget.initialPageCount, (i) => i);
  }

  void _rotateSelectedPages() {
    setState(() {
      final targets = _selectedPages.isEmpty ? _pageOrder : _selectedPages;
      for (final p in targets) {
        _pageRotations[p] = ((_pageRotations[p] ?? 0) + 90) % 360;
      }
    });
  }

  void _rotateSinglePage(int pageIndex) {
    setState(() {
      _pageRotations[pageIndex] = ((_pageRotations[pageIndex] ?? 0) + 90) % 360;
    });
  }

  Future<void> _deleteSelectedPages() async {
    if (_selectedPages.isEmpty) return;
    if (_selectedPages.length >= _pageOrder.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak dapat menghapus semua halaman. Sisakan minimal 1 halaman.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Halaman?'),
            content: Text(
              'Apakah Anda yakin ingin menghapus ${_selectedPages.length} halaman yang dipilih?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      setState(() {
        _pageOrder.removeWhere(_selectedPages.contains);
        _selectedPages.clear();
      });
    }
  }

  Future<void> _exportSelectedPageAsImage(int pageIndex) async {
    final tempDir = await getTemporaryDirectory();
    final outPath =
        '${tempDir.path}/page_${pageIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.png';

    final success = await widget.pageEngine.exportPageToImage(
      filePath: widget.filePath,
      pageIndex: pageIndex,
      outputPath: outPath,
    );

    if (success && File(outPath).existsSync() && mounted) {
      final saf = widget.safService ?? SafFileService();
      await saf.shareFile(
        uri: Uri.file(outPath).toString(),
        mimeType: 'image/png',
        displayName: 'Halaman ${pageIndex + 1}',
      );
    }
  }

  Future<void> _applyChanges() async {
    setState(() {
      _isSaving = true;
      _statusMessage = 'Menerapkan perubahan halaman...';
    });

    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final outDir = Directory('${appSupportDir.path}/working');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }

      var currentFile = widget.filePath;

      // 1. If any pages were deleted or reordered
      final isOriginalOrder = _pageOrder.length == widget.initialPageCount &&
          _pageOrder.asMap().entries.every((e) => e.key == e.value);

      if (!isOriginalOrder) {
        final reorderedPath =
            '${outDir.path}/reordered_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final ok = await widget.pageEngine.reorderPages(
          filePath: currentFile,
          newOrder: _pageOrder,
          outputPath: reorderedPath,
        );
        if (ok && File(reorderedPath).existsSync()) {
          currentFile = reorderedPath;
        }
      }

      // 2. If any pages were rotated
      for (var i = 0; i < _pageOrder.length; i++) {
        final origIndex = _pageOrder[i];
        final rot = _pageRotations[origIndex] ?? 0;
        if (rot > 0) {
          final rotatedPath =
              '${outDir.path}/rot_${i}_${DateTime.now().millisecondsSinceEpoch}.pdf';
          final ok = await widget.pageEngine.rotatePage(
            filePath: currentFile,
            pageIndex: i, // index in the new document
            degrees: rot,
            outputPath: rotatedPath,
          );
          if (ok && File(rotatedPath).existsSync()) {
            currentFile = rotatedPath;
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop(currentFile);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _statusMessage = 'Gagal menyimpan perubahan: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Halaman / Pages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.rotate_right),
            tooltip: 'Putar 90° (Rotate)',
            onPressed: _rotateSelectedPages,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus yang Dipilih (Delete)',
            onPressed: _selectedPages.isNotEmpty ? _deleteSelectedPages : null,
          ),
          PopupMenuButton<String>(
            tooltip: 'Alat Tambahan / Extra Tools',
            onSelected: (val) async {
              final nav = Navigator.of(context);
              if (val == 'merge') {
                final merged = await PdfMergeDialog.show(
                  context,
                  initialPdfPath: widget.filePath,
                  pageEngine: widget.pageEngine,
                  safService: widget.safService,
                );
                if (merged != null && mounted) {
                  nav.pop(merged);
                }
              } else if (val == 'split') {
                final split = await PdfSplitDialog.show(
                  context,
                  pdfPath: widget.filePath,
                  totalPages: _pageOrder.length,
                  pageEngine: widget.pageEngine,
                );
                if (split != null && mounted) {
                  nav.pop(split);
                }
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'merge',
                child: Row(
                  children: [
                    Icon(Icons.call_merge, size: 20),
                    SizedBox(width: 8),
                    Text('Gabung PDF / Merge PDFs'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'split',
                child: Row(
                  children: [
                    Icon(Icons.call_split, size: 20),
                    SizedBox(width: 8),
                    Text('Pisah PDF / Split PDF'),
                  ],
                ),
              ),
            ],
          ),
          FilledButton.icon(
            onPressed: _isSaving ? null : _applyChanges,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Terapkan'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isSaving
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage ?? 'Menyimpan...'),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total: ${_pageOrder.length} halaman '
                          '(${_selectedPages.length} dipilih)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Seret untuk urutkan',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _pageOrder.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) newIndex -= 1;
                        final item = _pageOrder.removeAt(oldIndex);
                        _pageOrder.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final origIndex = _pageOrder[index];
                      final isSelected = _selectedPages.contains(origIndex);
                      final rotation = _pageRotations[origIndex] ?? 0;

                      return Card(
                        key: ValueKey('page_$origIndex'),
                        elevation: isSelected ? 4 : 1,
                        color: isSelected
                            ? theme.colorScheme.primaryContainer.withAlpha(80)
                            : null,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val ?? false) {
                                  _selectedPages.add(origIndex);
                                } else {
                                  _selectedPages.remove(origIndex);
                                }
                              });
                            },
                          ),
                          title: Row(
                            children: [
                              Text(
                                'Halaman ${index + 1} (Asli: ${origIndex + 1})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (rotation > 0) ...[
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text('$rotation°'),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.rotate_right, size: 20),
                                tooltip: 'Putar 90°',
                                onPressed: () => _rotateSinglePage(origIndex),
                              ),
                              IconButton(
                                icon: const Icon(Icons.image, size: 20),
                                tooltip: 'Ekspor sebagai Gambar',
                                onPressed: () =>
                                    _exportSelectedPageAsImage(origIndex),
                              ),
                              const Icon(Icons.drag_handle, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
