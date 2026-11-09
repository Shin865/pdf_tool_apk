import 'package:document_reviewer/features/pdf_tools/annotations/pdf_annotation_controller.dart';
import 'package:document_reviewer/features/pdf_tools/annotations/pdf_tool_mode.dart';
import 'package:document_reviewer/features/pdf_tools/signature/signature_dialog.dart';
import 'package:flutter/material.dart';

/// Bottom action bar providing PDF tool selection, undo/redo, and export actions.
class PdfToolsBottomBar extends StatelessWidget {
  const PdfToolsBottomBar({
    required this.currentMode,
    required this.onModeChanged,
    required this.controller,
    required this.onSaveAs,
    required this.onOverwrite,
    required this.onOpenPageManager,
    required this.onExportImage,
    required this.onShare,
    required this.onSignatureCreated,
    super.key,
  });

  final PdfToolMode currentMode;
  final ValueChanged<PdfToolMode> onModeChanged;
  final PdfAnnotationController controller;
  final VoidCallback onSaveAs;
  final VoidCallback onOverwrite;
  final VoidCallback onOpenPageManager;
  final VoidCallback onExportImage;
  final VoidCallback onShare;
  final ValueChanged<String> onSignatureCreated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.pan_tool_outlined),
                      tooltip: 'Lihat / Pan (View Mode)',
                      isSelected: currentMode == PdfToolMode.view,
                      onPressed: () => onModeChanged(PdfToolMode.view),
                    ),
                    IconButton(
                      icon: const Icon(Icons.border_color),
                      tooltip: 'Sorot / Highlight',
                      isSelected: currentMode == PdfToolMode.highlight,
                      color: currentMode == PdfToolMode.highlight
                          ? Colors.amber.shade800
                          : null,
                      onPressed: () => onModeChanged(PdfToolMode.highlight),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_underlined),
                      tooltip: 'Garis Bawah / Underline',
                      isSelected: currentMode == PdfToolMode.underline,
                      color: currentMode == PdfToolMode.underline
                          ? Colors.blue.shade800
                          : null,
                      onPressed: () => onModeChanged(PdfToolMode.underline),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Pena Bebas / Pen Drawing',
                      isSelected: currentMode == PdfToolMode.pen,
                      color: currentMode == PdfToolMode.pen
                          ? Colors.deepPurple
                          : null,
                      onPressed: () => onModeChanged(PdfToolMode.pen),
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_fields),
                      tooltip: 'Catatan Teks / Text Note',
                      isSelected: currentMode == PdfToolMode.text,
                      onPressed: () => onModeChanged(PdfToolMode.text),
                    ),
                    IconButton(
                      icon: const Icon(Icons.draw),
                      tooltip: 'Tanda Tangan / Signature',
                      isSelected: currentMode == PdfToolMode.signature,
                      onPressed: () async {
                        final sigPath = await SignatureDialog.show(context);
                        if (sigPath != null) {
                          onSignatureCreated(sigPath);
                          onModeChanged(PdfToolMode.signature);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    const VerticalDivider(width: 1, thickness: 1),
                    const SizedBox(width: 8),
                    // Undo
                    ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) => IconButton(
                        icon: const Icon(Icons.undo),
                        tooltip: 'Urungkan / Undo',
                        onPressed: controller.canUndo ? controller.undo : null,
                      ),
                    ),
                    // Redo
                    ListenableBuilder(
                      listenable: controller,
                      builder: (context, _) => IconButton(
                        icon: const Icon(Icons.redo),
                        tooltip: 'Ulangi / Redo',
                        onPressed: controller.canRedo ? controller.redo : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const VerticalDivider(width: 1, thickness: 1),
                    const SizedBox(width: 8),
                    // Page Organizer
                    IconButton(
                      icon: const Icon(Icons.auto_stories),
                      tooltip: 'Kelola Halaman / Page Manager',
                      onPressed: onOpenPageManager,
                    ),
                    // Export & Save menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.save_alt),
                      tooltip: 'Simpan / Ekspor',
                      onSelected: (value) {
                        switch (value) {
                          case 'save_as':
                            onSaveAs();
                          case 'overwrite':
                            onOverwrite();
                          case 'export_img':
                            onExportImage();
                          case 'share':
                            onShare();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'save_as',
                          child: Row(
                            children: [
                              Icon(Icons.save_as, size: 20),
                              SizedBox(width: 8),
                              Text('Simpan Sebagai File Baru (Default)'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'overwrite',
                          child: Row(
                            children: [
                              Icon(Icons.save, size: 20),
                              SizedBox(width: 8),
                              Text('Timpa File Asli (Dengan Konfirmasi)'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export_img',
                          child: Row(
                            children: [
                              Icon(Icons.image, size: 20),
                              SizedBox(width: 8),
                              Text('Ekspor Halaman ke Gambar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 20),
                              SizedBox(width: 8),
                              Text('Bagikan File / Share'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
