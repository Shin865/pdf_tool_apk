/// Home screen — main entry point for the user.
///
/// Features:
/// - Open file via SAF
/// - Recent documents & favorites
/// - Search by name, category filter (All, PDF, Office, Images, Text/CSV)
/// - Sorting (name, date, size)
/// - Share file & Remove from list (without deleting original file)
/// - Adaptive layout: single panel on phones, two-panel (master-detail) on tablets
library;

import 'dart:async';

import 'package:document_reviewer/app/providers.dart';
import 'package:document_reviewer/app/router.dart';
import 'package:document_reviewer/core/constants/app_constants.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:document_reviewer/data/database/app_database.dart';
import 'package:document_reviewer/data/save/save_coordinator.dart';
import 'package:document_reviewer/features/document_reader/document_reader_screen.dart';
import 'package:document_reviewer/shared/widgets/adaptive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum DocumentCategoryFilter {
  all,
  pdf,
  office,
  images,
  text,
}

enum DocumentSortOption {
  dateDesc,
  dateAsc,
  nameAsc,
  nameDesc,
  sizeDesc,
  sizeAsc,
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Provider for the list of recent documents.
final recentDocumentsProvider =
    FutureProvider.autoDispose<List<DocumentRecord>>((ref) async {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.getRecentDocuments();
});

/// Provider for favorite documents.
final favoriteDocumentsProvider =
    FutureProvider.autoDispose<List<DocumentRecord>>((ref) async {
  final repo = ref.watch(documentRepositoryProvider);
  return repo.getFavorites();
});

/// Provider for pending recovered sessions from process death.
final pendingRecoveryProvider =
    FutureProvider.autoDispose<List<EditingSession>>((ref) async {
  final coordinator = ref.watch(saveCoordinatorProvider);
  return coordinator.checkForPendingRecovery();
});

// ---------------------------------------------------------------------------
// Home Screen
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  DocumentCategoryFilter _selectedCategory = DocumentCategoryFilter.all;
  DocumentSortOption _sortOption = DocumentSortOption.dateDesc;
  final TextEditingController _searchController = TextEditingController();

  // For two-panel master-detail layout on tablet / landscape
  DocumentRecord? _selectedDocument;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onDocumentSelected(DocumentRecord document, bool isTablet) {
    if (isTablet) {
      setState(() {
        _selectedDocument = document;
      });
    } else {
      context.push(
        Uri(
          path: AppRoutes.reader,
          queryParameters: {
            'uri': document.uri,
            'displayName': document.displayName,
            'mimeType': document.mimeType,
          },
        ).toString(),
      );
    }
  }

  Future<void> _pickFile() async {
    final repo = ref.read(documentRepositoryProvider);
    final doc = await repo.pickAndOpenDocument(
      mimeTypes: SupportedMimeTypes.all,
    );

    if (doc != null && mounted) {
      ref
        ..invalidate(recentDocumentsProvider)
        ..invalidate(favoriteDocumentsProvider);

      setState(() {
        _selectedDocument = doc;
      });

      // On phone, navigate to reader
      final isTablet = MediaQuery.of(context).size.width >= 600;
      if (!isTablet) {
        unawaited(
          context.push(
            Uri(
              path: AppRoutes.reader,
              queryParameters: {
                'uri': doc.uri,
                'displayName': doc.displayName,
                'mimeType': doc.mimeType,
              },
            ).toString(),
          ),
        );
      }
    }
  }

