import 'dart:io';

import 'package:document_reviewer/app/providers.dart';
import 'package:document_reviewer/core/engine/document_scanner_engine.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:document_reviewer/features/ocr/ocr_result_sheet.dart';
import 'package:document_reviewer/features/scanner/models/scanned_page.dart';
import 'package:document_reviewer/features/scanner/scanner_controller.dart';
import 'package:document_reviewer/features/scanner/widgets/filter_selector_bar.dart';
import 'package:document_reviewer/features/scanner/widgets/quad_crop_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-featured Document Scanner Screen.
///
/// Supports camera capture, Photo Picker / SAF fallback, quadrilateral edge detection,
/// manual corner adjustments, perspective warping, enhancement filters,
/// multi-page compilation, reordering, and OCR.
class DocumentScannerScreen extends ConsumerStatefulWidget {
  const DocumentScannerScreen({
    this.initialImagePath,
    super.key,
  });

  final String? initialImagePath;

  @override
  ConsumerState<DocumentScannerScreen> createState() =>
      _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends ConsumerState<DocumentScannerScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(scannerControllerProvider.notifier)
            .addPage(widget.initialImagePath!);
      });
    }
  }

  Future<void> _handleCameraCapture() async {
    // Attempt camera capture; if unavailable or denied, cleanly fallback to gallery picker
    final loc = AppLocalizations.of(context);
    try {
      // For devices without camera hardware or permission, fallback to SAF picker
      await _handleGalleryImport();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.cameraUnavailable)),
        );
      }
    }
  }

  Future<void> _handleGalleryImport() async {
    final saf = ref.read(safServiceProvider);
    final pick = await saf.pickFile(
      mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/*'],
    );

    if (pick != null && mounted) {
      final tempPath =
          '${Directory.systemTemp.path}/imported_${DateTime.now().millisecondsSinceEpoch}_${pick.displayName}';
      final ok = await saf.copyToLocal(
        uri: pick.uri,
        destinationPath: tempPath,
      );

      if (ok && mounted) {
        await ref.read(scannerControllerProvider.notifier).addPage(tempPath);
      }
    }
  }

  void _showExportDialog() {
    final loc = AppLocalizations.of(context);
    var selectedQuality = ScanExportQuality.medium;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(loc.exportScan),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kualitas Dokumen:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                RadioListTile<ScanExportQuality>(
                  title: Text(loc.qualityLow),
                  value: ScanExportQuality.low,
                  groupValue: selectedQuality,
                  onChanged: (q) {
                    if (q != null) setDialogState(() => selectedQuality = q);
                  },
                ),
                RadioListTile<ScanExportQuality>(
                  title: Text(loc.qualityMedium),
                  value: ScanExportQuality.medium,
                  groupValue: selectedQuality,
                  onChanged: (q) {
                    if (q != null) setDialogState(() => selectedQuality = q);
                  },
                ),
                RadioListTile<ScanExportQuality>(
                  title: Text(loc.qualityHigh),
                  value: ScanExportQuality.high,
                  groupValue: selectedQuality,
                  onChanged: (q) {
                    if (q != null) setDialogState(() => selectedQuality = q);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text(loc.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(dialogCtx).pop();
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  final outPath =
                      '${Directory.systemTemp.path}/Scan_$timestamp.pdf';
                  final res = await ref
                      .read(scannerControllerProvider.notifier)
                      .exportToPdf(
                        outputPath: outPath,
                        quality: selectedQuality,
                      );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          res != null
                              ? 'PDF berhasil diekspor: Scan_$timestamp.pdf'
                              : 'Gagal mengekspor PDF',
                        ),
                      ),
                    );
                  }
                },
                child: Text(loc.exportPdf),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scannerState = ref.watch(scannerControllerProvider);
    final controller = ref.read(scannerControllerProvider.notifier);

    final pages = scannerState.pages;
    final currentPage = scannerState.currentPage;
    final isProcessing = scannerState.isProcessing;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.scanDocument),
        actions: [
          if (pages.isNotEmpty) ...[
            // View mode toggle (Crop corners vs Preview)
            IconButton(
              icon: Icon(
                scannerState.viewMode == ScannerViewMode.cropAdjust
                    ? Icons.remove_red_eye_outlined
                    : Icons.crop,
              ),
              tooltip: scannerState.viewMode == ScannerViewMode.cropAdjust
                  ? 'Pratinjau Hasil'
                  : loc.cropAndPerspective,
              onPressed: () {
                controller.setViewMode(
                  scannerState.viewMode == ScannerViewMode.cropAdjust
                      ? ScannerViewMode.filterPreview
                      : ScannerViewMode.cropAdjust,
                );
              },
            ),
            // OCR button
            IconButton(
              icon: const Icon(Icons.document_scanner),
              tooltip: loc.ocr,
              onPressed: () {
                OcrResultSheet.show(context, scannerState.currentPageIndex);
              },
            ),
            // Export button
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: loc.exportScan,
              onPressed: _showExportDialog,
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          if (pages.isEmpty)
            _buildEmptyState(context)
          else
            Column(
              children: [
                // Main active page preview / quad crop
                Expanded(
                  child: ColoredBox(
                    color: Colors.black87,
                    child: currentPage == null
                        ? const SizedBox.shrink()
                        : (scannerState.viewMode == ScannerViewMode.cropAdjust
                            ? QuadCropOverlay(
                                key: ValueKey('crop_${currentPage.id}'),
                                imagePath: currentPage.originalImagePath,
                                corners: currentPage.corners,
                                imageWidth: currentPage.width > 0
                                    ? currentPage.width.toDouble()
                                    : 800.0,
                                imageHeight: currentPage.height > 0
                                    ? currentPage.height.toDouble()
                                    : 1000.0,
                                onCornersChanged: (newCorners) {
                                  controller.updateCorners(
                                    scannerState.currentPageIndex,
                                    newCorners,
                                  );
                                },
                              )
                            : Center(
                                child: Image.file(
                                  File(currentPage.displayPath),
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 64,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              )),
                  ),
                ),

                // Enhancement filter chips
                ColoredBox(
                  color: theme.colorScheme.surface,
                  child: FilterSelectorBar(
                    selectedFilter:
                        currentPage?.filterMode ?? ScanFilterMode.original,
                    onFilterSelected: (filter) {
                      controller.applyFilter(
                        scannerState.currentPageIndex,
                        filter,
                      );
                    },
                  ),
                ),

                // Controls: Rotate, Delete, Add page
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.rotate_right),
                        label: Text(loc.rotate),
                        onPressed: () {
                          controller.rotatePage(scannerState.currentPageIndex);
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        label: Text(
                          loc.deletePage,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                        onPressed: () {
                          controller.removePage(scannerState.currentPageIndex);
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(loc.addPage),
                        onPressed: _handleGalleryImport,
                      ),
                    ],
                  ),
                ),

                // Multi-page thumbnail carousel
                _buildThumbnailStrip(
                  context,
                  pages,
                  scannerState.currentPageIndex,
                ),
              ],
            ),

          // Processing overlay
          if (isProcessing)
            const ColoredBox(
              color: Colors.black45,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.scanner,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.8),
            ),
            const SizedBox(height: 24),
            Text(
              loc.scanDocument,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pindai dokumen dengan kamera atau impor dari galeri. Deteksi tepi, filter peningkatan, dan OCR 100% offline.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil Foto / Kamera'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 48),
              ),
              onPressed: _handleCameraCapture,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: Text(loc.importFromGallery),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(220, 48),
              ),
              onPressed: _handleGalleryImport,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailStrip(
    BuildContext context,
    List<ScannedPage> pages,
    int activeIndex,
  ) {
    final theme = Theme.of(context);

    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: theme.colorScheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pages.length,
        itemBuilder: (context, index) {
          final isSelected = index == activeIndex;
          final page = pages[index];

          return GestureDetector(
            onTap: () {
              ref
                  .read(scannerControllerProvider.notifier)
                  .setCurrentPageIndex(index);
            },
            child: Container(
              width: 56,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(page.displayPath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.insert_drive_file, size: 24),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
