import 'package:document_reviewer/core/engine/document_scanner_engine.dart';
import 'package:document_reviewer/core/localization/app_localizations.dart';
import 'package:flutter/material.dart';

/// Filter selection bar for scanned documents.
class FilterSelectorBar extends StatelessWidget {
  const FilterSelectorBar({
    required this.selectedFilter,
    required this.onFilterSelected,
    super.key,
  });

  final ScanFilterMode selectedFilter;
  final ValueChanged<ScanFilterMode> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    final filters = [
      (
        mode: ScanFilterMode.original,
        label: loc.filterOriginal,
        icon: Icons.photo_outlined,
      ),
      (
        mode: ScanFilterMode.magicColor,
        label: loc.filterMagic,
        icon: Icons.auto_awesome,
      ),
      (
        mode: ScanFilterMode.grayscale,
        label: loc.filterGrayscale,
        icon: Icons.gradient,
      ),
      (
        mode: ScanFilterMode.blackWhite,
        label: loc.filterBw,
        icon: Icons.contrast,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: filters.map((f) {
          final isSelected = selectedFilter == f.mode;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              avatar: Icon(f.icon, size: 18),
              label: Text(f.label),
              selected: isSelected,
              onSelected: (_) => onFilterSelected(f.mode),
            ),
          );
        }).toList(),
      ),
    );
  }
}
