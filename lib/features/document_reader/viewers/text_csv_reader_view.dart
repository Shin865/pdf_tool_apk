import 'dart:convert';
import 'dart:io';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

/// Viewer for TXT, LOG, MD, and CSV files.
/// Designed for low memory consumption with chunked/lazy reading
/// to support files up to 100 MB without freezing or out-of-memory.
class TextCsvReaderView extends StatefulWidget {
  const TextCsvReaderView({
    required this.filePath,
    this.isCsv = false,
    super.key,
  });

  final String filePath;
  final bool isCsv;

  @override
  State<TextCsvReaderView> createState() => _TextCsvReaderViewState();
}

class _TextCsvReaderViewState extends State<TextCsvReaderView> {
  bool _isLoading = true;
  String? _errorMessage;

  // Text viewer state
  List<String> _textLines = [];
  int _totalLines = 0;

  // CSV viewer state
  List<String> _csvHeaders = [];
  List<List<String>> _csvRows = [];

  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFile() async {
    try {
      final file = File(widget.filePath);
      if (!file.existsSync()) {
        if (mounted) {
          setState(() {
            _errorMessage = 'File not found';
            _isLoading = false;
          });
        }
        return;
      }

      final fileSize = file.lengthSync();
      // Fast path for small files (<= 2 MB): read instantly
      if (fileSize <= 2 * 1024 * 1024) {
        final content = file.readAsStringSync();
        if (widget.isCsv) {
          _parseCsvContent(content);
        } else {
          _textLines = const LineSplitter().convert(content);
          _totalLines = _textLines.length;
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Streaming path for large files (> 2 MB) to preserve RAM
      if (widget.isCsv) {
        await _loadCsv(file);
      } else {
        await _loadText(file);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  void _parseCsvContent(String content) {
    final rawLines = const LineSplitter().convert(content);
    final rows = <List<String>>[];
    String? delimiter;
    for (final line in rawLines) {
      if (line.trim().isEmpty) continue;
      delimiter ??= _detectDelimiter(line);
      final cols = _parseCsvLine(line, delimiter);
      if (rows.isEmpty) {
        _csvHeaders = cols;
        rows.add(cols);
      } else {
        rows.add(cols);
      }
    }
    if (rows.isNotEmpty) {
      _csvRows = rows.sublist(1);
    }
    _totalLines = rows.length;
  }

  Future<void> _loadText(File file) async {
    final lines = <String>[];
    const maxLinesToLoad = 50000;
    var lineCount = 0;

    final stream =
        file.openRead().transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in stream) {
      lineCount++;
      if (lines.length < maxLinesToLoad) {
        lines.add(line);
      }
    }

    _textLines = lines;
    _totalLines = lineCount;
  }

  Future<void> _loadCsv(File file) async {
    final rows = <List<String>>[];
    const maxRowsToLoad = 10000;

    final stream =
        file.openRead().transform(utf8.decoder).transform(const LineSplitter());

    String? delimiter;

    await for (final line in stream) {
      if (line.trim().isEmpty) continue;

      delimiter ??= _detectDelimiter(line);

      final cols = _parseCsvLine(line, delimiter);
      if (rows.isEmpty) {
        _csvHeaders = cols;
        rows.add(cols);
      } else if (rows.length < maxRowsToLoad) {
        rows.add(cols);
      }
    }

    if (rows.isNotEmpty) {
      _csvRows = rows.sublist(1);
    }
    _totalLines = rows.length;
  }

  String _detectDelimiter(String line) {
    final commas = ','.allMatches(line).length;
    final semicolons = ';'.allMatches(line).length;
    final tabs = '\t'.allMatches(line).length;
    if (tabs > commas && tabs > semicolons) return '\t';
    if (semicolons > commas) return ';';
    return ',';
  }

  List<String> _parseCsvLine(String line, String delimiter) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == delimiter && !inQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString().trim());
    return result;
  }

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

    return Column(
      children: [
        // Search & Filter header
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
              const SizedBox(width: 12),
              Chip(
                label: Text(
                  widget.isCsv
                      ? '${_csvRows.length} rows'
                      : '$_totalLines lines',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),

        // Content Area
        Expanded(
          child: widget.isCsv ? _buildCsvTable(theme) : _buildTextView(theme),
        ),
      ],
    );
  }

  Widget _buildTextView(ThemeData theme) {
    final filteredLines = _searchQuery.isEmpty
        ? _textLines
        : _textLines
            .where((l) => l.toLowerCase().contains(_searchQuery))
            .toList();

    return SelectionArea(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredLines.length,
        itemBuilder: (context, index) {
          final line = filteredLines[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line number
                SizedBox(
                  width: 48,
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    line,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCsvTable(ThemeData theme) {
    final filteredRows = _searchQuery.isEmpty
        ? _csvRows
        : _csvRows.where((row) {
            return row.any((cell) => cell.toLowerCase().contains(_searchQuery));
          }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            theme.colorScheme.surfaceContainerHighest,
          ),
          columns: _csvHeaders
              .map(
                (h) => DataColumn(
                  label: Text(
                    h.isNotEmpty ? h : 'Col',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
              .toList(),
          rows: filteredRows.map((row) {
            return DataRow(
              cells: List.generate(
                _csvHeaders.length,
                (i) => DataCell(
                  Text(i < row.length ? row[i] : ''),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
