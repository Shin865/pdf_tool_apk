import 'dart:io';

import 'package:document_reviewer/core/engine/pdf_page_engine.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Dialog to extract or split a page range from a PDF.
class PdfSplitDialog extends StatefulWidget {
  const PdfSplitDialog({
    required this.pdfPath,
    required this.totalPages,
    required this.pageEngine,
    super.key,
  });

  final String pdfPath;
  final int totalPages;
  final PdfPageEngine pageEngine;

  static Future<String?> show(
    BuildContext context, {
    required String pdfPath,
    required int totalPages,
    required PdfPageEngine pageEngine,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PdfSplitDialog(
        pdfPath: pdfPath,
        totalPages: totalPages,
        pageEngine: pageEngine,
      ),
    );
  }

  @override
  State<PdfSplitDialog> createState() => _PdfSplitDialogState();
}

class _PdfSplitDialogState extends State<PdfSplitDialog> {
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController(text: '1');
    _endController = TextEditingController(text: '${widget.totalPages}');
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _split() async {
    final start = int.tryParse(_startController.text.trim());
    final end = int.tryParse(_endController.text.trim());

    if (start == null || end == null) {
      setState(() => _errorMessage = 'Masukkan nomor halaman yang valid.');
      return;
    }

    if (start < 1 || start > widget.totalPages) {
      setState(
        () => _errorMessage =
            'Halaman mulai harus antara 1 dan ${widget.totalPages}.',
      );
      return;
    }

    if (end < start || end > widget.totalPages) {
      setState(
        () => _errorMessage =
            'Halaman akhir harus antara $start dan ${widget.totalPages}.',
      );
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
          '${outDir.path}/split_${start}_to_${end}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // start - 1 and end - 1 for 0-indexed engine
      final success = await widget.pageEngine.splitPdf(
        filePath: widget.pdfPath,
        startPage: start - 1,
        endPage: end - 1,
        outputPath: outPath,
      );

      if (success && File(outPath).existsSync()) {
        if (mounted) {
          Navigator.of(context).pop(outPath);
        }
      } else {
        setState(() {
          _errorMessage = 'Gagal memisahkan PDF.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Kesalahan saat memisahkan PDF: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.call_split),
          SizedBox(width: 8),
          Expanded(child: Text('Pisah PDF / Split PDF')),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tentukan rentang halaman yang akan diekstrak (Total: ${widget.totalPages} halaman):',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Dari Halaman',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _endController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sampai Halaman',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
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
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _isProcessing ? null : _split,
          icon: const Icon(Icons.check),
          label: const Text('Ekstrak / Pisah'),
        ),
      ],
    );
  }
}
