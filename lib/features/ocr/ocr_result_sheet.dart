import 'package:document_reviewer/core/engine/ocr_engine.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:document_reviewer/features/scanner/scanner_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modal bottom sheet or dialog displaying OCR recognition results,
/// language selection, progress/cancellation, and export to Searchable PDF.
class OcrResultSheet extends ConsumerStatefulWidget {
  const OcrResultSheet({
    required this.pageIndex,
    super.key,
  });

  final int pageIndex;

  static Future<void> show(BuildContext context, int pageIndex) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => OcrResultSheet(pageIndex: pageIndex),
    );
  }

  @override
  ConsumerState<OcrResultSheet> createState() => _OcrResultSheetState();
}

class _OcrResultSheetState extends ConsumerState<OcrResultSheet> {
  OcrLanguage _selectedLanguage = OcrLanguage.indonesianAndEnglish;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startOcr();
    });
  }

  void _startOcr() {
    ref.read(scannerControllerProvider.notifier).runOcr(
          index: widget.pageIndex,
          language: _selectedLanguage,
        );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scannerState = ref.watch(scannerControllerProvider);
    final activeResult = scannerState.activeOcrResult;
    final isRunning = scannerState.ocrProgress != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header handle & title
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.document_scanner_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.ocrResult,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: loc.close,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),

          // Language selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  '${loc.ocrLanguage}: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<OcrLanguage>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: OcrLanguage.indonesianAndEnglish,
                        child: Text(loc.languageBoth),
                      ),
                      DropdownMenuItem(
                        value: OcrLanguage.indonesian,
                        child: Text(loc.languageIndonesian),
                      ),
                      DropdownMenuItem(
                        value: OcrLanguage.english,
                        child: Text(loc.languageEnglish),
                      ),
                    ],
                    onChanged: isRunning
                        ? null
                        : (lang) {
                            if (lang != null) {
                              setState(() {
                                _selectedLanguage = lang;
                              });
                              _startOcr();
                            }
                          },
                  ),
                ),
              ],
            ),
          ),

          // Running progress bar with Cancel button
          if (isRunning) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  LinearProgressIndicator(value: scannerState.ocrProgress),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.processing),
                      TextButton.icon(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: Text(loc.cancel),
                        onPressed: () {
                          ref
                              .read(scannerControllerProvider.notifier)
                              .cancelOcr();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // OCR Result display
          Expanded(
            child: activeResult == null
                ? Center(
                    child: isRunning
                        ? CircularProgressIndicator(
                            value: scannerState.ocrProgress)
                        : Text(loc.processing),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.dividerColor,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Confidence Badge
                          Row(
                            children: [
                              Icon(
                                Icons.verified_outlined,
                                size: 16,
                                color: activeResult.averageConfidence > 80
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Akurasi: ${activeResult.averageConfidence.toStringAsFixed(1)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: activeResult.averageConfidence > 80
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${activeResult.processingTimeMs} ms',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const Divider(),
                          SelectableText(
                            activeResult.fullText.isEmpty
                                ? 'Tidak ada teks terdeteksi.'
                                : activeResult.fullText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          // Action buttons: Copy Text & Searchable PDF
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: Text(loc.copyText),
                  onPressed:
                      activeResult == null || activeResult.fullText.isEmpty
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: activeResult.fullText),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(loc.textCopied),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(loc.createSearchablePdf),
                  onPressed: activeResult == null
                      ? null
                      : () async {
                          final outputPath =
                              '${activeResult.fullText.hashCode}_searchable.pdf';
                          final tempPath =
                              '${Theme.of(context).platform == TargetPlatform.android ? "/data/user/0/com.example.documentreviewer.document_reviewer/cache" : "."}/$outputPath';
                          final res = await ref
                              .read(scannerControllerProvider.notifier)
                              .createSearchablePdf(
                                index: widget.pageIndex,
                                outputPath: tempPath,
                              );
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res != null
                                      ? 'Searchable PDF berhasil disimpan!'
                                      : 'Gagal membuat Searchable PDF',
                                ),
                              ),
                            );
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
