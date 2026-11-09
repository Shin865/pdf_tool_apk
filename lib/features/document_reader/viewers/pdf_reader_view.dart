import 'dart:io';

import 'package:document_reviewer/core/engine/document_reader_engine.dart';
import 'package:document_reviewer/core/engine/pdf_annotation_engine.dart';
import 'package:document_reviewer/core/engine/pdf_page_engine.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:document_reviewer/data/engine_impl/native_pdf_annotation_engine.dart';
import 'package:document_reviewer/data/engine_impl/native_pdf_page_engine.dart';
import 'package:document_reviewer/data/saf/saf_file_service.dart';
import 'package:document_reviewer/data/save/save_coordinator.dart';
import 'package:document_reviewer/features/pdf_tools/annotations/pdf_annotation_controller.dart';
import 'package:document_reviewer/features/pdf_tools/annotations/pdf_annotation_overlay.dart';
import 'package:document_reviewer/features/pdf_tools/annotations/pdf_tool_mode.dart';
import 'package:document_reviewer/features/pdf_tools/annotations/pdf_tools_bottom_bar.dart';
import 'package:document_reviewer/features/pdf_tools/pages/pdf_page_manager_screen.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Bounded LRU cache for rendered PDF page bitmaps.
/// Evicts least recently used pages when capacity is exceeded to prevent out-of-memory.
class _LruPageCache {
  _LruPageCache({this.maxPages = 8});

  final int maxPages;
  final Map<int, RenderedPage> _cache = {};

  RenderedPage? get(int pageIndex) {
    final page = _cache.remove(pageIndex);
    if (page != null) {
      _cache[pageIndex] = page;
    }
    return page;
  }

  void put(int pageIndex, RenderedPage page) {
    if (_cache.length >= maxPages) {
      _cache.remove(_cache.keys.first);
    }
    _cache[pageIndex] = page;
  }

  void clear() => _cache.clear();
  void remove(int pageIndex) => _cache.remove(pageIndex);
}

/// PDF reader widget with bounded cache, pinch-zoom, page navigation,
/// thumbnails/jump-to-page, text search navigation, and integrated PDF tools.
class PdfReaderView extends StatefulWidget {
  const PdfReaderView({
    required this.engine,
    required this.metadata,
    this.filePath,
    this.sourceUri,
    this.documentId,
    this.annotationEngine,
    this.pageEngine,
    this.saveCoordinator,
    this.safService,
    this.initialPageIndex = 0,
    this.initialZoom = 1.0,
    this.onPageChanged,
    this.onDocumentModified,
    this.maxCachePages = 8,
    super.key,
  });

  final DocumentReaderEngine engine;
  final DocumentMetadata metadata;
  final String? filePath;
  final String? sourceUri;
  final int? documentId;
  final PdfAnnotationEngine? annotationEngine;
  final PdfPageEngine? pageEngine;
  final SaveCoordinator? saveCoordinator;
  final SafFileService? safService;
  final int initialPageIndex;
  final double initialZoom;
  final void Function(int pageIndex)? onPageChanged;
  final void Function(String newPath)? onDocumentModified;
  final int maxCachePages;