  List<DocumentRecord> _filterAndSort(List<DocumentRecord> rawList) {
    var list = rawList.toList();

    // 1. Search filter
    if (_searchQuery.isNotEmpty) {
      list = list.where((d) {
        return d.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // 2. Category filter
    list = list.where((d) {
      final name = d.displayName.toLowerCase();
      final mime = d.mimeType.toLowerCase();
      return switch (_selectedCategory) {
        DocumentCategoryFilter.all => true,
        DocumentCategoryFilter.pdf =>
          mime == SupportedMimeTypes.pdf || name.endsWith('.pdf'),
        DocumentCategoryFilter.office => mime.contains('word') ||
            mime.contains('sheet') ||
            name.endsWith('.docx') ||
            name.endsWith('.xlsx'),
        DocumentCategoryFilter.images => mime.startsWith('image/') ||
            name.endsWith('.jpg') ||
            name.endsWith('.jpeg') ||
            name.endsWith('.png') ||
            name.endsWith('.webp') ||
            name.endsWith('.bmp'),
        DocumentCategoryFilter.text => mime.startsWith('text/') ||
            mime == SupportedMimeTypes.csv ||
            name.endsWith('.txt') ||
            name.endsWith('.csv') ||
            name.endsWith('.log') ||
            name.endsWith('.md'),
      };
    }).toList();

    // 3. Sorting
    switch (_sortOption) {
      case DocumentSortOption.dateDesc:
        list.sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
      case DocumentSortOption.dateAsc:
        list.sort((a, b) => a.lastOpenedAt.compareTo(b.lastOpenedAt));
      case DocumentSortOption.nameAsc:
        list.sort(
          (a, b) => a.displayName
              .toLowerCase()
              .compareTo(b.displayName.toLowerCase()),
        );
      case DocumentSortOption.nameDesc:
        list.sort(
          (a, b) => b.displayName
              .toLowerCase()
              .compareTo(a.displayName.toLowerCase()),
        );
      case DocumentSortOption.sizeDesc:
        list.sort(
          (a, b) => (b.fileSizeBytes ?? 0).compareTo(a.fileSizeBytes ?? 0),
        );
      case DocumentSortOption.sizeAsc:
        list.sort(
          (a, b) => (a.fileSizeBytes ?? 0).compareTo(b.fileSizeBytes ?? 0),
        );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;

        return AdaptiveScaffold(
          currentIndex: 0,
          onNavigationIndexChanged: (index) {
            if (index == 1) {
              context.push(AppRoutes.settings);
            }
          },
          destinations: [
            AdaptiveDestination(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: loc.appTitle,
              semanticLabel: loc.appTitle,
            ),
            AdaptiveDestination(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: loc.settings,
              semanticLabel: loc.settings,
            ),
          ],
          appBar: AppBar(
            title: Text(loc.appTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.document_scanner_outlined),
                tooltip: loc.scanDocument,
                onPressed: () => context.push(AppRoutes.scanner),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: loc.settings,
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
          body: isTablet
              ? _buildTwoPanelLayout(isTablet)
              : _buildSinglePanelLayout(isTablet),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _pickFile,
            icon: const Icon(Icons.file_open),
            label: Text(loc.openFile),
          ),
        );
      },
    );
  }

  Widget _buildSinglePanelLayout(bool isTablet) {
    final loc = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(recentDocumentsProvider)
          ..invalidate(favoriteDocumentsProvider)
          ..invalidate(pendingRecoveryProvider);
      },
      child: CustomScrollView(
        slivers: [
          // Process death recovery prompt if present
          const SliverToBoxAdapter(
            child: _RecoveryBannerSection(),
          ),

          // Open File and Scan Document buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _OpenFileButton(onPick: _pickFile),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ScanDocumentButton(
                      onScan: () => context.push(AppRoutes.scanner),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search & Filter controls
          SliverToBoxAdapter(
            child: _buildSearchAndFilterBar(),
          ),

          // Favorites section
          SliverToBoxAdapter(
            child: _SectionHeader(title: loc.favoriteDocuments),
          ),
          _buildFavoritesList(isTablet),

          // Recent documents section
          SliverToBoxAdapter(
            child: _SectionHeader(title: loc.recentDocuments),
          ),
          _buildRecentList(isTablet),

          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoPanelLayout(bool isTablet) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        // Left Panel: Document List (Width 400)
        SizedBox(
          width: 400,
          child: Column(
            children: [
              // Search & filter
              _buildSearchAndFilterBar(),

              // Document list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref
                      ..invalidate(recentDocumentsProvider)
                      ..invalidate(favoriteDocumentsProvider)
                      ..invalidate(pendingRecoveryProvider);
                  },
                  child: CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(
                        child: _RecoveryBannerSection(),
                      ),
                      SliverToBoxAdapter(
                        child: _SectionHeader(title: loc.recentDocuments),
                      ),
                      _buildRecentList(isTablet),
                      SliverToBoxAdapter(
                        child: _SectionHeader(title: loc.favoriteDocuments),
                      ),
                      _buildFavoritesList(isTablet),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 80),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const VerticalDivider(width: 1),

        // Right Panel: Preview Area
        Expanded(
          child: _selectedDocument != null
              ? DocumentReaderScreen(
                  key: ValueKey(_selectedDocument!.uri),
                  uri: _selectedDocument!.uri,
                  displayName: _selectedDocument!.displayName,
                  mimeType: _selectedDocument!.mimeType,
                  isEmbedded: true,
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 72,
                          color:
                              theme.colorScheme.onSurfaceVariant.withAlpha(100),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.twoPanelPlaceholder,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search TextField & Sort Menu
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: loc.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<DocumentSortOption>(
                icon: const Icon(Icons.sort),
                tooltip: loc.sortBy,
                initialValue: _sortOption,
                onSelected: (opt) {
                  setState(() {
                    _sortOption = opt;
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: DocumentSortOption.dateDesc,
                    child: Text(loc.sortDateDesc),
                  ),
                  PopupMenuItem(
                    value: DocumentSortOption.dateAsc,
                    child: Text(loc.sortDateAsc),
                  ),
                  PopupMenuItem(
                    value: DocumentSortOption.nameAsc,
                    child: Text(loc.sortNameAsc),
                  ),
                  PopupMenuItem(
                    value: DocumentSortOption.nameDesc,
                    child: Text(loc.sortNameDesc),
                  ),
                  PopupMenuItem(
                    value: DocumentSortOption.sizeDesc,
                    child: Text(loc.sortSizeDesc),
                  ),
                  PopupMenuItem(
                    value: DocumentSortOption.sizeAsc,
                    child: Text(loc.sortSizeAsc),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(
                  label: loc.categoryAll,
                  category: DocumentCategoryFilter.all,
                  icon: Icons.apps,
                ),
                _buildCategoryChip(
                  label: loc.categoryPdf,
                  category: DocumentCategoryFilter.pdf,
                  icon: Icons.picture_as_pdf,
                ),
                _buildCategoryChip(
                  label: loc.categoryOffice,
                  category: DocumentCategoryFilter.office,
                  icon: Icons.article,
                ),
                _buildCategoryChip(
                  label: loc.categoryImages,
                  category: DocumentCategoryFilter.images,
                  icon: Icons.image,
                ),
                _buildCategoryChip(
                  label: loc.categoryText,
                  category: DocumentCategoryFilter.text,
                  icon: Icons.text_snippet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required DocumentCategoryFilter category,
    required IconData icon,
  }) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategory = category;
            });
          }
        },
      ),
    );
  }

  Widget _buildRecentList(bool isTablet) {
    final recentsAsync = ref.watch(recentDocumentsProvider);
    final loc = AppLocalizations.of(context);

    return recentsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SliverToBoxAdapter(
        child: _ErrorCard(message: 'Failed to load recents: $err'),
      ),
      data: (recents) {
        final filtered = _filterAndSort(recents);
        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyState(
              icon: Icons.description_outlined,
              message: loc.noRecentDocuments,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = filtered[index];
              final isSelected = _selectedDocument?.id == doc.id;
              return _DocumentListTile(
                document: doc,
                isSelected: isSelected,
                onTap: () => _onDocumentSelected(doc, isTablet),
                onFavoriteToggle: () async {
                  await ref
                      .read(documentRepositoryProvider)
                      .toggleFavorite(doc.id, isFavorite: !doc.isFavorite);
                  ref
                    ..invalidate(recentDocumentsProvider)
                    ..invalidate(favoriteDocumentsProvider);
                },
                onRemoveFromList: () => _showRemoveDialog(doc),
                onShare: () {
                  ref.read(documentRepositoryProvider).shareDocument(doc);
                },
              );
            },
            childCount: filtered.length,
          ),
        );
      },
    );
  }

