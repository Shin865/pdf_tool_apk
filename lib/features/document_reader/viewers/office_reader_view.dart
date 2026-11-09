import 'dart:io';

import 'package:document_reviewer/core/engine/document_reader_engine.dart';
import 'package:document_reviewer/core/engine/office_editor_engine.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:document_reviewer/data/engine_impl/native_office_editor_engine.dart';
import 'package:document_reviewer/data/saf/saf_file_service.dart';
import 'package:document_reviewer/data/save/save_coordinator.dart';
import 'package:document_reviewer/features/office_editor/office_editor_controller.dart';
import 'package:document_reviewer/features/office_editor/ui/docx_editor_widget.dart';
import 'package:document_reviewer/features/office_editor/ui/office_adaptive_toolbar.dart';
import 'package:document_reviewer/features/office_editor/ui/xlsx_editor_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Interactive viewer and editor for Microsoft Office documents (DOCX and XLSX)
/// powered by Apache POI via native Android platform channel.
class OfficeReaderView extends StatefulWidget {
  const OfficeReaderView({
    required this.filePath,
    required this.mimeType,
    this.engine,
    this.officeEngine,
    this.saveCoordinator,
    this.safService,
    this.sourceUri,
    this.documentId,
    this.onDocumentModified,
    super.key,
  });

  final String filePath;
  final String mimeType;
  final DocumentReaderEngine? engine;
  final OfficeEditorEngine? officeEngine;
  final SaveCoordinator? saveCoordinator;
  final SafFileService? safService;
  final String? sourceUri;
  final int? documentId;
  final void Function(String newPath)? onDocumentModified;

  @override
  State<OfficeReaderView> createState() => _OfficeReaderViewState();
}

class _OfficeReaderViewState extends State<OfficeReaderView> {
  final MethodChannel _channel =
      const MethodChannel('com.example.documentreviewer/engine');

  late OfficeEditorEngine _officeEngine;
  OfficeEditorController? _controller;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isEditMode = false;

  // DOCX read-only state
  List<String> _docxParagraphs = [];

  // XLSX read-only state
  List<String> _xlsxSheetNames = [];
  int _activeSheetIndex = 0;
  List<List<String>> _xlsxSheetRows = [];

  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool get _isDocx =>
      widget.mimeType.contains('word') ||
      widget.mimeType.contains('document') ||
      widget.filePath.endsWith('.docx');

  @override
  void initState() {
    super.initState();
    _officeEngine = widget.officeEngine ?? NativeOfficeEditorEngine();
    _loadDocument();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final docType =
          _isDocx ? OfficeDocumentType.docx : OfficeDocumentType.xlsx;

      // Prepare drafts directory
      final appSupportDir = await getApplicationSupportDirectory();
      final draftsDir = Directory('${appSupportDir.path}/drafts');
      if (!draftsDir.existsSync()) {
        draftsDir.createSync(recursive: true);
      }

      final controller = OfficeEditorController(
        filePath: widget.filePath,
        documentType: docType,
        sourceUri: widget.sourceUri,
        draftsDirectory: draftsDir,
      );

      await controller.loadFromEngine(_officeEngine);
      _controller = controller;

      if (_isDocx) {
        await _loadDocx();
      } else {
        await _loadXlsx();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (await controller.hasDraft()) {
          _promptDraftRecovery();
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _promptDraftRecovery() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.history, color: Colors.blue),
            SizedBox(width: 8),
            Text('Pulihkan Draf Edit?'),
          ],
        ),
        content: const Text(
          'Ditemukan draf edit yang belum disimpan dari sesi sebelumnya. Apakah Anda ingin memulihkan perubahan tersebut?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _controller?.discardDraft();
              Navigator.of(ctx).pop();
            },
            child: const Text('Abaikan / Discard'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _controller?.restoreDraft();
              if (mounted) {
                setState(() {
                  _isEditMode = true;
                });
              }
            },
            child: const Text('Pulihkan / Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDocx() async {
    try {
      final paragraphs = await _channel.invokeMethod<List<dynamic>>(
        'docx_getParagraphs',
        {'filePath': widget.filePath},
      );
      if (paragraphs != null) {
        _docxParagraphs = paragraphs
            .map((p) => (p as Map<dynamic, dynamic>)['text']?.toString() ?? '')
            .where((text) => text.trim().isNotEmpty)
            .toList();
      }
    } on PlatformException {
      if (widget.engine != null) {
        final text = await widget.engine!.extractText(pageIndex: 0);
        _docxParagraphs = text.split('\n');
      }
    }
  }

