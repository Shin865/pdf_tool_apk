import 'dart:io';

import 'package:document_reviewer/core/engine/pdf_page_engine.dart';
import 'package:document_reviewer/data/saf/saf_file_service.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Dialog to select and merge multiple PDF documents into a single PDF.
class PdfMergeDialog extends StatefulWidget {
  const PdfMergeDialog({
    required this.initialPdfPath,
    required this.pageEngine,
    this.safService,
    super.key,
  });

  final String initialPdfPath;
  final PdfPageEngine pageEngine;
  final SafFileService? safService;

  static Future<String?> show(
    BuildContext context, {
    required String initialPdfPath,
    required PdfPageEngine pageEngine,
    SafFileService? safService,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PdfMergeDialog(
        initialPdfPath: initialPdfPath,
        pageEngine: pageEngine,
        safService: safService,
      ),
    );
  }

  @override
  State<PdfMergeDialog> createState() => _PdfMergeDialogState();
}

class _PdfMergeDialogState extends State<PdfMergeDialog> {
  late final List<String> _pdfPaths;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pdfPaths = [widget.initialPdfPath];
  }

  Future<void> _pickAdditionalPdf() async {
    final saf = widget.safService ?? SafFileService();
    final picked = await saf.pickFile(mimeTypes: ['application/pdf']);
    if (picked == null) return;

    // Copy to temp directory
    final tempDir = await getTemporaryDirectory();
    final localCopy = File(
      '${tempDir.path}/merge_src_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final copied = await saf.copyToLocal(
      uri: picked.uri,
      destinationPath: localCopy.path,
    );

    if (copied && localCopy.existsSync()) {
      setState(() {
        _pdfPaths.add(localCopy.path);
        _errorMessage = null;
      });
    }
  }

  Future<void> _merge() async {
    if (_pdfPaths.length < 2) {
      setState(() {
        _errorMessage = 'Pilih minimal 2 dokumen PDF untuk digabungkan.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final outDir = Directory('${appSupportDir.path}/export');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }

      final outPath =
          '${outDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final success = await widget.pageEngine.mergePdfs(
        filePaths: _pdfPaths,
        outputPath: outPath,
      );

      if (success && File(outPath).existsSync()) {
        if (mounted) {
          Navigator.of(context).pop(outPath);
        }
      } else {
        setState(() {
          _errorMessage = 'Gagal menggabungkan PDF. Periksa file sumber.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat penggabungan: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.call_merge),
          SizedBox(width: 8),
          Expanded(child: Text('Gabung PDF / Merge PDFs')),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Urutan penggabungan file PDF (seret untuk mengubah urutan):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: _pdfPaths.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    var target = newIndex;
                    if (oldIndex < target) target -= 1;
                    final item = _pdfPaths.removeAt(oldIndex);
                    _pdfPaths.insert(target, item);
                  });
                },
                itemBuilder: (context, index) {
                  final path = _pdfPaths[index];
                  final name = File(path).uri.pathSegments.last;
                  return ListTile(
                    key: ValueKey(path),
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: _pdfPaths.length > 1
                        ? IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                _pdfPaths.removeAt(index);
                              });
                            },
                          )
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isProcessing ? null : _pickAdditionalPdf,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah PDF Lain...'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            if (_isProcessing) ...[
              const SizedBox(height: 12),
              const Center(child: LinearProgressIndicator()),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _isProcessing || _pdfPaths.length < 2 ? null : _merge,
          icon: const Icon(Icons.check),
          label: const Text('Gabungkan'),
        ),
      ],
    );
  }
}
