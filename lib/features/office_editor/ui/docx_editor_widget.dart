import 'package:document_reviewer/features/office_editor/models/office_models.dart';
import 'package:document_reviewer/features/office_editor/office_editor_controller.dart';
import 'package:flutter/material.dart';

/// Widget rendering interactive block editor for DOCX documents.
class DocxEditorWidget extends StatefulWidget {
  const DocxEditorWidget({
    required this.controller,
    super.key,
  });

  final OfficeEditorController controller;

  @override
  State<DocxEditorWidget> createState() => _DocxEditorWidgetState();
}

class _DocxEditorWidgetState extends State<DocxEditorWidget> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final blocks = widget.controller.docxBlocks;
        final theme = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Header display/edit
            if (widget.controller.docxHeader.isNotEmpty)
              _buildHeaderFooterChip(
                context,
                title: 'Header',
                text: widget.controller.docxHeader,
                onEdit: () => _showTextEditDialog(
                  context,
                  title: 'Ubah Header / Edit Header',
                  initialValue: widget.controller.docxHeader,
                  onSaved: widget.controller.setDocxHeader,
                ),
              ),

            // Blocks list
            for (var i = 0; i < blocks.length; i++)
              _buildBlock(context, blocks[i], i, theme),

            const SizedBox(height: 16),

            // Quick Add Block Bar
            _buildAddBlockBar(context, theme),

            const SizedBox(height: 16),

            // Footer display/edit
            if (widget.controller.docxFooter.isNotEmpty)
              _buildHeaderFooterChip(
                context,
                title: 'Footer',
                text: widget.controller.docxFooter,
                onEdit: () => _showTextEditDialog(
                  context,
                  title: 'Ubah Footer / Edit Footer',
                  initialValue: widget.controller.docxFooter,
                  onSaved: widget.controller.setDocxFooter,
                ),
              ),
            const SizedBox(height: 80), // Padding for bottom toolbar
          ],
        );
      },
    );
  }

  Widget _buildBlock(
    BuildContext context,
    DocxBlock block,
    int index,
    ThemeData theme,
  ) {
    switch (block.type) {
      case DocxBlockType.heading:
        final style = switch (block.headingLevel) {
          1 => theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          2 => theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          _ => theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
        };
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          child: ListTile(
            dense: true,
            title: Text(
              block.text.isEmpty
                  ? '(Heading ${block.headingLevel} kosong)'
                  : block.text,
              style: style,
            ),
            subtitle: Text('Heading ${block.headingLevel}',
                style: theme.textTheme.labelSmall),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: () => _showTextEditDialog(
              context,
              title: 'Edit Heading ${block.headingLevel}',
              initialValue: block.text,
              onSaved: (val) =>
                  widget.controller.updateDocxBlockText(index, val),
            ),
          ),
        );

      case DocxBlockType.paragraph:
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: ListTile(
            title: Text(
              block.text.isEmpty
                  ? '(Paragraf kosong / Empty paragraph)'
                  : block.text,
              style: theme.textTheme.bodyMedium,
            ),
            trailing: const Icon(Icons.edit_note, size: 20),
            onTap: () => _showTextEditDialog(
              context,
              title: 'Edit Paragraf / Edit Paragraph',
              initialValue: block.text,
              maxLines: 5,
              onSaved: (val) =>
                  widget.controller.updateDocxBlockText(index, val),
            ),
          ),
        );

      case DocxBlockType.table:
        final data = block.tableData ?? [];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tabel / Table', style: theme.textTheme.titleSmall),
                    Text(
                      '${data.length} baris x ${data.firstOrNull?.length ?? 0} kolom',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                const Divider(),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    defaultColumnWidth: const IntrinsicColumnWidth(),
                    border: TableBorder.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                    children: [
                      for (var r = 0; r < data.length; r++)
                        TableRow(
                          children: [
                            for (var c = 0; c < data[r].length; c++)
                              InkWell(
                                onTap: () => _showTextEditDialog(
                                  context,
                                  title: 'Edit Sel ($r, $c)',
                                  initialValue: data[r][c],
                                  onSaved: (val) => widget.controller
                                      .updateDocxTableCell(index, r, c, val),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    data[r][c].isEmpty ? '-' : data[r][c],
                                    style: theme.textTheme.bodySmall,
                                  ),
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
        );

      case DocxBlockType.pageBreak:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '── Pemisah Halaman / Page Break ──',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
              Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
            ],
          ),
        );

      case DocxBlockType.image:
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.image),
            title: Text(block.imagePath ?? 'Gambar / Image'),
            subtitle: const Text('Embedded image'),
          ),
        );
    }
  }

  Widget _buildHeaderFooterChip(
    BuildContext context, {
    required String title,
    required String text,
    required VoidCallback onEdit,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ActionChip(
        avatar: const Icon(Icons.vertical_align_top, size: 16),
        label: Text('$title: $text'),
        onPressed: onEdit,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildAddBlockBar(BuildContext context, ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.text_fields, size: 16),
          label: const Text('+ Paragraf'),
          onPressed: () => _showTextEditDialog(
            context,
            title: 'Tambah Paragraf / Add Paragraph',
            initialValue: '',
            maxLines: 4,
            onSaved: widget.controller.addDocxParagraph,
          ),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.title, size: 16),
          label: const Text('+ Heading'),
          onPressed: () => _showHeadingDialog(context),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.table_chart, size: 16),
          label: const Text('+ Tabel'),
          onPressed: () => _showAddTableDialog(context),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.insert_page_break, size: 16),
          label: const Text('+ Page Break'),
          onPressed: widget.controller.addDocxPageBreak,
        ),
      ],
    );
  }

  void _showTextEditDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    required void Function(String) onSaved,
    int maxLines = 1,
  }) {
    final textController = TextEditingController(text: initialValue);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: textController,
          maxLines: maxLines,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal / Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onSaved(textController.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Simpan / OK'),
          ),
        ],
      ),
    );
  }

  void _showHeadingDialog(BuildContext context) {
    final textController = TextEditingController();
    var level = 1;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Heading / Add Heading'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Judul Heading / Heading Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('H1')),
                  ButtonSegment(value: 2, label: Text('H2')),
                  ButtonSegment(value: 3, label: Text('H3')),
                ],
                selected: {level},
                onSelectionChanged: (set) {
                  setDialogState(() {
                    level = set.first;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal / Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  widget.controller
                      .addDocxHeading(textController.text, level: level);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Tambah / Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTableDialog(BuildContext context) {
    var rows = 2;
    var cols = 2;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Tabel / Add Table'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Baris / Rows:'),
                  DropdownButton<int>(
                    value: rows,
                    items: [2, 3, 4, 5]
                        .map((n) =>
                            DropdownMenuItem(value: n, child: Text('$n')))
                        .toList(),
                    onChanged: (v) => setDialogState(() => rows = v ?? 2),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kolom / Columns:'),
                  DropdownButton<int>(
                    value: cols,
                    items: [2, 3, 4, 5]
                        .map((n) =>
                            DropdownMenuItem(value: n, child: Text('$n')))
                        .toList(),
                    onChanged: (v) => setDialogState(() => cols = v ?? 2),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal / Cancel'),
            ),
            FilledButton(
              onPressed: () {
                widget.controller.addDocxTable(rows, cols);
                Navigator.of(ctx).pop();
              },
              child: const Text('Buat Tabel / Create Table'),
            ),
          ],
        ),
      ),
    );
  }
}
