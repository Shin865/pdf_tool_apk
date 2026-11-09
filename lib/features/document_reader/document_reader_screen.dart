import 'dart:io';

import 'package:document_reviewer/app/providers.dart';
import 'package:document_reviewer/core/constants/app_constants.dart';
import 'package:document_reviewer/core/engine/document_reader_engine.dart';
import 'package:document_reviewer/core/error/exceptions.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/features/document_reader/viewers/image_reader_view.dart';
import 'package:document_reviewer/features/document_reader/viewers/office_reader_view.dart';
import 'package:document_reviewer/features/document_reader/viewers/pdf_reader_view.dart';
import 'package:document_reviewer/features/document_reader/viewers/text_csv_reader_view.dart';
import 'package:document_reviewer/features/document_reader/widgets/password_dialog.dart';
import 'package:document_reviewer/features/document_reader/widgets/reader_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Screen for viewing and interacting with documents.
/// Dispatches to format-specific viewers with bounded memory cache,
/// reading position persistence, orientation lock, and password unlocking.
class DocumentReaderScreen extends ConsumerStatefulWidget {
  const DocumentReaderScreen({
    required this.uri,
    this.displayName,
    this.mimeType,
    this.isEmbedded = false,
    super.key,
  });

  final String uri;
  final String? displayName;
  final String? mimeType;
  final bool isEmbedded;

  @override
  ConsumerState<DocumentReaderScreen> createState() =>
      _DocumentReaderScreenState();
}

class _DocumentReaderScreenState extends ConsumerState<DocumentReaderScreen> {
  bool _isLoading = true;
  Object? _error;
  String? _localFilePath;
  DocumentRecord? _documentRecord;
  DocumentMetadata? _metadata;
  int _lastPageIndex = 0;
  double _lastZoomLevel = 1;

  // Reading modes: Orientation lock
  int _orientationMode = 0; // 0 = Auto, 1 = Portrait, 2 = Landscape

  @override
  void initState() {
    super.initState();
    _openDocument();
  }