  Widget _buildFavoritesList(bool isTablet) {
    final favoritesAsync = ref.watch(favoriteDocumentsProvider);
    final loc = AppLocalizations.of(context);

    return favoritesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SliverToBoxAdapter(
        child: _ErrorCard(message: 'Failed to load favorites: $err'),
      ),
      data: (favorites) {
        final filtered = _filterAndSort(favorites);
        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyState(
              icon: Icons.star_border,
              message: loc.noFavorites,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final doc = filtered[index];
              final isSelected = _selectedDocument?.id == doc.id;
              return _DocumentListTile(
                document: doc,
                isSelected: isSelected,
                onTap: () => _onDocumentSelected(doc, isTablet),
                onFavoriteToggle: () async {
                  await ref
                      .read(documentRepositoryProvider)
                      .toggleFavorite(doc.id, isFavorite: false);
                  ref
                    ..invalidate(favoriteDocumentsProvider)
                    ..invalidate(recentDocumentsProvider);
                },
                onRemoveFromList: () => _showRemoveDialog(doc),
                onShare: () {
                  ref.read(documentRepositoryProvider).shareDocument(doc);
                },
              );
            },
            childCount: filtered.length,
          ),
        );
      },
    );
  }

  void _showRemoveDialog(DocumentRecord doc) {
    final loc = AppLocalizations.of(context);

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.removeDialogTitle),
        content: Text(loc.removeDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.remove),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed ?? false) {
        await ref
            .read(documentRepositoryProvider)
            .removeDocumentFromList(doc.id);
        if (_selectedDocument?.id == doc.id) {
          setState(() {
            _selectedDocument = null;
          });
        }
        ref
          ..invalidate(recentDocumentsProvider)
          ..invalidate(favoriteDocumentsProvider);
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _RecoveryBannerSection extends ConsumerWidget {
  const _RecoveryBannerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recoveryAsync = ref.watch(pendingRecoveryProvider);
    final loc = AppLocalizations.of(context);

    return recoveryAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) return const SizedBox.shrink();
        final session = sessions.first;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.restore_page,
                        color:
                            Theme.of(context).colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.recoveryPrompt,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.displayName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final coordinator = ref.read(saveCoordinatorProvider);
                          await coordinator.discardSession(session);
                          ref.invalidate(pendingRecoveryProvider);
                        },
                        child: Text(loc.discard),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: () {
                          context.push(
                            Uri(
                              path: AppRoutes.reader,
                              queryParameters: {
                                'uri': session.sourceUri,
                                'displayName': session.displayName,
                                'mimeType': session.mimeType,
                              },
                            ).toString(),
                          );
                        },
                        child: Text(loc.restore),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _OpenFileButton extends StatelessWidget {
  const _OpenFileButton({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Card(
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Text(
                loc.openFile,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanDocumentButton extends StatelessWidget {
  const _ScanDocumentButton({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Card(
      child: InkWell(
        onTap: onScan,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.document_scanner,
                size: 32,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 16),
              Text(
                loc.scanDocument,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _DocumentListTile extends StatelessWidget {
  const _DocumentListTile({
    required this.document,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onRemoveFromList,
    required this.onShare,
    this.isSelected = false,
  });

  final DocumentRecord document;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onRemoveFromList;
  final VoidCallback onShare;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return Card(
      color:
          isSelected ? theme.colorScheme.primaryContainer.withAlpha(80) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: _mimeIcon(document.mimeType),
        title: Text(
          document.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          _formatFileInfo(document),
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                document.isFavorite ? Icons.star : Icons.star_border,
                color: document.isFavorite ? Colors.amber : null,
              ),
              tooltip: document.isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
              onPressed: onFavoriteToggle,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Options',
              onSelected: (val) {
                if (val == 'share') {
                  onShare();
                } else if (val == 'remove') {
                  onRemoveFromList();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      const Icon(Icons.share, size: 20),
                      const SizedBox(width: 8),
                      Text(loc.share),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loc.removeFromList,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _mimeIcon(String mimeType) {
    final (IconData icon, Color color) = switch (mimeType) {
      'application/pdf' => (Icons.picture_as_pdf, Colors.red),
      final String m when m.contains('word') || m.contains('document') => (
          Icons.article,
          Colors.blue
        ),
      final String m when m.contains('sheet') || m.contains('spreadsheet') => (
          Icons.table_chart,
          Colors.green
        ),
      final String m when m.contains('presentation') => (
          Icons.slideshow,
          Colors.orange
        ),
      final String m when m.startsWith('image/') => (
          Icons.image,
          Colors.purple
        ),
      final String m
          when m.startsWith('text/') || m == SupportedMimeTypes.csv =>
        (Icons.text_snippet, Colors.teal),
      _ => (Icons.insert_drive_file, Colors.blueGrey),
    };

    return CircleAvatar(
      backgroundColor: color.withAlpha(30),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _formatFileInfo(DocumentRecord doc) {
    final parts = <String>[];
    if (doc.fileSizeBytes != null && doc.fileSizeBytes! > 0) {
      parts.add(_formatBytes(doc.fileSizeBytes!));
    }
    parts.add(_formatDate(doc.lastOpenedAt));
    return parts.join(' · ');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final surfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: surfaceVariant.withAlpha(100),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: surfaceVariant.withAlpha(150),
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