  @override
  State<PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends State<PdfReaderView> {
  late int _currentPageIndex;
  late int _pageCount;
  late String? _currentFilePath;
  late final _LruPageCache _cache;
  final TransformationController _transformationController =
      TransformationController();

  bool _isLoading = false;
  String? _errorMessage;
  RenderedPage? _renderedPage;

  // Search state
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  List<TextSearchResult> _searchResults = [];
  int _currentMatchIndex = -1;
  bool _isSearchingLoading = false;

  // PDF Tools State
  bool _isToolsMode = false;
  PdfToolMode _toolMode = PdfToolMode.view;
  late final PdfAnnotationController _annotationController;
  late final PdfAnnotationEngine _annotationEngine;
  late final PdfPageEngine _pageEngine;
  String? _activeSignaturePath;

  @override
  void initState() {
    super.initState();
    _currentFilePath = widget.filePath;
    _pageCount = widget.metadata.pageCount;
    _currentPageIndex = widget.initialPageIndex.clamp(
      0,
      (_pageCount - 1).clamp(0, 999999),
    );
    _cache = _LruPageCache(maxPages: widget.maxCachePages);
    _annotationController = PdfAnnotationController(
      documentUri: widget.sourceUri ?? widget.filePath ?? 'doc_default',
    );
    _annotationEngine = widget.annotationEngine ?? NativePdfAnnotationEngine();
    _pageEngine = widget.pageEngine ?? NativePdfPageEngine();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPage(_currentPageIndex);
        _checkForDrafts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _transformationController.dispose();
    _annotationController.dispose();
    _cache.clear();
    super.dispose();
  }

  Future<void> _checkForDrafts() async {
    final hasDraft = await _annotationController.hasDraft();
    if (hasDraft && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Draf anotasi sebelumnya ditemukan (setelah proses ditutup).',
          ),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Pulihkan',
            onPressed: () async {
              final ok = await _annotationController.restoreDraft();
              if (ok && mounted) {
                setState(() => _isToolsMode = true);
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _loadPage(int pageIndex) async {
    if (!mounted) return;

    // Check LRU cache first
    final cached = _cache.get(pageIndex);
    if (cached != null) {
      setState(() {
        _currentPageIndex = pageIndex;
        _renderedPage = cached;
        _errorMessage = null;
        _isLoading = false;
      });
      widget.onPageChanged?.call(pageIndex);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final width = MediaQuery.maybeOf(context)?.size.width.toInt() ?? 600;
      final renderWidth = (width > 0 ? width : 600) * 2; // High resolution
      final page = await widget.engine.renderPage(
        pageIndex: pageIndex,
        width: renderWidth,
      );

      _cache.put(pageIndex, page);

      if (mounted) {
        setState(() {
          _currentPageIndex = pageIndex;
          _renderedPage = page;
          _isLoading = false;
        });
        widget.onPageChanged?.call(pageIndex);
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _goToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pageCount) return;
    _transformationController.value = Matrix4.identity();
    _loadPage(pageIndex);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _currentMatchIndex = -1;
      });
      return;
    }

    setState(() {
      _isSearchingLoading = true;
    });

    try {
      final results = await widget.engine.searchText(query: query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearchingLoading = false;
          _currentMatchIndex = results.isNotEmpty ? 0 : -1;
        });
        if (results.isNotEmpty) {
          _goToPage(results[0].pageIndex);
        }
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearchingLoading = false;
          _currentMatchIndex = -1;
        });
      }
    }
  }

  void _nextMatch() {
    if (_searchResults.isEmpty) return;
    final nextIdx = (_currentMatchIndex + 1) % _searchResults.length;
    setState(() {
      _currentMatchIndex = nextIdx;
    });
    _goToPage(_searchResults[nextIdx].pageIndex);
  }

  void _prevMatch() {
    if (_searchResults.isEmpty) return;
    final prevIdx = (_currentMatchIndex - 1 + _searchResults.length) %
        _searchResults.length;
    setState(() {
      _currentMatchIndex = prevIdx;
    });
    _goToPage(_searchResults[prevIdx].pageIndex);
  }

  void _showJumpToPageDialog() {
    final loc = AppLocalizations.of(context);
    final controller =
        TextEditingController(text: (_currentPageIndex + 1).toString());

    showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.goToPage),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '${loc.page} (1 - $_pageCount)',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final page = int.tryParse(value);
            if (page != null) {
              Navigator.of(context).pop(page - 1);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null) {
                Navigator.of(context).pop(page - 1);
              }
            },
            child: Text(loc.goToPage),
          ),
        ],
      ),
    ).then((selectedPage) {
      if (selectedPage != null && mounted) {
        _goToPage(selectedPage);
      }
    });
  }

  void _showThumbnailsSheet() {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${loc.page} (1 - $_pageCount)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _pageCount,
                    itemBuilder: (context, index) {
                      final isSelected = index == _currentPageIndex;
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          _goToPage(index);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withAlpha(50)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- PDF Tools Handlers ---

  Future<void> _handleSaveAs() async {
    final path = _currentFilePath;
    if (path == null) return;

    final appSupportDir = await getApplicationSupportDirectory();
    final exportDir = Directory('${appSupportDir.path}/export');
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }

    final newPath =
        '${exportDir.path}/annotated_${DateTime.now().millisecondsSinceEpoch}.pdf';

    // Commit staged annotations via engine
    await _annotationEngine.openForAnnotation(filePath: path);
    for (final a in _annotationController.annotations) {
      await _annotationEngine.addAnnotation(a);
    }
    final success =
        await _annotationEngine.saveAnnotatedDocument(outputPath: newPath);

    if (success && mounted) {
      await _annotationController.discardDraft();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Disimpan sebagai file baru di:\n$newPath'),
          ),
        );
      }
    }
  }

  Future<void> _handleOverwrite() async {
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
          'PERINGATAN: Menimpa file asli akan memperbarui dokumen sumber secara permanen lewat Save Coordinator.\n\nApakah Anda yakin ingin menimpa file asli?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Timpa File Asli'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final path = _currentFilePath;
    if (path == null) return;

    final messenger = ScaffoldMessenger.of(context);

    // Commit staged annotations to working file
    await _annotationEngine.openForAnnotation(filePath: path);
    for (final a in _annotationController.annotations) {
      await _annotationEngine.addAnnotation(a);
    }
    await _annotationEngine.saveAnnotatedDocument(outputPath: path);

    // Coordinate save back through SaveCoordinator if source URI available
    if (widget.saveCoordinator != null &&
        widget.sourceUri != null &&
        widget.documentId != null) {
      final session = await widget.saveCoordinator!.startSession(
        documentId: widget.documentId!,
        sourceUri: widget.sourceUri!,
        displayName: widget.metadata.title,
        mimeType: widget.metadata.mimeType,
      );
      final result = await widget.saveCoordinator!.save(session);
      if (mounted) {
        if (result.success) {
          await _annotationController.discardDraft();
          messenger.showSnackBar(
            const SnackBar(content: Text('Berhasil menyimpan ke file asli.')),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Gagal menimpa file asli: ${result.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      await _annotationController.discardDraft();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Dokumen kerja berhasil diperbarui.')),
        );
      }
    }

    _cache.clear();
    await _loadPage(_currentPageIndex);
  }

  Future<void> _handleExportImage() async {
    final path = _currentFilePath;
    if (path == null) return;

    final tempDir = await getTemporaryDirectory();
    final outImgPath =
        '${tempDir.path}/page_${_currentPageIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.png';

    final ok = await _pageEngine.exportPageToImage(
      filePath: path,
      pageIndex: _currentPageIndex,
      outputPath: outImgPath,
    );

    if (ok && File(outImgPath).existsSync() && mounted) {
      final saf = widget.safService ?? SafFileService();
      await saf.shareFile(
        uri: Uri.file(outImgPath).toString(),
        mimeType: 'image/png',
        displayName: 'Gambar Halaman ${_currentPageIndex + 1}',
      );
    }
  }

  Future<void> _handleShare() async {
    final path = _currentFilePath;
    if (path == null) return;
    final saf = widget.safService ?? SafFileService();
    await saf.shareFile(
      uri: path.startsWith('content://') ? path : Uri.file(path).toString(),
      mimeType: 'application/pdf',
      displayName: widget.metadata.title,
    );
  }

  Future<void> _openPageManager() async {
    final path = _currentFilePath;
    if (path == null) return;

    final modifiedPath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (ctx) => PdfPageManagerScreen(
          filePath: path,
          initialPageCount: _pageCount,
          pageEngine: _pageEngine,
          safService: widget.safService,
        ),
      ),
    );

    if (modifiedPath != null && mounted) {
      _currentFilePath = modifiedPath;
      _cache.clear();
      // Re-open with reader engine
      final meta = await widget.engine.openDocument(filePath: modifiedPath);
      setState(() {
        _pageCount = meta.pageCount;
        _currentPageIndex = _currentPageIndex.clamp(0, _pageCount - 1);
      });
      await _loadPage(_currentPageIndex);
      widget.onDocumentModified?.call(modifiedPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search bar (if search is active)
        if (_isSearching)
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: loc.searchInDocument,
                      border: InputBorder.none,
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 20),
                    ),
                    onSubmitted: _performSearch,
                  ),
                ),
                if (_isSearchingLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_searchResults.isNotEmpty) ...[
                  Text(
                    '${_currentMatchIndex + 1}/${_searchResults.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    tooltip: 'Previous match',
                    onPressed: _prevMatch,
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    tooltip: 'Next match',
                    onPressed: _nextMatch,
                  ),
                ] else if (_searchController.text.isNotEmpty)
                  Text(
                    loc.noMatchesFound,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: loc.close,
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchResults = [];
                      _searchController.clear();
                    });
                  },
                ),
              ],
            ),
          ),

        // Main Viewer Area
        Expanded(
          child: Stack(
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                panEnabled: _toolMode == PdfToolMode.view,
                scaleEnabled: _toolMode == PdfToolMode.view,
                maxScale: 4,
                child: Center(
                  child: Stack(
                    children: [
                      if (_renderedPage != null &&
                          _renderedPage!.pixels.isNotEmpty)
                        Image.memory(
                          _renderedPage!.pixels,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        )
                      else if (!_isLoading)
                        Text(
                          _errorMessage ?? 'Page ${_currentPageIndex + 1}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      // Annotation overlay
                      if (_isToolsMode)
                        PdfAnnotationOverlay(
                          pageIndex: _currentPageIndex,
                          controller: _annotationController,
                          toolMode: _toolMode,
                          activeSignaturePath: _activeSignaturePath,
                        ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),

              // Action Floating Buttons (Top-Right)
              Positioned(
                top: 16,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PDF Tools Toggle
                    FloatingActionButton.small(
                      heroTag: 'pdf_tools_toggle_btn',
                      tooltip: _isToolsMode
                          ? 'Tutup Alat PDF'
                          : 'Buka Alat PDF / Edit',
                      backgroundColor: _isToolsMode
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surface,
                      foregroundColor: _isToolsMode
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      onPressed: () {
                        setState(() {
                          _isToolsMode = !_isToolsMode;
                          if (!_isToolsMode) {
                            _toolMode = PdfToolMode.view;
                          }
                        });
                      },
                      child: Icon(_isToolsMode ? Icons.edit_off : Icons.edit),
                    ),
                    const SizedBox(width: 8),
                    // Floating search button
                    if (!_isSearching)
                      FloatingActionButton.small(
                        heroTag: 'pdf_search_btn',
                        tooltip: loc.searchInDocument,
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                          });
                        },
                        child: const Icon(Icons.search),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Conditional Bottom Bar: Tools or Reader Navigation
        if (_isToolsMode)
          PdfToolsBottomBar(
            currentMode: _toolMode,
            onModeChanged: (mode) => setState(() => _toolMode = mode),
            controller: _annotationController,
            onSaveAs: _handleSaveAs,
            onOverwrite: _handleOverwrite,
            onOpenPageManager: _openPageManager,
            onExportImage: _handleExportImage,
            onShare: _handleShare,
            onSignatureCreated: (path) {
              setState(() {
                _activeSignaturePath = path;
              });
            },
          )
        else
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.grid_view),
                    tooltip: 'Pages overview',
                    onPressed: _showThumbnailsSheet,
                  ),
                  IconButton(
                    icon: const Icon(Icons.navigate_before),
                    tooltip: 'Previous page',
                    onPressed: _currentPageIndex > 0
                        ? () => _goToPage(_currentPageIndex - 1)
                        : null,
                  ),
                  if (_pageCount > 1)
                    Expanded(
                      child: Slider(
                        value: _currentPageIndex.toDouble(),
                        max: (_pageCount - 1).toDouble(),
                        divisions: _pageCount > 1 ? _pageCount - 1 : 1,
                        onChanged: (val) {
                          _goToPage(val.round());
                        },
                      ),
                    )
                  else
                    const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.navigate_next),
                    tooltip: 'Next page',
                    onPressed: _currentPageIndex < _pageCount - 1
                        ? () => _goToPage(_currentPageIndex + 1)
                        : null,
                  ),
                  TextButton(
                    onPressed: _showJumpToPageDialog,
                    child: Text(
                      '${_currentPageIndex + 1} / $_pageCount',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
