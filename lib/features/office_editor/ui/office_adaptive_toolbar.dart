import 'package:document_reviewer/features/office_editor/office_editor_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Adaptive toolbar providing contextual bottom bar for mobile
/// and ribbon bar for tablets, plus hardware keyboard shortcuts.
class OfficeAdaptiveToolbar extends StatelessWidget {
  const OfficeAdaptiveToolbar({
    required this.controller,
    required this.onSaveAs,
    required this.onOverwrite,
    this.onAddHeading,
    this.onAddParagraph,
    this.onAddTable,
    this.onAddPageBreak,
    this.onAddSheet,
    this.onAddRow,
    super.key,
  });

  final OfficeEditorController controller;
  final VoidCallback onSaveAs;
  final VoidCallback onOverwrite;
  final VoidCallback? onAddHeading;
  final VoidCallback? onAddParagraph;
  final VoidCallback? onAddTable;
  final VoidCallback? onAddPageBreak;
  final VoidCallback? onAddSheet;
  final VoidCallback? onAddRow;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isTablet = screenWidth >= 600;

        return isTablet
            ? _buildTabletRibbon(context)
            : _buildMobileBottomBar(context);
      },
    );
  }

  /// Tablet Ribbon Bar at top of editor
  Widget _buildTabletRibbon(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Undo / Redo Group
            IconButton(
              icon: const Icon(Icons.undo, size: 20),
              tooltip: 'Undo (Ctrl+Z)',
              onPressed: controller.canUndo ? controller.undo : null,
            ),
            IconButton(
              icon: const Icon(Icons.redo, size: 20),
              tooltip: 'Redo (Ctrl+Y)',
              onPressed: controller.canRedo ? controller.redo : null,
            ),
            const VerticalDivider(width: 20, thickness: 1),

            // Contextual Insert Actions
            if (onAddParagraph != null)
              ActionChip(
                avatar: const Icon(Icons.text_fields, size: 16),
                label: const Text('Paragraf'),
                onPressed: onAddParagraph,
              ),
            if (onAddHeading != null) ...[
              const SizedBox(width: 6),
              ActionChip(
                avatar: const Icon(Icons.title, size: 16),
                label: const Text('Heading'),
                onPressed: onAddHeading,
              ),
            ],
            if (onAddTable != null) ...[
              const SizedBox(width: 6),
              ActionChip(
                avatar: const Icon(Icons.table_chart, size: 16),
                label: const Text('Tabel'),
                onPressed: onAddTable,
              ),
            ],
            if (onAddPageBreak != null) ...[
              const SizedBox(width: 6),
              ActionChip(
                avatar: const Icon(Icons.insert_page_break, size: 16),
                label: const Text('Page Break'),
                onPressed: onAddPageBreak,
              ),
            ],
            if (onAddSheet != null) ...[
              const SizedBox(width: 6),
              ActionChip(
                avatar: const Icon(Icons.post_add, size: 16),
                label: const Text('+ Sheet'),
                onPressed: onAddSheet,
              ),
            ],
            if (onAddRow != null) ...[
              const SizedBox(width: 6),
              ActionChip(
                avatar: const Icon(Icons.playlist_add, size: 16),
                label: const Text('+ Baris'),
                onPressed: onAddRow,
              ),
            ],

            const SizedBox(width: 16),

            // Dirty state chip
            if (controller.isDirty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Belum Disimpan / Unsaved',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            const SizedBox(width: 8),

            // Save Actions
            FilledButton.tonalIcon(
              icon: const Icon(Icons.save_as, size: 18),
              label: const Text('Simpan Baru / Save As'),
              onPressed: onSaveAs,
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Timpa / Overwrite'),
              onPressed: onOverwrite,
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile Bottom Toolbar
  Widget _buildMobileBottomBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: controller.canUndo ? controller.undo : null,
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: 'Redo',
              onPressed: controller.canRedo ? controller.redo : null,
            ),

            if (controller.isDirty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.circle,
                  size: 10,
                  color: theme.colorScheme.error,
                ),
              ),

            const Spacer(),

            // Save As Button (Default)
            FilledButton.tonalIcon(
              icon: const Icon(Icons.save_as, size: 18),
              label: const Text('Simpan'),
              onPressed: onSaveAs,
            ),
            const SizedBox(width: 4),

            // More Menu (Overwrite, etc.)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (val) {
                if (val == 'overwrite') {
                  onOverwrite();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'overwrite',
                  child: Row(
                    children: [
                      Icon(Icons.save, size: 18),
                      SizedBox(width: 8),
                      Text('Timpa File Asli / Overwrite'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper wrapping a child with standard office editor keyboard shortcuts.
class OfficeKeyboardShortcuts extends StatelessWidget {
  const OfficeKeyboardShortcuts({
    required this.controller,
    required this.onSave,
    required this.child,
    super.key,
  });

  final OfficeEditorController controller;
  final VoidCallback onSave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          if (controller.canUndo) controller.undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
          if (controller.canRedo) controller.redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ,
            control: true, shift: true): () {
          if (controller.canRedo) controller.redo();
        },
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): onSave,
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
