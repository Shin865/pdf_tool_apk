import 'package:document_reviewer/features/office_editor/models/office_models.dart';
import 'package:document_reviewer/features/office_editor/office_editor_controller.dart';
import 'package:flutter/material.dart';

/// Widget rendering interactive spreadsheet grid and sheet tabs for XLSX documents.
class XlsxEditorWidget extends StatefulWidget {
  const XlsxEditorWidget({
    required this.controller,
    super.key,
  });

  final OfficeEditorController controller;

  @override
  State<XlsxEditorWidget> createState() => _XlsxEditorWidgetState();
}

class _XlsxEditorWidgetState extends State<XlsxEditorWidget> {
  int _selectedRow = 0;
  int _selectedCol = 0;
  final TextEditingController _formulaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateFormulaBar();
  }

  @override
  void dispose() {
    _formulaController.dispose();
    super.dispose();
  }

  void _updateFormulaBar() {
    final rows = widget.controller.activeSheetRows;
    if (_selectedRow < rows.length &&
        _selectedCol < rows[_selectedRow].length) {
      final cell = rows[_selectedRow][_selectedCol];
      _formulaController.text = cell.formula ?? cell.value;
    } else {
      _formulaController.text = '';
    }
  }

  String _colIndexToLetter(int index) {
    var letter = '';
    var idx = index;
    while (idx >= 0) {
      letter = String.fromCharCode(65 + (idx % 26)) + letter;
      idx = (idx ~/ 26) - 1;
    }
    return letter;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final sheetNames = widget.controller.xlsxSheetNames;
        final activeSheetIdx = widget.controller.activeSheetIndex;
        final rows = widget.controller.activeSheetRows;

        final colLetter = _colIndexToLetter(_selectedCol);
        final cellCoord = '$colLetter${_selectedRow + 1}';

        // Calculate max columns across rows
        var maxCols = 5;
        for (final r in rows) {
          if (r.length > maxCols) maxCols = r.length;
        }

        return Column(
          children: [
            // Sheet Tabs Bar
            Container(
              height: 48,
              color: theme.colorScheme.surfaceContainerHighest,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (var i = 0; i < sheetNames.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                      child: ChoiceChip(
                        label: Text(sheetNames[i]),
                        selected: activeSheetIdx == i,
                        onSelected: (_) {
                          widget.controller.switchSheet(i);
                          setState(() {
                            _selectedRow = 0;
                            _selectedCol = 0;
                            _updateFormulaBar();
                          });
                        },
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'Tambah Sheet / Add Sheet',
                    onPressed: () => _showAddSheetDialog(context),
                  ),
                ],
              ),
            ),

            // Formula Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cellCoord,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('fx',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _formulaController,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Nilai atau =FORMULA / Value or =FORMULA',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      onSubmitted: (val) {
                        final isFormula = val.startsWith('=');
                        widget.controller.updateXlsxCell(
                          row: _selectedRow,
                          col: _selectedCol,
                          value: isFormula ? val : val,
                          formula: isFormula ? val : null,
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, size: 20),
                    tooltip: 'Terapkan / Apply',
                    onPressed: () {
                      final val = _formulaController.text;
                      final isFormula = val.startsWith('=');
                      widget.controller.updateXlsxCell(
                        row: _selectedRow,
                        col: _selectedCol,
                        value: isFormula ? val : val,
                        formula: isFormula ? val : null,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Row Action Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              child: Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Baris / + Row'),
                    onPressed: () {
                      widget.controller
                          .addXlsxRow(List.generate(maxCols, (_) => ''));
                    },
                  ),
                  if (rows.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text('Hapus Baris ${_selectedRow + 1} / - Row'),
                      onPressed: () {
                        widget.controller.deleteXlsxRow(_selectedRow);
                        if (_selectedRow > 0) {
                          setState(() {
                            _selectedRow--;
                            _updateFormulaBar();
                          });
                        }
                      },
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'Edit Sel / Edit Cell',
                    onPressed: () => _showCellEditModal(context),
                  ),
                ],
              ),
            ),

            // Spreadsheet Grid
            Expanded(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    defaultColumnWidth: const FixedColumnWidth(90),
                    border: TableBorder.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 0.8,
                    ),
                    children: [
                      // Header Row (A, B, C...)
                      TableRow(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        children: [
                          // Top-left blank corner
                          Container(
                            height: 32,
                            width: 40,
                            alignment: Alignment.center,
                            child: const Text('#',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          for (var c = 0; c < maxCols; c++)
                            Container(
                              height: 32,
                              alignment: Alignment.center,
                              child: Text(
                                _colIndexToLetter(c),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                        ],
                      ),

                      // Data Rows
                      for (var r = 0; r < rows.length; r++)
                        TableRow(
                          children: [
                            // Row number
                            Container(
                              height: 36,
                              color: theme.colorScheme.surfaceContainerHighest,
                              alignment: Alignment.center,
                              child: Text('${r + 1}',
                                  style: const TextStyle(fontSize: 11)),
                            ),
                            for (var c = 0; c < maxCols; c++)
                              _buildCellWidget(
                                context,
                                row: r,
                                col: c,
                                cell: c < rows[r].length
                                    ? rows[r][c]
                                    : XlsxCell(),
                                theme: theme,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCellWidget(
    BuildContext context, {
    required int row,
    required int col,
    required XlsxCell cell,
    required ThemeData theme,
  }) {
    final isSelected = row == _selectedRow && col == _selectedCol;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRow = row;
          _selectedCol = col;
          _updateFormulaBar();
        });
      },
      onDoubleTap: () {
        setState(() {
          _selectedRow = row;
          _selectedCol = col;
          _updateFormulaBar();
        });
        _showCellEditModal(context);
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : null,
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          cell.value.isEmpty && cell.formula != null
              ? cell.formula!
              : cell.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: cell.bold ? FontWeight.bold : FontWeight.normal,
            fontStyle: cell.italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  void _showAddSheetDialog(BuildContext context) {
    final nameController = TextEditingController(
      text: 'Sheet${widget.controller.xlsxSheetNames.length + 1}',
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Sheet / Add Sheet'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama Sheet / Sheet Name',
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
              if (nameController.text.trim().isNotEmpty) {
                widget.controller.addXlsxSheet(nameController.text.trim());
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Tambah / Add'),
          ),
        ],
      ),
    );
  }

  void _showCellEditModal(BuildContext context) {
    final rows = widget.controller.activeSheetRows;
    final currentCell =
        (_selectedRow < rows.length && _selectedCol < rows[_selectedRow].length)
            ? rows[_selectedRow][_selectedCol]
            : XlsxCell();

    final valController = TextEditingController(text: currentCell.value);
    final formulaController =
        TextEditingController(text: currentCell.formula ?? '');
    var isBold = currentCell.bold;
    var isItalic = currentCell.italic;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
              'Edit Sel ${_colIndexToLetter(_selectedCol)}${_selectedRow + 1}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: valController,
                decoration: const InputDecoration(
                  labelText: 'Nilai / Value',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: formulaController,
                decoration: const InputDecoration(
                  labelText: 'Formula (mis: =SUM(A1:A5))',
                  border: OutlineInputBorder(),
                  prefixText: 'fx: ',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Bold'),
                    selected: isBold,
                    onSelected: (val) => setDialogState(() => isBold = val),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Italic'),
                    selected: isItalic,
                    onSelected: (val) => setDialogState(() => isItalic = val),
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
                final formText = formulaController.text.trim();
                widget.controller.updateXlsxCell(
                  row: _selectedRow,
                  col: _selectedCol,
                  value: valController.text,
                  formula: formText.isNotEmpty ? formText : null,
                  bold: isBold,
                  italic: isItalic,
                );
                _updateFormulaBar();
                Navigator.of(ctx).pop();
              },
              child: const Text('Simpan / Save'),
            ),
          ],
        ),
      ),
    );
  }
}