  Future<void> _loadXlsx() async {
    try {
      final sheets = await _channel.invokeMethod<List<dynamic>>(
        'xlsx_getSheetNames',
        {'filePath': widget.filePath},
      );
      if (sheets != null) {
        _xlsxSheetNames = sheets.map((s) => s.toString()).toList();
      } else {
        _xlsxSheetNames = ['Sheet 1'];
      }
      await _loadSheetData(_activeSheetIndex);
    } on PlatformException {
      _xlsxSheetNames = ['Sheet 1'];
      _xlsxSheetRows = [];
    }
  }

  Future<void> _loadSheetData(int sheetIndex) async {
    try {
      final rows = await _channel.invokeMethod<List<dynamic>>(
        'xlsx_getSheetData',
        {'filePath': widget.filePath, 'sheetIndex': sheetIndex},
      );
      if (rows != null) {
        _xlsxSheetRows = rows
            .map(
              (r) => (r as List<dynamic>).map((c) {
                if (c is Map) {
                  return c['value']?.toString() ?? '';
                }
                return c.toString();
              }).toList(),
            )
            .toList();
      }
    } on PlatformException {
      _xlsxSheetRows = [];
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

  // ─────────────────────────────────────────────────────────────────────────
  // Save Handlers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handleSaveAs() async {
    final ctrl = _controller;
    if (ctrl == null) return;

    final appSupportDir = await getApplicationSupportDirectory();
    final exportDir = Directory('${appSupportDir.path}/export');
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }

    final ext = _isDocx ? '.docx' : '.xlsx';
    final newPath =
        '${exportDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}$ext';

    final ok = await ctrl.commitToFile(
      engine: _officeEngine,
      targetPath: newPath,
    );

    if (ok && mounted) {
      widget.onDocumentModified?.call(newPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Disimpan sebagai file baru di:\n$newPath'),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan file baru')),
      );
    }
  }

  Future<void> _handleOverwrite() async {
    final ctrl = _controller;
    if (ctrl == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Konfirmasi Timpa File'),
          ],
        ),
        content: const Text(
          'PERINGATAN: Tindakan ini akan menimpa file asli secara permanen.\n\nSimpan sebagai file baru sangat disarankan untuk menjaga keutuhan dokumen. Lanjutkan menimpa?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal / Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Timpa Berkas / Overwrite'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await ctrl.commitToFile(
      engine: _officeEngine,
      targetPath: widget.filePath,
    );

    if (ok && mounted) {
      if (widget.saveCoordinator != null &&
          widget.sourceUri != null &&
          widget.documentId != null) {
        final session = await widget.saveCoordinator!.startSession(
          documentId: widget.documentId!,
          sourceUri: widget.sourceUri!,
          displayName: p.basename(widget.filePath),
          mimeType: widget.mimeType,
        );
        final result = await widget.saveCoordinator!.save(session);
        if (result.success && mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'File berhasil ditimpa dan disimpan lewat Save Coordinator',
              ),
            ),
          );
        }
      } else if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('File berhasil diperbarui')),
        );
      }
      await _loadDocument();
    } else if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal menimpa dokumen')),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI Builder
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      );
    }

    final ctrl = _controller;

    return Column(
      children: [
        // Mode switch header: [Lihat / View] vs [Edit Dasar / Edit]
        Container(
          color: theme.colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Lihat / View'),
                    icon: Icon(Icons.visibility, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Edit Dasar / Edit'),
                    icon: Icon(Icons.edit, size: 16),
                  ),
                ],
                selected: {_isEditMode},
                onSelectionChanged: (set) {
                  final newMode = set.first;
                  if (!newMode && (ctrl?.isDirty ?? false)) {
                    showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Perubahan Belum Disimpan'),
                        content: const Text(
                          'Terdapat perubahan yang belum disimpan. Tetap beralih ke mode lihat?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Beralih'),
                          ),
                        ],
                      ),
                    ).then((ok) {
                      if ((ok ?? false) && mounted) {
                        setState(() => _isEditMode = false);
                      }
                    });
                  } else {
                    setState(() => _isEditMode = newMode);
                  }
                },
              ),
              const Spacer(),
              if (_isEditMode && ctrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    ctrl.isDirty ? '• Diedit' : 'Tersimpan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ctrl.isDirty
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Body: Edit Mode vs Read-Only Mode
        Expanded(
          child: _isEditMode && ctrl != null
              ? _buildEditModeBody(ctrl)
              : _buildReadOnlyModeBody(loc, theme),
        ),
      ],
    );
  }

  Widget _buildEditModeBody(OfficeEditorController ctrl) {
    return OfficeKeyboardShortcuts(
      controller: ctrl,
      onSave: _handleSaveAs,
      child: Column(
        children: [
          // Tablet Top Ribbon if width >= 600
          OfficeAdaptiveToolbar(
            controller: ctrl,
            onSaveAs: _handleSaveAs,
            onOverwrite: _handleOverwrite,
            onAddParagraph:
                _isDocx ? () => ctrl.addDocxParagraph('Paragraf baru') : null,
            onAddHeading:
                _isDocx ? () => ctrl.addDocxHeading('Heading Baru') : null,
            onAddTable: _isDocx ? () => ctrl.addDocxTable(2, 2) : null,
            onAddPageBreak: _isDocx ? ctrl.addDocxPageBreak : null,
            onAddSheet: !_isDocx
                ? () =>
                    ctrl.addXlsxSheet('Sheet${ctrl.xlsxSheetNames.length + 1}')
                : null,
            onAddRow:
                !_isDocx ? () => ctrl.addXlsxRow(['', '', '', '', '']) : null,
          ),

          // Editor View
          Expanded(
            child: _isDocx
                ? DocxEditorWidget(controller: ctrl)
                : XlsxEditorWidget(controller: ctrl),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyModeBody(AppLocalizations loc, ThemeData theme) {
    return Column(
      children: [
        // Search bar
        Container(
          color: theme.colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: loc.searchHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
            ],
          ),
        ),

        // Read-only Content
        Expanded(
          child: _isDocx
              ? _buildDocxReadOnlyView(theme)
              : _buildXlsxReadOnlyView(theme),
        ),
      ],
    );
  }

  Widget _buildDocxReadOnlyView(ThemeData theme) {
    final filtered = _docxParagraphs.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _docxParagraphs.isEmpty
              ? 'Dokumen kosong / Empty document'
              : 'Tidak ada hasil / No results found',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final text = filtered[index];
        final isHeading =
            text.length < 50 && (text.startsWith('#') || text.endsWith(':'));

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            text,
            style: isHeading
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )
                : theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        );
      },
    );
  }

  Widget _buildXlsxReadOnlyView(ThemeData theme) {
    return Column(
      children: [
        if (_xlsxSheetNames.length > 1)
          Container(
            height: 48,
            color: theme.colorScheme.surfaceContainerHighest,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _xlsxSheetNames.length,
              itemBuilder: (context, index) {
                final isSelected = index == _activeSheetIndex;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text(_xlsxSheetNames[index]),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _activeSheetIndex = index;
                        });
                        _loadSheetData(index);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: _xlsxSheetRows.isEmpty
              ? Center(
                  child: Text(
                    'Sheet kosong / Empty sheet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Table(
                        defaultColumnWidth: const IntrinsicColumnWidth(),
                        border: TableBorder.all(
                          color: theme.colorScheme.outlineVariant,
                          width: 0.5,
                        ),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                child: const Text(
                                  '#',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              for (var c = 0;
                                  c <
                                      (_xlsxSheetRows.isNotEmpty
                                          ? _xlsxSheetRows[0].length
                                          : 0);
                                  c++)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    _colIndexToLetter(c),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          for (var r = 0; r < _xlsxSheetRows.length; r++)
                            TableRow(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: Text(
                                    '${r + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                for (var c = 0;
                                    c < _xlsxSheetRows[r].length;
                                    c++)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      _xlsxSheetRows[r][c],
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