  @override
  void didUpdateWidget(covariant DocumentReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      _openDocument();
    }
  }

  @override
  void dispose() {
    _persistReadingPosition();
    // Reset orientation lock on leave
    SystemChrome.setPreferredOrientations([]);
    ref.read(documentReaderEngineProvider).closeDocument();
    super.dispose();
  }

  Future<void> _openDocument([String? password]) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = ref.read(documentRepositoryProvider);
    final engine = ref.read(documentReaderEngineProvider);
    final dirManager = ref.read(storageDirectoryManagerProvider);

    try {
      // 1. Check URI accessibility if SAF URI
      if (widget.uri.startsWith('content://')) {
        final accessible = await dirManager.isUriAccessible(widget.uri);
        if (!accessible) {
          throw DocumentNotFoundException(
            'Cannot access URI: ${widget.uri}',
          );
        }
      }

      // 2. Fetch or create DocumentRecord
      final record = await repo.getDocumentByUri(widget.uri);
      final title = widget.displayName ??
          record?.displayName ??
          widget.uri.split('/').last;

      // 3. Obtain working copy
      String? localPath;
      if (record != null) {
        localPath = await repo.getWorkingCopy(record);
      }

      if (localPath == null) {
        // Fallback: copy directly or use local path
        if (widget.uri.startsWith('content://')) {
          final workPath =
              await dirManager.getWorkingCopyPath(widget.uri, title);
          final copied = await ref.read(safServiceProvider).copyToLocal(
                uri: widget.uri,
                destinationPath: workPath,
              );
          if (!copied) {
            throw DocumentNotFoundException(
              'Failed to create working copy of ${widget.uri}',
            );
          }
          localPath = workPath;
        } else {
          localPath = widget.uri.replaceFirst('file://', '');
        }
      }

      if (!File(localPath).existsSync()) {
        throw DocumentNotFoundException('File does not exist: $localPath');
      }

      _localFilePath = localPath;
      _documentRecord = record;

      // 4. Restore last reading position
      if (record != null) {
        final lastPos = await repo.getReadingPosition(record.id);
        if (lastPos != null) {
          _lastPageIndex = lastPos.lastPageIndex;
          _lastZoomLevel = lastPos.lastZoomLevel;
        }
      }

      // 5. Open in engine if supported
      try {
        _metadata = await engine.openDocument(
          filePath: localPath,
          password: password,
        );
      } on DocumentEncryptedException {
        // Prompt for password
        if (mounted) {
          final enteredPassword = await PasswordDialog.show(context);
          if (enteredPassword != null) {
            await _openDocument(enteredPassword);
            return;
          }
        }
        rethrow;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e;
        });
      }
    }
  }

  void _persistReadingPosition() {
    final record = _documentRecord;
    if (record != null && _localFilePath != null) {
      ref.read(documentRepositoryProvider).updateReadingPosition(
            documentId: record.id,
            pageIndex: _lastPageIndex,
            zoomLevel: _lastZoomLevel,
          );
    }
  }

  void _toggleOrientationLock() {
    setState(() {
      _orientationMode = (_orientationMode + 1) % 3;
    });

    switch (_orientationMode) {
      case 1:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      case 2:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      default:
        SystemChrome.setPreferredOrientations([]);
    }
  }

  String _detectMimeType(String uri) {
    final lower = uri.toLowerCase();
    if (lower.endsWith('.pdf')) return SupportedMimeTypes.pdf;
    if (lower.endsWith('.docx')) return SupportedMimeTypes.docx;
    if (lower.endsWith('.xlsx')) return SupportedMimeTypes.xlsx;
    if (lower.endsWith('.csv')) return SupportedMimeTypes.csv;
    if (lower.endsWith('.txt') ||
        lower.endsWith('.log') ||
        lower.endsWith('.md')) {
      return SupportedMimeTypes.txt;
    }
    if (lower.endsWith('.png')) return SupportedMimeTypes.png;
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return SupportedMimeTypes.jpeg;
    }
    if (lower.endsWith('.webp')) return SupportedMimeTypes.webp;
    if (lower.endsWith('.bmp')) return SupportedMimeTypes.bmp;
    return 'application/octet-stream';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final title = widget.displayName ??
        _documentRecord?.displayName ??
        p.basename(widget.uri);

    final orientationIcon = switch (_orientationMode) {
      1 => Icons.screen_lock_portrait,
      2 => Icons.screen_lock_landscape,
      _ => Icons.screen_rotation,
    };

    final orientationTooltip = switch (_orientationMode) {
      1 => loc.orientationPortrait,
      2 => loc.orientationLandscape,
      _ => loc.orientationAuto,
    };

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  icon: Icon(orientationIcon),
                  tooltip: orientationTooltip,
                  onPressed: _toggleOrientationLock,
                ),
                IconButton(
                  icon: Icon(
                    theme.brightness == Brightness.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  tooltip: loc.theme,
                  onPressed: () {
                    final current = ref.read(themeModeProvider);
                    ref.read(themeModeProvider.notifier).state =
                        current == ThemeModePreference.dark
                            ? ThemeModePreference.light
                            : ThemeModePreference.dark;
                  },
                ),
                if (_documentRecord != null)
                  IconButton(
                    icon: const Icon(Icons.share),
                    tooltip: loc.share,
                    onPressed: () {
                      ref
                          .read(documentRepositoryProvider)
                          .shareDocument(_documentRecord!);
                    },
                  ),
              ],
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ReaderErrorView(
        error: _error!,
        onRetry: _openDocument,
        onUnlock: () async {
          final pwd = await PasswordDialog.show(context);
          if (pwd != null) {
            await _openDocument(pwd);
          }
        },
        onClose: () {
          if (!widget.isEmbedded && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      );
    }

    final path = _localFilePath;
    if (path == null) {
      return const Center(child: Text('No file loaded'));
    }

    final mime =
        widget.mimeType ?? _documentRecord?.mimeType ?? _detectMimeType(path);
    final engine = ref.read(documentReaderEngineProvider);

    // Format dispatching
    if (mime == SupportedMimeTypes.pdf || path.toLowerCase().endsWith('.pdf')) {
      final meta = _metadata ??
          DocumentMetadata(
            title: p.basename(path),
            pageCount: 1,
            mimeType: SupportedMimeTypes.pdf,
          );
      return PdfReaderView(
        engine: engine,
        metadata: meta,
        filePath: path,
        sourceUri: widget.uri,
        documentId: _documentRecord?.id,
        annotationEngine: ref.read(pdfAnnotationEngineProvider),
        pageEngine: ref.read(pdfPageEngineProvider),
        saveCoordinator: ref.read(saveCoordinatorProvider),
        safService: ref.read(safServiceProvider),
        initialPageIndex: _lastPageIndex,
        initialZoom: _lastZoomLevel,
        onPageChanged: (page) {
          _lastPageIndex = page;
          _persistReadingPosition();
        },
        onDocumentModified: (newPath) {
          _localFilePath = newPath;
        },
      );
    } else if (mime.startsWith('image/') ||
        path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.jpeg') ||
        path.toLowerCase().endsWith('.png') ||
        path.toLowerCase().endsWith('.webp') ||
        path.toLowerCase().endsWith('.bmp')) {
      return ImageReaderView(filePath: path);
    } else if (mime == SupportedMimeTypes.csv ||
        path.toLowerCase().endsWith('.csv')) {
      return TextCsvReaderView(filePath: path, isCsv: true);
    } else if (mime.startsWith('text/') ||
        path.toLowerCase().endsWith('.txt') ||
        path.toLowerCase().endsWith('.log') ||
        path.toLowerCase().endsWith('.md')) {
      return TextCsvReaderView(filePath: path);
    } else if (mime.contains('word') ||
        mime.contains('spreadsheet') ||
        path.toLowerCase().endsWith('.docx') ||
        path.toLowerCase().endsWith('.xlsx')) {
      return OfficeReaderView(
        filePath: path,
        mimeType: mime,
        engine: engine,
        officeEngine: ref.read(officeEditorEngineProvider),
        saveCoordinator: ref.read(saveCoordinatorProvider),
        safService: ref.read(safServiceProvider),
        sourceUri: widget.uri,
        documentId: _documentRecord?.id,
        onDocumentModified: (newPath) {
          _localFilePath = newPath;
        },
      );
    }

    // Fallback unsupported format
    return ReaderErrorView(
      error: UnsupportedFormatException(
        'Format $mime is not supported for reading',
      ),
      onClose: () {
        if (!widget.isEmbedded && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
